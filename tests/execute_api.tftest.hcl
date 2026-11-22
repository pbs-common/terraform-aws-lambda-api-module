# The default execute-api endpoint.
# HTTP APIs cannot take AWS WAF, so throttling, route authorization and the
# disabled execute-api endpoint are the API's only protections. The mocked
# provider makes no AWS calls. Run from the module root: terraform test

mock_provider "aws" {
  source = "./tests/mocks"
}

variables {
  handler             = "bootstrap"
  filename            = "examples/artifacts/handler.zip"
  runtime             = "provided.al2023"
  primary_hosted_zone = "example.org"

  environment  = "dev"
  product      = "example-lambda-api"
  owner        = "plops"
  repo         = "https://github.com/pbs/terraform-aws-lambda-api-module.git"
  organization = "example"

  authorization_type = "AWS_IAM"
}

run "defaults_disable_the_execute_api_endpoint" {
  assert {
    condition     = aws_apigatewayv2_api.api.disable_execute_api_endpoint == true
    error_message = "The execute-api endpoint must be disabled: the module always creates a custom domain."
  }
}

# --- execute-api endpoint --------------------------------------------------------

run "refuses_enabling_the_execute_api_endpoint" {
  command = plan
  variables {
    disable_execute_api_endpoint = false
  }
  expect_failures = [var.disable_execute_api_endpoint]
}

run "execute_api_null_keeps_it_disabled" {
  variables {
    disable_execute_api_endpoint = null
  }
  assert {
    condition     = aws_apigatewayv2_api.api.disable_execute_api_endpoint == true
    error_message = "null must not enable the execute-api endpoint."
  }
}
