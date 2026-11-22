# Mock values for the aws provider, shared by every tests/*.tftest.hcl file.
# The mock still runs the provider's own argument validation, so values that
# reach a validated argument (JSON policies, ARNs) must be well formed.

mock_data "aws_iam_policy_document" {
  defaults = {
    json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
  }
}

mock_data "aws_acm_certificate" {
  defaults = {
    arn = "arn:aws:acm:us-east-1:123456789012:certificate/00000000-0000-0000-0000-000000000000"
  }
}

mock_data "aws_region" {
  defaults = {
    region = "us-east-1"
  }
}

mock_data "aws_ssm_parameter" {
  defaults = {
    value = "arn:aws:lambda:us-east-1:123456789012:layer:extension:1"
  }
}

mock_resource "aws_iam_role" {
  defaults = {
    arn = "arn:aws:iam::123456789012:role/example"
  }
}

mock_resource "aws_iam_policy" {
  defaults = {
    arn = "arn:aws:iam::123456789012:policy/example"
  }
}

mock_resource "aws_apigatewayv2_api" {
  defaults = {
    execution_arn = "arn:aws:execute-api:us-east-1:123456789012:abcdef1234"
  }
}

# Stands in for "not sent": the provider computes this attribute when the
# configuration leaves it null, as it must for WebSocket APIs.
mock_resource "aws_apigatewayv2_authorizer" {
  defaults = {
    authorizer_result_ttl_in_seconds = 0
  }
}
