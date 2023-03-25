import boto3
import json


dynamodb_resource = boto3.resource("dynamodb")
table = dynamodb_resource.Table("lotion-30122680")

def lambda_handler(event, context):
    note = json.loads(event["body"])
    try:
        table.put_item(Item=note)
        return {
            "statusCode": 201,
            "body": "success"
        }
    except Exception as exp:
        print(f"exception: {exp}")
        return{
            "statusCode": 500,
            "body": json.dumps({
                "message": str(exp)
            })
        }