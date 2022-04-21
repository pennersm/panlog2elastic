
output "instance-private-ip" {
  value = aws_instance.elastic_inst.private_ip
}

output "instance-public-ip" {
  value = aws_instance.elastic_inst.public_ip
}
#-------------------------------------------------
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity
#
data "aws_caller_identity" "current" {}
output "account_id" {
  value = data.aws_caller_identity.current.account_id
}
output "caller_arn" {
  value = data.aws_caller_identity.current.arn
}
output "caller_user" {
  value = data.aws_caller_identity.current.user_id
}
output "region_selected" {
  value = data.aws_region.current.name
}
output "EC2_selected" {
  value = data.aws_region.current.endpoint
}
output "AWS_local_profile" {
  value = var.myawsprof
}
#---------------------------------------------------
output "ANSIBLE_PRIVATE_KEY_FILE" {
  value = var.ansible_privkey
}
output "ANSIBLE_LOG_PATH" {
  value = var.ansible_log
}
output "ANSIBLE_REMOTE_USER" {
  value = var.ami_user
}
output "ANSIBLE_INVENTORY" {
  value = var.ansible_hosts
}
output "ansible_tf_statfile" {
  value = var.ansible_tf_statfile
}
output "ANSIBLE_PLAYBOOK_COMMAND" {
  value = "ansible-playbook ${path.module}/${var.ansible_playbook} >/dev/null 2>&1"
}
