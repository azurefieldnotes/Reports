#REQUIRES -Version 5 -Modules @{ModuleName='Avanade.AzureAD';ModuleVersion="1.1.1"},AzureADReports,AzureReports
using module AzureReports
using module AzureADReports

[CmdletBinding(ConfirmImpact='None',DefaultParameterSetName='Credential')]
param
(
    [Parameter(Mandatory=$false,ParameterSetName='Username')]
    [Parameter(Mandatory=$false,ParameterSetName='Credential')]
    [String]    
    $ClientId='1950a258-227b-4e31-a9cf-717495945fc2',
    [Parameter(Mandatory=$false,ParameterSetName='Username')]
    [Parameter(Mandatory=$false,ParameterSetName='Credential')]
    [String]    
    $TenantId='common',
    [Parameter(Mandatory=$false,ParameterSetName='Username')]
    [Parameter(Mandatory=$false,ParameterSetName='Credential')]
    [String[]]    
    $GraphTenants='myOrganization',
    [Parameter(Mandatory=$false,ParameterSetName='Username')]
    [Parameter(Mandatory=$false,ParameterSetName='Credential')]
    [System.Uri]
    $ArmResourceUri='https://management.core.windows.net',
    [Parameter(Mandatory=$false,ParameterSetName='Username')]
    [Parameter(Mandatory=$false,ParameterSetName='Credential')]
    [System.Uri]
    $GraphResourceUri="https://graph.windows.net",
    [Parameter(Mandatory=$true,ParameterSetName='Credential')] 
    [PSCredential]
    $Credential,
    [Parameter(Mandatory=$true,ParameterSetName='Username')]
    [String]    
    $Username,
    [Parameter(Mandatory=$true,ParameterSetName='Username')]
    [SecureString]    
    $Password,
    [Parameter(Mandatory=$false,ParameterSetName='Username')]
    [Parameter(Mandatory=$false,ParameterSetName='Credential')]
    [datetime]
    $End=[DateTime]::UtcNow.Date,
    [Parameter(Mandatory=$false,ParameterSetName='Username')]
    [Parameter(Mandatory=$false,ParameterSetName='Credential')]
    [datetime]    
    $Start=[DateTime]::UtcNow.Date.AddDays(-30),
    [Parameter(Mandatory=$false,ParameterSetName='Username')]
    [Parameter(Mandatory=$false,ParameterSetName='Credential')]
    [String]
    $OfferId="0003P",
    [Parameter(Mandatory=$false,ParameterSetName='Username')]
    [Parameter(Mandatory=$false,ParameterSetName='Credential')]
    [String]
    $Region="US",
    [Parameter(Mandatory=$false,ParameterSetName='Username')]
    [Parameter(Mandatory=$false,ParameterSetName='Credential')]
    [String]
    $Locale="en-US",
    [Parameter(Mandatory=$false,ParameterSetName='Username')]
    [Parameter(Mandatory=$false,ParameterSetName='Credential')]
    [String]
    $MetricAggregationType="Average",
    [Parameter(Mandatory=$false,ParameterSetName='Username')]
    [Parameter(Mandatory=$false,ParameterSetName='Credential')]
    [String]
    $MetricGranularity='PT1H',
    [Parameter(Mandatory=$false,ParameterSetName='Username')]
    [Parameter(Mandatory=$false,ParameterSetName='Credential')]
    [String]
    $UsageGranularity='Daily',
    [Parameter(Mandatory=$false,ParameterSetName='Username')]
    [Parameter(Mandatory=$false,ParameterSetName='Credential')]
    [Switch]
    $Usage,
    [Parameter(Mandatory=$false,ParameterSetName='Username')]
    [Parameter(Mandatory=$false,ParameterSetName='Credential')]
    [Switch]
    $Metrics,
    [Parameter(Mandatory=$false,ParameterSetName='Username')]
    [Parameter(Mandatory=$false,ParameterSetName='Credential')]
    [Switch]
    $InstanceData,
    [Parameter(Mandatory=$false,ParameterSetName='Username')]
    [Parameter(Mandatory=$false,ParameterSetName='Credential')]
    [ScriptBlock]
    $SubscriptionFilter={$_.DisplayName -ne 'Access To Azure Active Directory'},
    [Parameter(Mandatory=$false,ParameterSetName='Username')]
    [Parameter(Mandatory=$false,ParameterSetName='Credential')]
    [Switch]
    $TenantEvents,
    [Parameter(Mandatory=$false,ParameterSetName='Username')]
    [Parameter(Mandatory=$false,ParameterSetName='Credential')]
    [Switch]
    $OAuthPermissionGrants   
)

if($TenantEvents.IsPresent -and $GraphTenants -eq 'myOrganization')
{
    throw "I apologize. You must specify a tenant id to gather usage"
}

if($PSCmdlet.ParameterSetName -ne 'Credential')
{
    $Credential=New-Object PSCredential($UserName,$Password)
}

$ArmConnection=New-Object PSObject -Property @{
    ClientId=$ClientId;
    TenantId=$TenantId;
    Resource=$ArmResourceUri.AbsoluteUri;
    Credential=$Credential;
}
$GraphConnection=New-Object PSObject -Property @{
    ClientId=$ClientId;
    TenantId=$TenantId;
    Resource=$GraphResourceUri.AbsoluteUri;
    Credential=$Credential;
}
$GraphToken=Get-AzureADUserToken -ConnectionDetails $GraphConnection
$ArmToken=Get-AzureADUserToken -ConnectionDetails $ArmConnection

#Subscriptions
[SubscriptionInstance[]]$Subscriptions=Get-ArmSubscription -AccessToken $ArmToken.access_token|Where-Object -FilterScript $SubscriptionFilter

[SubscriptionSummary[]]$SubscriptionSummaries=$Subscriptions|Get-SubscriptionSummary -AccessToken $ArmToken.access_token -OfferId $OfferId `
    -Start $Start -End $End -Region $Region -Locale $Locale `
    -AggregationType $MetricAggregationType -MetricGranularity $MetricGranularity -UsageGranularity $UsageGranularity `
    -InstanceData:$InstanceData.IsPresent `
    -Usage:$Usage.IsPresent -Metrics:$Metrics.IsPresent
#AD Graph
[TenantSummary[]]$TenantSummary=Get-TenantSummary -TenantId $GraphTenants -AccessToken $GraphToken.access_token `
    -Start $Start -End $End `
    -Events:$TenantEvents.IsPresent -OAuthPermissionGrants:$OAuthPermissionGrants.IsPresent

$ReportData=@{
    RateCards=($SubscriptionSummaries|Export-SubscriptionRateCard);
    EventLogs=($SubscriptionSummaries|Export-SubscriptionEventlog);
    AdvisorRecommendations=($SubscriptionSummaries|Export-SubscriptionRecommendations);
    Resources=($SubscriptionSummaries|Export-SubscriptionResources);
    ResourceLocks=($SubscriptionSummaries|Export-SubscriptionResourceLocks);
    PolicyDefinitions=($SubscriptionSummaries|Export-SubscriptionPolicyDefinitions);
    RoleAssignments=($SubscriptionSummaries|Export-SubscriptionRoleAssignments);
    RoleDefinitions=($SubscriptionSummaries|Export-SubscriptionRoleDefinitions);
    PolicyAssignments=($SubscriptionSummaries|Export-SubscriptionPolicyAssignments);
    Groups=($TenantSummary|Export-TenantGroups);
    Roles=($TenantSummary|Export-TenantRoles);
    RoleTemplates=($TenantSummary|Export-TenantRoleTemplates);
    Users=($TenantSummary|Export-TenantUsers);
    AuditEvents=($TenantSummary|Export-TenantAuditEvents);
    SigninEvents=($TenantSummary|Export-TenantSigninEvents);
    StorageQuotaUsage=($SubscriptionSummaries|Export-SubscriptionStorageQuotaUsage);
    ComputeQuotaUsage=($SubscriptionSummaries|Export-SubscriptionComputeQuotaUsage);
}
if ($OAuthPermissionGrants.IsPresent) {
    $ReportData.Add('OauthPermissionGrants',($TenantSummary|Export-TenantOauthPermissionGrants))
}
if($Metrics.IsPresent)
{
    $ReportData.Add('ResourceMetrics',($SubscriptionSummaries|Export-SubscriptionMetricSet))
}
if($Usage.IsPresent)
{
    $ReportData.Add('ResourceUsage',($SubscriptionSummaries|Export-SubscriptionUsageAggregates))
}
$ReportResult=New-Object PSObject -Property $ReportData

Write-Output $ReportResult

