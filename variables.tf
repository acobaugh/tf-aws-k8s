variable "cluster_name" {
  description = "Short name for this cluster. Should be unique across all clusters."
  type        = "string"
}

variable "cluster_fqdn" {
  description = "FQDN for this cluster. Should be rooted under `route53_zone`. api, master*, and etcd* entries are created under this domain"
  type        = "string"
}

variable "route53_zone_id" {
  description = "Route53 zone id corresponding to cluster_fqdn."
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

variable "ssh_key" {
  description = "SSH public key to allow login as core user on master and worker instances"
  type        = "string"
  default     = ""
}

variable "azs" {
  description = "Availability zones. Should have an equal number of AZs as subnets."
  type        = "list"
}

variable "vpc_id" {
  description = "VPC id in which to place resources"
  type        = "string"
}

variable "vpc_ig_id" {
  description = "VPC Internet Gateway"
  type        = "string"
}

variable "vpc_ipv6_cidr_block" {
  description = "IPv6 /56 CIDR block for the VPC. Subnets will be calculated out of this block."
  type        = "string"
}

variable "ipv6_subnet_offset" {
  description = "Base /64 subnet number to start creating subnets at. Eg. the N in x:x:x:N::/64"
  type        = "string"
}

variable "vpc_subnet_cidrs" {
  description = "CIDRs of the subnets to create and launch EC2 instances in"
  type        = "list"
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
}

variable "service_cidr" {
  description = "Internal IPv4 CIDR for services"
  type        = "string"
}

variable "cluster_domain_suffix" {
  description = "Internal cluster DNS domain served by kube-dns"
  type        = "string"
  default     = "cluster.local"
}

variable "config_s3_bucket" {
  description = "AWS S3 bucket to place bootkube rendered assets and ssl material for usage by the masters when bootstrapping"
  type        = "string"
}

variable "config_s3_prefix" {
  description = "AWS S3 bucket key prefix, under which bootkube-assets.zip and various ssl files will be placed"
  type        = "string"
  default     = ""
}

variable "master_icmp_src_cidrs" {
  description = "CIDRs that are allowed to send ICMP to Masters and API LB"
  type        = "list"
  default     = ["0.0.0.0/0"]
}

variable "master_ssh_src_cidrs" {
  description = "CIDRs that are allowed to SSH to Masters"
  type        = "list"
  default     = ["0.0.0.0/0"]
}

variable "master_https_src_cidrs" {
  description = "CIDRs that are allowed to https to Masters and API LB"
  type        = "list"
  default     = ["0.0.0.0/0"]
}

variable "worker_icmp_src_cidrs" {
  description = "CIDRs that are allowed to send ICMP to workers"
  type        = "list"
  default     = []
}

variable "worker_ssh_src_cidrs" {
  description = "CIDRs that are allowed to SSH to workers"
  type        = "list"
  default     = []
}

variable "worker_https_src_cidrs" {
  description = "CIDRs that are allowed to http(s) to workers and API LB"
  type        = "list"
  default     = []
}
