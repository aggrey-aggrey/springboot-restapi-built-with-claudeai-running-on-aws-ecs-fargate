# terraform/variables.tf

 # Core Variables
 variable "aws_region" {
   description = "AWS region"
   type        = string
   default     = "us-west-2"
 }

 variable "environment" {
   description = "Environment (dev/prod)"
   type        = string
 }

 variable "app_name" {
   description = "Application name"
   type        = string
 }

 # VPC Variables
 variable "vpc_cidr" {
   description = "VPC CIDR block"
   type        = string
 }

 variable "private_subnets" {
   description = "Private subnet CIDR blocks"
   type        = list(string)
 }

 variable "public_subnets" {
   description = "Public subnet CIDR blocks"
   type        = list(string)
 }

 # ECS Variables
 variable "container_cpu" {
   description = "Container CPU units"
   type        = number
 }

 variable "container_memory" {
   description = "Container memory in MiB"
   type        = number
 }

 variable "health_check_path" {
   description = "Health check path"
   type        = string
   default     = "/actuator/health"
 }

 # Database Variables (for connecting to manually created RDS)
 variable "db_host" {
   description = "Database host"
   type        = string
 }

 variable "db_port" {
   description = "Database port"
   type        = string
   default     = "3306"
 }

 variable "db_name" {
   description = "Database name"
   type        = string
 }

 variable "db_username" {
   description = "Database username"
   type        = string
 }

 variable "db_password" {
   description = "Database password"
   type        = string
 }

 # Tags
 variable "tags" {
   description = "Default tags for all resources"
   type        = map(string)
   default     = {}
   }