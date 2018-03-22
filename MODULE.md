# tf-aws-k8s
This is a Terraform module to build a Kubernetes cluster in AWS.


## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| asg_tags | Tags to be added to ASG-defined resources | map | `<map>` | no |
| azs | Availability zones. Should have an equal number of AZs as subnets. | list | - | yes |
| cluster_domain_suffix | Internal cluster DNS domain served by kube-dns | string | `cluster.local` | no |
| cluster_fqdn | FQDN for this cluster. Should be rooted under `route53_zone` | string | - | yes |
| cluster_name | Short name for this cluster. Should be unique across all clusters. | string | - | yes |
| config_s3_bucket | AWS S3 bucket to place bootkube rendered assets and ssl material for usage by the masters when bootstrapping | string | - | yes |
| config_s3_prefix | AWS S3 bucket key prefix, under which bootkube-assets.zip and various ssl files will be placed | string | `` | no |
| ipv6_subnet_offset | Base /64 subnet number to start creating subnets at. Eg. the N in x:x:x:N::/64 | string | - | yes |
| master_https_src_cidrs | CIDRs that are allowed to https to Masters and API LB | list | `<list>` | no |
| master_icmp_src_cidrs | CIDRs that are allowed to send ICMP to Masters and API LB | list | `<list>` | no |
| master_ssh_src_cidrs | CIDRs that are allowed to SSH to Masters | list | `<list>` | no |
| master_type | EC2 instance type for master nodes | string | `t2.small` | no |
| network_mtu | CNI interface MTU. Use 8981 if you are using EC2 instances that support Jumbo frames. Only applicable with calico CNI provider | string | `1480` | no |
| network_provider | CNI provider: calico, flannel | string | `calico` | no |
| os_channel | Container Linux AMI channel (stable, beta, alpha) | string | `stable` | no |
| pod_cidr | Internal IPv4 CIDR for pods | string | `10.2.0.0/16` | no |
| route53_zone_id | Route53 zone id to place master and apiserver ELB resource records | string | - | yes |
| service_cidr | Internal IPv4 CIDR for services | string | `10.3.0.0/16` | no |
| ssh_key | SSH public key to allow login as core user on master and worker instances | string | `` | no |
| tags | Tags to be added to terraform-defined resources | map | `<map>` | no |
| vpc_id | VPC id in which to place resources | string | - | yes |
| vpc_ig_id | VPC Internet Gateway | string | - | yes |
| vpc_ipv6_cidr_block | IPv6 /56 CIDR block for the VPC. Subnets will be calculated out of this block. | string | - | yes |
| vpc_subnet_cidrs | CIDRs of the subnets to create and launch EC2 instances in | list | - | yes |
| worker_asg_max | Worker node autoscaling group max size | string | `1` | no |
| worker_asg_min | Worker node autoscaling group min size | string | `1` | no |
| worker_https_src_cidrs | CIDRs that are allowed to http(s) to workers and API LB | list | `<list>` | no |
| worker_icmp_src_cidrs | CIDRs that are allowed to send ICMP to workers | list | `<list>` | no |
| worker_ssh_src_cidrs | CIDRs that are allowed to SSH to workers | list | `<list>` | no |
| worker_type | EC2 instance type for worker nodes | string | `t2.small` | no |

## Outputs

| Name | Description |
|------|-------------|
| api_hostname | Kubernetes API load balancer hostname |
| cluster_fqdn | DNS domain for this cluster. etcdN and masterN are rooted under this domain |
| cluster_name | Short name for this cluster |
| master_iam_role_arn | Master IAM Role ARN |
| master_instance_ids | List of all master EC2 instance IDs |
| master_sg_id | Master security group ID |
| user-kubeconfig | Admin user's kubeconfig file contents. |
| worker_iam_role_arn | Worker IAM Role ARN |
| worker_sg_id | Worker security group ID |

