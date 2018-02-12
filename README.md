# tf-k8s-aws
This is a Terraform module to build a Kubernetes cluster in AWS.

Inspiration comes from:
* https://github.com/FutureSharks/tf-kops-cluster
* https://github.com/poseidon/typhoon

## Goals
* Fully leverage AWS-native capabilities when creating the resources. No SSH for provisioning.
* Allow placement within a predefined VPC, subnets, and AZs.
* Enable AWS cloud provider features within Kubernetes itself
* Fully export useful resource IDs and names for later reference by other Terraform'd infrastructure

## Non-goals
* In-place upgrades
* Supporting every single permutation on the theme
* Supporting other public clouds (at this time)

## Implementation
* [2-4](https://github.com/kubernetes/community/blob/master/contributors/design-proposals/cluster-lifecycle/self-hosted-kubernetes.md) self-hosted cluster via bootkube
* [terraform-render-bootkube](https://github.com/poseidon/terraform-render-bootkube) to render the initial bootkube assets
* AWS Autoscaling groups for each individual controller/master to ensure availability
* AWS ELB for apiserver ingress
* Configurable security group rules for workers and controllers so that these resources may be locked down


## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| asg_tags | Tags to be added to ASG-defined resources | map | `<map>` | no |
| cluster_domain_suffix | Internal cluster DNS domain served by kube-dns | string | `cluster.local` | no |
| cluster_name | Short name for this cluster | string | - | yes |
| master_type | EC2 instance type for master nodes | string | `t2.small` | no |
| network_mtu | CNI interface MTU. Use 8981 if you are using EC2 instances that support Jumbo frames. Only applicable with calico CNI provider | string | `1480` | no |
| network_provider | CNI provider: calico, flannel | string | `calico` | no |
| os_channel | Container Linux AMI channel (stable, beta, alpha) | string | `stable` | no |
| pod_cidr | Internal IPv4 CIDR for pods | string | `10.2.0.0/16` | no |
| route53_zone | Route53 zone to place master and apiserver ELB resource records | string | - | yes |
| route53_zone_id | Route53 zone id to place master and apiserver ELB resource records | string | - | yes |
| service_cidr | Internal IPv4 CIDR for services | string | `10.3.0.0/16` | no |
| tags | Tags to be added to terraform-defined resources | map | `<map>` | no |
| vpc_id | VPC id in which to place resources | string | - | yes |
| vpc_ig_id | VPC Internet Gateway | string | - | yes |
| vpc_subnet_cidrs | CIDRs of the subnets to create and launch EC2 instances in | string | - | yes |
| worker_asg_max | Worker node autoscaling group max size | string | `1` | no |
| worker_asg_min | Worker node autoscaling group min size | string | `1` | no |
| worker_type | EC2 instance type for worker nodes | string | `t2.small` | no |

