import boto3
import base64
from botocore.exceptions import ClientError
import os
import json


# os.environ['region'] = 'ap-southeast-2'
# os.environ['SECRET_ARN'] = 'arn:aws:secretsmanager:ap-southeast-2:566105134773:secret:lambda_spotifySecret-EnkGVB'
class Secret:
    def __init__(self):
        self.client_id = None
        self.client_secret = None
        self.github_access_token = None
        self.get_secret()
        
    
    def get_secret(self):
        region_name = os.environ.get("region")

        # Create a Secrets Manager client
        # session = boto3.session.Session(profile_name  = 'vivek-personal-iam-user')
        session = boto3.session.Session()
        client = session.client(
            service_name='secretsmanager',
            region_name=region_name
        )

        # In this sample we only handle the specific exceptions for the 'GetSecretValue' API.
        # See https://docs.aws.amazon.com/secretsmanager/latest/apireference/API_GetSecretValue.html
        # We rethrow the exception by default.

        try:
            get_secret_value_response = client.get_secret_value(
                SecretId= os.environ.get('SECRET_ARN')
                )

        except ClientError as e:
            if e.response['Error']['Code'] == 'DecryptionFailureException':
                # Secrets Manager can't decrypt the protected secret text using the provided KMS key.
                # Deal with the exception here, and/or rethrow at your discretion.
                raise e
            elif e.response['Error']['Code'] == 'InternalServiceErrorException':
                # An error occurred on the server side.
                # Deal with the exception here, and/or rethrow at your discretion.
                raise e
            elif e.response['Error']['Code'] == 'InvalidParameterException':
                # You provided an invalid value for a parameter.
                # Deal with the exception here, and/or rethrow at your discretion.
                raise e
            elif e.response['Error']['Code'] == 'InvalidRequestException':
                # You provided a parameter value that is not valid for the current state of the resource.
                # Deal with the exception here, and/or rethrow at your discretion.
                raise e
            elif e.response['Error']['Code'] == 'ResourceNotFoundException':
                # We can't find the resource that you asked for.
                # Deal with the exception here, and/or rethrow at your discretion.
                raise e
        else:
            # Decrypts secret using the associated KMS key.
            # Depending on whether the secret is a string or binary, one of these fields will be populated.
            if 'SecretString' in get_secret_value_response:
                secret = json.loads(get_secret_value_response['SecretString'])
                self.client_id, self.client_secret, self.github_access_token = secret['client_id'],secret['client_secret'], secret['github_access_token']
            else:
                decoded_binary_secret = json.loads(base64.b64decode(get_secret_value_response['SecretBinary']))



if __name__ == "__main__":
    secret = Secret()
    print(secret.client_id)