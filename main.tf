/** 
* # tf-k8s-aws
* This is a Terraform module to build a Kubernetes cluster in AWS.
*
* Inspiration comes from:
* * https://github.com/FutureSharks/tf-kops-cluster
* * https://github.com/poseidon/typhoon
*
* ## Goals
* * Fully leverage AWS-native capabilities when creating the resources. No SSH for provisioning.
* * Allow placement within a predefined VPC.
* * Enable AWS cloud provider features within Kubernetes itself
* * Fully export useful resource IDs and names for later reference by other Terraform'd infrastructure
*
* ## Non-goals
* * In-place upgrades
* * Supporting every single permutation on the theme
* * Supporting other public clouds (at this time)
*
* ## Features
* * [2-4](https://github.com/kubernetes/community/blob/master/contributors/design-proposals/cluster-lifecycle/self-hosted-kubernetes.md) self-hosted cluster via bootkube
* * [terraform-render-bootkube](https://github.com/poseidon/terraform-render-bootkube) to render the initial bootkube assets
* * AWS Autoscaling groups for each individual controller/master to ensure availability
* * AWS ELB for apiserver ingress
* * Configurable security group rules for workers and controllers so that these resources may be locked down
* * User-provided VPC, user-defined AZs, user-defined subnets. Subnets are created 1-per-AZ within the specified VPC
* * Custom tagging of resources in addition to those tags necessary for K8s to interface with AWS
* * Container Linux AMIs
* * Calico (preferred) or flannel CNI provider
*/

data "aws_ami" "coreos" {
  most_recent = true
  owners      = ["595879546273"]

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "name"
    values = ["CoreOS-${var.os_channel}-*"]
  }
}

## VPC resources
resource "aws_subnet" "subnet" {
  count                   = "${length(var.subnet_cidrs)}"
  vpc_id                  = "${var.vpc_id}"
  cidr_block              = "${element(var.subnet_cidrs, count.index)}"
  availability_zone       = "${element(var.az_names, count.index)}"
  map_public_ip_on_launch = true

  tags {
    Name              = "k8s cluster ${var.cluster_name} ${element(var.az_names, count.index)} subnet"
    KubernetesCluster = "${var.cluster_fqdn}"
  }
}

resource "aws_route_table" "rt" {
  vpc_id = "${var.vpc_id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${var.vpc_ig_id}"
  }

  tags {
    Name = "k8s cluster ${var_cluster_name} route table"
  }
}

resource "aws_route_table_association" "rt_association" {
  count          = "${length(var.subnet_cidrs)}"
  route_table_id = "${aws_route_table.rt.id}"
  subnet_id      = "${element(aws_subnet.subnet.*.id, count.index)}"
}

## masters
resource "aws_security_group" "master" {
  name        = "${var.cluster_name}-master"
  description = "${var.cluster_name} master security group"
  vpc_id      = "${var.vpc_id}"

  tags {
    Name = "${var.cluster_name}"
  }
}

resource "aws_security_group_rule" "master-egress" {
  security_group_id = "${aws_security_group.master.id}"

  type        = "egress"
  protocol    = "-1"
  from_port   = 0
  to_port     = 0
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "master-icmp" {
  security_group_id = "${aws_security_group.master.id}"

  type        = "ingress"
  protocol    = "icmp"
  from_port   = 0
  to_port     = 0
  cidr_blocks = [""]      # FIXME
}

resource "aws_security_group_rule" "master-ssh" {
  security_group_id = "${aws_security_group.master.id}"

  type        = "ingress"
  protocol    = "tcp"
  from_port   = 22
  to_port     = 22
  cidr_blocks = [""]      # FIXME
}

resource "aws_security_group_rule" "master-apiserver" {
  security_group_id = "${aws_security_group.master.id}"

  type        = "ingress"
  protocol    = "tcp"
  from_port   = 443
  to_port     = 443
  cidr_blocks = [""]      # FIXME
}

resource "aws_security_group_rule" "master-etcd" {
  security_group_id = "${aws_security_group.master.id}"

  type      = "ingress"
  protocol  = "tcp"
  from_port = 2379
  to_port   = 2380
  self      = true
}

resource "aws_security_group_rule" "master-flannel" {
  security_group_id = "${aws_security_group.master.id}"

  type                     = "ingress"
  protocol                 = "udp"
  from_port                = 8472
  to_port                  = 8472
  source_security_group_id = "${aws_security_group.worker.id}"
}

resource "aws_security_group_rule" "master-flannel-self" {
  security_group_id = "${aws_security_group.master.id}"

  type      = "ingress"
  protocol  = "udp"
  from_port = 8472
  to_port   = 8472
  self      = true
}

resource "aws_security_group_rule" "master-node-exporter" {
  security_group_id = "${aws_security_group.master.id}"

  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 9100
  to_port                  = 9100
  source_security_group_id = "${aws_security_group.worker.id}"
}

resource "aws_security_group_rule" "master-kubelet-self" {
  security_group_id = "${aws_security_group.master.id}"

  type      = "ingress"
  protocol  = "tcp"
  from_port = 10250
  to_port   = 10250
  self      = true
}

resource "aws_security_group_rule" "master-kubelet-read" {
  security_group_id = "${aws_security_group.master.id}"

  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 10255
  to_port                  = 10255
  source_security_group_id = "${aws_security_group.worker.id}"
}

resource "aws_security_group_rule" "master-kubelet-read-self" {
  security_group_id = "${aws_security_group.master.id}"

  type      = "ingress"
  protocol  = "tcp"
  from_port = 10255
  to_port   = 10255
  self      = true
}

resource "aws_security_group_rule" "master-bgp" {
  security_group_id = "${aws_security_group.master.id}"

  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 179
  to_port                  = 179
  source_security_group_id = "${aws_security_group.worker.id}"
}

resource "aws_security_group_rule" "master-bgp-self" {
  security_group_id = "${aws_security_group.master.id}"

  type      = "ingress"
  protocol  = "tcp"
  from_port = 179
  to_port   = 179
  self      = true
}

resource "aws_security_group_rule" "master-ipip" {
  security_group_id = "${aws_security_group.master.id}"

  type                     = "ingress"
  protocol                 = 4
  from_port                = 0
  to_port                  = 0
  source_security_group_id = "${aws_security_group.worker.id}"
}

resource "aws_security_group_rule" "master-ipip-self" {
  security_group_id = "${aws_security_group.master.id}"

  type      = "ingress"
  protocol  = 4
  from_port = 0
  to_port   = 0
  self      = true
}

resource "aws_security_group_rule" "master-ipip-legacy" {
  security_group_id = "${aws_security_group.master.id}"

  type                     = "ingress"
  protocol                 = 94
  from_port                = 0
  to_port                  = 0
  source_security_group_id = "${aws_security_group.worker.id}"
}

resource "aws_security_group_rule" "master-ipip-legacy-self" {
  security_group_id = "${aws_security_group.master.id}"

  type      = "ingress"
  protocol  = 94
  from_port = 0
  to_port   = 0
  self      = true
}

resource "aws_launch_configuration" "master-lc" {
  count                = "${length(var.subnet_cidrs)}"                                      # create one master per subnet/az
  name_prefix          = "${var.cluster_name}-master-${element(var.az_names, count.index)}"
  image_id             = "${data.aws_ami.coreos.id}"
  instance_type        = "${var.master_type}"
  key_name             = ""
  iam_instance_profile = "${aws_iam_instance_profile.master.name}"
  user_data            = ""

  root_block_device {
    volume_type           = "standard"
    delete_on_termination = true
  }

  associate_public_ip_address = true
  subnet_id                   = "${element(aws_subnet.subnet.*.id, count.index)}"
  vpc_security_group_ids      = ["${aws_security_group.master.id}"]
}

## IAM resources

