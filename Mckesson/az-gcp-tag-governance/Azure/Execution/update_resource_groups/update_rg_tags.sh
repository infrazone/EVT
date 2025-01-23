#!/usr/bin/env bash
#
# FILE: update_rg_tags.sh
#
# PURPOSE:
#   Applies 8 required tags to Azure Resource Groups:
#       1. core-snow-as-number
#       2. core-snow-ba-number
#       3. snow-application-name
#       4. snow-application-owner
#       5. snow-business-criticality
#       6. snow-data-classification
#       7. snow-environment
#       8. snow-service-owner
#
#   Uses --is-incremental to preserve existing tags. Supports dry-run, verbose logging, and retry logic.
#
# USAGE:
#   ./update_rg_tags.sh <path-to-csv> [--dry-run] [--verbose] [--log-file <path>] [--strict-check]
#
# DESCRIPTION:
#   - Reads a CSV file containing resource group information.
#   - The CSV must have 10 columns in the following order:
#       1) subscriptionId
#       2) resourceGroupName
#       3) coreSnowAsNumber
#       4) coreSnowBaNumber
#       5) snowApplicationName
#       6) snowApplicationOwner
#       7) snowBusinessCriticality
#       8) snowDataClassification
#       9) snowEnvironment
#      10) snowServiceOwner
#   - Applies the tags if values are present, preserving existing tags with --is-incremental.
#   - Summarizes how many resource groups were updated, skipped, or failed.
#
# CSV FORMAT:
#   Example row (skipping the CSV header line):
#       12345678-1234-1234-1234-123456789abc, MyResourceGroup, AS123, BA456, MyApp, appOwner@contoso.com, High, Confidential, Prod, serviceOwner@contoso.com
#
# PREREQUISITES:
#   - Azure CLI installed (az command).
#   - Logged into Azure via 'az login'.
#   - Bash shell (macOS/Linux). On Windows, run within Git Bash or WSL.
#
# NOTES:
#   - For advanced CSV parsing (quotes, commas in fields), use a dedicated parser/tool or a Python script.
#   - If 'az resource tag' becomes unreliable, consider using 'az group update' (but that may not preserve existing tags incrementally).
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
      # Assume the first unknown argument is the CSV file
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

log_message "Starting Resource Group tag update script."
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
#   PROCESS CSV RECORDS
# ------------------------------
# Summary counters
count_rg_updated=0
count_rg_skipped=0
count_rg_failed=0

# Skip the CSV header with tail -n +2
tail -n +2 "$CSV_FILE" | while IFS=',' read -r \
  subscriptionId \
  resourceGroupName \
  coreSnowAsNumber \
  coreSnowBaNumber \
  snowApplicationName \
  snowApplicationOwner \
  snowBusinessCriticality \
  snowDataClassification \
  snowEnvironment \
  snowServiceOwner
do
  # Ensure we have at least 10 columns
  if [[ -z "$snowServiceOwner" ]]; then
    verbose_log "Skipping row: insufficient columns or empty fields."
    ((count_rg_skipped++))
    continue
  fi

  # Trim whitespace
  subscriptionId=$(echo "$subscriptionId" | xargs)
  resourceGroupName=$(echo "$resourceGroupName" | xargs)
  coreSnowAsNumber=$(echo "$coreSnowAsNumber" | xargs)
  coreSnowBaNumber=$(echo "$coreSnowBaNumber" | xargs)
  snowApplicationName=$(echo "$snowApplicationName" | xargs)
  snowApplicationOwner=$(echo "$snowApplicationOwner" | xargs)
  snowBusinessCriticality=$(echo "$snowBusinessCriticality" | xargs)
  snowDataClassification=$(echo "$snowDataClassification" | xargs)
  snowEnvironment=$(echo "$snowEnvironment" | xargs)
  snowServiceOwner=$(echo "$snowServiceOwner" | xargs)

  # Basic check for subscription ID format
  if ! [[ "$subscriptionId" =~ ^[0-9a-fA-F-]{36}$ ]]; then
    verbose_log "Skipping invalid subscription ID: $subscriptionId"
    ((count_rg_skipped++))
    continue
  fi

  # Resource group name must not be empty
  if [[ -z "$resourceGroupName" ]]; then
    verbose_log "Skipping row because resourceGroupName is empty."
    ((count_rg_skipped++))
    continue
  fi

  # Strict subscription validation (optional)
  if [[ "$STRICT_SUBSCRIPTION_CHECK" == true ]]; then
    if ! az account show --subscription "$subscriptionId" >/dev/null 2>&1; then
      log_message "Warning: No access to subscription $subscriptionId or it does not exist. Skipping..."
      ((count_rg_skipped++))
      continue
    fi
  fi

  # Build a list of RG tags if they're non-empty
  TAGS_RG=()
  [[ -n "$coreSnowAsNumber" ]]        && TAGS_RG+=( "core-snow-as-number=$coreSnowAsNumber" )
  [[ -n "$coreSnowBaNumber" ]]        && TAGS_RG+=( "core-snow-ba-number=$coreSnowBaNumber" )
  [[ -n "$snowApplicationName" ]]     && TAGS_RG+=( "snow-application-name=$snowApplicationName" )
  [[ -n "$snowApplicationOwner" ]]    && TAGS_RG+=( "snow-application-owner=$snowApplicationOwner" )
  [[ -n "$snowBusinessCriticality" ]] && TAGS_RG+=( "snow-business-criticality=$snowBusinessCriticality" )
  [[ -n "$snowDataClassification" ]]  && TAGS_RG+=( "snow-data-classification=$snowDataClassification" )
  [[ -n "$snowEnvironment" ]]         && TAGS_RG+=( "snow-environment=$snowEnvironment" )
  [[ -n "$snowServiceOwner" ]]        && TAGS_RG+=( "snow-service-owner=$snowServiceOwner" )

  if [[ ${#TAGS_RG[@]} -eq 0 ]]; then
    verbose_log "No tags to update for RG '$resourceGroupName' in subscription $subscriptionId."
    ((count_rg_skipped++))
    continue
  fi

  local_rg_id="/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName"

  if [[ "$DRY_RUN" == true ]]; then
    log_message "[DRY-RUN] Resource Group: $local_rg_id"
    log_message "[DRY-RUN] Would apply RG tags: ${TAGS_RG[*]}"
    ((count_rg_skipped++))
  else
    log_message "Updating RESOURCE GROUP '$local_rg_id' with tags: ${TAGS_RG[*]}"
    # Apply the tags incrementally
    if retry_az_command az resource tag \
        --ids "$local_rg_id" \
        --tags "${TAGS_RG[@]}" \
        --is-incremental \
        --only-show-errors; then
      log_message "Resource Group update complete for $local_rg_id."
      ((count_rg_updated++))
    else
      log_message "Error applying tags to resource group $local_rg_id. Skipping..."
      ((count_rg_failed++))
    fi
  fi

done

# ------------------------------
#    PRINT SUMMARY
# ------------------------------
log_message ""
log_message "==============================================="
log_message " Resource Group Tag Update Script Finished"
log_message "   Updated:  $count_rg_updated"
log_message "   Skipped:  $count_rg_skipped"
log_message "   Failed:   $count_rg_failed"
log_message "==============================================="
