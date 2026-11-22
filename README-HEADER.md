# PBS TF Lambda API Module

## Installation

### Using the Repo Source

Use this URL for the source of the module. See the usage examples below for more details.

```hcl
github.com/pbs/terraform-aws-lambda-api-module?ref=x.y.z
```

### Alternative Installation Methods

More information can be found on these install methods and more in [the documentation here](./docs/general/install).

## Usage

This module provisions a Lambda function with an API Gateway in front of it to accept HTTP traffic.

Integrate this module like so:

```hcl
module "api" {
  source = "github.com/pbs/terraform-aws-lambda-api-module?ref=x.y.z"

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

`x.y.z`

Note, however that subtrees can be altered as desired within repositories.

Further documentation on usage can be found [here](./docs).

Below is automatically generated documentation on this Terraform module using [terraform-docs][terraform-docs]

---

[terraform-docs]: https://github.com/terraform-docs/terraform-docs
