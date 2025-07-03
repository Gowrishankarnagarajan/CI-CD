# variable "subscription_id" {}
# variable "tenant_id" {}
# variable "client_id" {}
# variable "client_secret" {}
variable "prefix" {
  description = "Prefix for resource names"
  default     = "gs"
  type        = string

}

