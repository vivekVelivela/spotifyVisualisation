import boto3
import os
from datetime import datetime


def handler(event, context):
    

    return {
                "statusCode": 200,
                "headers": {
                    "Access-Control-Allow-Origin":"*",
                    "Content-Type": "application/json"
                },
                "body": "Success"
            }