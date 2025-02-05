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
# USAGE:
#   ./update_subscription_tags.sh <path-to-csv> [--dry-run] [--verbose] [--log-file <path>] [--strict-check] [--help]
#
# DESCRIPTION:
#   1. Reads a CSV file containing subscription information.
#   2. Builds a tag list from the CSV fields (only if they have values).
#   3. Applies tags incrementally with Azure CLI, preserving existing tags.
#   4. Supports dry-run mode to preview changes, verbose logging, and optional log file output.
#   5. Summarizes the results (updated, skipped, failed) at the end.
#
# CSV FORMAT:
#   9 columns in the following order:
#     subscriptionId, subscriptionName,
#     coreSubscriptionOwner, coreSubscriptionSuperOwner,
#     coreCostCenter, coreFinancialBU, coreFinancialSubBU,
#     coreNamespaceOwner, coreNamespaceSuperOwner
#
#   Example row:
#     12345678-1234-1234-1234-123456789abc, MySubscription, alice@contoso.com, bob@contoso.com, CC123, Finance, SubFinance, nspaceAlice, nspaceBob
#
# PREREQUISITES:
#   - Azure CLI installed (az command).
#   - Logged into Azure (az login).
#   - Bash shell (macOS/Linux). For Windows, run within Git Bash or WSL.
#
# NOTES:
#   - For robust CSV parsing (handling quotes, commas in fields), use a dedicated parser/tool.
#   - Consider using "az subscription update" if "az resource tag" becomes unreliable for subscription-level tags.
#   - For large CSVs, consider parallelizing the tagging process (see the commented-out example near the end).
#

set -euo pipefail

# ------------------------------------
#           USAGE / HELP
# ------------------------------------
usage() {
  cat << EOF
Usage: $0 <path-to-csv> [OPTIONS]

Update 7 required tags on Azure subscriptions from a CSV file.

OPTIONS:
  --dry-run       Show what would be done, without applying any changes
  --verbose       Enable verbose logging
  --log-file FILE Write logs to FILE
  --strict-check  Validate subscription access before applying tags
  --help          Show this help message and exit

CSV FORMAT:
  The CSV file must have 9 columns (including header), in this order:
    1) subscriptionId
    2) subscriptionName
    3) coreSubscriptionOwner
    4) coreSubscriptionSuperOwner
    5) coreCostCenter
    6) coreFinancialBU
    7) coreFinancialSubBU
    8) coreNamespaceOwner
    9) coreNamespaceSuperOwner

EXAMPLE:
  $0 subscriptions.csv --dry-run

EOF
}

# ------------------------------------
#         PARSE ARGUMENTS
# ------------------------------------
CSV_FILE=""
DRY_RUN=false
VERBOSE=false
LOG_FILE=""
STRICT_SUBSCRIPTION_CHECK=false

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

# ------------------------------------
#       LOGGING & RETRY LOGIC
# ------------------------------------
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

# ------------------------------------
#   VALIDATE REQUIRED INPUT & ENV
# ------------------------------------
if [[ -z "$CSV_FILE" ]]; then
  echo "Error: No CSV file specified."
  usage
  exit 1
fi

if [[ ! -f "$CSV_FILE" ]]; then
  echo "Error: CSV file '$CSV_FILE' not found."
  exit 1
fi

if [[ -n "$LOG_FILE" ]]; then
  : > "$LOG_FILE"  # Truncate existing log file
fi

log_message "Starting subscription tag update script."
log_message "CSV file: $CSV_FILE"

if [[ "$DRY_RUN" == true ]]; then
  log_message "Running in DRY-RUN mode: No changes will be applied."
fi

if ! command -v az >/dev/null 2>&1; then
  log_message "Error: Azure CLI (az) is not installed or not found in PATH."
  exit 1
fi

if ! az account show >/dev/null 2>&1; then
  log_message "Error: Not logged in to Azure. Please run 'az login' first."
  exit 1
fi

# ------------------------------------
#      PROCESS CSV RECORDS
# ------------------------------------
count_updated=0
count_skipped=0
count_failed=0

# We skip the header row by starting from line 2
tail -n +2 "$CSV_FILE" | while IFS= read -r line; do
  
  # Convert CSV row to array
  IFS=',' read -ra fields <<< "$line"

  # Strictly check for exactly 9 columns
  if [[ ${#fields[@]} -ne 9 ]]; then
    verbose_log "Skipping row due to incorrect number of columns (${#fields[@]}). Expected 9."
    ((count_skipped++))
    continue
  fi

  # Assign each field, trimming whitespace
  subscriptionId="$(echo "${fields[0]}" | xargs)"
  subscriptionName="$(echo "${fields[1]}" | xargs)"
  coreSubscriptionOwner="$(echo "${fields[2]}" | xargs)"
  coreSubscriptionSuperOwner="$(echo "${fields[3]}" | xargs)"
  coreCostCenter="$(echo "${fields[4]}" | xargs)"
  coreFinancialBU="$(echo "${fields[5]}" | xargs)"
  coreFinancialSubBU="$(echo "${fields[6]}" | xargs)"
  coreNamespaceOwner="$(echo "${fields[7]}" | xargs)"
  coreNamespaceSuperOwner="$(echo "${fields[8]}" | xargs)"

  # Basic validity checks
  if ! [[ "$subscriptionId" =~ ^[0-9a-fA-F-]{36}$ ]]; then
    verbose_log "Skipping invalid subscription ID format: $subscriptionId"
    ((count_skipped++))
    continue
  fi

  # Strict subscription validation (optional)
  if [[ "$STRICT_SUBSCRIPTION_CHECK" == true ]]; then
    if ! az account show --subscription "$subscriptionId" >/dev/null 2>&1; then
      log_message "Warning: No access or invalid subscription $subscriptionId. Skipping..."
      ((count_skipped++))
      continue
    fi
  fi

  # Build list of tags if they have values
  TAGS=()
  [[ -n "$coreSubscriptionOwner" ]]       && TAGS+=( "core-subscription-owner=$coreSubscriptionOwner" )
  [[ -n "$coreSubscriptionSuperOwner" ]]  && TAGS+=( "core-subscription-super-owner=$coreSubscriptionSuperOwner" )
  [[ -n "$coreCostCenter" ]]              && TAGS+=( "core-cost-center=$coreCostCenter" )
  [[ -n "$coreFinancialBU" ]]             && TAGS+=( "core-financial-bu=$coreFinancialBU" )
  [[ -n "$coreFinancialSubBU" ]]          && TAGS+=( "core-financial-sub-bu=$coreFinancialSubBU" )
  [[ -n "$coreNamespaceOwner" ]]          && TAGS+=( "core-namespace-owner=$coreNamespaceOwner" )
  [[ -n "$coreNamespaceSuperOwner" ]]     && TAGS+=( "core-namespace-super-owner=$coreNamespaceSuperOwner" )

  if [[ ${#TAGS[@]} -eq 0 ]]; then
    verbose_log "No tags to apply for subscription $subscriptionId ($subscriptionName)."
    ((count_skipped++))
    continue
  fi

  if [[ "$DRY_RUN" == true ]]; then
    log_message "[DRY-RUN] Subscription: $subscriptionId ($subscriptionName)"
    log_message "[DRY-RUN] Would apply tags: ${TAGS[*]}"
    ((count_skipped++))
    continue
  fi

  # ---------------------------------------
  # Apply Tags (Incrementally)
  # ---------------------------------------
  log_message "Applying tags to subscription '$subscriptionId' ($subscriptionName): ${TAGS[*]}"

  if retry_az_command az resource tag \
      --ids "/subscriptions/$subscriptionId" \
      --tags "${TAGS[@]}" \
      --is-incremental \
      --only-show-errors; then
    log_message "Successfully updated subscription: $subscriptionId."
    ((count_updated++))
  else
    log_message "Error applying tags to subscription: $subscriptionId. Skipping..."
    ((count_failed++))
  fi

done

# ------------------------------------
#           SUMMARY
# ------------------------------------
log_message ""
log_message "==============================================="
log_message " Subscription Tag Update Script Finished"
log_message "   Updated:  $count_updated"
log_message "   Skipped:  $count_skipped"
log_message "   Failed:   $count_failed"
log_message "==============================================="

# ------------------------------------
# OPTIONAL: PARALLEL EXECUTION HINT
# ------------------------------------
# If you have a large CSV and want to parallelize, you could do something like:
#
# tail -n +2 "$CSV_FILE" | \
#   parallel -j 5 --colsep ',' --header : \
#   'az resource tag --ids "/subscriptions/{1}" \
#       --tags "core-subscription-owner={3}" \
#                "core-subscription-super-owner={4}" \
#                "core-cost-center={5}" \
#                "core-financial-bu={6}" \
#                "core-financial-sub-bu={7}" \
#                "core-namespace-owner={8}" \
#                "core-namespace-super-owner={9}" \
#       --is-incremental'
#
# 1) This example uses GNU Parallel with column separation by comma (--colsep ',').
# 2) Adjust "-j 5" to control the concurrency level.
# 3) You'd need to replicate the same data trimming, existence checks, etc. for a production environment.
# 4) Error handling, logging, and retries might be handled differently in a parallel context.
