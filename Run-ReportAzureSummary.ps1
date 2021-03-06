<#PSScriptInfo

.VERSION 1.0.0.0

.GUID 4258516b-09a1-4912-b317-86178c0afcb1

.AUTHOR Matthew Quickenden

.COMPANYNAME Avanade / ACE

.COPYRIGHT 

.TAGS Report HTML Azure AD

.LICENSEURI https://github.com/azurefieldnotes/Reports

.PROJECTURI https://github.com/azurefieldnotes/Reports

.ICONURI 

.EXTERNALMODULEDEPENDENCIES AzureRM

.REQUIREDSCRIPTS 

.EXTERNALSCRIPTDEPENDENCIES 
.RELEASENOTES


#>

<# 

.DESCRIPTION 
 A report to show Meter Rates from Azure.  This is a prototype.  
#> 

#Requires –Modules AzureRM
#Requires -Modules Avanade.AzureAD
#Requires -Modules Avanade.AzureAD.Graph
#Requires -Modules Avanade.ArmTools



[CmdletBinding(DefaultParameterSetName='ReportParameters')]
param 
(
    [Parameter(Mandatory=$false,ParameterSetName='ReportParameters')]
    [string]
    $LeftLogo ='https://azurefieldnotesblog.blob.core.windows.net/wp-content/2017/02/YourLogoHere.png',
    [Parameter(Mandatory=$false,ParameterSetName='ReportParameters')]
    [string]
    $RightLogo ='https://azurefieldnotesblog.blob.core.windows.net/wp-content/2017/02/ReportHTML.png', 
    [Parameter(Mandatory=$false,ParameterSetName='ReportParameters')]
    [string]
    $reportPath,
    [Parameter(Mandatory=$false,ParameterSetName='ReportParameters')]
    [string]
    $ReportName='Azure Active Directory Report',
    [Parameter(Mandatory=$false,ParameterSetName='ReportParameters')]
    [Parameter(Mandatory=$false,ParameterSetName='ReportParametersObject')]
    [switch]
    $UseExistingData,
    [Parameter(Mandatory=$false,ParameterSetName='ReportParametersObject')]
    [PSObject]
    $ReportParameterObject
)

import-module C:\Users\matt.quickenden\Documents\GitHub\ReportHTML\ReportHTML\ReportHTML.psd1




$AzureDataScript = join-path $PSScriptRoot Get-AzureReportData.ps1
if (!($UseExistingData))
{		
	$AzureData = . $AzureDataScript -GraphTenants 'ci.avahc.com' -TenantEvents -OAuthPermissionGrants
	
} 
else
{
	Write-Warning "Using Existing Data"
}

$PortalLink = 'https://portal.azure.com/#resource'
$colourSchemes = Get-HTMLColorSchemes 
$tabHeaders = @('Advisor Recommendations','Event Logs','Policy Definitions','RBAC','Audit Events','Signin Events','Resource Locks','Oauth Permission Grants','Compute Quota Usage','Storage Quota Usage')

$rpt = @()
$rpt += Get-HTMLOpenPage -LeftLogoString $LeftLogo  -RightLogoString $RightLogo -TitleText $ReportName
$rpt += Get-HTMLTabheader $tabHeaders

#region Resource Locks
$tab = 'Resource Locks'
$rpt += Get-HTMLTabContentOpen -TabName  $tab  -TabHeading $tab 
	$rpt += Get-HTMLContentOpen -HeaderText 'Resource Lock Records'
		$rpt += Get-HTMLContentTable ($AzureData.ResourceLocks | select @{n='Resource';e={("URL01NEW" + $PortalLink + $_.Id + "URL02Goto ResourceURL03")}},Name,Level,Notes)
	$rpt += Get-HTMLContentClose	
$rpt += Get-HTMLTabContentclose
#Endregion

#region AdvisorRecommendations

$ImpactGroup = $AzureData.AdvisorRecommendations | Group Impact   
$ImpactPie = Get-HTMLPieChartObject -ColorScheme ColorScheme3
$CategoryGroup = $AzureData.AdvisorRecommendations | Group Category
$CategoryPie = Get-HTMLPieChartObject -ColorScheme Generated6

$tab = 'Advisor Recommendations'
$rpt += Get-HTMLTabContentOpen -TabName  $tab  -TabHeading $tab 
	$rpt += Get-HTMLContentOpen -HeaderText 'Advisor Recommendations'
		$rpt += Get-HTMLColumn1of2
			$rpt += Get-HTMLPieChart -ChartObject $ImpactPie -DataSet $ImpactGroup
		$rpt += Get-HTMLColumnclose
		$rpt += Get-HTMLColumn2of2
			$rpt += Get-HTMLPieChart -ChartObject $CategoryPie -DataSet $CategoryGroup
		$rpt += Get-HTMLColumnclose
		$rpt += Get-HTMLContentTable ($AzureData.AdvisorRecommendations | select Category,Impact,ResourceType,ResourceName,Risk,Problem,`
		@{n='Resource';e={("URL01NEW" + $PortalLink + $_.ResourceURI + "URL02Goto ResourceURL03")}}		) -GroupBy Category
	$rpt += Get-HTMLContentClose	
$rpt += Get-HTMLTabContentclose
#endRegion



#region Event Logs
$EventsLog = $AzureData.EventLogs
$LevelGroup = $EventsLog | Group Level   
$LevelPie = Get-HTMLPieChartObject -ColorScheme Random
$LevelPie.Size.Height =300
$EventSourceGroup = $EventsLog | Group ResourceProviderName                  
$EventSourcePie = Get-HTMLPieChartObject -ColorScheme Generated6
$EventSourcePie.Size.Height =300
$RGGroup = $EventsLog | Group ResourceGroupName         
$RGPie = Get-HTMLPieChartObject -ColorScheme ColorScheme4
$RGPie.Size.Height =300
$ChannelsGroup = $EventsLog | Group Channels                                 
$ChannelsPie = Get-HTMLPieChartObject -ColorScheme Generated7
$ChannelsPie.Size.Height =300



$tab = 'Event Logs'
$rpt += Get-HTMLTabContentOpen -TabName  $tab  -TabHeading $tab 
	$rpt += Get-HTMLContentOpen -HeaderText 'Event Logs'
		
		$rpt += Get-HTMLColumn1of2
			$rpt += Get-HTMLPieChart -ChartObject $LevelPie -DataSet $LevelGroup
		$rpt += Get-HTMLColumnclose
		$rpt += Get-HTMLColumn2of2
			$rpt += Get-HTMLPieChart -ChartObject $EventSourcePie -DataSet $EventSourceGroup
		$rpt += Get-HTMLColumnclose
		
		$rpt += Get-HTMLColumn1of2
			$rpt += Get-HTMLPieChart -ChartObject $RGPie -DataSet $RGGroup
		$rpt += Get-HTMLColumnclose
		$rpt += Get-HTMLColumn2of2
			$rpt += Get-HTMLPieChart -ChartObject $ChannelsPie -DataSet $ChannelsGroup
		$rpt += Get-HTMLColumnclose
		
		$rpt += Get-HTMLContentOpen -HeaderText 'Events by Resource Group' -IsHidden
			$rpt += Get-HTMLContentTable ($EventsLog | select  ResourceGroupName,`
				@{n='Resource';e={("URL01NEW" + $PortalLink + $_.ResourceURI + "URL02Goto ResourceURL03")}}, `
				@{n='Event';e={("URL01NEW" + $PortalLink + $_.ID + "URL02Goto EventURL03")}}, `
				ResourceProviderName,OperationName) -GroupBy ResourceGroupName      
		$rpt += Get-HTMLContentClose	
		
		$rpt += Get-HTMLContentOpen -HeaderText 'Events by ResourceProviderName' -IsHidden
			$rpt += Get-HTMLContentTable ($EventsLog | select  ResourceProviderName,`
				@{n='Resource';e={("URL01NEW" + $PortalLink + $_.ResourceURI + "URL02Goto ResourceURL03")}},`
				@{n='Event';e={("URL01NEW" + $PortalLink + $_.ID + "URL02Goto EventURL03")}}, `
				EventSource   ,ResourceGroupName, OperationName) -GroupBy ResourceProviderName   
		$rpt += Get-HTMLContentClose	
		
	$rpt += Get-HTMLContentClose	
$rpt += Get-HTMLTabContentclose
#Endregion

#region Policy Definitions
$PolicyDefinitions = $AzureData.PolicyDefinitions
$PolicyAssignments = $AzureData.PolicyAssignments

$tab = 'Policy Definitions'
$rpt += Get-HTMLTabContentOpen -TabName  $tab  -TabHeading $tab 
	$rpt += Get-HTMLContentOpen -HeaderText 'Policy Definitions' -BackgroundShade 2
		$rpt += Get-HTMLContentOpen -HeaderText 'Policy Definitions' -IsHidden
			$rpt += Get-HTMLContentTable ($PolicyDefinitions | select  DisplayName,Description ,PolicyType )
		$rpt += Get-HTMLContentClose	
		$rpt += Get-HTMLContentOpen -HeaderText 'Policy Assignments' -IsHidden
			$rpt += Get-HTMLContentTable ($PolicyAssignments | select  Name,Scope)
		$rpt += Get-HTMLContentClose	
	$rpt += Get-HTMLContentClose	
$rpt += Get-HTMLTabContentclose
#Endregion

#region RBAC
$roles= $AzureData.roles      
$groups = $AzureData.Groups
$users = $AzureData.Users
$RoleTemplates = $AzureData.RoleTemplates          
$RoleAssignments = $AzureData.RoleAssignments
$tab = 'RBAC'
$rpt += Get-HTMLTabContentOpen -TabName  $tab  -TabHeading $tab 
	$rpt += Get-HTMLContentOpen -HeaderText 'RBAC' -BackgroundShade 2
		$rpt += Get-HTMLContentOpen -HeaderText 'Groups' -IsHidden
			$rpt += Get-HTMLContentTable ($groups | select  DisplayName,ObjectType ,DirSyncEnabled,LastDirSyncTime              ) 
		$rpt += Get-HTMLContentClose
		$rpt += Get-HTMLContentOpen -HeaderText 'Users' -IsHidden
			$rpt += Get-HTMLContentTable ($users | select  DisplayName,AccountEnabled,ForceChangePasswordNextLogin ,DirSyncEnabled,LastDirSyncTime,UserPrincipalName,UserType) 
		$rpt += Get-HTMLContentClose
		$rpt += Get-HTMLContentOpen -HeaderText 'Roles' -IsHidden
			$rpt += Get-HTMLContentTable ($roles | select  DisplayName,Description ,IsSystem,	ObjectType,RoleDisabled) 
		$rpt += Get-HTMLContentClose	
		$rpt += Get-HTMLContentOpen -HeaderText 'Role Templates' -IsHidden
			$rpt += Get-HTMLContentTable ($RoleTemplates | select  DisplayName,Description ,IsSystem,	ObjectType,RoleDisabled) 
		$rpt += Get-HTMLContentClose	
		$rpt += Get-HTMLContentOpen -HeaderText 'Role Assignments' -IsHidden
			$rpt += Get-HTMLContentTable ($RoleAssignments | select PrincipalId ,RoleDefinitionId , Scope  ) 
		$rpt += Get-HTMLContentClose
	$rpt += Get-HTMLContentClose	
$rpt += Get-HTMLTabContentclose
#Endregion

#region Audit Events
$AuditEvents = $azuredata.AuditEvents

$tab = 'Audit Events'
$rpt += Get-HTMLTabContentOpen -TabName  $tab  -TabHeading $tab 
	$rpt += Get-HTMLContentOpen -HeaderText 'Audit Events' -BackgroundShade 2
		$rpt += Get-HTMLContentOpen -HeaderText 'Audit Events' -IsHidden
			$rpt += Get-HTMLContentTable ($AuditEvents )
		$rpt += Get-HTMLContentClose	
	$rpt += Get-HTMLContentClose	
$rpt += Get-HTMLTabContentclose
#Endregion

#region ComputeQuotaUsage
$ComputeQuotaUsage = $azuredata.ComputeQuotaUsage

$tab = 'Compute Quota Usage'
$rpt += Get-HTMLTabContentOpen -TabName  $tab  -TabHeading $tab 
	$rpt += Get-HTMLContentOpen -HeaderText 'Compute Quota Usage' -BackgroundShade 2
		$rpt += Get-HTMLContentOpen -HeaderText 'Compute Quota Usage' -IsHidden
			$rpt += Get-HTMLContentTable ($ComputeQuotaUsage)
		$rpt += Get-HTMLContentClose	
	$rpt += Get-HTMLContentClose	
$rpt += Get-HTMLTabContentclose
#Endregion


#region StorageQuotaUsage
$StorageQuotaUsage =$azuredata.StorageQuotaUsage

$tab = 'Storage Quota Usage'
$rpt += Get-HTMLTabContentOpen -TabName  $tab  -TabHeading $tab 
	$rpt += Get-HTMLContentOpen -HeaderText 'Storage Quota Usage' -BackgroundShade 2
		$rpt += Get-HTMLContentOpen -HeaderText 'Storage Quota Usage' -IsHidden
			$rpt += Get-HTMLContentTable ($StorageQuotaUsage)
		$rpt += Get-HTMLContentClose	
	$rpt += Get-HTMLContentClose	
$rpt += Get-HTMLTabContentclose
#Endregion


#region SigninEvents
$SigninEvents =$azuredata.SigninEvents

$tab = 'Signin Events'
$rpt += Get-HTMLTabContentOpen -TabName  $tab  -TabHeading $tab 
	$rpt += Get-HTMLContentOpen -HeaderText 'Signin Events' -BackgroundShade 2
		$rpt += Get-HTMLContentOpen -HeaderText 'Signin Events' -IsHidden
			$rpt += Get-HTMLContentTable ($StorageQuotaUsage)
		$rpt += Get-HTMLContentClose	
	$rpt += Get-HTMLContentClose	
$rpt += Get-HTMLTabContentclose
#Endregion

#region OauthPermissionGrants
$OauthPermissionGrants =$azuredata.OauthPermissionGrants

$tab = 'Oauth Permission Grants'
$rpt += Get-HTMLTabContentOpen -TabName  $tab  -TabHeading $tab 
	$rpt += Get-HTMLContentOpen -HeaderText 'Oauth Permission Grants' -BackgroundShade 2
		$rpt += Get-HTMLContentOpen -HeaderText 'Oauth Permission Grants' -IsHidden
			$rpt += Get-HTMLContentTable ($OauthPermissionGrants)
		$rpt += Get-HTMLContentClose	
	$rpt += Get-HTMLContentClose	
$rpt += Get-HTMLTabContentclose
#Endregion

$rpt += Get-HTMLClosePage
Save-HTMLReport -ReportContent $rpt -ReportPath $ReportPath -ReportName $ReportName.Replace(' ','') -ShowReport 

