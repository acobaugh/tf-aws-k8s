module "bootkube" {
  source = "git::https://github.com/poseidon/terraform-render-bootkube.git?ref=c5fc93d95fe4993511656cdd6372afbd1307f08f"

  cloud_provider = "aws"
  cluster_name   = "${var.cluster_name}"
  api_servers    = ["${format("api.%s", var.cluster_fqdn)}"]
  etcd_servers   = ["${aws_route53_record.etcd.*.fqdn}"]
  asset_dir      = "${path.cwd}/bootkube-assets"
  networking     = "${var.network_provider}"
  network_mtu    = "${var.network_mtu}"
  pod_cidr       = "${var.pod_cidr}"
  service_cidr   = "${var.service_cidr}"
}

data "archive_file" "bootkube-archive" {
  depends_on  = ["module.bootkube"]
  type        = "zip"
  source_dir  = "${path.cwd}/bootkube-assets"
  output_path = "${path.cwd}/bootkube-assets.zip"
}

resource "aws_s3_bucket_object" "bootkube_assets" {
  depends_on = ["data.archive_file.bootkube-archive"]

  bucket                 = "${var.config_s3_bucket}"
  acl                    = "private"
  key                    = "${var.config_s3_prefix}bootkube-assets.zip"
  source                 = "${path.cwd}/bootkube-assets.zip"
  server_side_encryption = "AES256"
  tags                   = "${var.tags}"
}

resource "null_resource" "rm-bootkube-assets" {
  depends_on = ["aws_s3_bucket_object.bootkube_assets"]

  provisioner "local-exec" {
    command = "rm -rf ${path.cwd}/bootkube-assets ${path.cwd}/bootkube-assets.zip"
  }
}

resource "aws_s3_bucket_object" "etcd_ca_cert" {
  bucket                 = "${var.config_s3_bucket}"
  acl                    = "private"
  key                    = "${var.config_s3_prefix}etcd-ca.crt"
  content                = "${module.bootkube.etcd_ca_cert}"
  server_side_encryption = "AES256"
  tags                   = "${var.tags}"
}

resource "aws_s3_bucket_object" "etcd_client_cert" {
  bucket                 = "${var.config_s3_bucket}"
  acl                    = "private"
  key                    = "${var.config_s3_prefix}etcd-client.crt"
  content                = "${module.bootkube.etcd_client_cert}"
  server_side_encryption = "AES256"
  tags                   = "${var.tags}"
}

resource "aws_s3_bucket_object" "etcd_client_key" {
  bucket                 = "${var.config_s3_bucket}"
  acl                    = "private"
  key                    = "${var.config_s3_prefix}etcd-client.key"
  content                = "${module.bootkube.etcd_client_key}"
  server_side_encryption = "AES256"
  tags                   = "${var.tags}"
}

resource "aws_s3_bucket_object" "etcd_server_cert" {
  bucket                 = "${var.config_s3_bucket}"
  acl                    = "private"
  key                    = "${var.config_s3_prefix}etcd-server.crt"
  content                = "${module.bootkube.etcd_server_cert}"
  server_side_encryption = "AES256"
  tags                   = "${var.tags}"
}

resource "aws_s3_bucket_object" "etcd_server_key" {
  bucket                 = "${var.config_s3_bucket}"
  acl                    = "private"
  key                    = "${var.config_s3_prefix}etcd-server.key"
  content                = "${module.bootkube.etcd_server_key}"
  server_side_encryption = "AES256"
  tags                   = "${var.tags}"
}

resource "aws_s3_bucket_object" "etcd_peer_cert" {
  bucket                 = "${var.config_s3_bucket}"
  acl                    = "private"
  key                    = "${var.config_s3_prefix}etcd-peer.crt"
  content                = "${module.bootkube.etcd_peer_cert}"
  server_side_encryption = "AES256"
  tags                   = "${var.tags}"
}

resource "aws_s3_bucket_object" "etcd_peer_key" {
  bucket                 = "${var.config_s3_bucket}"
  acl                    = "private"
  key                    = "${var.config_s3_prefix}etcd-peer.key"
  content                = "${module.bootkube.etcd_peer_key}"
  server_side_encryption = "AES256"
  tags                   = "${var.tags}"
}
