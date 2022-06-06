import argparse
import boto3
import botocore
from datetime import datetime
from utils import Logger

log = Logger()
s3 = boto3.client('s3')
s3_resource = boto3.resource('s3')


def check_key(bucket, key):
    try:
        s3_resource.Object(bucket, key).load()
    except botocore.exceptions.ClientError as e:
        if e.response['Error']['Code'] == "404":
            # The bucket key does not exist.
            return(False)
        else:
            # Something went wrong.
            raise
    else:
        # The key exists.
        return(True)

def copy_data(origin_bucket, origin_key, dest_bucket, dest_key):
    if not check_key(dest_bucket, dest_key):
        s3_resource.meta.client.copy({'Bucket': origin_bucket, 'Key': origin_key}, dest_bucket, dest_key)        
        log.info(f"The file '{dest_key}' was saved to bucket '{dest_bucket}'.")
    else:
        log.warn(f"The file '{dest_key}' already exists inside the bucket '{dest_bucket}'!") 


def execute(type, year_data="2020", month_interval="1-2"):
    try:
        is_ok = True
        interval = month_interval.split('-')
        min_interval = int(interval[0])
        max_interval = int(interval[1])
        while is_ok:
            if type == "zone_lookup":
                # Copy zone lookup data
                copy_data(origin_bucket="nyc-tlc", origin_key=f"misc/taxi _zone_lookup.csv",
                        dest_bucket='wp-lakehouse', dest_key=f"raw/zone_lookup_taxi/zone_lookup.csv")
                is_ok = False
            else:
                # Copy taxi trip data
                min_interval_str = "{:02d}".format(min_interval)
                copy_data(origin_bucket="nyc-tlc", origin_key=f"trip data/{type}_tripdata_{year_data}-{min_interval_str}.parquet",
                        dest_bucket='wp-lakehouse', dest_key=f"raw/{type}_taxi/trip_{year_data}_{min_interval_str}.parquet")
                
                if min_interval < max_interval:
                    min_interval = min_interval + 1
                    is_ok = True
                else: 
                    is_ok = False
    except Exception as e:
        log.error(f"Fail to extract data: {str(e)}")


if __name__ == '__main__':
    app_parser = argparse.ArgumentParser(allow_abbrev=False)
    app_parser.add_argument('--type', ## Possible values: zone_lookup, green, yellow
                            action='store',
                            type=str,
                            required=True,
                            dest='type_opt',
                            help='Set the taxi type that will be extracted data from AWS Open Data.')
    app_parser.add_argument('--year_data',
                            action='store',
                            type=str,
                            required=False,
                            dest='year_data_opt',
                            help='Set the year that will be extracted data from AWS Open Data.')
    app_parser.add_argument('--interval',
                            action='store',
                            type=str,
                            required=False,
                            dest='interval_opt',
                            help='Set the month interval to extract data from AWS Open Data.')

    args = app_parser.parse_args()
    log.info(f"Started extraction of '{str(args.type_opt)}' taxi/lookup data related to interval of '{args.interval_opt}'.")
    execute(args.type_opt, args.year_data_opt, args.interval_opt)