# tf-aws-k8s
This is a Terraform module to build a Kubernetes cluster in AWS.

Inspiration comes from:
* https://github.com/FutureSharks/tf-kops-cluster
* https://github.com/poseidon/typhoon
* https://github.com/poseidon/typhoon/pull/76

## Goals
* Fully leverage AWS-native capabilities when creating the resources. No SSH for provisioning.
* Allow placement within a predefined VPC.
* Enable AWS cloud provider features within Kubernetes itself
* Fully export useful resource IDs and names for later reference by other Terraform'd infrastructure

## Non-goals
* In-place upgrades
* Supporting every single permutation on the theme
* Supporting other public clouds (at this time)

## Features
* [2-4](https://github.com/kubernetes/community/blob/master/contributors/design-proposals/cluster-lifecycle/self-hosted-kubernetes.md) self-hosted cluster via bootkube
* [terraform-render-bootkube](https://github.com/poseidon/terraform-render-bootkube) to render the initial bootkube assets
* [terraform-provider-ct](https://github.com/coreos/terraform-provider-ct) to render/transpile ContainerLinux Ignition specs
* CoreOS's ContainerLinux AMI
* AWS ELB for apiserver ingress (will be switched to NLB in the near future)
* Configurable security group rules for workers and masters so that these resources may be locked down
* User-provided VPC, user-defined AZs, user-defined subnets. Subnets are created 1-per-AZ within the specified VPC
* Custom tagging of resources in addition to those tags necessary for K8s to interface with AWS
* Calico (preferred) or flannel CNI provider

## Module usage
[MODULE.md](MODULE.md)

## Kubectl usage
```
export cluster_name=$(terraform output cluster_name)
export KUBECONFIG=~/.kube/$cluster_name
terraform output user-kubeconfig > $KUBECONFIG
kubectl config use-context ${cluster_name}-context
kubectl cluster-info
```
