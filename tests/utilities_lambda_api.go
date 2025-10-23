package test

import (
	"fmt"
	"io/ioutil"
	"net/http"
	"os"
	"testing"
	"time"
	"bytes"
	"context"
	"os/exec"

	"github.com/gruntwork-io/terratest/modules/docker"
	httpHelper "github.com/gruntwork-io/terratest/modules/http-helper"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/ecr"
	"github.com/aws/aws-sdk-go-v2/service/sts"
)

func ecrLogin() {
	ctx := context.Background()

	// Load AWS config
	cfg, err := config.LoadDefaultConfig(ctx, config.WithRegion("us-east-1"))
	if err != nil {
		panic(err)
	}

	// Get AWS account ID
	stsClient := sts.NewFromConfig(cfg)
	id, err := stsClient.GetCallerIdentity(ctx, &sts.GetCallerIdentityInput{})
	if err != nil {
		panic(err)
	}
	accountID := *id.Account

	// Get ECR login password
	ecrClient := ecr.NewFromConfig(cfg)
	auth, err := ecrClient.GetAuthorizationToken(ctx, &ecr.GetAuthorizationTokenInput{})
	if err != nil {
		panic(err)
	}
	password := ""
	if len(auth.AuthorizationData) > 0 {
		password = *auth.AuthorizationData[0].AuthorizationToken
	}

	// Decode base64 password
	decoded, err := exec.Command("bash", "-c", fmt.Sprintf("echo %s | base64 -d | cut -d: -f2", password)).Output()
	if err != nil {
		panic(err)
	}

	// Docker login
	registry := fmt.Sprintf("%s.dkr.ecr.us-east-1.amazonaws.com", accountID)
	cmd := exec.Command("docker", "login", "--username", "AWS", "--password-stdin", registry)
	cmd.Stdin = bytes.NewReader(decoded)
	out, err := cmd.CombinedOutput()
	if err != nil {
		panic(string(out))
	}
	fmt.Println(string(out))
}

func testLambdaAPI(t *testing.T, variant string) {
	t.Parallel()

	primaryHostedZone := os.Getenv("TF_VAR_primary_hosted_zone")

	if primaryHostedZone == "" {
		t.Fatal("TF_VAR_primary_hosted_zone must be set to run tests. e.g. 'export TF_VAR_primary_hosted_zone=example.org'")
	}

	terraformDir := fmt.Sprintf("../examples/%s", variant)

	terraformOptions := &terraform.Options{
		TerraformDir: terraformDir,
		LockTimeout:  "5m",
		Upgrade:      true,
	}

	defer terraform.Destroy(t, terraformOptions)

	expectedName := fmt.Sprintf("ex-tf-lambda-api-%s", variant)

	// This is annoying, but necessary. Log Group isn't cleaned up correctly after destroy.
	logGroupName := fmt.Sprintf("/aws/lambda/%s", expectedName)
	deleteLogGroup(t, logGroupName)

	terraform.Init(t, terraformOptions)

	dockerResponse := ""

	if variant == "docker" {
		ecrTargetTerraformOptions := &terraform.Options{
			TerraformDir: terraformDir,
			LockTimeout:  "5m",
			Upgrade:      true,
			Targets:      []string{"module.ecr"},
		}

		terraform.Apply(t, ecrTargetTerraformOptions)

		ecrRepo := terraform.Output(t, ecrTargetTerraformOptions, "ecr_repo_url")

		tag := fmt.Sprintf("%s:latest", ecrRepo)
		buildOptions := &docker.BuildOptions{
			Tags:          []string{tag},
			Architectures: []string{"linux/arm64"},
			OtherOptions: []string{
				"--provenance", "false", "--load",
			},
		}

		docker.Build(t, "../examples/src-docker", buildOptions)

		// We can test the image locally before pushing it to ECR

		logger := logger.Terratest

		runOptions := &docker.RunOptions{
			Remove: true,
			Detach: true,
			Name:   variant,
			OtherOptions: []string{
				"-p", "8080:8080",
			},
		}

		docker.Run(t, tag, runOptions)
		defer docker.Stop(t, []string{variant}, &docker.StopOptions{Time: 5, Logger: logger})

		resp, err := http.Get("http://localhost:8080/")

		if err != nil {
			for i := 0; i < 10; i++ {
				t.Log("Waiting for container to start...")
				time.Sleep(1 * time.Second)
				resp, err = http.Get("http://localhost:8080/")
				if err == nil {
					break
				}
			}
			if err != nil {
				t.Fatal(err)
			}
		}

		defer resp.Body.Close()

		assert.Equal(t, 200, resp.StatusCode)

		body, err := ioutil.ReadAll(resp.Body)

		if err != nil {
			t.Fatal(err)
		}

		assert.NotNil(t, body)

		dockerResponse = string(body)

        ecrLogin()
		docker.Push(t, logger, tag)
	}

	terraform.Apply(t, terraformOptions)

	region := getAWSRegion(t)

	expectedARNWithoutID := fmt.Sprintf("arn:aws:apigateway:%s::/apis/", region)
	expectedDomainName := fmt.Sprintf("%s.%s", expectedName, primaryHostedZone)

	if variant == "alt-domain" {
		expectedAltDomainName := os.Getenv("TF_VAR_alternate_domain_name")

		if expectedAltDomainName == "" {
			t.Fatalf("TF_VAR_alternate_domain_name must be set to test %s variant. e.g. 'export TF_VAR_alternate_domain_name=example.org'", variant)
		}

		altDomainName := terraform.Output(t, terraformOptions, "alternate_domain_name")
		assert.Equal(t, expectedAltDomainName, altDomainName)
		altDomainEndpoint := terraform.Output(t, terraformOptions, "alternate_domain_endpoint")
		assert.NotEmpty(t, altDomainEndpoint)
	}

	arn := terraform.Output(t, terraformOptions, "arn")
	assert.Contains(t, arn, expectedARNWithoutID)

	domainName := terraform.Output(t, terraformOptions, "domain_name")
	assert.Equal(t, expectedDomainName, domainName)

	baseURL := fmt.Sprintf("https://%s", domainName)
	statusURL := fmt.Sprintf("https://%s/status", domainName)
	expectedStatus := "ok"

	if variant != "docker" {
		httpHelper.HttpGetWithRetry(t, statusURL, nil, 200, expectedStatus, 60, 5*time.Second)
	} else {
		resp, err := http.Get(baseURL)

		if err != nil {
			for i := 0; i < 30; i++ {
				t.Log("Waiting for API to be available...")
				time.Sleep(1 * time.Second)
				resp, err = http.Get(baseURL)
				if err == nil {
					break
				}
			}
			if err != nil {
				t.Fatal(err)
			}
		}

		if err != nil {
			t.Fatal(err)
		}
		if resp.StatusCode != 200 {
			t.Fatalf("Expected 200, got %d", resp.StatusCode)
		}
		defer resp.Body.Close()
		body, err := ioutil.ReadAll(resp.Body)
		if err != nil {
			t.Fatal(err)
		}
		assert.NotNil(t, body)
		assert.Equal(t, dockerResponse, string(body))
	}
}
