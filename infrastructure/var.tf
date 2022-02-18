variable "region" {
  description = "The AWS region we want this bucket to live in."
  default     = "us-east-1"
}

variable "project_name" {
  description = "The project name that every resource is related to."
  default     = "Data Research - EMR"
}

variable "env_type" {
  description = "The environment that our resources will be deployed."
  default     = "dev"
}

variable "client_name" {
  description = "The team name that is responsible for this deployment."
  default     = "WP"
}

variable "cluster_name" {
  description = "EMR cluster name"
  default = "Terraform-Automation"
}

variable "step_concurrency_level" {
  default = 1
}

variable "release_label" {
  description = "EMR Version"
  default = "emr-6.2.0"
}

variable "cluster_applications" {
  type    = list(string)
  description = "Name the applications to be installed"
  default = ["Hadoop", "Hive", "Hue", "Presto", "Spark"]
}
#------------------------------Master Instance Group------------------------------

variable "master_instance_group_name" {
  type        = string
  description = "Name of the Master instance group"
  default = "MasterGroup"
}

variable "master_instance_group_instance_type" {
  type        = string
  description = "EC2 instance type for all instances in the Master instance group"
  default = "m6g.xlarge"
}

variable "master_instance_group_instance_count" {
  type        = number
  description = "Target number of instances for the Master instance group. Must be at least 1"
  default     = 1
}

variable "master_instance_group_ebs_size" {
  type        = number
  description = "Master instances volume size, in gibibytes (GiB)"
  default = 30
}

variable "master_instance_group_ebs_type" {
  type        = string
  description = "Master instances volume type. Valid options are `gp2`, `io1`, `standard` and `st1`"
  default     = "gp2"
}

variable "master_instance_group_ebs_iops" {
  type        = number
  description = "The number of I/O operations per second (IOPS) that the Master volume supports"
  default     = null
}

variable "master_instance_group_ebs_volumes_per_instance" {
  type        = number
  description = "The number of EBS volumes with this configuration to attach to each EC2 instance in the Master instance group"
  default     = 1
}

variable "master_instance_group_bid_price" {
  type        = string
  description = "Bid price for each EC2 instance in the Master instance group, expressed in USD. By setting this attribute, the instance group is being declared as a Spot Instance, and will implicitly create a Spot request. Leave this blank to use On-Demand Instances"
  default     = 0.10
}
#----------------------Core Instance Group-----------------------------------#
variable "core_instance_group_name" {
  type        = string
  description = "Name of the Master instance group"
  default = "CoreGroup"
}

variable "core_instance_group_instance_type" {
  type        = string
  description = "EC2 instance type for all instances in the Core instance group"
  default = "m6g.xlarge"
}

variable "core_instance_group_instance_count" {
  type        = number
  description = "Target number of instances for the Core instance group. Must be at least 1"
  default     = 1
}

variable "core_instance_group_ebs_size" {
  type        = number
  description = "Core instances volume size, in gibibytes (GiB)"
  default = 30
}

variable "core_instance_group_ebs_type" {
  type        = string
  description = "Core instances volume type. Valid options are `gp2`, `io1`, `standard` and `st1`"
  default     = "gp2"
}

variable "core_instance_group_ebs_iops" {
  type        = number
  description = "The number of I/O operations per second (IOPS) that the Core volume supports"
  default     = null
}

variable "core_instance_group_ebs_volumes_per_instance" {
  type        = number
  description = "The number of EBS volumes with this configuration to attach to each EC2 instance in the Core instance group"
  default     = 1
}

variable "core_instance_group_bid_price" {
  type        = string
  description = "Bid price for each EC2 instance in the Core instance group, expressed in USD. By setting this attribute, the instance group is being declared as a Spot Instance, and will implicitly create a Spot request. Leave this blank to use On-Demand Instances"
  default     = 0.10
}

#=================================================================#

variable "key_name" {
  default = "key-pair.pem"
}

variable "subnet_id" {
  default = "subnet-xxxxxxxx"
}

variable "instance_profile" {
  default =  "EMR_EC2_DefaultRole"
}

variable "service_access_security_group"{
  default =  "sg-xxxxxxxx"
}
  
variable "emr_managed_master_security_group" {
  default = "sg-xxxxxxxx"
}

variable "emr_managed_slave_security_group" {
  default = "sg-xxxxxxxx"
}

variable "service_role" {
  default = "arn:aws:iam::xxxxxxxx:role/xxxxxxxx/EMR_DefaultRole"
}

variable "configurations_json" {
  type        = string
  description = "A JSON file with a list of configurations for the EMR cluster"
  default = "./infrastructure/config/configuration.json"
}  

variable "log_uri" {
  default = "s3://wp-emr-processing/emr-logs/"
}

variable "steps" {
  type        = string
  description = "Steps to execute after creation of EMR cluster"
  default = "./infrastructure/config/steps.json"
}