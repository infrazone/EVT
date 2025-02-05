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
#   ./update_rg_tags.sh <path-to-csv> [--dry-run] [--verbose] [--log-file <path>] [--strict-check] [--help]
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

# ----------------------------------
# Usage / Help
# ----------------------------------
usage() {
  cat << EOF
Usage: $0 <path-to-csv> [OPTIONS]

Applies eight required tags to Azure Resource Groups, preserving existing tags.

OPTIONS:
  --dry-run         Show which tags would be applied without making changes
  --verbose         Enable verbose logging
  --log-file <path> Write logs to a specified file
  --strict-check    Validate access to subscription before tagging
  --help            Show this help text and exit

EXAMPLE:
  $0 myFile.csv --verbose --log-file tagging.log

The CSV file must have 10 columns:
1) subscriptionId
2) resourceGroupName
3) coreSnowAsNumber
4) coreSnowBaNumber
5) snowApplicationName
6) snowApplicationOwner
7) snowBusinessCriticality
8) snowDataClassification
9) snowEnvironment
10) snowServiceOwner
EOF
}

# ----------------------------------
# Parse Arguments
# ----------------------------------
CSV_FILE=""
DRY_RUN=false
VERBOSE=false
LOG_FILE=""
STRICT_SUBSCRIPTION_CHECK=false

# Retry parameters
MAX_RETRIES=3
RETRY_DELAY=5  # seconds

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
    --help)
      usage
      exit 0
      ;;
    *)
      # Assume the first unknown argument is the CSV file
      if [[ -z "$CSV_FILE" ]]; then
        CSV_FILE="$1"
      else
        echo "Unknown argument: $1"
        usage
        exit 1
      fi
      shift
      ;;
  esac
done

# ----------------------------------
# Logging Functions
# ----------------------------------
log_message() {
  local TIMESTAMP
  TIMESTAMP="$(date +'%Y-%m-%d %H:%M:%S')"
  local MSG="[$TIMESTAMP] $1"
  echo -e "$MSG"
  if [[ -n "$LOG_FILE" ]]; then
    echo -e "$MSG" >> "$LOG_FILE"
  fi
}

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
    if "${COMMAND[@]}"; then
      return 0
    else
      exitCode=$?
      log_message "Command failed (attempt $attempt/$MAX_RETRIES). Retrying in $RETRY_DELAY seconds..."
      sleep "$RETRY_DELAY"
      ((attempt++))
    fi
  done

  return $exitCode
}

# ----------------------------------
# Validate Required Input
# ----------------------------------
if [[ -z "$CSV_FILE" ]]; then
  echo "Error: No CSV file specified."
  usage
  exit 1
fi

if [[ ! -f "$CSV_FILE" ]]; then
  echo "Error: CSV file '$CSV_FILE' not found."
  exit 1
fi

# If a log file is specified, clear or create it
if [[ -n "$LOG_FILE" ]]; then
  : > "$LOG_FILE"  # Truncate existing file
fi

log_message "Starting Resource Group tag update script."
log_message "CSV file: $CSV_FILE"
if [[ "$DRY_RUN" == true ]]; then
  log_message "Running in DRY-RUN mode: No changes will be applied."
fi

# ----------------------------------
# Check Azure CLI & Login
# ----------------------------------
if ! command -v az &>/dev/null; then
  log_message "Error: Azure CLI (az) is not installed or not found in PATH."
  exit 1
fi

if ! az account show &>/dev/null; then
  log_message "Error: Not logged in to Azure. Please run 'az login' first."
  exit 1
fi

# ----------------------------------
# Process CSV Records
# ----------------------------------
count_rg_updated=0
count_rg_skipped=0
count_rg_failed=0

# Skip the CSV header row, then read each line
tail -n +2 "$CSV_FILE" | while read -r line; do

  # Split the row by commas into an array
  IFS=',' read -ra fields <<< "$line"

  # Check we have exactly 10 fields
  if [[ ${#fields[@]} -ne 10 ]]; then
    verbose_log "Skipping row: incorrect number of columns (${#fields[@]})."
    ((count_rg_skipped++))
    continue
  fi

  # Assign them to variables (in the defined order)
  subscriptionId="${fields[0]}"
  resourceGroupName="${fields[1]}"
  coreSnowAsNumber="${fields[2]}"
  coreSnowBaNumber="${fields[3]}"
  snowApplicationName="${fields[4]}"
  snowApplicationOwner="${fields[5]}"
  snowBusinessCriticality="${fields[6]}"
  snowDataClassification="${fields[7]}"
  snowEnvironment="${fields[8]}"
  snowServiceOwner="${fields[9]}"

  # Trim whitespace around each variable
  subscriptionId="$(echo "$subscriptionId" | xargs)"
  resourceGroupName="$(echo "$resourceGroupName" | xargs)"
  coreSnowAsNumber="$(echo "$coreSnowAsNumber" | xargs)"
  coreSnowBaNumber="$(echo "$coreSnowBaNumber" | xargs)"
  snowApplicationName="$(echo "$snowApplicationName" | xargs)"
  snowApplicationOwner="$(echo "$snowApplicationOwner" | xargs)"
  snowBusinessCriticality="$(echo "$snowBusinessCriticality" | xargs)"
  snowDataClassification="$(echo "$snowDataClassification" | xargs)"
  snowEnvironment="$(echo "$snowEnvironment" | xargs)"
  snowServiceOwner="$(echo "$snowServiceOwner" | xargs)"

  # Basic checks
  if ! [[ "$subscriptionId" =~ ^[0-9a-fA-F-]{36}$ ]]; then
    verbose_log "Skipping invalid subscription ID: $subscriptionId"
    ((count_rg_skipped++))
    continue
  fi

  if [[ -z "$resourceGroupName" ]]; then
    verbose_log "Skipping row: resourceGroupName is empty."
    ((count_rg_skipped++))
    continue
  fi

  # Optional strict subscription check
  if [[ "$STRICT_SUBSCRIPTION_CHECK" == true ]]; then
    if ! az account show --subscription "$subscriptionId" &>/dev/null; then
      log_message "Warning: No access to subscription $subscriptionId (or it doesn't exist). Skipping..."
      ((count_rg_skipped++))
      continue
    fi
  fi

  # Optional resource group existence check (disabled by default)
  # if ! az group show --name "$resourceGroupName" --subscription "$subscriptionId" &>/dev/null; then
  #   verbose_log "Skipping row: Resource Group '$resourceGroupName' does not exist in subscription $subscriptionId."
  #   ((count_rg_skipped++))
  #   continue
  # fi

  # Build tag list if non-empty
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

  # Construct resource group ID for 'az resource tag'
  local_rg_id="/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName"

  # Dry Run Mode
  if [[ "$DRY_RUN" == true ]]; then
    log_message "[DRY-RUN] Resource Group: $local_rg_id"
    log_message "[DRY-RUN] Would apply RG tags: ${TAGS_RG[*]}"
    ((count_rg_skipped++))
  else
    log_message "Updating Resource Group '$local_rg_id' with tags: ${TAGS_RG[*]}"
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

# ----------------------------------
# Print Summary
# ----------------------------------
log_message ""
log_message "==============================================="
log_message " Resource Group Tag Update Script Finished"
log_message "   Updated:  $count_rg_updated"
log_message "   Skipped:  $count_rg_skipped"
log_message "   Failed:   $count_rg_failed"
log_message "==============================================="
