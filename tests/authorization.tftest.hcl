# Route authorization.
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

run "aws_iam_route_has_no_authorizer" {
  assert {
    condition     = aws_apigatewayv2_route.route.authorization_type == "AWS_IAM"
    error_message = "The route must use the chosen authorization type."
  }
  assert {
    condition     = aws_apigatewayv2_route.route.authorizer_id == null
    error_message = "AWS_IAM takes no authorizer."
  }
  assert {
    condition     = length(aws_apigatewayv2_authorizer.jwt) == 0 && length(aws_apigatewayv2_authorizer.lambda) == 0
    error_message = "AWS_IAM creates no authorizer."
  }
  assert {
    condition     = length(aws_lambda_permission.authorizer) == 0
    error_message = "AWS_IAM grants no authorizer invoke permission."
  }
  assert {
    condition     = !contains(keys(aws_apigatewayv2_api.api.tags), "pbs:edge:exception")
    error_message = "An authenticated API carries no exception tag."
  }
}

# --- authorization type and the NONE exception --------------------------------

run "refuses_a_missing_authorization_type" {
  command = plan
  variables {
    authorization_type = null
  }
  expect_failures = [var.authorization_type]
}

run "refuses_an_unknown_authorization_type" {
  command = plan
  variables {
    authorization_type = "OPEN"
  }
  expect_failures = [var.authorization_type]
}

run "refuses_none_without_an_exception" {
  command = plan
  variables {
    authorization_type = "NONE"
  }
  expect_failures = [var.edge_exception]
}

run "none_with_an_exception_is_open_and_tagged" {
  variables {
    authorization_type = "NONE"
    edge_exception     = "pbs-common/terraform-aws-lambda-api-module#182"
  }
  assert {
    condition     = aws_apigatewayv2_route.route.authorization_type == "NONE"
    error_message = "The exception must allow NONE."
  }
  assert {
    condition     = aws_apigatewayv2_api.api.tags["pbs:edge:exception"] == "pbs-common/terraform-aws-lambda-api-module#182"
    error_message = "The exception must be recorded as the pbs:edge:exception tag on the API."
  }
}

run "refuses_an_exception_on_an_authenticated_route" {
  command = plan
  variables {
    edge_exception = "pbs-common/terraform-aws-lambda-api-module#182"
  }
  expect_failures = [var.edge_exception]
}

# The value is an Issue reference, <owner>/<repo>#<number>. Each refusal below
# breaks exactly one part of a reference the accepting runs take.

run "accepts_the_longest_owner_and_repo_and_number" {
  command = plan
  variables {
    authorization_type = "NONE"
    edge_exception     = "a-bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbc/${join("", [for i in range(100) : "r"])}#1234567890"
  }
}

run "accepts_dots_underscores_and_hyphens_in_the_repo" {
  command = plan
  variables {
    authorization_type = "NONE"
    edge_exception     = "pbs/my_repo.v2-x#7"
  }
}

run "refuses_free_text" {
  command = plan
  variables {
    authorization_type = "NONE"
    edge_exception     = "INC-123: public status endpoint"
  }
  expect_failures = [var.edge_exception]
}

run "refuses_a_blank_exception" {
  command = plan
  variables {
    authorization_type = "NONE"
    edge_exception     = "  "
  }
  expect_failures = [var.edge_exception]
}

run "refuses_trailing_text" {
  command = plan
  variables {
    authorization_type = "NONE"
    edge_exception     = "pbs-common/terraform-aws-lambda-api-module#182 approved"
  }
  expect_failures = [var.edge_exception]
}

run "refuses_an_owner_starting_with_a_hyphen" {
  command = plan
  variables {
    authorization_type = "NONE"
    edge_exception     = "-pbs/repo#1"
  }
  expect_failures = [var.edge_exception]
}

run "refuses_an_owner_ending_with_a_hyphen" {
  command = plan
  variables {
    authorization_type = "NONE"
    edge_exception     = "pbs-/repo#1"
  }
  expect_failures = [var.edge_exception]
}

run "refuses_an_owner_with_consecutive_hyphens" {
  command = plan
  variables {
    authorization_type = "NONE"
    edge_exception     = "pbs--common/repo#1"
  }
  expect_failures = [var.edge_exception]
}

run "refuses_an_owner_longer_than_39" {
  command = plan
  variables {
    authorization_type = "NONE"
    edge_exception     = "a-bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbc/repo#1"
  }
  expect_failures = [var.edge_exception]
}

run "refuses_a_repo_longer_than_100" {
  command = plan
  variables {
    authorization_type = "NONE"
    edge_exception     = "pbs/${join("", [for i in range(101) : "r"])}#1"
  }
  expect_failures = [var.edge_exception]
}

run "refuses_a_repo_named_dot" {
  command = plan
  variables {
    authorization_type = "NONE"
    edge_exception     = "pbs/.#1"
  }
  expect_failures = [var.edge_exception]
}

run "refuses_a_repo_named_dot_dot" {
  command = plan
  variables {
    authorization_type = "NONE"
    edge_exception     = "pbs/..#1"
  }
  expect_failures = [var.edge_exception]
}

run "refuses_a_repo_with_another_character" {
  command = plan
  variables {
    authorization_type = "NONE"
    edge_exception     = "pbs/repo!#1"
  }
  expect_failures = [var.edge_exception]
}

run "refuses_a_missing_number" {
  command = plan
  variables {
    authorization_type = "NONE"
    edge_exception     = "pbs/repo#"
  }
  expect_failures = [var.edge_exception]
}

run "refuses_issue_number_zero" {
  command = plan
  variables {
    authorization_type = "NONE"
    edge_exception     = "pbs/repo#0"
  }
  expect_failures = [var.edge_exception]
}

run "refuses_a_leading_zero" {
  command = plan
  variables {
    authorization_type = "NONE"
    edge_exception     = "pbs/repo#01"
  }
  expect_failures = [var.edge_exception]
}

run "refuses_a_number_longer_than_10_digits" {
  command = plan
  variables {
    authorization_type = "NONE"
    edge_exception     = "pbs/repo#12345678901"
  }
  expect_failures = [var.edge_exception]
}

# --- JWT -----------------------------------------------------------------------------

run "jwt_creates_and_attaches_an_authorizer" {
  variables {
    authorization_type = "JWT"
    jwt_authorizer = {
      issuer               = "https://cognito-idp.us-east-1.amazonaws.com/us-east-1_example"
      audience             = ["client-a"]
      authorization_scopes = ["api/read"]
    }
  }
  assert {
    condition     = aws_apigatewayv2_authorizer.jwt[0].authorizer_type == "JWT"
    error_message = "A JWT authorizer must be created."
  }
  assert {
    condition     = aws_apigatewayv2_authorizer.jwt[0].jwt_configuration[0].issuer == "https://cognito-idp.us-east-1.amazonaws.com/us-east-1_example"
    error_message = "The issuer must be wired."
  }
  assert {
    condition     = aws_apigatewayv2_authorizer.jwt[0].jwt_configuration[0].audience == toset(["client-a"])
    error_message = "The audience must be wired."
  }
  assert {
    condition     = aws_apigatewayv2_authorizer.jwt[0].identity_sources == toset(["$request.header.Authorization"])
    error_message = "The identity source must default to the Authorization header."
  }
  assert {
    condition     = aws_apigatewayv2_route.route.authorization_type == "JWT"
    error_message = "The route must use JWT."
  }
  assert {
    condition     = aws_apigatewayv2_route.route.authorizer_id == aws_apigatewayv2_authorizer.jwt[0].id
    error_message = "The route must use the JWT authorizer."
  }
  assert {
    condition     = aws_apigatewayv2_route.route.authorization_scopes == toset(["api/read"])
    error_message = "The route must require the scopes."
  }
}

run "refuses_jwt_without_an_authorizer" {
  command = plan
  variables {
    authorization_type = "JWT"
  }
  expect_failures = [var.jwt_authorizer]
}

run "refuses_jwt_without_an_issuer" {
  command = plan
  variables {
    authorization_type = "JWT"
    jwt_authorizer = {
      issuer   = ""
      audience = ["client-a"]
    }
  }
  expect_failures = [var.jwt_authorizer]
}

run "refuses_jwt_without_an_audience" {
  command = plan
  variables {
    authorization_type = "JWT"
    jwt_authorizer = {
      issuer   = "https://cognito-idp.us-east-1.amazonaws.com/us-east-1_example"
      audience = [""]
    }
  }
  expect_failures = [var.jwt_authorizer]
}

run "refuses_jwt_with_an_empty_audience" {
  command = plan
  variables {
    authorization_type = "JWT"
    jwt_authorizer = {
      issuer   = "https://cognito-idp.us-east-1.amazonaws.com/us-east-1_example"
      audience = []
    }
  }
  expect_failures = [var.jwt_authorizer]
}

run "refuses_jwt_on_a_websocket_api" {
  command = plan
  variables {
    protocol_type      = "WEBSOCKET"
    authorization_type = "JWT"
    jwt_authorizer = {
      issuer   = "https://cognito-idp.us-east-1.amazonaws.com/us-east-1_example"
      audience = ["client-a"]
    }
  }
  expect_failures = [var.authorization_type]
}

# --- Lambda (CUSTOM) authorizer -----------------------------------------------------

run "custom_creates_attaches_and_permits_a_lambda_authorizer" {
  variables {
    authorization_type = "CUSTOM"
    lambda_authorizer = {
      function_arn = "arn:aws:lambda:us-east-1:123456789012:function:authorizer"
    }
  }
  assert {
    condition     = aws_apigatewayv2_authorizer.lambda[0].authorizer_type == "REQUEST"
    error_message = "A REQUEST authorizer must be created."
  }
  assert {
    condition     = aws_apigatewayv2_authorizer.lambda[0].authorizer_uri == "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:123456789012:function:authorizer/invocations"
    error_message = "The authorizer URI must be the function's invocation URI."
  }
  assert {
    condition     = aws_apigatewayv2_authorizer.lambda[0].authorizer_payload_format_version == "2.0" && aws_apigatewayv2_authorizer.lambda[0].enable_simple_responses == true
    error_message = "HTTP Lambda authorizers default to payload 2.0 with simple responses."
  }
  assert {
    condition     = aws_apigatewayv2_authorizer.lambda[0].authorizer_result_ttl_in_seconds == 300
    error_message = "The cache TTL must default to 300."
  }
  assert {
    condition     = aws_apigatewayv2_authorizer.lambda[0].identity_sources == toset(["$request.header.Authorization"])
    error_message = "The identity source must default to the Authorization header."
  }
  assert {
    condition     = aws_apigatewayv2_route.route.authorization_type == "CUSTOM" && aws_apigatewayv2_route.route.authorizer_id == aws_apigatewayv2_authorizer.lambda[0].id
    error_message = "The route must use the Lambda authorizer."
  }
  assert {
    condition     = aws_lambda_permission.authorizer[0].function_name == "arn:aws:lambda:us-east-1:123456789012:function:authorizer"
    error_message = "API Gateway must be allowed to invoke the authorizer function."
  }
  assert {
    condition     = aws_lambda_permission.authorizer[0].principal == "apigateway.amazonaws.com"
    error_message = "Only API Gateway may invoke the authorizer through this permission."
  }
  assert {
    condition     = aws_lambda_permission.authorizer[0].source_arn == "${aws_apigatewayv2_api.api.execution_arn}/authorizers/${aws_apigatewayv2_authorizer.lambda[0].id}"
    error_message = "The permission must be scoped to this API's authorizer."
  }
}

run "custom_on_websocket_omits_http_only_arguments" {
  # A fresh state: computed values from the HTTP run above would otherwise carry over.
  state_key = "websocket"
  variables {
    protocol_type      = "WEBSOCKET"
    authorization_type = "CUSTOM"
    lambda_authorizer = {
      function_arn = "arn:aws:lambda:us-east-1:123456789012:function:authorizer"
    }
  }
  assert {
    condition     = aws_apigatewayv2_authorizer.lambda[0].authorizer_payload_format_version == null && aws_apigatewayv2_authorizer.lambda[0].enable_simple_responses == null
    error_message = "Payload format and simple responses are HTTP-only."
  }
  assert {
    condition     = aws_apigatewayv2_authorizer.lambda[0].authorizer_result_ttl_in_seconds == 0
    error_message = "The cache TTL is HTTP-only: it must not be sent (0 is the mock's value for an unsent TTL)."
  }
}

run "refuses_custom_without_an_authorizer" {
  command = plan
  variables {
    authorization_type = "CUSTOM"
  }
  expect_failures = [var.lambda_authorizer]
}

run "refuses_a_lambda_authorizer_that_is_not_a_function_arn" {
  command = plan
  variables {
    authorization_type = "CUSTOM"
    lambda_authorizer = {
      function_arn = "authorizer"
    }
  }
  expect_failures = [var.lambda_authorizer]
}

run "refuses_an_unknown_payload_format_version" {
  command = plan
  variables {
    authorization_type = "CUSTOM"
    lambda_authorizer = {
      function_arn            = "arn:aws:lambda:us-east-1:123456789012:function:authorizer"
      payload_format_version  = "3.0"
      enable_simple_responses = false
    }
  }
  expect_failures = [var.lambda_authorizer]
}

run "refuses_a_cache_ttl_above_3600" {
  command = plan
  variables {
    authorization_type = "CUSTOM"
    lambda_authorizer = {
      function_arn          = "arn:aws:lambda:us-east-1:123456789012:function:authorizer"
      result_ttl_in_seconds = 3601
    }
  }
  expect_failures = [var.lambda_authorizer]
}

run "refuses_caching_without_an_identity_source" {
  command = plan
  variables {
    authorization_type = "CUSTOM"
    lambda_authorizer = {
      function_arn     = "arn:aws:lambda:us-east-1:123456789012:function:authorizer"
      identity_sources = []
    }
  }
  expect_failures = [var.lambda_authorizer]
}

run "allows_no_identity_source_when_caching_is_off" {
  command = plan
  variables {
    authorization_type = "CUSTOM"
    lambda_authorizer = {
      function_arn          = "arn:aws:lambda:us-east-1:123456789012:function:authorizer"
      identity_sources      = []
      result_ttl_in_seconds = 0
    }
  }
}

run "refuses_simple_responses_with_payload_1_0" {
  command = plan
  variables {
    authorization_type = "CUSTOM"
    lambda_authorizer = {
      function_arn           = "arn:aws:lambda:us-east-1:123456789012:function:authorizer"
      payload_format_version = "1.0"
    }
  }
  expect_failures = [var.lambda_authorizer]
}

run "allows_payload_1_0_without_simple_responses" {
  command = plan
  variables {
    authorization_type = "CUSTOM"
    lambda_authorizer = {
      function_arn            = "arn:aws:lambda:us-east-1:123456789012:function:authorizer"
      payload_format_version  = "1.0"
      enable_simple_responses = false
    }
  }
}
