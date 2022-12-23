const awsSdk = require("aws-sdk");
const util = require("util");
const sharp = require("sharp");
const s3 = new awsSdk.S3();

exports.handler = async (event) => {
  const sourceBucket = event.Records[0].s3.bucket.name;
  const sourceKey = decodeURIComponent(
    event.Records[0].s3.object.key.replace(/\+/g, " ")
  );
  const destinationBucket = "destinationbucket-markus-pascal-konstantin";
  const destinationKey = "resized-" + sourceKey;

  const typeMatch = sourceKey.match(/\.([^.]*)$/);
  if (!typeMatch) {
    console.log("Could not determine the image type.");
    return;
  }

  const imageType = typeMatch[1].toLowerCase();
  if (imageType != "jpg" && imageType != "png") {
    console.log(`Unsupported image type: ${imageType}`);
    return;
  }

  try {
    const params = {
      Bucket: sourceBucket,
      Key: sourceKey,
    };
    var origimage = await s3.getObject(params).promise();
  } catch (error) {
    console.log(error);
    return;
  }

  const width = 200;

  try {
    var buffer = await sharp(origimage.Body).resize(width).toBuffer();
  } catch (error) {
    console.log(error);
    return;
  }

  try {
    const destparams = {
      Bucket: destinationBucket,
      Key: destinationKey,
      Body: buffer,
      ContentType: "image",
    };

    const putResult = await s3.putObject(destparams).promise();
  } catch (error) {
    console.log(error);
    return;
  }

  console.log(
    "Successfully resized " +
      sourceBucket +
      "/" +
      sourceKey +
      " and uploaded to " +
      destinationBucket +
      "/" +
      destinationKey
  );
};
