variable "cluster_name" {}

variable "tags" {}
variable "asg_tags" {}

variable "route53_zone" {}
variable "route53_zone_id" {}
variable "vpc_id" {}
variable "vpc_ig_id" {}
variable "vpc_subnet_ids" {}

variable "os_channel" {}

variable "master_type" {}
variable "worker_type" {}
variable "worker_asg_min" {}
variable "worker_asg_max" {}

# kubernetes specifics
variable "network_provider" {}
variable "network_mtu" {}
variable "pod_cidr" {}
variable "service_cidr" {}
variable "cluster_domain_suffix" {}

