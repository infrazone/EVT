# Azure Policy as Code Implementation Guide

## Overview

This guide outlines the implementation of Azure Policy as Code using GitHub, combining Infrastructure as Code principles with DevOps practices for managing Azure policies at scale.

## File Structure

```
policies/
├── policy1/
│   ├── versions/
│   │   ├── policy-v1.json              # Full policy definition
│   │   ├── policy-v1.parameters.json   # Policy parameters
│   │   └── policy-v1.rules.json        # Policy rules
│   ├── assign.dev.json                 # Dev environment assignment
│   └── assign.prod.json                # Prod environment assignment
├── policy2/
    └── [Similar structure]

initiatives/
├── init1/
│   ├── versions/
│   │   ├── policyset.json              # Initiative definition
│   │   ├── policyset.definitions.json  # List of included policies
│   │   └── policyset.parameters.json   # Initiative parameters
│   └── assign.dev.json                 # Dev environment assignment
└── init2/
    └── [Similar structure]
```

## Implementation Workflow

1. **Source Control Setup**
   - Initialize a GitHub repository
   - Create the folder structure as shown above
   - Set up branch protection rules for main/master branch

2. **Policy Development Process**
   - Create policies in feature branches
   - Include all required files (definition, parameters, rules)
   - Version policies using semantic versioning
   - Submit changes via Pull Request

3. **Continuous Integration**
   - Set up GitHub Actions for automated testing
   - Validate policy JSON syntax
   - Check parameter consistency
   - Verify policy rule logic

4. **Deployment Pipeline**
   ```yaml
   name: Deploy Azure Policy
   on:
     push:
       branches: [ main ]
     pull_request:
       branches: [ main ]

   jobs:
     deploy:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v2
         - name: Azure Login
           uses: azure/login@v1
         - name: Deploy Policy
           uses: azure/cli@v1
           with:
             inlineScript: |
               # Policy deployment scripts
   ```

5. **Testing Strategy**
   - Deploy to dev environment first
   - Use `enforcementMode: "Disabled"` initially
   - Validate policy evaluation results
   - Test remediation tasks if applicable
   - Verify no unintended consequences

6. **Production Deployment**
   - Use gradual rollout strategy
   - Enable enforcement in stages
   - Monitor policy compliance
   - Track remediation progress

## Best Practices

1. **Version Control**
   - Use clear commit messages
   - Maintain changelog
   - Tag releases
   - Document breaking changes

2. **Policy Organization**
   - Group related policies
   - Use consistent naming conventions
   - Include metadata tags
   - Document dependencies

3. **Security Considerations**
   - Restrict write permissions
   - Use service principals
   - Implement least privilege
   - Audit deployment logs

4. **Monitoring and Maintenance**
   - Set up alerts for failures
   - Track compliance trends
   - Regular policy reviews
   - Update documentation

## Sample Policy Definition

```json
{
  "properties": {
    "displayName": "Require resource tags",
    "description": "Requires specified tags on resources",
    "mode": "Indexed",
    "parameters": {
      "requiredTags": {
        "type": "Array",
        "metadata": {
          "displayName": "Required tags",
          "description": "List of required tags"
        }
      }
    },
    "policyRule": {
      "if": {
        "field": "tags",
        "exists": "false"
      },
      "then": {
        "effect": "deny"
      }
    }
  }
}
```

## Troubleshooting

Common issues and solutions:
- Policy not evaluating: Check assignment scope
- Remediation failing: Verify managed identity permissions
- Deployment errors: Validate JSON syntax
- Compliance issues: Review policy rules and conditions

## Resources

- [Azure Policy Documentation](https://docs.microsoft.com/azure/governance/policy/)
- [GitHub Actions Documentation](https://docs.github.com/actions)
- [Azure CLI Reference](https://docs.microsoft.com/cli/azure/)

## Support and Maintenance

For ongoing maintenance:
1. Regular policy reviews
2. Compliance monitoring
3. Version updates
4. Documentation updates
5. Security patches