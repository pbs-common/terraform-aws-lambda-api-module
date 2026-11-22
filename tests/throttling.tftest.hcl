# Stage throttling.
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

run "defaults_throttle_the_stage" {
  assert {
    condition     = aws_apigatewayv2_stage.stage.default_route_settings[0].throttling_burst_limit == 200
    error_message = "Default burst limit must be 200."
  }
  assert {
    condition     = aws_apigatewayv2_stage.stage.default_route_settings[0].throttling_rate_limit == 100
    error_message = "Default rate limit must be 100."
  }
}

# --- throttling ----------------------------------------------------------------

run "throttling_can_be_raised_and_rate_may_be_fractional" {
  variables {
    throttling_burst_limit = 5000
    throttling_rate_limit  = 0.5
  }
  assert {
    condition     = aws_apigatewayv2_stage.stage.default_route_settings[0].throttling_burst_limit == 5000
    error_message = "The burst limit must be wired to the stage."
  }
  assert {
    condition     = aws_apigatewayv2_stage.stage.default_route_settings[0].throttling_rate_limit == 0.5
    error_message = "The rate limit must be wired to the stage."
  }
}

run "throttling_null_keeps_the_default" {
  variables {
    throttling_burst_limit = null
    throttling_rate_limit  = null
  }
  assert {
    condition     = aws_apigatewayv2_stage.stage.default_route_settings[0].throttling_burst_limit == 200 && aws_apigatewayv2_stage.stage.default_route_settings[0].throttling_rate_limit == 100
    error_message = "null must not switch throttling off."
  }
}

run "refuses_fractional_burst" {
  command = plan
  variables {
    throttling_burst_limit = 1.5
  }
  expect_failures = [var.throttling_burst_limit]
}

run "refuses_negative_burst" {
  command = plan
  variables {
    throttling_burst_limit = -1
  }
  expect_failures = [var.throttling_burst_limit]
}

run "refuses_burst_above_int32" {
  command = plan
  variables {
    throttling_burst_limit = 2147483648
  }
  expect_failures = [var.throttling_burst_limit]
}

run "refuses_negative_rate" {
  command = plan
  variables {
    throttling_rate_limit = -0.5
  }
  expect_failures = [var.throttling_rate_limit]
}

run "refuses_rate_above_int32" {
  command = plan
  variables {
    throttling_rate_limit = 2147483648
  }
  expect_failures = [var.throttling_rate_limit]
}
