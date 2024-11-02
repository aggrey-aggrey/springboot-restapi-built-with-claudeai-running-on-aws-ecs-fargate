# terraform/outputs.tf
 output "rds_endpoint" {
   description = "RDS instance endpoint"
   value       = aws_db_instance.main.endpoint
   sensitive   = true
 }

 output "ecr_repository_url" {
   description = "ECR repository URL"
   value       = aws_ecr_repository.app.repository_url
 }

 output "api_endpoint" {
   description = "Application Load Balancer DNS name"
   value       = aws_lb.main.dns_name
 }

 output "vpc_id" {
   description = "VPC ID"
   value       = module.vpc.vpc_id
 }

 output "private_subnets" {
   description = "List of private subnet IDs"
   value       = module.vpc.private_subnets
 }

 output "public_subnets" {
   description = "List of public subnet IDs"
   value       = module.vpc.public_subnets
 }

 output "ecs_cluster_name" {
   description = "ECS cluster name"
   value       = aws_ecs_cluster.main.name
 }

 output "ecs_service_name" {
   description = "ECS service name"
   value       = aws_ecs_service.app.name
 }

 output "task_definition_arn" {
   description = "Task definition ARN"
   value       = aws_ecs_task_definition.app.arn
 }

 output "cloudwatch_log_group" {
   description = "CloudWatch log group name"
   value       = aws_cloudwatch_log_group.app.name
 }
