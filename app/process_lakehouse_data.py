import json
import pyspark.sql.functions as F
from pyspark.sql.types import StructType, StructField, StringType, IntegerType, DoubleType, TimestampType
from pyspark.context import SparkContext
from pyspark.sql.session import SparkSession
from delta.tables import *
from utils import Logger

sc = SparkContext.getOrCreate()
spark = SparkSession.builder.master("local[*]").getOrCreate()
log = Logger()

def create_temp_views():
    try:
        bucket_name = "wp-lakehouse"
        #green_taxi_trusted = f"s3://{bucket_name}/trusted/green_taxi/"
        #yellow_taxi_trusted = f"s3://{bucket_name}/trusted/yellow_taxi/"
        #zone_lookup_taxi_trusted = f"s3://{bucket_name}/trusted/zone_lookup_taxi/"

        green_taxi_trusted = f"/home/jonathan/Documents/Work/Projects/WhitePrompt/data-lakehouse/demo_data/trusted/green_taxi/"
        yellow_taxi_trusted = f"/home/jonathan/Documents/Work/Projects/WhitePrompt/data-lakehouse/demo_data/trusted/yellow_taxi/"

        # Green Taxi view
        log.info("Creating temp view 'green_taxi_tmp'.")
        df_green_taxi = spark.read.parquet(green_taxi_trusted)
        df_green_taxi.createOrReplaceTempView("green_taxi_tmp")

        # Yellow Taxi view
        log.info("Creating temp view 'yellow_taxi_tmp'.")
        df_yellow_taxi = spark.read.parquet(yellow_taxi_trusted)
        df_yellow_taxi.createOrReplaceTempView("yellow_taxi_tmp")

        # Zone Lookup data view
        log.info("Creating temp view 'zone_lookup_tmp'.")
        df_zone_lookup = spark.read.parquet(zone_lookup_taxi_trusted)
        df_zone_lookup.createOrReplaceTempView("zone_lookup_tmp")
    except Exception as e:
        log.error(f"Fail to create temp view: {str(e)}")


def total_payment_method_type(path):
    try:
        # Count how many payments were made by type
        table_name = "payment_method_type"
        dfPaymentMadeTotal = spark.sql("""
        WITH 
        green_19 as (SELECT payment_type FROM `green_taxi_tmp` WHERE year = 2019),
        green_20 as (SELECT payment_type FROM `green_taxi_tmp` WHERE year = 2020),
        yellow as (SELECT payment_type FROM `yellow_taxi_tmp` WHERE year in (2019, 2020))

        SELECT case when Payment_type = 1 then 'Credit card'
        when Payment_type = 2 then 'Cash'
        when Payment_type = 3 then 'No charge'
        when Payment_type = 4 then 'Dispute' 
        when Payment_type = 5 then 'Other' end as payment_type, Count(Payment_type) as total_payment 
        FROM (SELECT * FROM green_19 UNION ALL SELECT * FROM green_20 UNION ALL SELECT * FROM yellow) 
        WHERE Payment_type IS NOT NULL Group by Payment_type
        """)
        log.info(f"Generating delta table for '{table_name}' at '{path}'.")
        dfPaymentMadeTotal.write.format("delta").mode("overwrite").save(f"{path}/{table_name}/")
        deltaTable = DeltaTable.forPath(spark, f"{path}/{table_name}/")
        deltaTable.generate("symlink_format_manifest")
        return deltaTable
    except Exception as e:
        log.error(f"Fail to create delta table '{table_name}': {str(e)}")

def total_passenger_taxi_type(path):
    try:
        # Number of passenger served by taxi type
        table_name = "passenger_taxi_type"
        dfTotalPassengerByType = spark.sql("""
        WITH  
        green_19 as (SELECT passenger_count FROM `green_taxi_tmp` WHERE year = 2019),
        green_20 as (SELECT passenger_count FROM `green_taxi_tmp` WHERE year = 2020),
        green as (SELECT * FROM green_19 UNION ALL SELECT * FROM green_20),
        yellow as (SELECT passenger_count FROM `yellow_taxi_tmp` WHERE year in (2019, 2020)),
        total_passenger_yellow as (SELECT count(*) as Total_Passenger FROM (SELECT passenger_count FROM yellow)),
        total_passenger_green as (SELECT count(*) as Total_Passenger FROM (SELECT passenger_count FROM green))

        SELECT total_passenger, 'Yellow' as taxi_type
        FROM total_passenger_yellow
        UNION ALL
        SELECT total_passenger, 'Green' as taxi_type
        FROM total_passenger_green
        """)
        log.info(f"Generating delta table for '{table_name}' at '{path}'.")
        dfTotalPassengerByType.write.format("delta").mode("overwrite").save(f"{path}/{table_name}/")
        deltaTable = DeltaTable.forPath(spark, f"{path}/{table_name}/")
        deltaTable.generate("symlink_format_manifest")
        return deltaTable
    except Exception as e:
        log.error(f"Fail to create delta table '{table_name}': {str(e)}")
    
def total_pickup_time_span_taxi_type(path):
    try:
        # Total pick up timing Time Span
        table_name = "pickup_time_span_taxi_type"
        dfPickUpTimeSpan = spark.sql("""
        WITH 
        green_19 as (SELECT pickup_datetime as Green_time FROM `green_taxi_tmp` WHERE year = 2019),
        green_20 as (SELECT pickup_datetime as Green_time FROM `green_taxi_tmp` WHERE year = 2020),
        green as (SELECT * FROM green_19 UNION ALL SELECT * FROM green_20),
        yellow as  (SELECT pickup_datetime as Yellow_time FROM `yellow_taxi_tmp` WHERE year in (2019, 2020)),
        final_data_green as (SELECT time , count(*) as c1 from (Select Extract(Hour From green.Green_time) as time From green) 
        group by time order by time),
        final_data_yellow as (SELECT time , count(*) as c1 from (Select Extract(Hour From yellow.Yellow_time) as time From yellow) 
        group by time order by time),
        green_graph_data as (
        SELECT CASE
            WHEN time between 0 and 2 THEN '00-02'
            WHEN time between 3 and 5 THEN '03-05'
            WHEN time between 6 and 8 THEN '06-08'
            WHEN time between 9 and 11 THEN '09-11'
            WHEN time between 12 and 14 THEN '12-14'
            WHEN time between 15 and 17 THEN '15-17'
            WHEN time between 18 and 20 THEN '18-20'
            WHEN time between 21 and 23 THEN '21-23'
        END AS span,sum(c1) as total, 'Green' as taxi_type
        FROM final_data_green
        group by span),

        yellow_graph_data as (SELECT CASE
            WHEN time between 0 and 2 THEN '00-02'
            WHEN time between 3 and 5 THEN '03-05'
            WHEN time between 6 and 8 THEN '06-08'
            WHEN time between 9 and 11 THEN '09-11'
            WHEN time between 12 and 14 THEN '12-14'
            WHEN time between 15 and 17 THEN '15-17'
            WHEN time between 18 and 20 THEN '18-20'
            WHEN time between 21 and 23 THEN '21-23'
        END AS span,sum(c1) as total, 'Yellow' as taxi_type
        FROM final_data_yellow
        group by span order by 1)

        Select *, SUBSTR(span, 0, 2) as timeslot From ((select * from green_graph_data)
        UNION ALL
        (select * from yellow_graph_data))
        order by timeslot
        """)
        log.info(f"Generating delta table for '{table_name}' at '{path}'.")
        dfPickUpTimeSpan.write.format("delta").mode("overwrite").save(f"{path}/{table_name}/")
        deltaTable = DeltaTable.forPath(spark, f"{path}/{table_name}/")
        deltaTable.generate("symlink_format_manifest")
        return deltaTable
    except Exception as e:
        log.error(f"Fail to create delta table '{table_name}': {str(e)}")


def total_trip_month_span_taxi_type(path):
    try:
        # Total of trips carried out by month and taxi type
        table_name = "trip_month_span_taxi_type"
        dfTotalTripByMonthAndType = spark.sql("""
        WITH 
        green_19 as (SELECT pickup_datetime as Green_time FROM `green_taxi_tmp` WHERE year = 2019),
        green_20 as (SELECT pickup_datetime as Green_time FROM `green_taxi_tmp` WHERE year = 2020),
        green as (SELECT * FROM green_19 UNION ALL SELECT * FROM green_20),
        yellow as  (SELECT pickup_datetime as Yellow_time FROM `yellow_taxi_tmp` WHERE year in (2019, 2020)),
        final_data_green as (SELECT month, count(*) as Count from (Select Extract(Month From green.Green_time) as month From green)
        group by month order by month),
        final_data_yellow as (SELECT month, count(*) as Count from (Select Extract(Month From yellow.Yellow_time) as month From yellow)
        group by month order by month)

        (SELECT CASE
            WHEN Month_Name = 1 THEN 'January'
            WHEN Month_Name = 2 THEN 'February'
            WHEN Month_Name = 3 THEN 'March'
            WHEN Month_Name = 4  THEN 'April'
            WHEN Month_Name = 5 THEN 'May'
            WHEN Month_Name = 6 THEN 'June'
            WHEN Month_Name = 7  THEN 'July'
            WHEN Month_Name = 8 THEN 'August'
            WHEN Month_Name = 9 THEN 'September'
            WHEN Month_Name = 10 THEN 'October'
            WHEN Month_Name = 11 THEN 'November'
            WHEN Month_Name = 12 THEN 'December'
        END AS span, count, month, taxi_type FROM 
        (Select count, month, 'Green' as taxi_type, month as Month_Name from final_data_green)
        Order by month)

        UNION ALL

        (SELECT CASE
            WHEN Month_Name = 1 THEN 'January'
            WHEN Month_Name = 2 THEN 'February'
            WHEN Month_Name = 3 THEN 'March'
            WHEN Month_Name = 4  THEN 'April'
            WHEN Month_Name = 5 THEN 'May'
            WHEN Month_Name = 6 THEN 'June'
            WHEN Month_Name = 7  THEN 'July'
            WHEN Month_Name = 8 THEN 'August'
            WHEN Month_Name = 9 THEN 'September'
            WHEN Month_Name = 10 THEN 'October'
            WHEN Month_Name = 11 THEN 'November'
            WHEN Month_Name = 12 THEN 'December'
        END AS span, count, month, taxi_type FROM 
        (Select count, month, 'Yellow' as taxi_type, month as Month_Name from final_data_yellow)
        Order by month) order by month
        """)
        log.info(f"Generating delta table for '{table_name}' at '{path}'.")
        dfTotalTripByMonthAndType.write.format("delta").mode("overwrite").save(f"{path}/{table_name}/")
        deltaTable = DeltaTable.forPath(spark, f"{path}/{table_name}/")
        deltaTable.generate("symlink_format_manifest")
        return deltaTable
    except Exception as e:
        log.error(f"Fail to create delta table '{table_name}': {str(e)}")


if __name__ == '__main__':
    log.info("Beginning of Data Lakehouse tables creation.")
    lakehouse_path = "s3://wp-lakehouse/refined/"
    create_temp_views()
    total_payment_method_type(lakehouse_path)
    total_passenger_taxi_type(lakehouse_path)
    total_pickup_time_span_taxi_type(lakehouse_path)
    total_trip_month_span_taxi_type(lakehouse_path)
    log.info("All tables were created inside of Data Lakehouse '{lakehouse_path}'.")