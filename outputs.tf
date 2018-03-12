output "user-kubeconfig" {
  value = "${module.bootkube.user-kubeconfig}"
}

output "cluster_name" {}
output "cluster_fqdn" {}
output "api_hostname" {}

output "master_iam_role_arn" {
  value = "${aws_iam_role.master_role.arn}"
}

output "master_sg_id" {
  value = "${aws_security_group.master.id}"
}

output "worker_iam_role_arn" {
  value = "${aws_iam_role.worker_role.arn}"
}

output "worker_sg_id" {
  value = "${aws_security_group.worker.id}"
}
