terraform {
  backend "s3" {
    bucket  = "wp-emr-processing"
    key     = "tfoutput/emrstate.tfstate"
    region  = "${var.region}"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.74.0"
    }
  }
}

provider "aws" {
  region = "${var.region}"
}

##resource "aws_s3_bucket" "emr_bucket" {
##  bucket = "${var.s3_bucket_name}"
##  acl    = "private"
##}

resource "aws_emr_cluster" "cluster" {
  name           = "${var.cluster_name}"
  release_label  = "${var.release_label}"
  applications   = "${var.cluster_applications}"
  termination_protection = false  
  configurations_json = file(var.configurations_json)
  log_uri      = "${var.log_uri}"
  service_role = "${var.service_role}"
 /* 
  dynamic "step" {
    for_each = jsondecode(templatefile("${var.steps}", {}))
    content {
      action_on_failure = step.value.action_on_failure
      name              = step.value.name
      hadoop_jar_step {
        jar  = step.value.hadoop_jar_step.jar
        args = step.value.hadoop_jar_step.args
      }
    }
  }*/

  step_concurrency_level = "${var.step_concurrency_level}"

  ec2_attributes {
    key_name                          = "${var.key_name}"
    subnet_id                         = "${var.subnet_id}"
    #emr_managed_master_security_group = "${var.emr_managed_master_security_group}"
    #emr_managed_slave_security_group  = "${var.emr_managed_slave_security_group}"
    #service_access_security_group = "${var.service_access_security_group}"
    instance_profile               = "${var.instance_profile}"
  }


master_instance_group {
      #name           = "${var.master_instance_group_name}"
      instance_type  = "${var.master_instance_group_instance_type}"
      instance_count = "${var.master_instance_group_instance_count}"
      bid_price      = "${var.master_instance_group_bid_price}"    
      ebs_config {
                    #iops = "${var.master_instance_group_ebs_iops}"
                    size = "${var.master_instance_group_ebs_size}"
                    type = "${var.master_instance_group_ebs_type}"
                    volumes_per_instance = "${var.master_instance_group_ebs_volumes_per_instance}"
                    }


}

core_instance_group {
      #name           = "${var.core_instance_group_name}"
      instance_type  = "${var.core_instance_group_instance_type}"
      instance_count = "${var.core_instance_group_instance_count}"
      bid_price      = "${var.core_instance_group_bid_price}"    #Do not use core instances as Spot Instance in Prod because terminating a core instance risks data loss.
      ebs_config {
                    #iops = "${var.core_instance_group_ebs_iops}"
                    size = "${var.core_instance_group_ebs_size}"
                    type = "${var.core_instance_group_ebs_type}"
                    volumes_per_instance = "${var.core_instance_group_ebs_volumes_per_instance}"
                    }
}

bootstrap_action {
    path = "s3://elasticmapreduce/bootstrap-actions/run-if"
    name = "runif"
    args = ["instance.isMaster=true", "echo running on master node"]
}
 
  tags = {
    EnvType = "${var.env_type}"
    Project = "${var.project_name}"
    Client  = "${var.client_name}"
  }

}
