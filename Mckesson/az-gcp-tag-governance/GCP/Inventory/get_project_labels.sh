#!/bin/bash

# Define the output file
OUTPUT_FILE="project_labels_report.csv"

# Write the CSV header
echo "Project ID,Labels" > $OUTPUT_FILE

# List of project IDs
PROJECT_IDS=(
    "adp-kadmindb-dev-a8fd"
    "adp-kadmindb-prod-99fd"
    "adp-kafkaadmin-dev-8825"
    "adp-kafkaadmin-prod-7235"
    "amelia-euwest1-dev-f268"
    "ana-bre-dev-9430"
    "ana-bre-prod-1dac"
    "ana-bredb-nonprod-7918"
    "ana-bredb-prod-6414"
    "ana-faxdb-test-762b"
    "ana-ssrxdb-nonprod-de13"
    "ana-ssrxdb-prod-a002"
    "api-common-prod-5888"
    "api-common-test-04db"
    "api-na-prod-1921"
    "api-na-test-0ac5"
    "api-rtfna-prod-1d81"
    "api-rtfna-test-320f"
    "apptrans-mt-dev-be82"
    "apptrans-mt-sand2-9b11"
    "asm-aa-dev-0c3e"
    "asm-aa-prod-55fa"
    "asm-aa-uat-2cfe"
    "ast-rpa-dev-5762"
    "attp-dscsa-dev-725b"
    "attp-dscsa-prod-0a17"
    "attp-dscsa-test-1abd"
    "auto-services-dev-bb9a"
    "automation-ocr-test-7cef"
    "b2b-analytics-dev-d897"
    "b2b-camp-dev-cdfa"
    "b2b-camp-prod-b3d3"
    "b2b-cc-nonprod-0837"
    "b2b-cims-dev-722f"
    "b2b-cims-prod-1c49"
    "b2b-cms-prod-88c6"
    "b2b-g4g-prod-6e58"
    "b2b-iw-prod-6995"
    "b2b-mastersrx-nonprod-2885"
    "b2b-mckcshared-dev-84fe"
    "b2b-mckcshared-prod-aaa6"
    "b2b-mckdirect-dev-4210"
    "b2b-mmsprcg-prod-83c5"
    "b2b-mpb-dev-1efb"
    "b2b-mpb-prod-a9b8"
    "b2b-ordering-nonprod-f9e9"
    "b2b-ordering-prod-fbe2"
    "b2b-ordersvcs-dev-5e99"
    "b2b-portal-nonprod-35d8"
    "b2b-portal-prod-13eb"
    "b2b-speciality-dev-013e"
    "b2b-specialty-nonprod-6d14"
    "b2b-specialty-prod-dc37"
    "b2b-symphony-prod-0b6d"
    "b2c-ecommbackup-dev-c727"
    "b2c-ecommbackup-prod-7857"
    "b2c-ecommshared-dev-c7c1"
    "b2c-ecommshared-prod-4d03"
    "b2c-ecommshared-uat-aea5"
    "b2c-unisante-dev-65db"
    "bcs-dr-test-18bb"
    "bcs-draas-nonprod-5f67"
    "bcs-draas-prod-3d7a"
    "cmm-analytics-prod-4ffb"
    "cmm-ocr-dev-661d"
    "cmm-ocr-prod-a659"
    "cmm-rxbc-dev-c2b5"
    "cmm-rxpc-dev-1106"
    "conc-uswest1-usprod-4a37"
    "consv-vacmop-dev-3faa"
    "consv-vacmop-prod-252d"
    "consv-vacmope-prod-f52b"
    "copay-rh-med-images-prod-bbc3"
    "copay-storage-dev-9304"
    "copay-storage-prod-3c65"
    "copay-storage-test-1d7e"
    "cops-admin-nonprod-18a5"
    "cops-appsmon-nonprod-c86c"
    "cops-appsmon-prod-84d0"
    "cops-cloudmonus-nonprod-563b"
    "cops-cloudmonus-prod-b71c"
    "cops-osmon-nonprod-b6c0"
    "cops-osmon-prod-8562"
    "cops-osplatform-dev-3151"
    "cops-osplatform-prod-d70e"
    "cops-servicenow-nonprod-67ba"
    "cops-servicenow-prod-64f8"
    "cops-zabbix-nonprod-c245"
    "cops-zabbix-prod-eab6"
    "core-admin-nonprod-5694"
    "core-admin-prod-6598"
    # Add more project IDs here
)

# Loop through each project ID
for PROJECT_ID in "${PROJECT_IDS[@]}"; do
    echo "Fetching labels for project: $PROJECT_ID"

    # Fetch labels using gcloud
    LABELS=$(gcloud projects describe $PROJECT_ID --format="value(labels)" 2>/dev/null)

    # Handle projects with no labels
    if [ -z "$LABELS" ]; then
        LABELS="No Labels"
    fi

    # Write to the CSV file
    echo "$PROJECT_ID,\"$LABELS\"" >> $OUTPUT_FILE
done

echo "Labels fetched successfully. Report saved to $OUTPUT_FILE."