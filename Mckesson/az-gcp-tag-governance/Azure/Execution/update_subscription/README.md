# Azure Subscription Tag Management Script

This script automates the application of standardized core tags to Azure Subscriptions while preserving existing tags.

## Features

- 🏷️ Applies 7 required core tags
- 🔄 Preserves existing tags with incremental updates
- ✅ Input validation and error handling
- 🔄 Automatic retry logic for Azure operations
- 📝 Detailed logging capabilities
- 🧪 Dry-run mode for testing
- 📊 Summary reporting

## Required Tags

| Tag Name                          | Example Value         |
|-----------------------------------|-----------------------|
| core-subscription-owner          | owner@contoso.com     |
| core-subscription-super-owner    | super-owner@contoso.com |
| core-cost-center                 | CC-1234               |
| core-financial-bu                | Finance               |
| core-financial-sub-bu            | SubFinance            |
| core-namespace-owner             | ns-owner@contoso.com  |
| core-namespace-super-owner       | ns-super@contoso.com  |

## Prerequisites

- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) installed
- Authenticated Azure session (`az login`)
- Bash shell environment (Linux/macOS/WSL/Git Bash)
- Owner/Contributor permissions on target subscriptions

## Usage

```bash
./update_subscription_tags.sh <input.csv> [OPTIONS]
```

### Options

| Option            | Description                                  |
|-------------------|----------------------------------------------|
| `--dry-run`       | Simulate changes without applying            |
| `--verbose`       | Enable detailed operation logging           |
| `--log-file PATH` | Save output to specified log file           |
| `--strict-check`  | Validate subscription access before tagging  |
| `--help`          | Show usage information                       |

## CSV File Format

Required columns (in order):

1. `subscriptionId` (UUID format)
2. `subscriptionName`
3. `coreSubscriptionOwner`
4. `coreSubscriptionSuperOwner`
5. `coreCostCenter`
6. `coreFinancialBU` 
7. `coreFinancialSubBU`
8. `coreNamespaceOwner`
9. `coreNamespaceSuperOwner`

Example CSV contents:
```csv
subscriptionId,subscriptionName,coreSubscriptionOwner,coreSubscriptionSuperOwner,coreCostCenter,coreFinancialBU,coreFinancialSubBU,coreNamespaceOwner,coreNamespaceSuperOwner
12345678-1234-1234-1234-123456789abc,Prod-Subscription,owner@contoso.com,super-owner@contoso.com,CC-1234,Finance,SubFinance,ns-owner@contoso.com,ns-super@contoso.com
```

## Operation Modes

### Dry Run Mode

```bash
./update_subscription_tags.sh input.csv --dry-run --verbose
```
- Validates CSV input
- Shows proposed tag changes
- No actual modifications made

### Production Mode
```bash
./update_subscription_tags.sh input.csv --log-file tagging.log
```
- Applies tags incrementally
- Retries failed operations (3 attempts)
- Generates summary report
- Saves logs to specified file

## Validation Checks

1. Azure CLI availability
2. Active Azure login session
3. CSV file existence and permissions
4. Subscription ID format validation
5. Mandatory tag value checks
6. Subscription access (with `--strict-check`)

## Output Example

```log
[2023-12-20 14:30:45] Starting subscription tag update script.
[2023-12-20 14:30:47] Applying tags to subscription '12345678...' (Prod-Subscription): core-subscription-owner=owner@contoso.com...
[2023-12-20 14:30:49] Successfully updated subscription: 12345678...

===============================================
 Subscription Tag Update Script Finished
   Updated:  15
   Skipped:  2
   Failed:   1
===============================================
```

## Troubleshooting

| Issue                          | Resolution Steps                              |
|--------------------------------|-----------------------------------------------|
| "Permission denied" errors     | 1. Verify Azure RBAC permissions<br>2. Check subscription owner role |
| Tag update failures            | 1. Check Azure CLI version<br>2. Verify --is-incremental flag |
| CSV format errors              | 1. Validate column count<br>2. Check for trailing commas |
| Subscription access issues     | 1. Use `--strict-check` option<br>2. Verify access with `az account show` |

## Best Practices

1. **Pre-production Testing**: Always use `--dry-run` first
2. **Change Management**: Maintain CSV files in version control
3. **Log Retention**: Keep logs for audit purposes
4. **Tag Governance**: Regularly review tag values and formats
5. **Security**: Restrict CSV file access containing owner emails

## Limitations

- Basic CSV parsing (no support for quoted fields)
- Requires subscription-level write permissions
- Azure CLI version 2.45.0+ recommended
- Maximum 3 retries for failed operations 

Updated tag names and structure
Different CSV column requirements
Subscription-specific permissions and troubleshooting
Modified example commands and outputs
Tailored best practices for subscription management