module "lambda_api" {
  source = "../.."

  handler  = "bootstrap"
  filename = "../artifacts/handler.zip"
  runtime  = "provided.al2023"

  primary_hosted_zone = var.primary_hosted_zone

  alternate_domain_name = var.alternate_domain_name

  environment  = var.environment
  product      = var.product
  repo         = var.repo
  owner        = var.owner
  organization = var.organization
}
