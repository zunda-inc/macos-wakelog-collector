import { S3Client, PutObjectCommand } from "@aws-sdk/client-s3";
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";

export const handler = async (event) => {
  console.log('Event: ', event);
  const s3Client = new S3Client({ region: process.env.aws_region });
  const command = new PutObjectCommand({
    Bucket: process.env.aws_s3_upload_bucket,
    Key: event.pathParameters.proxy,
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
    }
  } catch (err) {
    return {
      statusCode: 500,
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        error: err,
      }),
    }
  }
}