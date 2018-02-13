module "bootkube" {
  source = "git::https://github.com/poseidon/terraform-render-bootkube.git?ref=533e82f833c166297abd249ac3d4853d6ebed364"

  cloud_provider = "aws"
  cluster_name   = "${var.cluster_name}"
  api_servers    = ["${format("api.%s", var.cluster_fqdn)}"]
  etcd_servers   = ["${aws_route53_record.etcd.*.fqdn}"]
  asset_dir      = "${path.module}/bootkube-assets"
  networking     = "${var.network_provider}"
  network_mtu    = "${var.network_mtu}"
  pod_cidr       = "${var.pod_cidr}"
  service_cidr   = "${var.service_cidr}"
}

data "archive_file" "bootkube-archive" {
  depends_on  = ["module.bootkube"]
  type        = "zip"
  source_dir  = "${path.module}/bootkube-assets"
  output_path = "${path.module}/bootkube-assets.zip"
}

resource "aws_s3_bucket_object" "bootkube_assets" {
  depends_on = ["data.archive_file.bootkube-archive"]

  bucket                 = "${var.bootkube_s3_bucket}"
  acl                    = "private"
  key                    = "${var.bootkube_s3_prefix}bootkube_assets.zip"
  source                 = "${path.module}/bootkube-assets.zip"
  server_side_encryption = "AES256"
  tags                   = ""
}

resource "null_resource" "rm-bootkube-assets" {
  depends_on = ["aws_s3_bucket_object.bootkube_assets"]

  provisioner "local-exec" {
    command = "rm -rf ${path.module}/bootkube-assets ${path.module}/bootkube-assets.zip"
  }
}
