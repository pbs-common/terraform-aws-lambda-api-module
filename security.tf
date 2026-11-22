resource "aws_lambda_permission" "lambda_permission" {
  statement_id  = "AllowLambdaInvocation"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda.name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "authorizer" {
  count = var.authorization_type == "CUSTOM" ? 1 : 0

  statement_id  = "AllowApiGatewayAuthorizer-${aws_apigatewayv2_api.api.id}"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_authorizer.function_arn
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.api.execution_arn}/authorizers/${aws_apigatewayv2_authorizer.lambda[0].id}"
}
