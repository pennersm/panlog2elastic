# your local users personal aws settings and profile
# main.tf uses the same key for both aws and later login to the EC2 instance
variable "myawsconf" {
  default = "/Users/mpenners/.aws/config"
}
variable "myawscreds" {
  default = "/Users/mpenners/.aws/credentials"
}
# profile to use inside .aws/config
variable "myawsprof" {
  default = "pennersm"
}
# pub key to match the private key used for login to EC2
variable "def_pub_key" {
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDCa0hWHBLV05nDA1xPq785e4CU4d+K+Xw07SS0RhJlOKRU3OYh6PakKEJ69hehw+7D9v7agzJbKSJad9kTUkivrFypZyxeC56beWAMbT657o4xHtsuOcPxFutiteNiF2gULBGpP1ZxJHZSKUCkOZToMGX6UZS2PLmYEDo0Ek9188z8TbGplbahiRs180VSjhXvQWygPCF+iUR2o7cSXcpF56Z4DYnIwflvbGfJoL7xM62OATuLGUCefaMlU49rm40HB5IvwRcKAmk/lBcj6+uRNFz8N3vQWyYyYE8rSDqGBUPFHaEURF1vrKtQyWAwOXAZP0GmBK30wr+QM5WNeShj mpenners@M-C02W10FNHTDG"
}
# MIND TO ADJUST YOUR REGION
variable "myawsregion" {
  default = "us-east-1"
}
#-----------------------------------
# those 2 are just used to assign tags
variable "sourcerepo" {
  default = "devopsTrain-exe1-awstf"
}
variable "CIPipeline" {
  default = "devopsTrain-exe1-cipipe"
}
#-----------------------------------
# Define your EC2 settings here
variable "vpcidrblock" {
  default = "10.0.2.0/23"
}
variable "subnetblock" {
  default = "10.0.2.0/24"
}
# NOTE: the AMI is region specific
variable "aws_ami" {
  default = "ami-04505e74c0741db8d"
}
variable "ami_user" {
  default = "ubuntu"
}
variable "aws_instype" {
  default = "t2.xlarge"
}
variable "bucket_acl" {
  default = "private"
}
variable "bucket_name" {
  default = "elastic_bucket"
}
#-----------------------------------
# settings for ansible
# playbook that will be executed this file can be edited
# ansible resources are managed by terraform
# terraform runs this playbook on the EC2 after provisioning it
variable "ansible_playbook" {
  default = "install_docker.yml"
}
#resource file will be managed by terraform manual editing useless
variable "ansible_hosts" {
  default = "hosts"
}
# private key that matches the pub key used above in def_pub_key
variable "ansible_privkey" {
  default = "/Users/mpenners/.aws/id_aws_elastic"
}
# only while the EC2 instance is active tf keeps last ansible log here
# at destroy phse the log is removed
variable "ansible_log" {
  default = "current_ansible.log"
}
# showing output status to terraform tfstatfile
variable "ansible_tf_statfile" {
  default = "ansible_tf_stat.json"
}
#-----------------------------------
# settings for docker-compose
#
# compose file that ansible will kick-off docker-compose
# this file must be edited to define the cluster topology
variable "docker_compose_file" {
  default = "docker-compose.yml"
}
variable "dockercup_deploydir" {
  default = "./docker"
}
