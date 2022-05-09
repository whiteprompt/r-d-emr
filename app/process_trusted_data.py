import boto3
import sys
import argparse
import utils
import pyspark.sql.functions as F
from pyspark.sql.types import StructType, StructField, StringType, IntegerType, DoubleType, TimestampType
from pyspark.context import SparkContext
from pyspark.sql.session import SparkSession
from utils import Logger

sc = SparkContext.getOrCreate()
spark = SparkSession.builder.master("yarn").getOrCreate()
log = Logger()
s3 = boto3.client('s3')
s3_resource = boto3.resource('s3')

green_taxi_schema = StructType([
    StructField("vendor_id", IntegerType(), True),
    StructField("pickup_datetime", TimestampType(), True),
    StructField("dropoff_datetime", TimestampType(), True),
    StructField("store_and_fwd_flag", StringType(), True),
    StructField("rate_code_id", IntegerType(), True),
    StructField("pickup_location_id", IntegerType(), True),
    StructField("dropoff_location_id", IntegerType(), True),
    StructField("passenger_count", IntegerType(), True),
    StructField("trip_distance", DoubleType(), True),
    StructField("fare_amount", DoubleType(), True),
    StructField("extra", DoubleType(), True),
    StructField("mta_tax", DoubleType(), True),
    StructField("tip_amount", DoubleType(), True),
    StructField("tolls_amount", DoubleType(), True),
    StructField("ehail_fee", DoubleType(), True),
    StructField("improvement_surcharge", DoubleType(), True),
    StructField("total_amount", DoubleType(), True),
    StructField("payment_type", IntegerType(), True),
    StructField("trip_type", IntegerType(), True),
    StructField("congestion_surcharge", StringType(), True)])

yellow_taxi_schema = StructType([
    StructField("vendor_id", StringType(), True),
    StructField("pickup_datetime", TimestampType(), True),
    StructField("dropoff_datetime", TimestampType(), True),
    StructField("passenger_count", IntegerType(), True),
    StructField("trip_distance", DoubleType(), True),
    StructField("rate_code_id", IntegerType(), True),
    StructField("store_and_fwd_flag", StringType(), True),
    StructField("pickup_location_id", IntegerType(), True),
    StructField("dropoff_location_id", IntegerType(), True),
    StructField("payment_type", StringType(), True),
    StructField("fare_amount", DoubleType(), True),
    StructField("extra", DoubleType(), True),
    StructField("mta_tax", DoubleType(), True),
    StructField("tip_amount", DoubleType(), True),
    StructField("tolls_amount", DoubleType(), True),
    StructField("improvement_surcharge", DoubleType(), True),
    StructField("total_amount", DoubleType(), True),
    StructField("congestion_surcharge", StringType(), True)])

zone_lookup_schema = StructType([
    StructField("location_id", IntegerType(), True),
    StructField("borough", StringType(), True),
    StructField("zone", StringType(), True),
    StructField("service_zone", StringType(), True)])


def load_data_green_taxi(spark, path_file):
    try:
        green_taxi_df = spark.read.option("header", "true").schema(green_taxi_schema).option("escapeQuotes", "true").csv(f"{path_file}")
        green_taxi_df = green_taxi_df.withColumn("year", F.year(green_taxi_df['pickup_datetime']).cast("integer"))
        green_taxi_df = green_taxi_df.withColumn("month", F.month(green_taxi_df['pickup_datetime']).cast("integer"))
        return green_taxi_df
    except Exception as e:
        log.error(f"Fail to load green taxi data from '{path_file}': {str(e)}")


def load_data_yellow_taxi(spark, path_file):
    try:
        yellow_taxi_df = spark.read.option("header", "true").schema(yellow_taxi_schema).option("escapeQuotes", "true").csv(f"{path_file}")
        yellow_taxi_df = yellow_taxi_df.withColumn("year", F.year(yellow_taxi_df['pickup_datetime']).cast("integer"))
        yellow_taxi_df = yellow_taxi_df.withColumn("month", F.month(yellow_taxi_df['pickup_datetime']).cast("integer"))
        return yellow_taxi_df
    except Exception as e:
        log.error(f"Fail to load yellow taxi data from '{path_file}': {str(e)}")


def load_data_zone_lookup(spark, path_file):
    try:
        zone_lookup_df = spark.read.option("header", "true").schema(zone_lookup_schema).option("escapeQuotes", "true").csv(f"{path_file}")
        return zone_lookup_df
    except Exception as e:
        log.error(f"Fail to load data from '{path_file}': {str(e)}")



def process_data(type):
    raw_path = f"s3://wp-lakehouse/raw/{type}_taxi/"
    trusted_path = f"s3://wp-lakehouse/trusted/{type}_taxi/"
    bucket_name = raw_path.split('/')[2]
    bucket_key = f"{raw_path.split('/')[3]}/{raw_path.split('/')[4]}/"
    coalesce_size = (int(utils.calc_spark_coalesce(bucket_name, bucket_key)) + 1)
    if type == "green":
        log.info(f"Processing {type} taxi data.")
        df_green = load_data_green_taxi(spark, raw_path)
        df_green.coalesce(coalesce_size).write.mode("append").partitionBy("year", "month").option("compression", "snappy").parquet(trusted_path)
    elif type == "yellow":
        log.info(f"Processing {type} taxi data.")
        df_yellow = load_data_yellow_taxi(spark, raw_path)
        df_yellow.coalesce(coalesce_size).write.mode("append").partitionBy("year", "month").option("compression", "snappy").parquet(trusted_path)
    elif type == "zone_lookup":
        log.info(f"Processing {type} lookup data.")
        df_zone_lookup = load_data_zone_lookup()
        df_zone_lookup.coalesce(coalesce_size).write.mode("append").option("compression", "snappy").parquet(trusted_path)
    elif type == "all":
        log.info(f"Processing {type} taxi and lookup data.")
        # Green taxi
        df_green = load_data_green_taxi(spark, raw_path)
        df_green.coalesce(coalesce_size).write.mode("append").partitionBy("year", "month").option("compression", "snappy").parquet(trusted_path)
        # Yellow taxi
        df_yellow = load_data_yellow_taxi(spark, raw_path)
        df_yellow.coalesce(coalesce_size).write.mode("append").partitionBy("year", "month").option("compression", "snappy").parquet(trusted_path)
        # Lookup zone data
        df_zone_lookup = load_data_zone_lookup()
        df_zone_lookup.coalesce(coalesce_size).write.mode("append").option("compression", "snappy").parquet(trusted_path)
    else:
        log.warn(f"The option '{type}' is not valid, accepted values are (green, yellow, zone_lookup, all).")
        sys.exit(1)       
        

if __name__ == '__main__':
    app_parser = argparse.ArgumentParser(allow_abbrev=False)
    app_parser.add_argument('--type', ## Possible values: all, zone_lookup, green, yellow
                            action='store',
                            type=str,
                            required=True,
                            dest='type_opt',
                            help='Set the taxi type to process data.')

    args = app_parser.parse_args()
    log.info(f"Started processing of '{str(args.type_opt)}' taxi/lookup data'.")
    process_data(args.type_opt)
