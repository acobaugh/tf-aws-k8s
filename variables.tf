variable "cluster_name" {
  description = "Short name for this cluster"
  type        = "string"
}

variable "tags" {
  description = "Tags to be added to terraform-defined resources"
  type        = "map"
  default     = {}
}

variable "asg_tags" {
  description = "Tags to be added to ASG-defined resources"
  type        = "map"
  default     = {}
}

variable "route53_zone" {
  description = "Route53 zone to place master and apiserver ELB resource records"
  type        = "string"
}

variable "route53_zone_id" {
  description = "Route53 zone id to place master and apiserver ELB resource records"
  type        = "string"
}

variable "vpc_id" {
  description = "VPC id in which to place resources"
  type        = "string"
}

variable "vpc_ig_id" {
  description = "VPC Internet Gateway"
  type        = "string"
}

variable "vpc_subnet_cidrs" {
  description = "CIDRs of the subnets to create and launch EC2 instances in"
  type        = "string"
}

variable "os_channel" {
  description = "Container Linux AMI channel (stable, beta, alpha)"
  type        = "string"
  default     = "stable"
}

variable "master_type" {
  description = "EC2 instance type for master nodes"
  type        = "string"
  default     = "t2.small"
}

variable "worker_type" {
  description = "EC2 instance type for worker nodes"
  type        = "string"
  default     = "t2.small"
}

variable "worker_asg_min" {
  description = "Worker node autoscaling group min size"
  type        = "string"
  default     = "1"
}

variable "worker_asg_max" {
  description = "Worker node autoscaling group max size"
  type        = "string"
  default     = "1"
}

# kubernetes specifics

variable "network_provider" {
  description = "CNI provider: calico, flannel"
  type        = "string"
  default     = "calico"
}

variable "network_mtu" {
  description = "CNI interface MTU. Use 8981 if you are using EC2 instances that support Jumbo frames. Only applicable with calico CNI provider"
  type        = "string"
  default     = "1480"
}

variable "pod_cidr" {
  description = "Internal IPv4 CIDR for pods"
  type        = "string"
  default     = "10.2.0.0/16"
}

variable "service_cidr" {
  description = "Internal IPv4 CIDR for services"
  type        = "string"
  default     = "10.3.0.0/16"
}

variable "cluster_domain_suffix" {
  description = "Internal cluster DNS domain served by kube-dns"
  type        = "string"
  default     = "cluster.local"
}
