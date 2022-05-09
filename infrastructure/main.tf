terraform {
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

resource "aws_glue_registry" "glue_registry" {
  registry_name = "${var.registry_name}"
  tags = {
    EnvType = "${var.env_type}"
    Project = "${var.project_name}"
    Client  = "${var.client_name}"
  }
}

resource "aws_glue_schema" "green_taxi" {
  schema_name       = "green_taxi"
  registry_arn      = aws_glue_registry.glue_registry.arn
  data_format       = "JSON"
  compatibility     = "FULL_ALL"
  schema_definition = file(var.green_taxi_schema_json)
}

resource "aws_glue_schema" "yellow_taxi" {
  schema_name       = "yellow_taxi"
  registry_arn      = aws_glue_registry.glue_registry.arn
  data_format       = "JSON"
  compatibility     = "FULL_ALL"
  schema_definition = file(var.yellow_taxi_schema_json)
}

resource "aws_glue_schema" "zone_lookup" {
  schema_name       = "zone_lookup_taxi"
  registry_arn      = aws_glue_registry.glue_registry.arn
  data_format       = "JSON"
  compatibility     = "FULL_ALL"
  schema_definition = file(var.zone_lookup_taxi_schema_json)
}

resource "aws_glue_schema" "payment_method_type" {
  schema_name       = "payment_method_type"
  registry_arn      = aws_glue_registry.glue_registry.arn
  data_format       = "JSON"
  compatibility     = "FULL_ALL"
  schema_definition = file(var.payment_method_type_schema_json)
}

resource "aws_glue_schema" "passenger_taxi_type" {
  schema_name       = "passenger_taxi_type"
  registry_arn      = aws_glue_registry.glue_registry.arn
  data_format       = "JSON"
  compatibility     = "FULL_ALL"
  schema_definition = file(var.passenger_taxi_type_schema_json)
}

resource "aws_glue_schema" "pickup_time_span_taxi_type" {
  schema_name       = "pickup_time_span_taxi_type"
  registry_arn      = aws_glue_registry.glue_registry.arn
  data_format       = "JSON"
  compatibility     = "FULL_ALL"
  schema_definition = file(var.pickup_time_span_taxi_type_schema_json)
}

resource "aws_glue_schema" "trip_month_span_taxi_type" {
  schema_name       = "trip_month_span_taxi_type"
  registry_arn      = aws_glue_registry.glue_registry.arn
  data_format       = "JSON"
  compatibility     = "FULL_ALL"
  schema_definition = file(var.trip_month_span_taxi_type_schema_json)
}

# Trusted database and tables
resource "aws_glue_catalog_database" "aws_glue_database_trusted" {
  name = "${var.trusted_db}"
}

resource "aws_glue_catalog_table" "aws_glue_table_trusted" {
  for_each = toset(var.trusted_tables_list)
  name          = "${each.key}"
  database_name = "${aws_glue_catalog_database.aws_glue_database_trusted.name}"

  parameters = {
    EXTERNAL          = "TRUE"
    "classification"  = "parquet"
  }

  storage_descriptor {
    location      = "s3://${var.s3_bucket_name}/trusted/${each.key}/"
    input_format  = "${var.storage_input_format}"
    output_format = "${var.storage_output_format}"

    ser_de_info {
      name                  = "${var.serde_name}"
      serialization_library = "${var.serde_library}"

      parameters = {
        "serialization.format" = 1
        "parquet.compression"  = "SNAPPY"
      }
    }

    schema_reference {
      schema_id {
        registry_name = "${aws_glue_registry.glue_registry.registry_name}"
        schema_name   = "${each.key}"
      }
      schema_version_number = "${var.schema_version_number}"

    }
  }
}

# Lakehouse database and tables
resource "aws_glue_catalog_database" "aws_glue_database_lakehouse" {
  name = "${var.lakehouse_db}"
}

resource "aws_glue_catalog_table" "aws_glue_table_lakehouse" {
  for_each = toset(var.lakehouse_tables_list)
  name          = "${each.key}"
  database_name = "${aws_glue_catalog_database.aws_glue_database_lakehouse.name}"

  parameters = {
    EXTERNAL          = "TRUE"
    "classification"  = "parquet"
  }

  storage_descriptor {
    location      = "s3://${var.s3_bucket_name}/refined/${each.key}/_symlink_format_manifest/"
    input_format  = "${var.storage_input_format_delta}"
    output_format = "${var.storage_output_format_delta}"

    ser_de_info {
      name                  = "${var.serde_name}"
      serialization_library = "${var.serde_library}"

      parameters = {
        "serialization.format" = 1
        "parquet.compression"  = "SNAPPY"
      }
    }

    schema_reference {
      schema_id {
        registry_name = "${aws_glue_registry.glue_registry.registry_name}"
        schema_name   = "${each.key}"
      }
      schema_version_number = "${var.schema_version_number}"

    }
  }
}


resource "aws_emr_cluster" "cluster" {
  name           = "${var.cluster_name}"
  release_label  = "${var.release_label}"
  applications   = "${var.cluster_applications}"
  termination_protection = false  
  configurations_json = file(var.configurations_json)
  log_uri      = "${var.log_uri}"
  service_role = "${var.service_role}"
  
  dynamic "step" {
    for_each = jsondecode(templatefile("${var.emr_steps}", {}))
    content {
      action_on_failure = step.value.action_on_failure
      name              = step.value.name
      hadoop_jar_step {
        jar  = step.value.hadoop_jar_step.jar
        args = step.value.hadoop_jar_step.args
      }
    }
  }

  step_concurrency_level = "${var.step_concurrency_level}"

  ec2_attributes {
    key_name                          = "${var.key_name}"
    subnet_id                         = "${var.subnet_id}"
    emr_managed_master_security_group = "${var.emr_managed_master_security_group}"
    emr_managed_slave_security_group  = "${var.emr_managed_slave_security_group}"
    #service_access_security_group = "${var.service_access_security_group}"
    instance_profile               = "${var.instance_profile}"
  }


master_instance_group {
      name           = "${var.master_instance_group_name}"
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
      name           = "${var.core_instance_group_name}"
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
    path = "s3://wp-data-mgmt/emr-bootstrap-actions/emr_bootstrap.sh"
    name = "Install packages"
    args = []
}
 
  tags = {
    Name    = "${var.cluster_name}"
    EnvType = "${var.env_type}"
    Project = "${var.project_name}"
    Client  = "${var.client_name}"
  }

}
