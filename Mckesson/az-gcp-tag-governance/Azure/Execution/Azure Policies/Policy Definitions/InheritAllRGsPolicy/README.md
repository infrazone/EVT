# Azure Policy: Inherit Core Tags from Subscription

This document describes an Azure Policy that automatically inherits seven core tags from the subscription level to all resource groups. If the tags don't exist at the subscription level, they default to "NotSet".

## Policy Overview

The policy applies to all resource groups within the assigned scope (subscription or management group) and manages the following tags:

- core-subscription-owner
- core-subscription-super-owner
- core-cost-center
- core-financial-bu
- core-financial-sub-bu
- core-namespace-owner
- core-namespace-super-owner

## Policy Definition

```json
{
  "properties": {
    "displayName": "Inherit 7 core tags from subscription for all resource groups",
    "policyType": "Custom",
    "mode": "All",
    "description": "Automatically applies or updates seven tags (core-subscription-owner, core-subscription-super-owner, core-cost-center, core-financial-bu, core-financial-sub-bu, core-namespace-owner, core-namespace-super-owner) for all resource groups in the assigned scope, inheriting from subscription tags or defaulting to 'NotSet'.",
    "policyRule": {
      "if": {
        "allOf": [
          {
            "field": "type",
            "equals": "Microsoft.Resources/subscriptions/resourceGroups"
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

## Implementation Steps

### 1. Create Policy Definition

Save the policy JSON to a file (e.g., `InheritAllRGsPolicy.json`) and create the policy definition:

```bash
az policy definition create \
  --name "Inherit-7CoreTags-AllRGs" \
  --display-name "Inherit 7 core tags from subscription for all resource groups" \
  --description "Inherits or defaults to 'NotSet' for 7 core tags on all resource groups within scope." \
  --rules InheritAllRGsPolicy.json \
  --mode All \
  --subscription "<Your_Subscription_ID>"
```

### 2. Assign Policy

Assign the policy at your desired scope (e.g., subscription level):

```bash
az policy assignment create \
  --name "Inherit-7CoreTags-AllRGs-Assignment" \
  --policy "Inherit-7CoreTags-AllRGs" \
  --assign-identity "[system]" \
  --location "eastus" \
  --scope "/subscriptions/<Your_Subscription_ID>"
```

### 3. Remediate Existing Resources (Optional)

To apply the policy to existing resource groups:

```bash
az policy remediation create \
  --name "Remediate-7CoreTags-AllRGs" \
  --policy-assignment "Inherit-7CoreTags-AllRGs-Assignment" \
  --scope "/subscriptions/<Your_Subscription_ID>"
```

## Expected Outcome

Once implemented, this policy ensures:

1. All resource groups automatically inherit the seven core tags from the subscription level
2. If a tag doesn't exist at the subscription level, it's set to "NotSet" on the resource group
3. Consistent tagging is maintained across all resource groups in the environment