# Input bindings are passed in via param block.
param($Timer)
 
# Get the current universal time in the default string format.
$currentUTCtime = (Get-Date).ToUniversalTime()
 
# The 'IsPastDue' property is 'true' when the current function invocation is later than scheduled.
if ($Timer.IsPastDue) {
    Write-Host "PowerShell timer is running late!"
}
 
# Write an information log with the current time.
Write-Host "PowerShell timer trigger function ran! TIME: $currentUTCtime"
 
import-module Az.Resources
Import-Module Az.Accounts
Import-Module Az.KeyVault
Import-Module sqlserver
#Get subscriptions from Tenent
$subscriptions = Get-AzSubscription -TenantId (Get-AzContext).Tenant
 
#Key Vault variables
        $vaultname = "core-tagging-automation"
        $secretname = "coretaggingautomation"
        $password = get-azkeyvaultsecret -VaultName $vaultname -Name $secretname -asPlainText
#Loop through subscriptions
foreach ($subscription in $subscriptions.Id){
    Set-AzContext -Subscription $subscription
    # Get all resource groups in subscription
    $resourcegroups = Get-AzResourceGroup
    #Loop through resource groups
    foreach ($resourcegroup in $resourcegroups.ResourceGroupName) {
        #Get resource group ID
        $resourcegroupId = Get-AzResourceGroup $resourcegroup
        $resourceId = $resourcegroupId.ResourceId
        $taginfomation = Get-AzTag -ResourceId $resourceId
        
        #Get AS number for SQL Query
        $asnumberinfo = $taginfomation.Properties.TagsProperty.'core-snow-as-number'
        $asnumber = $asnumberinfo -split ';\s*'
        $corecostcenter = $taginfomation.Properties.TagsProperty.'core-cost-center'
        $coreuid = $taginfomation.Properties.TagsProperty.'core-uid'
        $businessunit = $taginfomation.Properties.TagsProperty.'business-unit'
        $applicationname = $taginfomation.Properties.TagsProperty.'application-name'
        $environment = $taginfomation.Properties.TagsProperty.'environment'
 
        if($asnumber.Count -gt 1){
            $coreasnumbers =@()
            $snowbanumber = @()
            $snowbabusinessunit = @()
            $snowbacompany = @()
            $snowbabusinessowner = @()
            $snowserviceowner = @()
            $snowproductowner = @()
            $snowmanagedbygroup = @()
            $snowleanixid = @()
            $snowbaapplicationname = @()
            $snowdataclassification = @()
            $snowenvironment = @()
            $snowsupportgroup = @()
        foreach($asnumbers in $asnumber){
        #SQL Server Query
        $passwords = ConvertTo-SecureString $password -AsPlainText -Force
        $Cred = New-Object System.Management.Automation.PSCredential ("az_tagging", $passwords)
 
        $query = "select *
    from dbo.v_azure_tagging_business_app
    where [as_number] = '$asnumbers'"
 
    $result = Invoke-Sqlcmd -ServerInstance "vision-dw-prod.database.windows.net" -Database "vision-dw-prod" -Credential $Cred -Query $query
    # variables for tag updates
    $snowbanumber += $result.ba_number
    $snowbabusinessunit += $result.business_unit
    $snowbacompany += $result.company
    $snowbabusinessowner += $result.business_owner
    $snowserviceowner += $result.serivce_owner
    $snowproductowner += $result.product_owner
    $snowmanagedbygroup += $result.managed_by_group
    $snowleanixid += $result.u_leanix_id
    $snowbaapplicationname += $result.name
    $snowdataclassification += $result.data_classification
    $snowenvironment += $result.environment
    $snowsupportgroup += $result.support_group
            }  
     $coreasnumbers += $asnumber
     $coreasnumber = $coreasnumbers -join "; "
     $snowbanumbers = $snowbanumber -join "; "
     $snowbabusinessunits = $snowbabusinessunit -join "; "
     $snowbacompanies = $snowbacompany -join "; "
     $snowbabusinessowners = $snowbabusinessowner -join "; "
     $snowserviceowners = $snowserviceowner -join "; "
     $snowproductowners = $snowproductowner -join "; "
     $snowmanagedbygroups = $snowmanagedbygroup -join "; "
     $snowleanixids = $snowleanixid -join "; "
     $snowbaapplicationnames = $snowbaapplicationname -join "; "
     $snowdataclassifications = $snowdataclassification -join "; "
     $snowenvironments = $snowenvironment -join "; "
     $snowsupportgroups = $snowsupportgroup -join "; "
    
    #tag automation
    $tagname = @{"snow-ba-business-unit" = "$snowbabusinessunits"; "snow-ba-company" = "$snowbacompanies"; "snow-ba-business-owner" = "$snowbabusinessowners";
    "snow-ba-service-owner" = "$snowserviceowners"; "snow-ba-product-owner" = "$snowproductowners"; "snow-ba-managed-by-group" = "$snowmanagedbygroups";
    "snow-ba-leanix-id" = "$snowleanixids"; "snow-ba-application-name" = "$snowbaapplicationnames"; "snow-ba-data-classification" = "$snowdataclassifications";
     "snow-as-environment" = "$snowenvironments"; "snow-as-support-group"="$snowsupportgroups"; "core-snow-as-number"="$coreasnumber"; "core-as-number"="$coreasnumber"; "core-cost-center"="$corecostcenter";
    "snow-ba-number" = "$snowbanumbers"; "core-uid"="$coreuid"; "business-unit"="$businessunit"; "application-name"="$applicationname"; "environment"="$environment"}
            foreach($tags in $tagname) {
                Write-Host "Updating Tag info"
                Update-AzTag -ResourceId $resourceId -Tag $tags -Operation Replace
              
    }
   
  }
    else{
        $passwords = ConvertTo-SecureString $password -AsPlainText -Force
        $Cred = New-Object System.Management.Automation.PSCredential ("az_tagging", $passwords)
 
        $query = "select *
    from dbo.v_azure_tagging_business_app
    where [as_number] = '$asnumber'"
 
    $result = Invoke-Sqlcmd -ServerInstance "vision-dw-prod.database.windows.net" -Database "vision-dw-prod" -Credential $Cred -Query $query
    # variables for tag updates
    $snowbanumber = $result.ba_number
    $snowbabusinessunit = $result.business_unit
    $snowbacompany = $result.company
    $snowbabusinessowner = $result.business_owner
    $snowserviceowner = $result.serivce_owner
    $snowproductowner = $result.product_owner
    $snowmanagedbygroup = $result.managed_by_group
    $snowleanixid = $result.u_leanix_id
    $snowbaapplicationname = $result.name
    $snowdataclassification = $result.data_classification
    $snowenvironment = $result.environment
    $snowsupportgroup = $result.support_group
    #tag automation
    $tagname = @{"snow-ba-business-unit" = "$snowbabusinessunit"; "snow-ba-company" = "$snowbacompany"; "snow-ba-business-owner" = "$snowbabusinessowner";
    "snow-ba-service-owner" = "$snowserviceowner"; "snow-ba-product-owner" = "$snowproductowner"; "snow-ba-managed-by-group" = "$snowmanagedbygroup"; "snow-ba-leanix-id" = "$snowleanixid"; "snow-ba-application-name" = "$snowbaapplicationname";
    "snow-ba-data-classification" = "$snowdataclassification"; "snow-as-environment" = "$snowenvironment"; "snow-as-support-group"="$snowsupportgroup"; "core-snow-as-number"="$asnumber";
    "core-as-number"="$asnumber"; "core-cost-center"="$corecostcenter";
    "snow-ba-number" = "$snowbanumber"; "core-uid"="$coreuid"; "business-unit"="$businessunit"; "application-name"="$applicationname"; "environment"="$environment"}
            foreach($tags in $tagname) {
                Write-Host "Updating Tag info"
                Update-AzTag -ResourceId $resourceId -Tag $tags -Operation Replace
    }
   }
    }
}