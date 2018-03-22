
# tf-aws-k8s
This is a Terraform module to build a Kubernetes cluster in AWS.


  [36mvar.asg_tags[0m (<map>)
  [90mTags to be added to ASG-defined resources[0m

  [36mvar.azs[0m (required)
  [90mAvailability zones. Should have an equal number of AZs as subnets.[0m

  [36mvar.cluster_domain_suffix[0m (cluster.local)
  [90mInternal cluster DNS domain served by kube-dns[0m

  [36mvar.cluster_fqdn[0m (required)
  [90mFQDN for this cluster. Should be rooted under `route53_zone`[0m

  [36mvar.cluster_name[0m (required)
  [90mShort name for this cluster. Should be unique across all clusters.[0m

  [36mvar.config_s3_bucket[0m (required)
  [90mAWS S3 bucket to place bootkube rendered assets and ssl material for usage by the masters when bootstrapping[0m

  [36mvar.config_s3_prefix[0m ()
  [90mAWS S3 bucket key prefix, under which bootkube-assets.zip and various ssl files will be placed[0m

  [36mvar.ipv6_subnet_offset[0m (required)
  [90mBase /64 subnet number to start creating subnets at. Eg. the N in x:x:x:N::/64[0m

  [36mvar.master_https_src_cidrs[0m (<list>)
  [90mCIDRs that are allowed to https to Masters and API LB[0m

  [36mvar.master_icmp_src_cidrs[0m (<list>)
  [90mCIDRs that are allowed to send ICMP to Masters and API LB[0m

  [36mvar.master_ssh_src_cidrs[0m (<list>)
  [90mCIDRs that are allowed to SSH to Masters[0m

  [36mvar.master_type[0m (t2.small)
  [90mEC2 instance type for master nodes[0m

  [36mvar.network_mtu[0m (1480)
  [90mCNI interface MTU. Use 8981 if you are using EC2 instances that support Jumbo frames. Only applicable with calico CNI provider[0m

  [36mvar.network_provider[0m (calico)
  [90mCNI provider: calico, flannel[0m

  [36mvar.os_channel[0m (stable)
  [90mContainer Linux AMI channel (stable, beta, alpha)[0m

  [36mvar.pod_cidr[0m (10.2.0.0/16)
  [90mInternal IPv4 CIDR for pods[0m

  [36mvar.route53_zone_id[0m (required)
  [90mRoute53 zone id to place master and apiserver ELB resource records[0m

  [36mvar.service_cidr[0m (10.3.0.0/16)
  [90mInternal IPv4 CIDR for services[0m

  [36mvar.ssh_key[0m ()
  [90mSSH public key to allow login as core user on master and worker instances[0m

  [36mvar.tags[0m (<map>)
  [90mTags to be added to terraform-defined resources[0m

  [36mvar.vpc_id[0m (required)
  [90mVPC id in which to place resources[0m

  [36mvar.vpc_ig_id[0m (required)
  [90mVPC Internet Gateway[0m

  [36mvar.vpc_ipv6_cidr_block[0m (required)
  [90mIPv6 /56 CIDR block for the VPC. Subnets will be calculated out of this block.[0m

  [36mvar.vpc_subnet_cidrs[0m (required)
  [90mCIDRs of the subnets to create and launch EC2 instances in[0m

  [36mvar.worker_asg_max[0m (1)
  [90mWorker node autoscaling group max size[0m

  [36mvar.worker_asg_min[0m (1)
  [90mWorker node autoscaling group min size[0m

  [36mvar.worker_https_src_cidrs[0m (<list>)
  [90mCIDRs that are allowed to http(s) to workers and API LB[0m

  [36mvar.worker_icmp_src_cidrs[0m (<list>)
  [90mCIDRs that are allowed to send ICMP to workers[0m

  [36mvar.worker_ssh_src_cidrs[0m (<list>)
  [90mCIDRs that are allowed to SSH to workers[0m

  [36mvar.worker_type[0m (t2.small)
  [90mEC2 instance type for worker nodes[0m



  [36moutput.api_hostname[0m
  [90mKubernetes API load balancer hostname[0m

  [36moutput.cluster_fqdn[0m
  [90mDNS domain for this cluster. etcdN and masterN are rooted under this domain[0m

  [36moutput.cluster_name[0m
  [90mShort name for this cluster[0m

  [36moutput.master_iam_role_arn[0m
  [90mMaster IAM Role ARN[0m

  [36moutput.master_instance_ids[0m
  [90mList of all master EC2 instance IDs[0m

  [36moutput.master_sg_id[0m
  [90mMaster security group ID[0m

  [36moutput.user-kubeconfig[0m
  [90mAdmin user's kubeconfig file contents.[0m

  [36moutput.worker_iam_role_arn[0m
  [90mWorker IAM Role ARN[0m

  [36moutput.worker_sg_id[0m
  [90mWorker security group ID[0m



