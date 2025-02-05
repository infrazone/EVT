# Azure Resource Group Tag Management Script

This script automates the application of standardized Mckesson Azure tags to Azure Resource Groups while preserving existing tags.

## Features

- 🏷️ Applies 8 required Azure-related tags
- 🔄 Preserves existing tags with incremental updates
- ✅ Input validation and error handling
- 🔄 Automatic retry logic for Azure operations
- 📝 Detailed logging capabilities
- 🧪 Dry-run mode for testing
- 📊 Summary reporting

## Required Tags

| Tag Name                     | Example Value         |
|------------------------------|-----------------------|
| core-snow-as-number          | AS123                 |
| core-snow-ba-number          | BA456                 |
| snow-application-name        | HR-Portal             |
| snow-application-owner       | owner@contoso.com     |
| snow-business-criticality    | High                  |
| snow-data-classification     | Confidential          |
| snow-environment             | Prod                  |
| snow-service-owner           | service-owner@contoso.com |

## Prerequisites

- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) installed
- Authenticated Azure session (`az login`)
- Bash shell environment (Linux/macOS/WSL/Git Bash)
- Contributor permissions on target resource groups

## Usage

bash
./update_rg_tags.sh <input.csv> [OPTIONS]

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
2. `resourceGroupName`
3. `coreSnowAsNumber`
4. `coreSnowBaNumber` 
5. `snowApplicationName`
6. `snowApplicationOwner`
7. `snowBusinessCriticality`
8. `snowDataClassification`
9. `snowEnvironment`
10. `snowServiceOwner`

Example CSV contents:

subscriptionId,resourceGroupName,coreSnowAsNumber,coreSnowBaNumber,snowApplicationName,snowApplicationOwner,snowBusinessCriticality,snowDataClassification,snowEnvironment,snowServiceOwner

## Operation Modes

### Dry Run Mode
```bash
./update_rg_tags.sh input.csv --dry-run --verbose
```
- Validates CSV input
- Shows proposed tag changes
- No actual modifications made

### Production Mode
```bash
./update_rg_tags.sh input.csv --log-file tagging.log
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
5. Resource group name presence
6. Tag value non-emptiness check
7. Subscription access (with `--strict-check`)

## Output Example

```
[2023-12-20 14:30:45] Starting Resource Group tag update script.
[2023-12-20 14:30:47] Updating Resource Group '/subscriptions/...' with tags: core-snow-as-number=AS123...
[2023-12-20 14:30:49] Resource Group update complete for /subscriptions/...

===============================================
 Resource Group Tag Update Script Finished
   Updated:  42
   Skipped:  5
   Failed:   2
===============================================
```

## Troubleshooting

| Issue                          | Resolution Steps                              |
|--------------------------------|-----------------------------------------------|
| Permission denied errors       | 1. Verify Azure RBAC permissions<br>2. Check subscription access |
| CSV parsing errors             | 1. Validate column count<br>2. Check for stray commas<br>3. Verify line endings |
| Tag not applied                | 1. Check for empty values in CSV<br>2. Verify --is-incremental flag<br>3. Review Azure CLI version |
| Subscription access issues     | 1. Use `--strict-check` option<br>2. Run `az account get-access-token` |

## Best Practices

1. **Test First**: Always run with `--dry-run` before production use
2. **Log Management**: Use `--log-file` for audit purposes
3. **CSV Validation**: Validate CSV structure before execution
4. **Error Monitoring**: Review failed entries for patterns
5. **Version Control**: Maintain CSV files in source control

## Limitations

- Basic CSV parsing (no support for quoted fields)
- Azure CLI version dependency (2.40.0+ recommended)
- Requires direct resource group access (no management group scope)


This README provides:
Clear usage instructions
CSV format specifications
Operational details
Troubleshooting guide
Best practices
Comprehensive examples
The documentation is structured to help users quickly understand requirements, execute the script properly, and troubleshoot common issues