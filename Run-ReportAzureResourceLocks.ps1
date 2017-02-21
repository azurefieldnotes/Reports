<#
    .DESCRIPTION
        Report: Resource Locks

    .NOTES
        AUTHOR: Keith Ellis
        LASTEDIT: Jan 31, 2017
#>
###########################################################
Write-Output ("Prepare Azure Connection")

Test-AzureRMAccountTokenExpiry
Get-AzurermSubscription
Select-AzureRMSubscription -SubscriptionId "73d55f68-40e5-4820-9e4b-6950dee6ac8a"

Connect-AzureRunAsConnection

$connectionName = "AzureRunAsConnection"
try
{
    # Get the connection "AzureRunAsConnection "
    $servicePrincipalConnection=Get-AutomationConnection -Name $connectionName

    #"Logging in to Azure..."
    Add-AzureRmAccount `
        -ServicePrincipal `
        -TenantId $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint | Out-Null 
}
catch {
    if (!$servicePrincipalConnection)
    {
        $ErrorMessage = "Connection $connectionName not found."
        throw $ErrorMessage
    } else{
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}

$resourceGroupName = "Ace-Workbench"
$storageAccountName = "aceworkbenchstorage"
$storageContainerName = "reportoutput"
$localFileName ="{0}\report.html" -f $env:TEMP
$blobFileName = "Report-ResourceLocks-{0}" -f [guid]::NewGuid() + ".html"

###########################################################
Write-Output ("Data Retrieval")
$resourceLocks = Get-AzureRmResourceLock
$breakdowns = @()

foreach ($lock in $resourceLocks) {

    #Determine lock scope
    $subscriptionEndpoint = "/subscriptions/{0}/providers/{1}/{2}" -f `
        $lock.SubscriptionId, $lock.ResourceType, $lock.ResourceName

    $resourceGroupEndpoint = "/subscriptions/{0}/resourceGroups/{1}/providers/{2}/{3}" -f `
        $lock.SubscriptionId, $lock.ResourceGroupName, $lock.ResourceType, $lock.ResourceName

    if ($lock.ExtensionResourceType) {
        $resourceEndpoint = "/subscriptions/{0}/resourceGroups/{1}/providers/{2}/{3}/providers/{4}/{5}" -f `
            $lock.SubscriptionId, $lock.ResourceGroupName, $lock.ResourceType, $lock.ResourceName, `
            $lock.ExtensionResourceType, $lock.ExtensionResourceName
    }

    $lockScope = switch ($lock.ResourceId) {
        $subscriptionEndpoint  { "Subscription" }
        $resourceGroupEndpoint { "Resource Group" }
        $resourceEndpoint      { "Child Resource" }
        default                { "Unknown" }
    };

    $scopedObject = switch ($lockScope) {
        "Subscription"   { ("/subscriptions/{0}" -f $lock.SubscriptionId) }
        "Resource Group" { ("/subscriptions/{0}/resourceGroups/{1}" -f $lock.SubscriptionId, $lock.ResourceGroupName) }
        "Child Resource" { ("/subscriptions/{0}/resourceGroups/{1}/providers/{2}/{3}" -f $lock.SubscriptionId, $lock.ResourceGroupName, $lock.ResourceType, $lock.ResourceName) }
        default          { "Unknown" }
    };

    $item = New-Object -TypeName PSObject -Property @{`
        "Lock Name" = $lock.Name;
        "Lock Type" = $lock.Properties.level;
        "Lock Scope" = $lockScope
        Notes = $lock.Properties.notes;

        "Scoped Object" = $scopedObject;

        #ResourceId = $lock.ResourceId;
        #ResourceName = $lock.ResourceName;
        #ResourceType = $lock.ResourceType;
        #ResourceGroupName = $lock.ResourceGroupName;
        #SubscriptionId = $lock.SubscriptionId;
        #LockId = $lock.LockId;

        #Properties = $lock.Properties;
        #Properties = ConvertTo-Json -InputObject ($lock.Properties) -Depth 99;
    }
    $breakdowns += $item
}

$locks = $breakdowns | Select "Lock Name", "Lock Type", Notes, "Lock Scope", "Scoped Object"

###########################################################
Write-Output ("Report Generation")

$rpt = @()
$rpt += Get-HtmlOpenPage -TitleText "Report: Resource Locks"

# Overview
$rpt += Get-HtmlContentOpen -HeaderText "Overview"
$rpt += Get-HtmlContentText -Heading "Why are Resource locks important?" -Detail "As an administrator, you may need to lock a subscription, resource group, or resource to prevent other users in your organization from accidentally deleting or modifying critical resources. You can set the lock level to CanNotDelete or ReadOnly. CanNotDelete means authorized users can still read and modify a resource, but they can't delete the resource. ReadOnly means authorized users can read a resource, but they can't delete or update the resource. Applying this lock is similar to restricting all authorized users to the permissions granted by the Reader role."
$rpt += Get-HtmlContentText -Heading "Tip" -Detail "Core network options should be protected with locks. Accidental deletion of a gateway, site-to-site VPN would be disastrous to an Azure subscription. Azure doesn't allow you to delete a virtual network that is in use, but applying more restrictions is a helpful precaution. Policies are also crucial to the maintenance of appropriate controls. We recommend that you apply a CanNotDelete lock to polices that are in use. Virtual Network: CanNotDelete. Network Security Group: CanNotDelete. Policies: CanNotDelete"
$rpt += Get-HtmlContentText -Heading "Learn more: Lock resources to prevent unexpected changes" -Detail "https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-lock-resources"
$rpt += Get-HtmlContentText -Heading "Learn more: Lock Down Your Azure Resources" -Detail "https://blogs.msdn.microsoft.com/cloud_solution_architect/2015/06/18/lock-down-your-azure-resources/"
$rpt += Get-HtmlContentText -Heading "Learn more: Azure enterprise scaffold - prescriptive subscription governance" -Detail "https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-manager-subscription-governance#azure-resource-locks"
$rpt += Get-HtmlContentClose

$rpt += Get-HtmlContentOpen -HeaderText ("{0} :: Resource Locks" -f $locks.Count)
$rpt += get-HtmlContentTable ($locks)
$rpt += Get-HtmlContentClose

$rpt += Get-HtmlClosePage
$rpt | Set-Content -Path $localFileName

###########################################################
Write-Output ("Report Saving")

Set-AzureRmCurrentStorageAccount `
    -ResourceGroupName $resourceGroupName `
    -Name $storageAccountName | Out-Null

$storageAccount = Get-AzureRmStorageAccount `
    -ResourceGroupName $resourceGroupName `
    -Name $storageAccountName

$storageAccountContainer = Get-AzureStorageContainer `
    -Name $storageContainerName

$blob = Set-AzureStorageBlobContent `
    -Container $storageContainerName `
    -Blob $blobFileName `
    -File $localFileName

#$blobs = Get-AzureStorageBlob -Container $storageAccountContainer.Name
#$blobs | Select-Object Name
#Remove-AzureStorageBlob -Container $storageContainerName -Blob $blobFileName

###########################################################
Write-Output ("Click the link to download and view the report")
$url = "https://{0}.blob.core.windows.net/{1}/{2}" -f $storageAccountName, $storageContainerName, $blob.Name
$hash = @{
    type = "hyperlink"; 
    name = $blob.Name; 
    value = $url
};
$str = ConvertTo-Json $hash
Write-Output($str)