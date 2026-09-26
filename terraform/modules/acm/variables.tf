variable "domain_name" {
  type        = string
  description = "Domain name for the ACM certificate"
}

variable "environment" {
  type        = string
  description = "Environment name"
}


variable "zone_id" {
  description = "Route53 Hosted Zone ID for domain validation"
  type        = string

}
