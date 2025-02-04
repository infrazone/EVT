# Azure Policy: Inherit Tags from Subscription to Azure-Managed Resource Groups

This custom policy automatically applies/updates seven core tags on resource groups matching specific naming patterns, inheriting from subscription tags or defaulting to "NotSet".

## Policy Overview
- **Type**: Custom
- **Mode**: All
- **Target**: Resource groups matching:
  - `MC_*` (AKS managed)
  - `AzureBackupRG_*` (Azure Backup)
  - `*asr*` (Azure Site Recovery)

## Core Tags
1. core-subscription-owner
2. core-subscription-super-owner
3. core-cost-center
4. core-financial-bu
5. core-financial-sub-bu
6. core-namespace-owner
7. core-namespace-super-owner

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

### 1. Create Policy Definition
```bash
az policy definition create \
  --name "Inherit-Tags-Managed-RGs" \
  --display-name "Inherit tags from subscription to Azure-managed resource groups" \
  --description "Automatically tags MC_*, AzureBackupRG_*, or containing asr RGs with subscription's 7 core tags or 'NotSet' fallback." \
  --rules InheritTagsPolicy.json \
  --mode All
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

## Adjustments
- Change fallback value from 'NotSet'
- Modify tag selection
- Refine resource group name matching
- Add exclusions via `--excluded-scopes`