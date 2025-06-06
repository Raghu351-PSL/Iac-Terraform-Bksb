variable "vpc_id" {
  description = "The VPC ID where resources will be created."
  type        = string
  default     = ""
}

variable "nat_gateway_allocation_id" {
  description = "The allocation ID for the NAT Gateway."
  type        = string
  default     = ""
}

variable "namespace_id" {
  description = "The ID of the Service Discovery namespace."
  type        = string
  default     = ""
}