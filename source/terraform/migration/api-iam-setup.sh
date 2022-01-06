
#!/bin/bash

set -e

if [[ -z "${GOOGLE_CLOUD_PROJECT}" ]]; then
  echo "Please make sure GOOGLE_CLOUD_PROJECT is defined before running this script."
  exit 1
fi

echo "Enabling the Cloud Resource Manager API for project $GOOGLE_CLOUD_PROJECT..."
gcloud services enable cloudresourcemanager.googleapis.com --project=$GOOGLE_CLOUD_PROJECT

echo "Enabling the Compute Engine API for project $GOOGLE_CLOUD_PROJECT..."
gcloud services enable compute.googleapis.com --project=$GOOGLE_CLOUD_PROJECT

echo "Enabling the Identity and Access Management (IAM) API for project $GOOGLE_CLOUD_PROJECT..."
gcloud services enable iam.googleapis.com --project=$GOOGLE_CLOUD_PROJECT

echo "Enabling the Cloud OS Login API for project $GOOGLE_CLOUD_PROJECT..."
gcloud services enable oslogin.googleapis.com --project=$GOOGLE_CLOUD_PROJECT

echo "Enabling the Service Networking API for project $GOOGLE_CLOUD_PROJECT..."
gcloud services enable servicenetworking.googleapis.com --project=$GOOGLE_CLOUD_PROJECT

echo "Enabling the Cloud SQL Admin API for project $GOOGLE_CLOUD_PROJECT..."
gcloud services enable sqladmin.googleapis.com --project=$GOOGLE_CLOUD_PROJECT


echo "Enabling the Cloud Build API for project $GOOGLE_CLOUD_PROJECT..."
gcloud services enable cloudbuild.googleapis.com --project=$GOOGLE_CLOUD_PROJECT

echo "Enabling the Container Registry API for project $GOOGLE_CLOUD_PROJECT..."
gcloud services enable containerregistry.googleapis.com --project=$GOOGLE_CLOUD_PROJECT

echo "Enabling the Cloud Run API for project $GOOGLE_CLOUD_PROJECT..."
gcloud services enable run.googleapis.com --project=$GOOGLE_CLOUD_PROJECT

echo "Enabling the API Gateway for project $GOOGLE_CLOUD_PROJECT..."
gcloud services enable apigateway.googleapis.com --project=$GOOGLE_CLOUD_PROJECT

echo "Enabling the Service Management API for project $GOOGLE_CLOUD_PROJECT..."
gcloud services enable servicemanagement.googleapis.com --project=$GOOGLE_CLOUD_PROJECT

echo "Enabling the Service Control for project $GOOGLE_CLOUD_PROJECT..."
gcloud services enable servicecontrol.googleapis.com --project=$GOOGLE_CLOUD_PROJECT

echo "Enabling the Cloud Sourse Repositories for project $GOOGLE_CLOUD_PROJECT..."
gcloud services enable sourcerepo.googleapis.com --project=$GOOGLE_CLOUD_PROJECT

# Uncomment if you are deploying a Cloud SQL database
#echo "Enabling the SQL Admin API for project $GOOGLE_CLOUD_PROJECT..."
#gcloud services enable sqladmin.googleapis.com --project=$GOOGLE_CLOUD_PROJECT

echo "Discovering Project ID for project $GOOGLE_CLOUD_PROJECT..."
PROJECT_NUM=$(gcloud projects describe $GOOGLE_CLOUD_PROJECT --format='value(projectNumber)')

echo "Got project number: ${PROJECT_NUM}"

echo "Applying IAM Policy Binding..."
gcloud iam service-accounts add-iam-policy-binding \
  ${PROJECT_NUM}-compute@developer.gserviceaccount.com \
  --member=serviceAccount:${PROJECT_NUM}@cloudbuild.gserviceaccount.com \
  --role=roles/iam.serviceAccountUser \
  --project=${GOOGLE_CLOUD_PROJECT}