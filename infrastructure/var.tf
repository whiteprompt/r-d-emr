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

variable "app_name" {
  description = "The common name for your deployment."
  default     = "emr_processing"
}

variable "s3_bucket_name" {
  default = "wp-lakehouse"
  description = "The bucket name used by the lakehouse."
}

variable "registry_name" {
  description = "The name of AWS Glue Schema Registry."
  default     = "whiteprompt-data-management"
}

variable "trusted_db" {
  description = "The common name for your deployment."
  default     = "wp_trusted_nyc_taxi"
}

variable "lakehouse_db" {
  description = "The common name for your deployment."
  default     = "wp_lakehouse_nyc_taxi"
}

variable "trusted_tables_list" {
  type = list(string)
  default = [ "green_taxy", "yellow_taxi", "zone_lookup_taxi" ]
}

variable "lakehouse_tables_list" {
  type = list(string)
  default = [ "payment_method_type", "passenger_taxi_type", "pickup_time_span_taxi_type", "trip_month_span_taxi_type" ]
}

variable "payment_method_type_schema_json" {
  type        = string
  description = "A JSON file with the schema definition."
  default = "./infrastructure/glue/registry_schemas/payment_method_type_schema.json"
}

variable "passenger_taxi_type_schema_json" {
  type        = string
  description = "A JSON file with the schema definition."
  default = "./infrastructure/glue/registry_schemas/passenger_taxi_type_schema.json"
}

variable "pickup_time_span_taxi_type_schema_json" {
  type        = string
  description = "A JSON file with the schema definition."
  default = "./infrastructure/glue/registry_schemas/pickup_time_span_taxi_type_schema.json"
}

variable "trip_month_span_taxi_type_schema_json" {
  type        = string
  description = "A JSON file with the schema definition."
  default = "./infrastructure/glue/registry_schemas/trip_month_span_taxi_type_schema.json"
}

variable "zone_lookup_schema_json" {
  type        = string
  description = "A JSON file with the schema definition."
  default = "./infrastructure/glue/registry_schemas/zone_lookup_schema.json"
}

variable "green_taxi_schema_json" {
  type        = string
  description = "A JSON file with the schema definition."
  default = "./infrastructure/glue/registry_schemas/green_taxi_schema.json"
}

variable "yellow_taxi_schema_json" {
  type        = string
  description = "A JSON file with the schema definition."
  default = "./infrastructure/glue/registry_schemas/yellow_taxi_schema.json"
}

variable "schema_version_number" {
  type        = number
  description = "The common version number of schemas."
  default     = 1
}

variable "storage_input_format" {
  description = "Storage input format class for aws glue for parcing data."
  default     = "org.apache.hadoop.hive.ql.io.SymlinkTextInputFormat"
}

variable "storage_output_format" {
  description = "Storage output format class for aws glue for parcing data."
  default     = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"
}

variable "serde_name" {
  description = "The serialization library name."
  default     = "JsonSerDe"
}
variable "serde_library" {
  description = "The serialization library class."
  default     = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"
}

#------------------------------EMR Variable section------------------------------

variable "cluster_name" {
  description = "EMR cluster name"
  default = "WP_Lakehouse_NYC_Taxi_Data"
}

variable "step_concurrency_level" {
  default = 1
}

variable "release_label" {
  description = "EMR Version"
  default = "emr-6.5.0"
}

variable "cluster_applications" {
  type    = list(string)
  description = "Name of the applications to be installed"
  default = ["Hadoop", "Hive", "Spark"]
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
  description = "Master instances volume type."
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
  default = "data-mgmt.pem"
}

variable "subnet_id" {
  default = "subnet-d66e7eb1"
}

variable "instance_profile" {
  default =  "EMR_EC2_DefaultRole"
}

variable "service_access_security_group"{
  default =  "sg-xxxxxxxx"
}
  
variable "emr_managed_master_security_group" {
  default = "sg-09f2e5de468ebfc3e"
}

variable "emr_managed_slave_security_group" {
  default = "sg-06347ea1f8bb1e4c2"
}

variable "service_role" {
  default = "arn:aws:iam:::role/EMR_DefaultRole"
}

variable "configurations_json" {
  type        = string
  description = "A JSON file with a list of configurations for the EMR cluster"
  default = "./infrastructure/config/configuration.json"
}  

variable "log_uri" {
  default = "s3://wp-data-mgmt/emr-logs/"
}

variable "steps" {
  type        = string
  description = "Steps to execute after creation of EMR cluster"
  default = "./infrastructure/config/steps.json"
}