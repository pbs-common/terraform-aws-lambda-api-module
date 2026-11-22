module "lambda_api" {
  source = "../.."

  handler  = "bootstrap"
  filename = "../artifacts/handler.zip"
  runtime  = "provided.al2023"

  primary_hosted_zone = var.primary_hosted_zone

  # The terratest suite calls this example anonymously, so it carries the edge
  # exception granted in the module's own Issue. Real APIs choose AWS_IAM, JWT
  # or CUSTOM.
  authorization_type = "NONE"
  edge_exception     = "pbs-common/terraform-aws-lambda-api-module#182"

  cors_configuration = {
    allow_credentials = false
    allow_headers     = ["*"]
    allow_methods     = ["*"]
    allow_origins     = ["*"]
    expose_headers    = ["*"]
    max_age           = 300
  }

  environment  = var.environment
  product      = var.product
  repo         = var.repo
  owner        = var.owner
  organization = var.organization
}
