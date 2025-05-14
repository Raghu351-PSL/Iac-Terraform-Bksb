variable "region" {
  description = "AWS region"
  type        = string
}
variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}
variable "cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
}
variable "availability_zone" {
  description = "Availability zone"
  type        = string
}
variable "subnet_cidr_block" {
  description = "CIDR block for the subnet"
  type        = string
}
variable "nat_allocation_id" {
  description = "Allocation ID for the NAT Gateway"
  type        = string
}
