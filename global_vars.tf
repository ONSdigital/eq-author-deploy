variable "env" {
  description = "The environment name, used to identify your environment"
}

variable "aws_secret_key" {
  description = "Amazon Web Service Secret Key"
}

variable "aws_access_key" {
  description = "Amazon Web Service Access Key"
}

variable "ecs_cluster_name" {
  description = "The name of the survey runner ECS cluster"
}

variable "aws_alb_listener_arn" {
  description = "The ARN of the survey runner ALB"
}

# DNS
variable "dns_zone_name" {
  description = "Amazon Route53 DNS zone name"
  default     = "eq.ons.digital."
}

# Docker
variable "docker_registry" {
  description = "The docker repository for the Survey Runner image"
  default     = "onsdigital"
}

variable "author_tag" {
  description = "The tag for the Author image to run"
  default     = "latest"
}

variable "author_api_tag" {
  description = "The tag for the Author API image to run"
  default     = "latest"
}

variable "publisher_tag" {
  description = "The tag for the Publisher image to run"
  default     = "latest"
}

variable "application_cidrs" {
  type        = "list"
  description = "CIDR blocks for application subnets"
}

variable "author_database_password" {
  description = "The password for the Author database"
  default     = "authorPassword"
}

variable "survey_launcher_url" {
  description = "The URL for the launcher service"
}