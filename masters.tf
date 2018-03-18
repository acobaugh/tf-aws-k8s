## masters
resource "aws_security_group" "master" {
  name        = "${var.cluster_name}-master"
  description = "${var.cluster_name} master security group"
  vpc_id      = "${var.vpc_id}"

  tags = "${
		merge(
			var.tags, 
			map(
				"Name", "${var.cluster_name}-master", 
				"kubernetes.io/cluster/${var.cluster_name}", "owned", 
				"KubernetesCluster", "${var.cluster_name}"
			)
		)
	}"
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
  cidr_blocks = ["${var.master_icmp_src_cidrs}"]
}

resource "aws_security_group_rule" "master-ssh" {
  security_group_id = "${aws_security_group.master.id}"

  type        = "ingress"
  protocol    = "tcp"
  from_port   = 22
  to_port     = 22
  cidr_blocks = ["${var.master_ssh_src_cidrs}"]
}

resource "aws_security_group_rule" "master-apiserver" {
  security_group_id = "${aws_security_group.master.id}"

  type        = "ingress"
  protocol    = "tcp"
  from_port   = 443
  to_port     = 443
  cidr_blocks = ["${var.master_https_src_cidrs}"]
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

resource "aws_instance" "master" {
  count = "${length(var.vpc_subnet_cidrs)}" # create one master per subnet/az

  ami                  = "${data.aws_ami.coreos.id}"
  instance_type        = "${var.master_type}"
  iam_instance_profile = "${aws_iam_instance_profile.master_profile.name}"
  user_data            = "${element(data.ct_config.master_ignition.*.rendered, count.index)}"

  root_block_device {
    volume_type           = "standard"
    delete_on_termination = true
  }

  associate_public_ip_address = true
  subnet_id                   = "${element(aws_subnet.subnet.*.id, count.index)}"
  vpc_security_group_ids      = ["${aws_security_group.master.id}"]

  lifecycle {
    ignore_changes = ["ami"]
  }

  tags = "${
		merge(
			var.tags, 
			map(
				"Name", "${var.cluster_name}-master${count.index}", 
				"kubernetes.io/cluster/${var.cluster_name}", "owned", 
				"KubernetesCluster", "${var.cluster_name}"
			)
		)
	}"
}

resource "null_resource" "repeat" {
  count = "${length(var.vpc_subnet_cidrs)}"

  triggers {
    name   = "etcd${count.index}"
    domain = "etcd${count.index}.${var.cluster_fqdn}"
  }
}

data "template_file" "master_ct_config" {
  count = "${length(var.vpc_subnet_cidrs)}"

  template = "${file("${path.module}/templates/master.yaml.tmpl")}"

  vars = {
    fqdn                  = "master${count.index}.${var.cluster_fqdn}"
    etcd_name             = "etcd${count.index}"
    etcd_domain           = "etcd${count.index}.${var.cluster_fqdn}"
    etcd_initial_cluster  = "${join(",", formatlist("%s=https://%s:2380", null_resource.repeat.*.triggers.name, null_resource.repeat.*.triggers.domain))}"
    k8s_dns_service_ip    = "${cidrhost(var.service_cidr, 10)}"
    cluster_domain_suffix = "${var.cluster_domain_suffix}"
    kubeconfig            = "${indent(10, module.bootkube.kubeconfig)}"
    ssh_authorized_key    = "${var.ssh_key}"
    config_s3_bucket      = "${var.config_s3_bucket}"
    config_s3_prefix      = "${var.config_s3_prefix}"
  }
}

data "ct_config" "master_ignition" {
  count        = "${length(var.vpc_subnet_cidrs)}"
  content      = "${element(data.template_file.master_ct_config.*.rendered, count.index)}"
  pretty_print = false
}

resource "aws_route53_record" "master" {
  count = "${length(var.vpc_subnet_cidrs)}"

  zone_id = "${var.route53_zone_id}"

  name = "${format("master%d.%s.", count.index, var.cluster_fqdn)}"
  type = "A"
  ttl  = 300

  records = ["${element(aws_instance.master.*.public_ip, count.index)}"]
}

resource "aws_route53_record" "master-v6" {
  count = "${length(var.vpc_subnet_cidrs)}"

  zone_id = "${var.route53_zone_id}"

  name = "${format("master%d.%s.", count.index, var.cluster_fqdn)}"
  type = "AAAA"
  ttl  = 300

  records = ["${element(aws_instance.master.*.ipv6_addresses.0, count.index)}"]
}

resource "aws_route53_record" "etcd" {
  count = "${length(var.vpc_subnet_cidrs)}"

  zone_id = "${var.route53_zone_id}"

  name = "${format("etcd%d.%s.", count.index, var.cluster_fqdn)}"
  type = "A"
  ttl  = 300

  records = ["${element(aws_instance.master.*.private_ip, count.index)}"]
}

resource "aws_route53_record" "api" {
  zone_id = "${var.route53_zone_id}"

  name = "${format("api.%s.", var.cluster_fqdn)}"
  type = "A"

  alias {
    name                   = "${aws_elb.api.dns_name}"
    zone_id                = "${aws_elb.api.zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_elb" "api" {
  name            = "${var.cluster_name}-api"
  subnets         = ["${aws_subnet.subnet.*.id}"]
  security_groups = ["${aws_security_group.master.id}"]

  listener {
    lb_port           = 443
    lb_protocol       = "tcp"
    instance_port     = 443
    instance_protocol = "tcp"
  }

  instances = ["${aws_instance.master.*.id}"]

  health_check {
    target              = "SSL:443"
    healthy_threshold   = 2
    unhealthy_threshold = 4
    timeout             = 5
    interval            = 6
  }

  idle_timeout                = 3600
  connection_draining         = true
  connection_draining_timeout = 300

  tags = "${
		merge(
			var.tags, 
			map("Name", "${var.cluster_name}-api")
		)
	}"
}
