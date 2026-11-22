variable "name" {
  description = "Name of the API"
  default     = null
  type        = string
}

variable "domain_name" {
  description = "Domain name for the API"
  default     = null
  type        = string
}

variable "alternate_domain_name" {
  description = "Alternate domain name for the API for which a DNS record will not be created. This can be useful for APIs that need to have CNAMEs defined in external accounts."
  default     = null
  type        = string
}

variable "primary_hosted_zone" {
  description = "Primary hosted zone for the API. e.g. example.org"
  default     = null
  type        = string
}

variable "protocol_type" {
  description = "Protocol type. Can be HTTP and WEBSOCKET"
  default     = "HTTP"
  type        = string
}

variable "endpoint_type" {
  description = "Endpoint type. Leave this REGIONAL"
  default     = "REGIONAL"
  type        = string
}

variable "security_policy" {
  description = "TLS version. Leave this TLS_1_2"
  default     = "TLS_1_2"
  type        = string
}

variable "stage_name" {
  description = "Name of the stage"
  default     = "$default"
  type        = string
}

variable "auto_deploy" {
  description = "Auto deploy API Gateway updates. Leave this true"
  default     = "true"
  type        = string
}

variable "integration_type" {
  description = "Integration type. Leave this AWS_PROXY"
  default     = "AWS_PROXY"
  type        = string
}

variable "connection_type" {
  description = "Connection type for the integeration endpoint. Probably want this to be INTERNET"
  default     = "INTERNET"
  type        = string
}

variable "integration_description" {
  description = "Integration description. Auto-generated off local.name if null"
  default     = null
  type        = string
}

variable "integration_method" {
  description = "Integration method. Leave this POST"
  default     = "POST"
  type        = string
}

variable "route_key" {
  description = "Route key. Leave this $default"
  default     = "$default"
  type        = string
}

variable "create_dns" {
  description = "Whether or not to provision a CNAME pointing to this API. domain_name returns API integration target, which requires separate CNAME if false."
  default     = true
  type        = bool
}

variable "acm_arn" {
  description = "ARN of the ACM certificate for the API integration"
  default     = null
  type        = string
}

variable "cors_configuration" {
  description = "CORS configuration map"
  default     = null
  type        = any
}

variable "dns_evaluate_target_health" {
  description = "(optional) evaluate health of endpoints by querying DNS records"
  default     = false
  type        = bool
}

variable "disable_execute_api_endpoint" {
  description = "(optional) Disable the default execute-api endpoint. Must be true: this module always creates a custom domain, and an enabled execute-api endpoint would let clients bypass it."
  default     = true
  type        = bool
  nullable    = false

  validation {
    condition     = var.disable_execute_api_endpoint
    error_message = "disable_execute_api_endpoint must be true: this module always creates a custom domain, and the execute-api endpoint would bypass it."
  }
}

variable "payload_format_version" {
  description = "(optional) payload format version"
  default     = "1.0"
  type        = string
}

variable "throttling_burst_limit" {
  description = "(optional) Stage throttling burst limit: the most requests served at once before API Gateway returns 429. A whole number from 0 to 2147483647. The default of 200 is deliberately conservative; raise it for APIs that need more. The account-wide default quota is 5,000 across all APIs in the Region."
  default     = 200
  type        = number
  nullable    = false

  validation {
    condition     = floor(var.throttling_burst_limit) == var.throttling_burst_limit && var.throttling_burst_limit >= 0 && var.throttling_burst_limit <= 2147483647
    error_message = "throttling_burst_limit must be a whole number from 0 to 2147483647."
  }
}

variable "throttling_rate_limit" {
  description = "(optional) Stage throttling rate limit in requests per second, from 0 to 2147483647; fractions are allowed. The default of 100 is deliberately conservative; raise it for APIs that need more. The account-wide default quota is 10,000 across all APIs in the Region."
  default     = 100
  type        = number
  nullable    = false

  validation {
    condition     = var.throttling_rate_limit >= 0 && var.throttling_rate_limit <= 2147483647
    error_message = "throttling_rate_limit must be from 0 to 2147483647."
  }
}

variable "edge_exception" {
  description = "(optional) The edge exception that allows authorization_type = NONE: the Issue that granted it, as <owner>/<repo>#<number>, e.g. pbs-common/terraform-aws-lambda-api-module#182. It is written to the API's pbs:edge:exception tag."
  default     = null
  type        = string

  validation {
    condition     = var.authorization_type != "NONE" || var.edge_exception != null
    error_message = "authorization_type = NONE leaves the route open to anyone. Set edge_exception to the Issue that granted the exception (<owner>/<repo>#<number>), or choose AWS_IAM, JWT or CUSTOM."
  }

  validation {
    condition     = var.edge_exception == null || var.authorization_type == "NONE"
    error_message = "edge_exception is valid only with authorization_type = NONE."
  }

  # Owner: GitHub account names are letters, digits and single hyphens, with no
  # hyphen first or last. Repo: letters, digits, '.', '-' and '_'. Number: an
  # Issue number, 1 to 10 digits with no leading zero.
  validation {
    condition     = var.edge_exception == null || can(regex("^[A-Za-z0-9](?:-?[A-Za-z0-9])*/[A-Za-z0-9._-]{1,100}#[1-9][0-9]{0,9}$", var.edge_exception))
    error_message = "edge_exception must be an Issue reference, <owner>/<repo>#<number>, e.g. pbs-common/terraform-aws-lambda-api-module#182."
  }

  validation {
    condition     = var.edge_exception == null || length(split("/", var.edge_exception)[0]) <= 39
    error_message = "The owner in edge_exception must be at most 39 characters."
  }

  validation {
    condition     = var.edge_exception == null || !contains([".", ".."], try(regex("^[^/]*/([^#]*)#", var.edge_exception)[0], ""))
    error_message = "The repo in edge_exception cannot be \".\" or \"..\"."
  }
}

variable "jwt_authorizer" {
  description = "(optional) JWT authorizer, required when authorization_type = JWT. issuer: the identity provider's issuer URL. audience: the accepted aud (or client_id) values. identity_sources: where the token is read (default the Authorization header). authorization_scopes: scopes the route requires; recommended, so that ID tokens are not accepted as access tokens."
  default     = null
  type = object({
    issuer               = string
    audience             = list(string)
    identity_sources     = optional(list(string), ["$request.header.Authorization"])
    authorization_scopes = optional(list(string))
  })

  validation {
    condition     = var.authorization_type != "JWT" || (try(trimspace(var.jwt_authorizer.issuer), "") != "" && length(try(var.jwt_authorizer.audience, [])) > 0 && alltrue([for a in try(var.jwt_authorizer.audience, []) : try(trimspace(a), "") != ""]))
    error_message = "authorization_type = JWT needs jwt_authorizer with a non-blank issuer and at least one audience, none of them blank."
  }
}

variable "lambda_authorizer" {
  description = "(optional) Lambda (REQUEST) authorizer, required when authorization_type = CUSTOM. function_arn: the authorizer function; the module lets API Gateway invoke it from this API's authorizer only. payload_format_version (1.0 or 2.0, default 2.0), enable_simple_responses (default true, needs 2.0) and result_ttl_in_seconds (0 to 3600, default 300) apply to HTTP APIs only. identity_sources (default the Authorization header) must not be empty while caching is on."
  default     = null
  type = object({
    function_arn            = string
    payload_format_version  = optional(string, "2.0")
    enable_simple_responses = optional(bool, true)
    result_ttl_in_seconds   = optional(number, 300)
    identity_sources        = optional(list(string), ["$request.header.Authorization"])
  })

  validation {
    condition     = var.authorization_type != "CUSTOM" || var.lambda_authorizer != null
    error_message = "authorization_type = CUSTOM needs lambda_authorizer."
  }

  validation {
    condition     = var.lambda_authorizer == null || can(regex("^arn:aws[a-z-]*:lambda:[a-z0-9-]+:[0-9]{12}:function:[A-Za-z0-9_-]{1,64}(:[A-Za-z0-9$_-]{1,128})?$", var.lambda_authorizer.function_arn))
    error_message = "lambda_authorizer.function_arn must be a Lambda function ARN."
  }

  validation {
    condition     = var.lambda_authorizer == null || contains(["1.0", "2.0"], var.lambda_authorizer.payload_format_version)
    error_message = "lambda_authorizer.payload_format_version must be 1.0 or 2.0."
  }

  validation {
    condition     = var.lambda_authorizer == null || !var.lambda_authorizer.enable_simple_responses || var.lambda_authorizer.payload_format_version == "2.0"
    error_message = "lambda_authorizer.enable_simple_responses needs payload_format_version = 2.0; set it to false for 1.0."
  }

  validation {
    condition     = var.lambda_authorizer == null || (floor(var.lambda_authorizer.result_ttl_in_seconds) == var.lambda_authorizer.result_ttl_in_seconds && var.lambda_authorizer.result_ttl_in_seconds >= 0 && var.lambda_authorizer.result_ttl_in_seconds <= 3600)
    error_message = "lambda_authorizer.result_ttl_in_seconds must be a whole number from 0 to 3600."
  }

  validation {
    condition     = var.lambda_authorizer == null || var.lambda_authorizer.result_ttl_in_seconds == 0 || length(var.lambda_authorizer.identity_sources) > 0
    error_message = "lambda_authorizer.identity_sources must not be empty while result_ttl_in_seconds is above 0: API Gateway uses them as the cache key."
  }
}
