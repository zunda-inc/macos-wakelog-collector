import { S3Client, PutObjectCommand } from "@aws-sdk/client-s3";
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";

export const handler = async (event) => {
  const authorizationHeader = event.headers.Authorization;
  let matches;
  let token;
  if (authorizationHeader) {
    matches = authorizationHeader.match(/bearer (\w+)$/i);
  }
  if (matches){
    token = matches[1];
  }
  
  if (token != process.env.client_token) {
    return {
      statusCode: 400,
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        error: 'No valid client token in the request',
      }),
    };
  }
  const s3Client = new S3Client({ region: process.env.aws_region });
  const command = new PutObjectCommand({
    Bucket: process.env.aws_s3_upload_bucket,
    Key: event.pathParameters.proxy,
    Metadata: {
      'device-serial': event.queryStringParameters.deviceSerial,
      'user': event.queryStringParameters.user,
      'log-type': event.queryStringParameters.logType,
    }
  });

  try {
    const url = await getSignedUrl(s3Client, command, { expiresIn: 3600 });
    return {
      statusCode: 200,
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        signedUrl: url,
      }),
    };
  } catch (err) {
    return {
      statusCode: 500,
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        error: err,
      }),
    };
  }
};
