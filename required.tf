variable "authorization_type" {
  description = "Authorization for the route: AWS_IAM, JWT (HTTP APIs only; set jwt_authorizer), CUSTOM (a Lambda authorizer; set lambda_authorizer), or NONE, which is refused unless edge_exception names the Issue that granted the exception."
  type        = string

  validation {
    condition     = var.authorization_type != null && contains(["AWS_IAM", "JWT", "CUSTOM", "NONE"], var.authorization_type)
    error_message = "authorization_type must be one of AWS_IAM, JWT, CUSTOM or NONE."
  }

  validation {
    condition     = var.authorization_type != "JWT" || var.protocol_type == "HTTP"
    error_message = "JWT authorizers are supported only for HTTP APIs (protocol_type = HTTP)."
  }
}
