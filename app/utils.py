import boto3
import json
import os
import logging


def calc_spark_coalesce(bucket, key_prefix):
    try:
        client = boto3.client('s3')
        paginator = client.get_paginator("list_objects")
        page_iterator = paginator.paginate(Bucket=bucket, Prefix=key_prefix)
        bucket_object_list = []
        logging.info("Analyzing S3 keys to defined the right number to Spark coalesce!")

        top_level_folders = dict()
        for page in page_iterator:
            if "Contents" in page:
                for key in page["Contents"]:
                    keyString = key["Key"]
                    bucket_object_list.append(keyString)
                    folder = key['Key'].split('/')[0].split('_$')[0]

                    if folder in top_level_folders:
                        top_level_folders[folder] += key['Size']
                    else:
                        top_level_folders[folder] = key['Size']

        for folder, size in top_level_folders.items():
            if ((size / 1024 < 1024) or (size / 1024 / 1024 / 250 == 0)) and (size != 0):
                coalesce_size = 1
            else:
                coalesce_size = size / 1024 / 1024 / 250
        return coalesce_size
    except Exception as e:
        logging.error(f"Fail to define the right number to Spark coalesce using the path 's3://{bucket}/{key_prefix}'.': {str(e)}")


class Logger:
    def __init__(self):
        logging.basicConfig(level=logging.INFO, format='%(asctime)s %(levelname)s %(message)s', datefmt='%y/%m/%d %H:%M:%S')

    def get_message(self, prefix, msg = None):
        message_log = ""
        if msg is None :
            message_log = prefix
        else :
            message_log = f"[{prefix}]: {msg}"            

        return message_log

    def error(self, prefix, msg = None):
        logging.error(self.get_message(prefix, msg))

    def warn(self, prefix, msg = None):
        logging.warn(self.get_message(prefix, msg))

    def info(self, prefix, msg = None):
        logging.info(self.get_message(prefix, msg))