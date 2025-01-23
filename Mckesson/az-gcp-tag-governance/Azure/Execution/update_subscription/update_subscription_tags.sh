#!/usr/bin/env bash
#
# FILE: update_subscription_tags.sh
#
# PURPOSE:
#   Update 7 required tags on Azure subscriptions using data from a CSV file:
#     1. core-subscription-owner
#     2. core-subscription-super-owner
#     3. core-cost-center
#     4. core-financial-bu
#     5. core-financial-sub-bu
#     6. core-namespace-owner
#     7. core-namespace-super-owner
#
#   Uses --is-incremental to preserve existing tags and appends the required ones
#   if values are provided in the CSV.
#
# USAGE:
#   ./update_subscription_tags.sh <path-to-csv> [--dry-run] [--verbose] [--log-file <path>] [--strict-check]
#
# DESCRIPTION:
#   1. Reads a CSV file containing subscription information.
#   2. Builds a tag list from the CSV fields (only if they have values).
#   3. Applies tags incrementally with Azure CLI, preserving existing tags.
#   4. Supports dry-run mode to preview changes, verbose logging, and optional log file output.
#   5. Summarizes the results (updated, skipped, failed) at the end.
#
# PREREQUISITES:
#   - Azure CLI installed (az command).
#   - Logged into Azure (az login).
#   - Bash shell (macOS/Linux). For Windows, run within Git Bash or WSL.
#
# CSV FORMAT:
#   The script expects 9 columns in the following order:
#     subscriptionId, subscriptionName,
#     coreSubscriptionOwner, coreSubscriptionSuperOwner,
#     coreCostCenter, coreFinancialBU, coreFinancialSubBU,
#     coreNamespaceOwner, coreNamespaceSuperOwner
#
#   Example CSV row:
#     12345678-1234-1234-1234-123456789abc, MySubscription, alice@contoso.com, bob@contoso.com, CC123, Finance, SubFinance, nspaceAlice, nspaceBob
#
#   The script automatically skips the CSV header (line 1).
#
# NOTES:
#   - For more robust CSV parsing (handling quotes, commas in fields), use a dedicated parser/tool.
#   - Consider using "az subscription update" if "az resource tag" becomes unreliable.
#

set -euo pipefail

# ------------------------------
#        PARSE ARGUMENTS
# ------------------------------
CSV_FILE=""
DRY_RUN=false
VERBOSE=false
LOG_FILE=""

# How many times to retry on transient errors
MAX_RETRIES=3
RETRY_DELAY=5  # seconds

# If you want to strictly validate access to each subscription, set to true
STRICT_SUBSCRIPTION_CHECK=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --verbose)
      VERBOSE=true
      shift
      ;;
    --log-file)
      LOG_FILE="$2"
      shift 2
      ;;
    --strict-check)
      STRICT_SUBSCRIPTION_CHECK=true
      shift
      ;;
    *)
      # Assume first unknown argument is the CSV file
      if [[ -z "$CSV_FILE" ]]; then
        CSV_FILE="$1"
      else
        echo "Unknown argument: $1"
        exit 1
      fi
      shift
      ;;
  esac
done

# ------------------------------
#    FUNCTION DEFINITIONS
# ------------------------------

# Print to console and optionally to log file if specified
log_message() {
  local MSG="$1"
  echo -e "$MSG"
  if [[ -n "$LOG_FILE" ]]; then
    echo -e "$MSG" >> "$LOG_FILE"
  fi
}

# Print verbose messages if --verbose is enabled
verbose_log() {
  if [[ "$VERBOSE" == true ]]; then
    log_message "$1"
  fi
}

# Retry wrapper for Azure CLI commands
retry_az_command() {
  local COMMAND=("$@")
  local attempt=1
  local exitCode=0

  while [[ $attempt -le $MAX_RETRIES ]]; do
    "${COMMAND[@]}" && return 0 || exitCode=$?
    log_message "Command failed (attempt $attempt/$MAX_RETRIES). Retrying in $RETRY_DELAY seconds..."
    sleep "$RETRY_DELAY"
    ((attempt++))
  done

  return $exitCode
}

# ------------------------------
#   VALIDATE REQUIRED INPUT
# ------------------------------
if [[ -z "$CSV_FILE" ]]; then
  echo "Error: No CSV file specified."
  echo "Usage: $0 <path-to-csv> [--dry-run] [--verbose] [--log-file <path>] [--strict-check]"
  exit 1
fi

if [[ ! -f "$CSV_FILE" ]]; then
  echo "Error: CSV file '$CSV_FILE' not found."
  exit 1
fi

# Clear or create the log file if specified
if [[ -n "$LOG_FILE" ]]; then
  : > "$LOG_FILE"  # Truncate existing log file
fi

log_message "Starting subscription tag update script."
log_message "CSV file: $CSV_FILE"
if [[ "$DRY_RUN" == true ]]; then
  log_message "Running in DRY-RUN mode: No changes will be applied."
fi

# ------------------------------
#  CHECK AZURE CLI & LOGIN
# ------------------------------
if ! command -v az >/dev/null 2>&1; then
  log_message "Error: Azure CLI (az) is not installed or not found in PATH."
  exit 1
fi

# Check if user is logged in
if ! az account show >/dev/null 2>&1; then
  log_message "Error: Not logged in to Azure. Please run 'az login' first."
  exit 1
fi

# ------------------------------
#    PROCESS CSV RECORDS
# ------------------------------
# Summary counters
count_updated=0
count_skipped=0
count_failed=0

# Skip the CSV header with tail -n +2
tail -n +2 "$CSV_FILE" | while IFS=',' read -r subscriptionId subscriptionName \
                                      coreSubscriptionOwner coreSubscriptionSuperOwner \
                                      coreCostCenter coreFinancialBU coreFinancialSubBU \
                                      coreNamespaceOwner coreNamespaceSuperOwner; do

  # Ensure we have at least 9 columns
  if [[ -z "$coreNamespaceSuperOwner" ]]; then
    verbose_log "Skipping row: insufficient columns or empty fields: \
$subscriptionId, $subscriptionName, $coreSubscriptionOwner, $coreSubscriptionSuperOwner, \
$coreCostCenter, $coreFinancialBU, $coreFinancialSubBU, $coreNamespaceOwner, $coreNamespaceSuperOwner"
    ((count_skipped++))
    continue
  fi

  # Trim whitespace
  subscriptionId=$(echo "$subscriptionId" | xargs)
  subscriptionName=$(echo "$subscriptionName" | xargs)
  coreSubscriptionOwner=$(echo "$coreSubscriptionOwner" | xargs)
  coreSubscriptionSuperOwner=$(echo "$coreSubscriptionSuperOwner" | xargs)
  coreCostCenter=$(echo "$coreCostCenter" | xargs)
  coreFinancialBU=$(echo "$coreFinancialBU" | xargs)
  coreFinancialSubBU=$(echo "$coreFinancialSubBU" | xargs)
  coreNamespaceOwner=$(echo "$coreNamespaceOwner" | xargs)
  coreNamespaceSuperOwner=$(echo "$coreNamespaceSuperOwner" | xargs)

  # Basic check for a valid subscriptionId format (UUID).
  if ! [[ "$subscriptionId" =~ ^[0-9a-fA-F-]{36}$ ]]; then
    verbose_log "Skipping invalid subscription ID format: $subscriptionId"
    ((count_skipped++))
    continue
  fi

  # Strict subscription validation (optional)
  if [[ "$STRICT_SUBSCRIPTION_CHECK" == true ]]; then
    if ! az account show --subscription "$subscriptionId" >/dev/null 2>&1; then
      log_message "Warning: You do not have access to subscription $subscriptionId or it does not exist. Skipping..."
      ((count_skipped++))
      continue
    fi
  fi

  # Build a list of tags to apply if they have values
  TAGS=()
  [[ -n "$coreSubscriptionOwner" ]]       && TAGS+=( "core-subscription-owner=$coreSubscriptionOwner" )
  [[ -n "$coreSubscriptionSuperOwner" ]]  && TAGS+=( "core-subscription-super-owner=$coreSubscriptionSuperOwner" )
  [[ -n "$coreCostCenter" ]]              && TAGS+=( "core-cost-center=$coreCostCenter" )
  [[ -n "$coreFinancialBU" ]]             && TAGS+=( "core-financial-bu=$coreFinancialBU" )
  [[ -n "$coreFinancialSubBU" ]]          && TAGS+=( "core-financial-sub-bu=$coreFinancialSubBU" )
  [[ -n "$coreNamespaceOwner" ]]          && TAGS+=( "core-namespace-owner=$coreNamespaceOwner" )
  [[ -n "$coreNamespaceSuperOwner" ]]     && TAGS+=( "core-namespace-super-owner=$coreNamespaceSuperOwner" )

  if [[ ${#TAGS[@]} -eq 0 ]]; then
    verbose_log "No tags to update for subscription $subscriptionId ($subscriptionName)."
    ((count_skipped++))
    continue
  fi

  if [[ "$DRY_RUN" == true ]]; then
    log_message "[DRY-RUN] Subscription: $subscriptionId ($subscriptionName)"
    log_message "[DRY-RUN] Would apply tags: ${TAGS[*]}"
    ((count_skipped++))
    continue
  fi

  log_message "Updating subscription '$subscriptionId' ($subscriptionName) with tags: ${TAGS[*]}"

  # Apply the tags incrementally using --is-incremental and a retry wrapper
  if retry_az_command az resource tag \
      --ids "/subscriptions/$subscriptionId" \
      --tags "${TAGS[@]}" \
      --is-incremental \
      --only-show-errors; then
    log_message "Update complete for subscription $subscriptionId."
    ((count_updated++))
  else
    log_message "Error applying tags to subscription $subscriptionId. Skipping..."
    ((count_failed++))
  fi
done

log_message ""
log_message "==============================================="
log_message " Tag update script finished."
log_message " Subscriptions updated:  $count_updated"
log_message " Subscriptions skipped:  $count_skipped"
log_message " Subscriptions failed:   $count_failed"
log_message "==============================================="
