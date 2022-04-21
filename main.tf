# @Author: mpenners
# @Date:   2022-04-04T15:22:16+02:00
# @Last modified by:   mpenners
# @Last modified time: 2022-04-04T15:30:05+02:00
# ----------------------------------------------------
# simple tf template:
# - create one EC2 instance with public IP
# - and needed VPC resources
# - then run an ansible playbook on it
# -----------------------------------------------------
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 4.7"
    }
    shell = {
      source  = "scottwinkler/shell"
      version = "~> 1.0"
    }
  }
}
# Configure the AWS Provider

provider "aws" {
  shared_config_files      = ["${var.myawsconf}"]
  shared_credentials_files = ["${var.myawscreds}"]
  profile                  = var.myawsprof
  alias                    = "region"

  default_tags {
    tags = {
      Source   = "${var.sourcerepo}"
      Pipeline = "${var.CIPipeline}"
      Name     = "PAN_elastic_dev"
    }
  }
}
data "aws_region" "current" {
  provider = aws.region
}
# -------------------------------------------------
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair
# ... and note in above: aws provider does not create-new but require-existing key file
# https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html#having-ec2-create-your-key-pair
# a) create a new pair according to aws spec e.g. with
#      ssh-keygen -b 2048 -t rsa -f [absolute-filename]
#  or  ssh-keygen -t ED25519 -f [abssolute-filename]
# b) paste the pub-key directly into a var and dont use file-path (would give format errors)
# c) this keypair obviously is NEW to AWS and not already imported or generated in console
resource "aws_key_pair" "dev_elastic_key" {
  provider   = aws.region
  key_name   = "dev_elastic_key"
  public_key = var.def_pub_key
}
#-------------------------------------------------
# 1. Create VPC
resource "aws_vpc" "elastic_vpc" {
  provider             = aws.region
  cidr_block           = var.vpcidrblock
  instance_tenancy     = "default"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"
  enable_classiclink   = "false"

  tags = {
    Name = "aws:vpc-${var.vpcidrblock}"
  }
}
# 2. Add subnet to VPC
resource "aws_subnet" "elastic_subnet" {
  vpc_id            = aws_vpc.elastic_vpc.id
  cidr_block        = var.subnetblock
  availability_zone = "${var.myawsregion}a"
  tags = {
    Name = "aws:subnet-${var.subnetblock}"
  }
}
# 3. Add IGW to VPC
resource "aws_internet_gateway" "elastic_igw" {
  vpc_id = aws_vpc.elastic_vpc.id
}
# 4. Add default route via IGW to VPC
resource "aws_route_table" "elastic_routes" {
  vpc_id = aws_vpc.elastic_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.elastic_igw.id
  }
}
# 5. connect IGW-routes and Subnet
resource "aws_route_table_association" "elastic_public" {
  subnet_id      = aws_subnet.elastic_subnet.id
  route_table_id = aws_route_table.elastic_routes.id
}
# 6. Prepare Security Group for instance
resource "aws_security_group" "elastic_sg" {
  name        = "PAN-Elastic-EC2-SG"
  description = "To get access to EC2 instance"
  vpc_id      = aws_vpc.elastic_vpc.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 5601
    to_port     = 5601
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 5519
    to_port     = 5519
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
# 7. Create EC2 Instance
resource "aws_instance" "elastic_inst" {
  ami                         = var.aws_ami
  instance_type               = var.aws_instype
  key_name                    = aws_key_pair.dev_elastic_key.id
  vpc_security_group_ids      = ["${aws_security_group.elastic_sg.id}"]
  subnet_id                   = aws_subnet.elastic_subnet.id
  availability_zone           = "${var.myawsregion}a"
  associate_public_ip_address = true
  connection {
    type        = "ssh"
    agent       = "false"
    host        = aws_instance.elastic_inst.public_ip
    user        = var.ami_user
    private_key = file("${var.ansible_privkey}")
  }
  provisioner "file" {
    source      = "${path.module}/${var.dockercup_deploydir}/"
    destination = "/home/${var.ami_user}"
  }
}
# 8. Create a hosts file for ansible
# but this way doesnt scale inventory groups and is ugly - can be done better:
# https://github.com/habakke/terraform-provider-ansible/blob/main/README.md
resource "local_file" "ansible_inventory" {
  depends_on = [aws_instance.elastic_inst]
  content = templatefile("${path.module}/ansible/inventory.tmpl",
    { ec2pubip = aws_instance.elastic_inst.public_ip }
  )
  filename        = "${path.module}/ansible/${var.ansible_hosts}"
  file_permission = "0644"
}
# 9. Run the playbook to install requested SW
#    ensure environment sets all needs of ansible-playbook command at runtime
# https://livebook.manning.com/book/terraform-in-action/appendix-d/v-11/14
resource "shell_script" "call_ansible" {
  lifecycle_commands {
    create = <<-EOF
      cd "${path.module}/ansible/"
      rc="$(ansible-playbook ${path.module}/${var.ansible_playbook} >/dev/null 2>&1)$?"
      echo "{\"ansible_playbook_exit_status\": \"$rc\"}" > ${path.module}/${var.ansible_tf_statfile}
    EOF
    delete = <<-EOF
      rm -f "ansible/${var.ansible_log}"
      rm -f "ansible/${var.ansible_tf_statfile}"
    EOF
    read   = <<-EOF
      cat ${path.module}/ansible/${var.ansible_tf_statfile}
    EOF
  }
  environment = {
    ANSIBLE_HOST_KEY_CHECKING = "False"
    ANSIBLE_PRIVATE_KEY_FILE  = var.ansible_privkey
    ANSIBLE_LOG_PATH          = var.ansible_log
    ANSIBLE_REMOTE_USER       = var.ami_user
    ANSIBLE_INVENTORY         = var.ansible_hosts
  }
  depends_on = [local_file.ansible_inventory]
}

#output "call_ansible" {
#  value = shell_script.call-ansible.output["ansible_playbook_exit_status"]
#}

# Create an S3 bucket and copy some files on it:
# 1. Create S3 bucket
# resource "aws_s3_bucket" "project1-bucket" {
#    bucket = var.bucket_name
#    acl = var.bucket_acl
#}
# upload stuff to the bucket
# resource "aws_s3_bucket_object" "upload_to_S3" {
#  for_each = fileset("uploadS3/", "*")
#  bucket = aws_s3_bucket.project1-bucket.id
#  key = each.value
#  source = "uploadS3/${each.value}"
#}
