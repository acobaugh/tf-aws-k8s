output "user-kubeconfig" {
  description = "Admin user's kubeconfig file contents."
  value       = "${module.bootkube.user-kubeconfig}"
}

output "cluster_name" {
  description = "Short name for this cluster"
  value       = "${var.cluster_name}"
}

output "cluster_fqdn" {
  description = "DNS domain for this cluster. etcdN and masterN are rooted under this domain"
  value       = "${var.cluster_fqdn}"
}

output "api_hostname" {
  description = "Kubernetes API load balancer hostname"
  value       = "${aws_route53_record.api.fqdn}"
}

output "master_iam_role_arn" {
  description = "Master IAM Role ARN"
  value       = "${aws_iam_role.master_role.arn}"
}

output "master_sg_id" {
  description = "Master security group ID"
  value       = "${aws_security_group.master.id}"
}

output "worker_iam_role_arn" {
  description = "Worker IAM Role ARN"
  value       = "${aws_iam_role.worker_role.arn}"
}

output "worker_sg_id" {
  description = "Worker security group ID"
  value       = "${aws_security_group.worker.id}"
}

output "master_instance_ids" {
  description = "List of all master EC2 instance IDs"
  value       = ["${aws_instance.master.*.id}"]
}
