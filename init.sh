#!/bin/bash

imageName=image.jpg
sudo apt-get install -qq jq > /dev/null;

if [ -n "$1" ]
then
    imageName=$1
fi

accountNumber=`aws sts get-caller-identity | jq -r '.Account'`;

echo Buckets und Lambda Funktion werden Überprüft;

if aws s3 ls "s3://sourcebucket-markus-pascal-konstantin" 2>&1 | grep -q 'NoSuchBucket'; 
then
  aws s3 mb "s3://sourcebucket-markus-pascal-konstantin"
  echo Bucket 'sourcebucket-markus-pascal-konstantin' wurde erstellt
fi

if aws s3 ls "s3://destination-markus-pascal-konstantin" 2>&1 | grep -q 'NoSuchBucket'; 
then
  aws s3 mb "s3://destination-markus-pascal-konstantin"
  echo Bucket 'destination-markus-pascal-konstantin' wurde erstellt
fi

if aws lambda get-function --function-name "shrinkFunction-markus-pascal-konstantin" 2>&1 | grep -q 'ResourceNotFoundException'; 
then
  aws lambda create-function \
    --function-name "shrinkFunction-markus-pascal-konstantin" \
    --runtime "nodejs18.x" \
    --role "arn:aws:iam::$accountNumber:role/LabRole" \
    --handler "index.handler" \
    --zip-file "fileb://archive.zip"
    echo "Die Funktion wurde erfolgreich erstellt"
fi

if aws lambda get-policy \
  --function-name "shrinkFunction-markus-pascal-konstantin" \
  --query Policy \
  --output text | grep -q "s3"; 
  then
  echo "Berechtigung ist bereits vorhanden";
else
  aws lambda add-permission \
    --function-name "shrinkFunction-markus-pascal-konstantin" \
    --action lambda:InvokeFunction \
    --statement-id s3 \
    --principal s3.amazonaws.com \
    --source-arn "arn:aws:s3:::sourcebucket-markus-pascal-konstantin" \
    > /dev/null
  echo "Berechtigung wurde hinzugefügt";
fi

if aws s3api get-bucket-notification-configuration \
  --bucket "sourcebucket-markus-pascal-konstantin" \
  --query "LambdaFunctionConfigurations[?LambdaFunctionArn=='arn:aws:lambda:us-east-1:$accountNumber:function:shrinkFunction-markus-pascal-konstantin'].LambdaFunctionArn" \
  --output text | grep -q "arn:aws:lambda:us-east-1:$accountNumber:function:shrinkFunction-markus-pascal-konstantin"; 
  then
  echo "Der Auslöser existiert bereits"
else
  aws s3api put-bucket-notification-configuration \
    --bucket "sourcebucket-markus-pascal-konstantin" \
    --notification-configuration '{
      "LambdaFunctionConfigurations": [
        {
          "Id": "",
          "LambdaFunctionArn": "arn:aws:lambda:us-east-1:$accountNumber:function:shrinkFunction-markus-pascal-konstantin",
          "Events": ["s3:ObjectCreated:*"]
        }
      ]
    }'
  echo "Der Auslöser wurde erfolgreich erstellt";
 fi

if test -f "./$imageName"; 
then
  aws s3 cp "./$imageName" "s3://sourcebucket-markus-pascal-konstantin/$imageName"
  echo "Das Bild wurde erfolgreich hochgeladen";
else
  echo "Die Datei $imageName konnte nicht gefunden werden, bitte beachten Sie, dass Sie den ganzen Namen angeben müssen und das Bild im Home verzeichnis sein muss";
fi