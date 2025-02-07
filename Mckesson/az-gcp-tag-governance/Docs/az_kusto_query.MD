Resource Groups

// PURPOSE:
// 1. Retrieve all resource groups in the tenant.
// 2. Display the specified tags in separate columns:
//    core-snow-as-number, core-snow-ba-number, snow-application-name, 
//    snow-application-owner, snow-business-criticality, 
//    snow-data-classification, snow-environment, snow-service-owner.

ResourceContainers
| where type == "microsoft.resources/subscriptions/resourcegroups"
| project
    resourceGroupId = id,
    subscriptionId,
    resourceGroupName = name,
    location,
    coreSnowAsNumber         = tostring(tags["core-snow-as-number"]),
    coreSnowBaNumber         = tostring(tags["core-snow-ba-number"]),
    snowApplicationName      = tostring(tags["snow-application-name"]),
    snowApplicationOwner     = tostring(tags["snow-application-owner"]),
    snowBusinessCriticality  = tostring(tags["snow-business-criticality"]),
    snowDataClassification   = tostring(tags["snow-data-classification"]),
    snowEnvironment          = tostring(tags["snow-environment"]),
    snowServiceOwner         = tostring(tags["snow-service-owner"])



Subscriptions

// PURPOSE:
// 1. Retrieve all subscriptions in the Azure tenant.
// 2. List the specific tag keys and their respective values:
//    core-subscription-owner, core-subscription-super-owner,
//    core-cost-center, core-financial-bu, core-financial-sub-bu,
//    core-namespace-owner, core-namespace-super-owner.

ResourceContainers
| where type == "microsoft.resources/subscriptions"    // Filter only subscription objects
| project
    subscriptionId,
    subscriptionName = name,
    // Retrieve each tag value using dynamic indexing
    coreSubscriptionOwner       = tostring(tags["core-subscription-owner"]),
    coreSubscriptionSuperOwner  = tostring(tags["core-subscription-super-owner"]),
    coreCostCenter              = tostring(tags["core-cost-center"]),
    coreFinancialBU             = tostring(tags["core-financial-bu"]),
    coreFinancialSubBU          = tostring(tags["core-financial-sub-bu"]),
    coreNamespaceOwner          = tostring(tags["core-namespace-owner"]),
    coreNamespaceSuperOwner     = tostring(tags["core-namespace-super-owner"])



