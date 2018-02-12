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
| asg_tags |  | string | - | yes |
| cluster_domain_suffix |  | string | - | yes |
| cluster_name |  | string | - | yes |
| master_type |  | string | - | yes |
| network_mtu |  | string | - | yes |
| network_provider | kubernetes specifics | string | - | yes |
| os_channel |  | string | - | yes |
| pod_cidr |  | string | - | yes |
| route53_zone |  | string | - | yes |
| route53_zone_id |  | string | - | yes |
| service_cidr |  | string | - | yes |
| tags |  | string | - | yes |
| vpc_id |  | string | - | yes |
| vpc_ig_id |  | string | - | yes |
| vpc_subnet_ids |  | string | - | yes |
| worker_asg_max |  | string | - | yes |
| worker_asg_min |  | string | - | yes |
| worker_type |  | string | - | yes |

