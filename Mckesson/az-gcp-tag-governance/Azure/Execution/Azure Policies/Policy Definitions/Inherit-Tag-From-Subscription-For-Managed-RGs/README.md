# Azure Policy: Inherit Tags from Subscription to Azure-Managed Resource Groups

This custom policy automatically applies/updates seven core tags on resource groups matching specific naming patterns, inheriting from subscription tags or defaulting to "NotSet".

## Policy Overview
- **Type**: Custom
- **Mode**: All
- **Category**: Tags
- **Effect**: Modify
- **Required Role**: Policy Contributor
- **Target**: Resource groups matching:
  - `MC_*` (AKS managed)
  - `AzureBackupRG_*` (Azure Backup)
  - `*asr*` (Azure Site Recovery)

## Core Tags
| Tag Name | Description | Default |
|----------|-------------|---------|
| core-subscription-owner | Primary owner of the subscription | NotSet |
| core-subscription-super-owner | Secondary/supervisory owner | NotSet |
| core-cost-center | Financial cost center code | NotSet |
| core-financial-bu | Business unit identifier | NotSet |
| core-financial-sub-bu | Sub-business unit identifier | NotSet |
| core-namespace-owner | Namespace/project owner | NotSet |
| core-namespace-super-owner | Secondary namespace owner | NotSet |

## Policy Definition

```json
{
  "properties": {
    "displayName": "Inherit tags from subscription to Azure-managed resource groups",
    "policyType": "Custom",
    "mode": "All",
    "description": "Automatically apply or update seven core tags on resource groups named MC_*, AzureBackupRG_*, or containing 'asr'. Inherits values from subscription tags or defaults to 'NotSet'.",
    "policyRule": {
      "if": {
        "allOf": [
          {
            "field": "type",
            "equals": "Microsoft.Resources/subscriptions/resourceGroups"
          },
          {
            "anyOf": [
              {
                "field": "name",
                "like": "MC_*"
              },
              {
                "field": "name",
                "like": "AzureBackupRG_*"
              },
              {
                "field": "name",
                "contains": "*asr*"
              }
            ]
          }
        ]
      },
      "then": {
        "effect": "modify",
        "details": {
          "roleDefinitionIds": [
            "/providers/Microsoft.Authorization/roleDefinitions/5d6b6bb7-de71-4623-b4af-96380a352509"
          ],
          "operations": [
            {
              "operation": "addOrReplace",
              "field": "tags['core-subscription-owner']",
              "value": "[if(empty(subscription().tags['core-subscription-owner']), 'NotSet', subscription().tags['core-subscription-owner'])]"
            },
            {
              "operation": "addOrReplace",
              "field": "tags['core-subscription-super-owner']",
              "value": "[if(empty(subscription().tags['core-subscription-super-owner']), 'NotSet', subscription().tags['core-subscription-super-owner'])]"
            },
            {
              "operation": "addOrReplace",
              "field": "tags['core-cost-center']",
              "value": "[if(empty(subscription().tags['core-cost-center']), 'NotSet', subscription().tags['core-cost-center'])]"
            },
            {
              "operation": "addOrReplace",
              "field": "tags['core-financial-bu']",
              "value": "[if(empty(subscription().tags['core-financial-bu']), 'NotSet', subscription().tags['core-financial-bu'])]"
            },
            {
              "operation": "addOrReplace",
              "field": "tags['core-financial-sub-bu']",
              "value": "[if(empty(subscription().tags['core-financial-sub-bu']), 'NotSet', subscription().tags['core-financial-sub-bu'])]"
            },
            {
              "operation": "addOrReplace",
              "field": "tags['core-namespace-owner']",
              "value": "[if(empty(subscription().tags['core-namespace-owner']), 'NotSet', subscription().tags['core-namespace-owner'])]"
            },
            {
              "operation": "addOrReplace",
              "field": "tags['core-namespace-super-owner']",
              "value": "[if(empty(subscription().tags['core-namespace-super-owner']), 'NotSet', subscription().tags['core-namespace-super-owner'])]"
            }
          ]
        }
      }
    }
  }
}
```

## Deployment Instructions

### Prerequisites
- Azure CLI installed and authenticated
- Sufficient permissions (Policy Contributor role or higher)
- Target subscription ID

### 1. Create Policy Definition
```bash
az policy definition create \
  --name "Inherit-Tags-Managed-RGs" \
  --display-name "Inherit tags from subscription to Azure-managed resource groups" \
  --description "Automatically tags MC_*, AzureBackupRG_*, or containing asr RGs with subscription's 7 core tags or 'NotSet' fallback." \
  --rules InheritTagsPolicy.json \
  --mode All \
  --metadata category=Tags
```

### 2. Assign Policy
```bash
az policy assignment create \
  --name "Inherit-Tags-Managed-RGs" \
  --display-name "Inherit tags from subscription to Azure-managed resource groups" \
  --policy "Inherit-Tags-Managed-RGs" \
  --assign-identity "[system]" \
  --location "eastus" \
  --scope "/subscriptions/<Your_Subscription_ID>"
```

### 3. Remediate Existing Resources (Optional)
```bash
az policy remediation create \
  --name "Remediate-Managed-RGs" \
  --policy-assignment "Inherit-Tags-Managed-RGs" \
  --scope "/subscriptions/<Your_Subscription_ID>"
```

## Validation
1. Check Policy → Assignments for custom policy
2. Verify Compliance blade for proper tag application
3. Inspect Tags blade on matching resource groups
4. Run the following command to check assignment status:
   ```bash
   az policy assignment list --query "[?displayName=='Inherit tags from subscription to Azure-managed resource groups']"
   ```

## Troubleshooting
- **Issue**: Policy not applying tags
  - Verify system-assigned identity has proper permissions
  - Check if resource groups match naming patterns
  - Review activity logs for policy evaluation errors

- **Issue**: Incorrect tag values
  - Verify subscription tags are properly set
  - Check policy evaluation logs
  - Ensure no conflicting policies exist

## Adjustments
- Change fallback value from 'NotSet' by modifying the policy rule
- Modify tag selection by updating the operations array
- Refine resource group name matching in the `if` condition
- Add exclusions via `--excluded-scopes` during assignment
- Update role definition ID if different permissions are needed

## Notes
- Policy evaluations occur approximately every hour
- Tag modifications may take up to 30 minutes to propagate
- Consider impact on existing automation that may depend on tags