## VPC resources
resource "aws_subnet" "subnet" {
  count                           = "${length(var.vpc_subnet_cidrs)}"
  vpc_id                          = "${var.vpc_id}"
  cidr_block                      = "${element(var.vpc_subnet_cidrs, count.index)}"
  ipv6_cidr_block                 = "${cidrsubnet(var.vpc_ipv6_cidr_block, 8, count.index + var.ipv6_subnet_offset)}"
  availability_zone               = "${element(var.azs, count.index)}"
  map_public_ip_on_launch         = true
  assign_ipv6_address_on_creation = true

  tags = "${merge(var.tags, map("Name", "k8s cluster ${var.cluster_name} ${element(var.azs, count.index)} subnet", "kubernetes.io/cluster/${var.cluster_name}", "owned", "KubernetesCluster", "${var.cluster_name}"))}"
}

resource "aws_route_table" "rt" {
  vpc_id = "${var.vpc_id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${var.vpc_ig_id}"
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = "${var.vpc_ig_id}"
  }

  tags = "${merge(var.tags, map("Name", "k8s cluster ${var.cluster_name} ${element(var.azs, count.index)} route table", "kubernetes.io/cluster/${var.cluster_name}", "owned", "KubernetesCluster", "${var.cluster_name}"))}"
}

resource "aws_route_table_association" "rt_association" {
  count          = "${length(var.vpc_subnet_cidrs)}"
  route_table_id = "${aws_route_table.rt.id}"
  subnet_id      = "${element(aws_subnet.subnet.*.id, count.index)}"
}
