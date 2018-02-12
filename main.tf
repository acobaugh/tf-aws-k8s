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

resource "aws_autoscaling_group" "master" {
  count = "${length(var.subnet_cidrs)}"
  name  = "${var.cluster_name}-master${count.index} ${aws_launch_configuration.master.name}"

  min_size                  = 1
  max_size                  = 1
  desired_size              = 1
  default_cooldown          = 30
  health_check_grace_period = 30

  vpc_zone_identifier = ["${element(aws_subnet.subnet.*.id, count.index)}"]

  launch_configuration = "${aws_launch_configuration.master.name}"

  lifecycle {
    ignore_changes = ["image_id"]
  }

  tags = [
    {
      key                 = "Name"
      value               = "${var.cluster_name}-master${count.index}"
      propogate_at_launch = true
    },
  ]
}

resource "aws_launch_configuration" "master" {
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

data "template_file" "master_ct_config" {
  count = "${length(var.subnet_cidrs)}"

  template = "${file("${path.module}/templates/master.yaml.tmpl")}"

  vars = {
    etcd_name               = ""
    etcd_domain             = ""
    etcd_initial_cluster    = ""
    k8s_dns_service_ip      = ""
    cluster_domain_suffix   = ""
    kubeconfig_ca_cert      = ""
    kubeconfig_kubelet_cert = ""
    kubeconfig_kublet_key   = ""
    kubeconfig_server       = ""
    ssh_authorized_key      = ""
  }
}

data "ct_config" "master_ignition" {
  count        = "${length(var.subnet_cidrs)}"
  content      = "${element(data.template_file.master_ct_config.*.rendered, count.index)}"
  pretty_print = false
}

## workers
resource "aws_security_group" "worker" {
  name        = "${var.cluster_name}-worker"
  description = "${var.cluster_name} worker security group"

  vpc_id = "${var.vpc_id}"

  tags = "${map("Name", "${var.cluster_name}-worker")}"
}

resource "aws_security_group_rule" "worker-icmp" {
  security_group_id = "${aws_security_group.worker.id}"

  type        = "ingress"
  protocol    = "icmp"
  from_port   = 0
  to_port     = 0
  cidr_blocks = [""]      # FIXME
}

resource "aws_security_group_rule" "worker-ssh" {
  security_group_id = "${aws_security_group.worker.id}"

  type        = "ingress"
  protocol    = "tcp"
  from_port   = 22
  to_port     = 22
  cidr_blocks = [""]      # FIXME
}

resource "aws_security_group_rule" "worker-http" {
  security_group_id = "${aws_security_group.worker.id}"

  type        = "ingress"
  protocol    = "tcp"
  from_port   = 80
  to_port     = 80
  cidr_blocks = [""]      # FIXME
}

resource "aws_security_group_rule" "worker-https" {
  security_group_id = "${aws_security_group.worker.id}"

  type        = "ingress"
  protocol    = "tcp"
  from_port   = 443
  to_port     = 443
  cidr_blocks = [""]      # FIXME
}

resource "aws_security_group_rule" "worker-flannel" {
  security_group_id = "${aws_security_group.worker.id}"

  type                     = "ingress"
  protocol                 = "udp"
  from_port                = 8472
  to_port                  = 8472
  source_security_group_id = "${aws_security_group.controller.id}"
}

resource "aws_security_group_rule" "worker-flannel-self" {
  security_group_id = "${aws_security_group.worker.id}"

  type      = "ingress"
  protocol  = "udp"
  from_port = 8472
  to_port   = 8472
  self      = true
}

resource "aws_security_group_rule" "worker-node-exporter" {
  security_group_id = "${aws_security_group.worker.id}"

  type      = "ingress"
  protocol  = "tcp"
  from_port = 9100
  to_port   = 9100
  self      = true
}

resource "aws_security_group_rule" "worker-kubelet" {
  security_group_id = "${aws_security_group.worker.id}"

  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 10250
  to_port                  = 10250
  source_security_group_id = "${aws_security_group.controller.id}"
}

resource "aws_security_group_rule" "worker-kubelet-self" {
  security_group_id = "${aws_security_group.worker.id}"

  type      = "ingress"
  protocol  = "tcp"
  from_port = 10250
  to_port   = 10250
  self      = true
}

resource "aws_security_group_rule" "worker-kubelet-read" {
  security_group_id = "${aws_security_group.worker.id}"

  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 10255
  to_port                  = 10255
  source_security_group_id = "${aws_security_group.controller.id}"
}

resource "aws_security_group_rule" "worker-kubelet-read-self" {
  security_group_id = "${aws_security_group.worker.id}"

  type      = "ingress"
  protocol  = "tcp"
  from_port = 10255
  to_port   = 10255
  self      = true
}

resource "aws_security_group_rule" "ingress-health-self" {
  security_group_id = "${aws_security_group.worker.id}"

  type      = "ingress"
  protocol  = "tcp"
  from_port = 10254
  to_port   = 10254
  self      = true
}

resource "aws_security_group_rule" "worker-bgp" {
  security_group_id = "${aws_security_group.worker.id}"

  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 179
  to_port                  = 179
  source_security_group_id = "${aws_security_group.controller.id}"
}

resource "aws_security_group_rule" "worker-bgp-self" {
  security_group_id = "${aws_security_group.worker.id}"

  type      = "ingress"
  protocol  = "tcp"
  from_port = 179
  to_port   = 179
  self      = true
}

resource "aws_security_group_rule" "worker-ipip" {
  security_group_id = "${aws_security_group.worker.id}"

  type                     = "ingress"
  protocol                 = 4
  from_port                = 0
  to_port                  = 0
  source_security_group_id = "${aws_security_group.controller.id}"
}

resource "aws_security_group_rule" "worker-ipip-self" {
  security_group_id = "${aws_security_group.worker.id}"

  type      = "ingress"
  protocol  = 4
  from_port = 0
  to_port   = 0
  self      = true
}

resource "aws_security_group_rule" "worker-ipip-legacy" {
  security_group_id = "${aws_security_group.worker.id}"

  type                     = "ingress"
  protocol                 = 94
  from_port                = 0
  to_port                  = 0
  source_security_group_id = "${aws_security_group.controller.id}"
}

resource "aws_security_group_rule" "worker-ipip-legacy-self" {
  security_group_id = "${aws_security_group.worker.id}"

  type      = "ingress"
  protocol  = 94
  from_port = 0
  to_port   = 0
  self      = true
}

resource "aws_security_group_rule" "worker-egress" {
  security_group_id = "${aws_security_group.worker.id}"

  type        = "egress"
  protocol    = "-1"
  from_port   = 0
  to_port     = 0
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_autoscaling_group" "workers" {
  name = "${var.cluster_name}-worker ${aws_launch_configuration.worker.name}"

  min_size                  = "${var.worker_asg_min}"
  max_size                  = "${var.worker_asg_max}"
  default_cooldown          = 30
  health_check_grace_period = 30

  vpc_zone_identifier = ["${aws_subnet.subnet.*.id}"]

  launch_configuration = "${aws_launch_configuration.worker.name}"

  lifecycle {
    create_before_destroy = true
    ignore_changes        = ["image_id"]
  }

  tags = [
    {
      key                 = "Name"
      value               = "${var.cluster_name}-worker"
      propogate_at_launch = true
    },
  ]
}

resource "aws_launch_configuration" "worker" {
  image_id      = "${data.aws_ami.coreos.image_id}"
  instance_type = "${var.worker_type}"

  user_data = ""

  root_block_device {
    volume_type           = "standard"
    delete_on_termination = true
  }

  security_groups = ["${aws_security_group.worker.id}"]

  lifecycle {
    create_before_destroy = true
  }
}

data "template_file" "worker_ct_config" {
  template = "${file("${path.module}/templates/worker.yaml.tmpl")}"

  vars = {
    k8s_dns_service_ip      = ""
    k8s_etcd_service_ip     = ""
    cluster_domain_suffix   = ""
    kubeconfig_ca_cert      = ""
    kubeconfig_kubelet_key  = ""
    kubeconfig_kubelet_cert = ""
    kubeconfig_server       = ""
    ssh_authorized_key      = ""
  }
}

data "ct_config" "worker_ignition" {
  content      = "${data.template_file.worker_ct_config.rendered}"
  pretty_print = false
}

## IAM resources

