provider "aws" {
  region  = var.region
  profile = "terraform_emr"
}

# use terraform apply -var-file="fixtures.eu-west-1.tfvars"

module "vpc" {
  source     = "git::https://github.com/cloudposse/terraform-aws-vpc.git?ref=tags/0.7.0"
  namespace  = var.namespace
  stage      = var.stage
  name       = var.name
  cidr_block = "172.16.0.0/16"
}

module "subnets" {
  source               = "git::https://github.com/cloudposse/terraform-aws-dynamic-subnets.git?ref=tags/0.16.0"
  availability_zones   = var.availability_zones
  namespace            = var.namespace
  stage                = var.stage
  name                 = var.name
  vpc_id               = module.vpc.vpc_id
  igw_id               = module.vpc.igw_id
  cidr_block           = module.vpc.vpc_cidr_block
  nat_gateway_enabled  = true
  nat_instance_enabled = false
}

module "s3_log_storage" {
  source        = "git::https://github.com/cloudposse/terraform-aws-s3-log-storage.git?ref=tags/0.5.0"
  region        = var.region
  namespace     = var.namespace
  stage         = var.stage
  name          = var.name
  attributes    = ["logs"]
  force_destroy = true
}

module "aws_key_pair" {
  source              = "git::https://github.com/cloudposse/terraform-aws-key-pair.git?ref=tags/0.4.0"
  namespace           = var.namespace
  stage               = var.stage
  name                = var.name
  attributes          = ["ssh", "key"]
  ssh_public_key_path = var.ssh_public_key_path
  generate_ssh_key    = var.generate_ssh_key
}

module "emr_cluster" {
  source                                         = "git::https://github.com/cloudposse/terraform-aws-emr-cluster.git?ref=tags/0.2.1"
  namespace                                      = var.namespace
  stage                                          = var.stage
  name                                           = var.name
  master_allowed_security_groups                 = [module.vpc.vpc_default_security_group_id, aws_security_group.allow_ssh.id]
  slave_allowed_security_groups                  = [module.vpc.vpc_default_security_group_id]
  region                                         = var.region
  vpc_id                                         = module.vpc.vpc_id
  subnet_id                                      = module.subnets.private_subnet_ids[0]
  route_table_id                                 = module.subnets.private_route_table_ids[0]
  subnet_type                                    = "private"
  ebs_root_volume_size                           = var.ebs_root_volume_size
  visible_to_all_users                           = var.visible_to_all_users
  release_label                                  = var.release_label
  applications                                   = var.applications
  configurations_json                            = var.configurations_json
  core_instance_group_instance_type              = var.core_instance_group_instance_type
  core_instance_group_instance_count             = var.core_instance_group_instance_count
  core_instance_group_ebs_size                   = var.core_instance_group_ebs_size
  core_instance_group_ebs_type                   = var.core_instance_group_ebs_type
  core_instance_group_ebs_volumes_per_instance   = var.core_instance_group_ebs_volumes_per_instance
  master_instance_group_instance_type            = var.master_instance_group_instance_type
  master_instance_group_instance_count           = var.master_instance_group_instance_count
  master_instance_group_ebs_size                 = var.master_instance_group_ebs_size
  master_instance_group_ebs_type                 = var.master_instance_group_ebs_type
  master_instance_group_ebs_volumes_per_instance = var.master_instance_group_ebs_volumes_per_instance
  create_task_instance_group                     = var.create_task_instance_group
  log_uri                                        = format("s3://%s", module.s3_log_storage.bucket_id)
  key_name                                       = module.aws_key_pair.key_name
}

resource "aws_instance" "bastion" {
  ami                         = "ami-02df9ea15c1778c9c"
  instance_type               = "t2.micro"
  subnet_id                   = module.subnets.public_subnet_ids[0]
  key_name                    = module.aws_key_pair.key_name
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]


  tags = {
    Name = "Spark_Bastion"

  }
}

resource "aws_security_group" "allow_ssh" {
  name_prefix = "SparkBastionSG"
  description = "Allow inbound SSH traffic"
  vpc_id      = module.vpc.vpc_id
  ingress {
    # TLS (change to whatever ports you need)
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    # Please restrict your ingress to only necessary IPs and ports.
    # Opening to 0.0.0.0/0 can lead to security vulnerabilities.
    cidr_blocks = ["79.66.135.229/32"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}
