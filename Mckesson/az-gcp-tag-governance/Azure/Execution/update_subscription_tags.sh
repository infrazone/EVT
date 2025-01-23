#!/usr/bin/env bash
#
# USAGE:
#   ./update_subscription_tags.sh <path-to-csv>

set -euo pipefail

CSV_FILE="$1"

if [[ ! -f "$CSV_FILE" ]]; then
  echo "Error: CSV file '$CSV_FILE' not found."
  exit 1
fi

# Skip the CSV header with tail -n +2
tail -n +2 "$CSV_FILE" | while IFS=',' read -r subscriptionId subscriptionName \
                                      coreSubscriptionOwner coreSubscriptionSuperOwner \
                                      coreCostCenter coreFinancialBU coreFinancialSubBU \
                                      coreNamespaceOwner coreNamespaceSuperOwner; do
  
  # Trim whitespace (optional but recommended)
  subscriptionId=$(echo "$subscriptionId" | xargs)
  
  # Build a list of tags to apply. Only add tags if they have values.
  TAGS=""

  if [[ -n "$coreSubscriptionOwner" ]]; then
    TAGS+=" core-subscription-owner=$coreSubscriptionOwner"
  fi

  if [[ -n "$coreSubscriptionSuperOwner" ]]; then
    TAGS+=" core-subscription-super-owner=$coreSubscriptionSuperOwner"
  fi

  if [[ -n "$coreCostCenter" ]]; then
    TAGS+=" core-cost-center=$coreCostCenter"
  fi

  if [[ -n "$coreFinancialBU" ]]; then
    TAGS+=" core-financial-bu=$coreFinancialBU"
  fi

  if [[ -n "$coreFinancialSubBU" ]]; then
    TAGS+=" core-financial-sub-bu=$coreFinancialSubBU"
  fi

  if [[ -n "$coreNamespaceOwner" ]]; then
    TAGS+=" core-namespace-owner=$coreNamespaceOwner"
  fi

  if [[ -n "$coreNamespaceSuperOwner" ]]; then
    TAGS+=" core-namespace-super-owner=$coreNamespaceSuperOwner"
  fi

  # If no tags exist, skip to the next line
  if [[ -z "$TAGS" ]]; then
    echo "No tags to update for subscription $subscriptionId ($subscriptionName)."
    continue
  fi

  echo "Updating subscription '$subscriptionId' with tags: $TAGS"
  
  # Apply the tags incrementally using --is-incremental
  # This ensures existing tags remain intact.
  az resource tag \
    --ids "/subscriptions/$subscriptionId" \
    --tags $TAGS \
    --is-incremental
  
  echo "Update complete for subscription $subscriptionId."
done

echo "Tag update script finished."