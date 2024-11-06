# Root-Level Access Prerequisites for Cloud Tagging
Version 1.0 | Date: November 1, 2024

## 1. Azure Root Management Group Access

### 1.1 Required Root-Level Roles
| Role                           | Purpose                        | Permissions                                                                                                                                |
| ------------------------------ | ------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------ |
| Management Group Administrator | Root-level management          | • Full access to manage management group hierarchy<br>• Create/modify/delete management groups<br>• Assign roles at management group scope |
| Tag Administrator              | Enterprise-wide tag management | • Read/Write/Delete tags at management group level<br>• Modify tag inheritance settings<br>• Define tag schemas                            |
| Policy Administrator           | Enterprise policy management   | • Create/modify/delete policy definitions<br>• Assign policies at management group scope<br>• Configure policy exemptions                  |

### 1.2 Critical Azure Permissions
- [ ] `/providers/Microsoft.Management/managementGroups/*`
- [ ] `/providers/Microsoft.Authorization/policyDefinitions/*`
- [ ] `/providers/Microsoft.Authorization/policyAssignments/*`
- [ ] `/providers/Microsoft.Authorization/roleAssignments/*`
- [ ] `/providers/Microsoft.Resources/tags/*`

## 2. GCP Organization Level Access

### 2.1 Required Organization Roles
| Role | Purpose | Permissions |
|------|---------|-------------|
| Organization Administrator | Root-level management | • Full access to organization settings<br>• Manage organization policies<br>• Control resource hierarchy |
| Organization Policy Administrator | Policy management | • Define organization policies<br>• Configure constraints<br>• Manage policy inheritance |
| Organization Viewer | Resource discovery | • View organization structure<br>• Read-only access to resources<br>• Monitor policy compliance |

### 2.2 Critical GCP Permissions
- [ ] `resourcemanager.organizations.*`
- [ ] `resourcemanager.folders.*`
- [ ] `resourcemanager.projects.*`
- [ ] `resourcemanager.tagKeys.*`
- [ ] `resourcemanager.tagValues.*`

## 3. Essential API Enablement

### 3.1 Azure APIs
- [ ] Azure Resource Manager API
- [ ] Microsoft.Resources API
- [ ] Microsoft.Authorization API
- [ ] Microsoft.Management API

### 3.2 GCP APIs
- [ ] Cloud Resource Manager API
- [ ] Cloud Asset API
- [ ] Identity and Access Management (IAM) API
- [ ] Tag Manager API

## 4. Minimum Required Permissions Matrix

### 4.1 Azure Root-Level Permissions
```plaintext
Management Group Scope:
• Microsoft.Resources/tags/*
• Microsoft.Authorization/policyDefinitions/*
• Microsoft.Authorization/policyAssignments/*
• Microsoft.Management/managementGroups/*
• Microsoft.Authorization/roleAssignments/*
```

### 4.2 GCP Organization-Level Permissions
```plaintext
Organization Scope:
• organizations.get
• organizations.setIamPolicy
• resourcemanager.tagKeys.create
• resourcemanager.tagValues.create
• resourcemanager.tags.get/list/update
```

## 5. Access Validation Checklist

### 5.1 Azure Validation
- [ ] Can view all management groups
- [ ] Can create/modify tags at root level
- [ ] Can create/assign policies at root level
- [ ] Can manage role assignments
- [ ] Can view compliance data

### 5.2 GCP Validation
- [ ] Can access organization settings
- [ ] Can create organization-wide tags
- [ ] Can assign organization policies
- [ ] Can view all folders/projects
- [ ] Can manage tag hierarchies

## 6. Security Requirements

### 6.1 Authentication Requirements
- [ ] Break-glass account configuration
- [ ] Multi-factor authentication
- [ ] Privileged Identity Management
- [ ] Just-In-Time Access

### 6.2 Audit Requirements
- [ ] Activity logging enabled
- [ ] Audit logging configured
- [ ] Alert rules established
- [ ] Regular access reviews

## 7. Administrative Access Prerequisites

### 7.1 Azure Administrative Access
| Requirement | Details | Priority |
|-------------|----------|----------|
| Root Management Group Access | Full administrative access | Critical |
| Enterprise-wide Policy Management | Policy definition and assignment | Critical |
| Tag Schema Management | Define and enforce tag standards | Critical |
| Role Assignment Privileges | Manage RBAC at root level | Critical |

### 7.2 GCP Administrative Access
| Requirement | Details | Priority |
|-------------|----------|----------|
| Organization Admin Access | Full organizational control | Critical |
| Tag Management Access | Create and manage tags | Critical |
| Policy Management Access | Define organizational policies | Critical |
| Resource Hierarchy Access | Manage folder/project structure | Critical |



- Portal Access:
    - Azure portal credentials and MFA setup
    - GCP console access and project access
    - Direct access vs VPN requirements
    - IP whitelisting needs
- API Access:
    - Service Principal configuration
    - API permissions and scopes
    - VS Code setup and extensions
    - Authentication methods
- RBAC/IAM:
    - Required roles for tag management
    - Permission scope verification
    - Custom role requirements
    - Access verification
