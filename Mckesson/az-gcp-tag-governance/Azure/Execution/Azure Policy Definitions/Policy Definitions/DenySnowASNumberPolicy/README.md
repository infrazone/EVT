

## DenySnowASNumberPolicy

### Purpose
This policy enforces proper tagging of resource groups with valid ServiceNow AS (Application Service) numbers. It prevents the creation or modification of resource groups that don't have a valid `core-snow-as-number` tag.

### Policy Details

- **Display Name**: Deny RG creation if core-snow-as-number is missing, empty, or invalid
- **Type**: Custom
- **Mode**: All
- **Category**: Tags

### Policy Behavior

The policy will **deny** resource group creation or updates when any of these conditions are met:

1. The `core-snow-as-number` tag is missing
2. The `core-snow-as-number` tag is empty
3. The `core-snow-as-number` tag value is not in the allowed list of AS/BA numbers

### Parameters

- **allowedAsNumbers**: An array of valid AS/BA values that are permitted
  - Format examples: "AS11003", "BA22609"
  - Contains thousands of valid AS numbers that can be used
  - Must be configured during policy assignment

### Example Usage

To assign this policy, you'll need to:

1. Create the policy definition using the provided JSON
2. Assign the policy at the desired scope (management group, subscription, etc.)
3. Provide the list of allowed AS numbers during assignment using the parameters file

### Sample Valid Tag Values

```json
{
    "core-snow-as-number": "AS23538"  // Example of a valid tag value
}
```

### Implementation Notes

- The policy evaluates all resource group operations
- Tag values are case-sensitive
- The policy uses exact matching against the allowed list
- Empty strings are explicitly denied

### Related Files

- `DenySnowASNumberPolicy.json` - Main policy definition
- `asNumbers-params.json` - Parameter file containing the allowed AS numbers
- `as_Numbers-params-azportal.json` - Azure portal compatible parameter file

For more information about Azure Policy, visit [Azure Policy documentation](https://docs.microsoft.com/en-us/azure/governance/policy/).
```
