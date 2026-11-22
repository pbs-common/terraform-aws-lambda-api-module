# PBS TF Lambda API Module

## Installation

### Using the Repo Source

Use this URL for the source of the module. See the usage examples below for more details.

```hcl
github.com/pbs/terraform-aws-lambda-api-module?ref=3.0.0
```

### Alternative Installation Methods

More information can be found on these install methods and more in [the documentation here](./docs/general/install).

## Usage

This module provisions a Lambda function with an API Gateway in front of it to accept HTTP traffic.

Integrate this module like so:

```hcl
module "api" {
  source = "github.com/pbs/terraform-aws-lambda-api-module?ref=3.0.0"

  handler  = "main"
  filename = "../artifacts/handler.zip"
  runtime  = "go1.x"

  primary_hosted_zone = "example.com"

  # Required: how callers authenticate. See Security below.
  authorization_type = "AWS_IAM"

  # Tagging Parameters
  organization = var.organization
  environment  = var.environment
  product      = var.product
  repo         = var.repo

  # Optional Parameters
}
```

## Security

This module creates an API Gateway HTTP API (or WebSocket API). AWS WAF cannot be associated with
these: its protectable regional resources include API Gateway REST APIs, not HTTP APIs
([AWS WAF: resources you can protect](https://docs.aws.amazon.com/waf/latest/developerguide/how-aws-waf-works-resources.html)),
so WAF cannot protect APIs made by this module. The API's own controls are its only protection,
and the module sets each of them:

- **Route authorization.** `authorization_type` is required: `AWS_IAM`, `JWT` (HTTP APIs only, with
  `jwt_authorizer`), or `CUSTOM` (a Lambda authorizer, with `lambda_authorizer`). `NONE` is refused
  unless `edge_exception` names the Issue that granted the exception, as `<owner>/<repo>#<number>`
  (for example `pbs-common/terraform-aws-lambda-api-module#182`); free text is refused. The value is
  written to the API's `pbs:edge:exception` tag, so every public API can be found by searching for
  `edge_exception` in code or for the tag in AWS. For `JWT`, also set
  `jwt_authorizer.authorization_scopes`, so that ID tokens are not accepted as access tokens.
  ([JWT authorizers](https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-jwt-authorizer.html),
  [Lambda authorizers](https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-lambda-authorizer.html))
- **Throttling.** The stage's default route is throttled to `throttling_rate_limit` = 100 requests
  per second and `throttling_burst_limit` = 200 by default. These are deliberately conservative;
  raise them for APIs that need more. The account-wide default quota, shared by every API in the
  Region, is 10,000 requests per second with a burst of 5,000
  ([HTTP API throttling](https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-throttling.html),
  [API Gateway quotas](https://docs.aws.amazon.com/apigateway/latest/developerguide/limits.html)).
- **Who can apply an exception.** The exception is an ordinary resource tag set at plan time. If
  your organization restricts who may set that tag, for example with a service control policy, the
  apply must run as a principal allowed to set it.
- **No execute-api bypass.** The module always creates a custom domain, so
  `disable_execute_api_endpoint` must be `true` (the default); `false` is refused. Otherwise clients
  could call the default `execute-api` hostname and bypass the custom domain and its DNS.

### Upgrading from 2.x

- Set `authorization_type`. To keep a public route, set `authorization_type = "NONE"` and
  `edge_exception` to the Issue that granted the exception (see "Who can apply an exception").
- Throttling now defaults to 100 requests per second with a burst of 200 (was 10,000 and 5,000,
  the whole account's default quota). Set `throttling_rate_limit` and `throttling_burst_limit` to
  keep higher limits. `null` no longer removes the stage limits; it selects the default.
- `disable_execute_api_endpoint = false` is refused, and `null` now selects `true`.

## Adding This Version of the Module

If this repo is added as a subtree, then the version of the module should be close to the version shown here:

`3.0.0`

Note, however that subtrees can be altered as desired within repositories.

Further documentation on usage can be found [here](./docs).

Below is automatically generated documentation on this Terraform module using [terraform-docs][terraform-docs]

---

[terraform-docs]: https://github.com/terraform-docs/terraform-docs

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.13.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.71.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_lambda"></a> [lambda](#module\_lambda) | github.com/pbs/terraform-aws-lambda-module | 3.0.0 |

## Resources

| Name | Type |
|------|------|
| [aws_apigatewayv2_api.api](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_api) | resource |
| [aws_apigatewayv2_api_mapping.alternate_domain_api_mapping](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_api_mapping) | resource |
| [aws_apigatewayv2_api_mapping.api_mapping](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_api_mapping) | resource |
| [aws_apigatewayv2_authorizer.jwt](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_authorizer) | resource |
| [aws_apigatewayv2_authorizer.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_authorizer) | resource |
| [aws_apigatewayv2_domain_name.alternate_domain_name](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_domain_name) | resource |
| [aws_apigatewayv2_domain_name.domain_name](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_domain_name) | resource |
| [aws_apigatewayv2_integration.integration](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_integration) | resource |
| [aws_apigatewayv2_route.route](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route) | resource |
| [aws_apigatewayv2_stage.stage](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_stage) | resource |
| [aws_lambda_permission.authorizer](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_lambda_permission.lambda_permission](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_route53_record.record](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_acm_certificate.wildcard](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/acm_certificate) | data source |
| [aws_default_tags.common_tags](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/default_tags) | data source |
| [aws_route53_zone.zone](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_authorization_type"></a> [authorization\_type](#input\_authorization\_type) | Authorization for the route: AWS\_IAM, JWT (HTTP APIs only; set jwt\_authorizer), CUSTOM (a Lambda authorizer; set lambda\_authorizer), or NONE, which is refused unless edge\_exception names the Issue that granted the exception. | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment (sharedtools, dev, staging, qa, prod) | `string` | n/a | yes |
| <a name="input_organization"></a> [organization](#input\_organization) | Organization using this module. Used to prefix tags so that they are easily identified as being from your organization | `string` | n/a | yes |
| <a name="input_owner"></a> [owner](#input\_owner) | Tag used to group resources according to product | `string` | n/a | yes |
| <a name="input_product"></a> [product](#input\_product) | Tag used to group resources according to product | `string` | n/a | yes |
| <a name="input_repo"></a> [repo](#input\_repo) | Tag used to point to the repo using this module | `string` | n/a | yes |
| <a name="input_acm_arn"></a> [acm\_arn](#input\_acm\_arn) | ARN of the ACM certificate for the API integration | `string` | `null` | no |
| <a name="input_add_app_config_extension_layer"></a> [add\_app\_config\_extension\_layer](#input\_add\_app\_config\_extension\_layer) | Add the AWS-AppConfig-Lambda-Extension layer to the Lambda function. Ignored if layers is not null or if runtime is not supported. | `bool` | `true` | no |
| <a name="input_add_ssm_extension_layer"></a> [add\_ssm\_extension\_layer](#input\_add\_ssm\_extension\_layer) | Add the AWS-Parameters-and-Secrets-Lambda-Extension layer to the Lambda function. Ignored if layers is not null or if using the ARM runtime. | `bool` | `true` | no |
| <a name="input_add_vpc_config"></a> [add\_vpc\_config](#input\_add\_vpc\_config) | Add VPC configuration to the Lambda function | `bool` | `false` | no |
| <a name="input_allow_app_config_access"></a> [allow\_app\_config\_access](#input\_allow\_app\_config\_access) | Allow AppConfig access from the Lambda function. Ignored if `policy_json` or `role_arn` are set. | `bool` | `true` | no |
| <a name="input_alternate_domain_name"></a> [alternate\_domain\_name](#input\_alternate\_domain\_name) | Alternate domain name for the API for which a DNS record will not be created. This can be useful for APIs that need to have CNAMEs defined in external accounts. | `string` | `null` | no |
| <a name="input_architectures"></a> [architectures](#input\_architectures) | Architectures to target for the Lambda function | `list(string)` | <pre>[<br/>  "x86_64"<br/>]</pre> | no |
| <a name="input_auto_deploy"></a> [auto\_deploy](#input\_auto\_deploy) | Auto deploy API Gateway updates. Leave this true | `string` | `"true"` | no |
| <a name="input_connection_type"></a> [connection\_type](#input\_connection\_type) | Connection type for the integeration endpoint. Probably want this to be INTERNET | `string` | `"INTERNET"` | no |
| <a name="input_cors_configuration"></a> [cors\_configuration](#input\_cors\_configuration) | CORS configuration map | `any` | `null` | no |
| <a name="input_create_dns"></a> [create\_dns](#input\_create\_dns) | Whether or not to provision a CNAME pointing to this API. domain\_name returns API integration target, which requires separate CNAME if false. | `bool` | `true` | no |
| <a name="input_disable_execute_api_endpoint"></a> [disable\_execute\_api\_endpoint](#input\_disable\_execute\_api\_endpoint) | (optional) Disable the default execute-api endpoint. Must be true: this module always creates a custom domain, and an enabled execute-api endpoint would let clients bypass it. | `bool` | `true` | no |
| <a name="input_dns_evaluate_target_health"></a> [dns\_evaluate\_target\_health](#input\_dns\_evaluate\_target\_health) | (optional) evaluate health of endpoints by querying DNS records | `bool` | `false` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Domain name for the API | `string` | `null` | no |
| <a name="input_edge_exception"></a> [edge\_exception](#input\_edge\_exception) | (optional) The edge exception that allows authorization\_type = NONE: the Issue that granted it, as <owner>/<repo>#<number>, e.g. pbs-common/terraform-aws-lambda-api-module#182. It is written to the API's pbs:edge:exception tag. | `string` | `null` | no |
| <a name="input_endpoint_type"></a> [endpoint\_type](#input\_endpoint\_type) | Endpoint type. Leave this REGIONAL | `string` | `"REGIONAL"` | no |
| <a name="input_environment_vars"></a> [environment\_vars](#input\_environment\_vars) | Map of environment variables for the Lambda. If null, defaults to setting an SSM\_PATH based on the environment and name of the function. Set to {} if you would like for there to be no environment variables present. This is important if you are creating a Lambda@Edge. | `map(any)` | `null` | no |
| <a name="input_file_system_config"></a> [file\_system\_config](#input\_file\_system\_config) | File system configuration for the Lambda function | `map(any)` | `null` | no |
| <a name="input_filename"></a> [filename](#input\_filename) | Filename for the artifact to use for the Lambda | `string` | `null` | no |
| <a name="input_handler"></a> [handler](#input\_handler) | Lambda handler | `string` | `null` | no |
| <a name="input_image_uri"></a> [image\_uri](#input\_image\_uri) | URI of the container image to use for the Lambda | `string` | `null` | no |
| <a name="input_integration_description"></a> [integration\_description](#input\_integration\_description) | Integration description. Auto-generated off local.name if null | `string` | `null` | no |
| <a name="input_integration_method"></a> [integration\_method](#input\_integration\_method) | Integration method. Leave this POST | `string` | `"POST"` | no |
| <a name="input_integration_type"></a> [integration\_type](#input\_integration\_type) | Integration type. Leave this AWS\_PROXY | `string` | `"AWS_PROXY"` | no |
| <a name="input_jwt_authorizer"></a> [jwt\_authorizer](#input\_jwt\_authorizer) | (optional) JWT authorizer, required when authorization\_type = JWT. issuer: the identity provider's issuer URL. audience: the accepted aud (or client\_id) values. identity\_sources: where the token is read (default the Authorization header). authorization\_scopes: scopes the route requires; recommended, so that ID tokens are not accepted as access tokens. | <pre>object({<br/>    issuer               = string<br/>    audience             = list(string)<br/>    identity_sources     = optional(list(string), ["$request.header.Authorization"])<br/>    authorization_scopes = optional(list(string))<br/>  })</pre> | `null` | no |
| <a name="input_lambda_authorizer"></a> [lambda\_authorizer](#input\_lambda\_authorizer) | (optional) Lambda (REQUEST) authorizer, required when authorization\_type = CUSTOM. function\_arn: the authorizer function; the module lets API Gateway invoke it from this API's authorizer only. payload\_format\_version (1.0 or 2.0, default 2.0), enable\_simple\_responses (default true, needs 2.0) and result\_ttl\_in\_seconds (0 to 3600, default 300) apply to HTTP APIs only. identity\_sources (default the Authorization header) must not be empty while caching is on. | <pre>object({<br/>    function_arn            = string<br/>    payload_format_version  = optional(string, "2.0")<br/>    enable_simple_responses = optional(bool, true)<br/>    result_ttl_in_seconds   = optional(number, 300)<br/>    identity_sources        = optional(list(string), ["$request.header.Authorization"])<br/>  })</pre> | `null` | no |
| <a name="input_lambda_description"></a> [lambda\_description](#input\_lambda\_description) | Description for this lambda function | `string` | `null` | no |
| <a name="input_lambda_insights_extension_account_number"></a> [lambda\_insights\_extension\_account\_number](#input\_lambda\_insights\_extension\_account\_number) | Account number for the LambdaInsightsExtension layer | `string` | `"580247275435"` | no |
| <a name="input_lambda_insights_extension_version"></a> [lambda\_insights\_extension\_version](#input\_lambda\_insights\_extension\_version) | Lambda layer version for the LambdaInsightsExtension layer | `number` | `null` | no |
| <a name="input_lambda_name"></a> [lambda\_name](#input\_lambda\_name) | Name of the Lambda function | `string` | `null` | no |
| <a name="input_layers"></a> [layers](#input\_layers) | Lambda layers to apply to function. If null, a Lambda Layer extension is added by default. | `list(string)` | `null` | no |
| <a name="input_log_retention_in_days"></a> [log\_retention\_in\_days](#input\_log\_retention\_in\_days) | Number of days to retain CloudWatch Log entries | `number` | `7` | no |
| <a name="input_memory_size"></a> [memory\_size](#input\_memory\_size) | Amount of memory in MB your Lambda Function can use at runtime | `number` | `128` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the API | `string` | `null` | no |
| <a name="input_package_type"></a> [package\_type](#input\_package\_type) | Package type for the Lambda function. Valid values are Zip and Image. | `string` | `"Zip"` | no |
| <a name="input_payload_format_version"></a> [payload\_format\_version](#input\_payload\_format\_version) | (optional) payload format version | `string` | `"1.0"` | no |
| <a name="input_permissions_boundary_arn"></a> [permissions\_boundary\_arn](#input\_permissions\_boundary\_arn) | ARN of the permissions boundary to use on the role created for this lambda | `string` | `null` | no |
| <a name="input_policy_json"></a> [policy\_json](#input\_policy\_json) | Policy JSON. If null, default policy granting access to SSM and cloudwatch logs is used | `string` | `null` | no |
| <a name="input_primary_hosted_zone"></a> [primary\_hosted\_zone](#input\_primary\_hosted\_zone) | Primary hosted zone for the API. e.g. example.org | `string` | `null` | no |
| <a name="input_protocol_type"></a> [protocol\_type](#input\_protocol\_type) | Protocol type. Can be HTTP and WEBSOCKET | `string` | `"HTTP"` | no |
| <a name="input_publish"></a> [publish](#input\_publish) | Whether to publish creation/change as new Lambda Function Version | `bool` | `true` | no |
| <a name="input_role_arn"></a> [role\_arn](#input\_role\_arn) | ARN of the role to be used for this Lambda | `string` | `null` | no |
| <a name="input_route_key"></a> [route\_key](#input\_route\_key) | Route key. Leave this $default | `string` | `"$default"` | no |
| <a name="input_runtime"></a> [runtime](#input\_runtime) | Runtime for the lambda function | `string` | `null` | no |
| <a name="input_security_group_id"></a> [security\_group\_id](#input\_security\_group\_id) | Security group ID. If null, one will be created. | `string` | `null` | no |
| <a name="input_security_policy"></a> [security\_policy](#input\_security\_policy) | TLS version. Leave this TLS\_1\_2 | `string` | `"TLS_1_2"` | no |
| <a name="input_ssm_path"></a> [ssm\_path](#input\_ssm\_path) | SSM path to use for environment variables. If null, defaults to /${var.environment}/${local.name} | `string` | `null` | no |
| <a name="input_stage_name"></a> [stage\_name](#input\_stage\_name) | Name of the stage | `string` | `"$default"` | no |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | Subnets to use for the Lambda function. Ignored if add\_vpc\_config is false. If null, one will be looked up based on environment tag. | `list(string)` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Extra tags | `map(string)` | `{}` | no |
| <a name="input_throttling_burst_limit"></a> [throttling\_burst\_limit](#input\_throttling\_burst\_limit) | (optional) Stage throttling burst limit: the most requests served at once before API Gateway returns 429. A whole number from 0 to 2147483647. The default of 200 is deliberately conservative; raise it for APIs that need more. The account-wide default quota is 5,000 across all APIs in the Region. | `number` | `200` | no |
| <a name="input_throttling_rate_limit"></a> [throttling\_rate\_limit](#input\_throttling\_rate\_limit) | (optional) Stage throttling rate limit in requests per second, from 0 to 2147483647; fractions are allowed. The default of 100 is deliberately conservative; raise it for APIs that need more. The account-wide default quota is 10,000 across all APIs in the Region. | `number` | `100` | no |
| <a name="input_timeout"></a> [timeout](#input\_timeout) | Timeout in seconds of the Lambda | `number` | `3` | no |
| <a name="input_tracing_config_mode"></a> [tracing\_config\_mode](#input\_tracing\_config\_mode) | Tracing config mode for X-Ray integration on Lambda | `string` | `"Active"` | no |
| <a name="input_use_prefix"></a> [use\_prefix](#input\_use\_prefix) | Use prefix for resources instead of explicitly defining whole name where possible | `bool` | `true` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID. If null, one will be looked up based on environment tag. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_alternate_domain_endpoint"></a> [alternate\_domain\_endpoint](#output\_alternate\_domain\_endpoint) | Alternate endpoint that the API can be accessed at if a CNAME corresponding to `alternate_domain_name` resolves to this endpoint. Only populated if `alternate_domain_name` is not null |
| <a name="output_alternate_domain_name"></a> [alternate\_domain\_name](#output\_alternate\_domain\_name) | Alternate domain name that the API can be accessed at. Returns the CNAME record name that should be created externally for the API with value output as `alternate_domain_endpoint`. This is useful for APIs where the CNAME is defined in another account. |
| <a name="output_arn"></a> [arn](#output\_arn) | ARN of the API Gateway |
| <a name="output_domain_name"></a> [domain\_name](#output\_domain\_name) | Domain name that the API can be accessed at. If create\_dns, return the CNAME created for the API, otherwise return the api integration domain name. This is useful when creating a DNS record for the API is not desired. |
| <a name="output_lambda_arn"></a> [lambda\_arn](#output\_lambda\_arn) | ARN of the Lambda function |
| <a name="output_lambda_name"></a> [lambda\_name](#output\_lambda\_name) | Name of the Lambda function |
| <a name="output_sg"></a> [sg](#output\_sg) | Security group of the lambda function if there is one |
