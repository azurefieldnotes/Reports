<#PSScriptInfo

.VERSION 1.0.0.5

.GUID 2b32a6b1-3ba3-4b6c-a4dd-2c3f09f2f835

.AUTHOR Matthew Quickenden

.COMPANYNAME Avanade / ACE

.COPYRIGHT meh

.TAGS Report HTML Azure RBAC

.LICENSEURI https://github.com/azurefieldnotes/Reports

.PROJECTURI https://github.com/azurefieldnotes/Reports

.ICONURI https://azurefieldnotesblog.blob.core.windows.net/wp-content/2017/02/RBAC.jpg

.EXTERNALMODULEDEPENDENCIES AzureRM

.REQUIREDSCRIPTS 

.EXTERNALSCRIPTDEPENDENCIES 
.RELEASENOTES


#>

<# 

.DESCRIPTION 
 A report to show RBAC from Azure.  This is a prototype.  
#> 

#Requires –Modules AzureRM
#Requires –Modules ReportHTML
#Requires -Modules ReportHTMLHelpers

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
    $ReportName='AzureRBAC',
    [Parameter(Mandatory=$false,ParameterSetName='ReportParameters')]
    [Parameter(Mandatory=$false,ParameterSetName='ReportParametersObject')]
    [switch]
    $UseExistingData,
    [Parameter(Mandatory=$false,ParameterSetName='ReportParametersObject')]
    [PSObject]
    $ReportParameterObject
)

Test-AzureRmAccountTokenExpiry

if ($UseExistingData) 
{
    Write-Warning "Reusing the data, helpful when developing the report"
} 
else 
{
    $RoleDefinitions = Get-AzureRmRoleDefinition 
    $AssignedRoles = Get-AzureRmRoleAssignment 
    $AzureUsers = $AssignedRoles | select SignInName -Unique
    $GroupAssignedRoles = $AssignedRoles  | group DisplayName 

    $ResourceGroups = Get-AzureRmResourceGroup 
    $i=0;$Records = $ResourceGroups.Count
    $RGRoleAssignments = @()
    foreach ($RG in $ResourceGroups ) {
        Write-Progress -PercentComplete ($i/$Records *100) -Activity "Getting role assignments from Resource Groups"
        $RGRoleAssignment = '' | select ResourceGroup, RoleAssignment  
        $RGRoleAssignment.ResourceGroup = $rg.ResourceGroupName
        $RGRoleAssignment.RoleAssignment  = Get-AzureRmRoleAssignment -ResourceGroupName $RG.ResourceGroupName | select DisplayName, RoleDefinitionName, Scope
        $RGRoleAssignments += $RGRoleAssignment
        $I++
    }

    $UserAssignedRBAC = @()
    foreach ($AzureUser in ($AzureUsers | ? {$_.SignInName -ne $null}) ) {
        $UserAssignedRBAC  += Get-AzureRmRoleAssignment -SignInName $AzureUser.SignInName | Select DisplayName, RoleDefinitionName, Scope
        #GROUP... $UserAssignedRBAC  += Get-AzureRmRoleAssignment -SignInName $AzureUser.SignInName -ExpandPrincipalGroups | FL DisplayName, RoleDefinitionName, Scope
    }
    $GroupedUserAssignedRBAC = $UserAssignedRBAC | group DisplayName
}


$rpt = @()
$rpt += Get-HTMLOpenPage -LeftLogoString $LeftLogo  -RightLogoString $RightLogo -TitleText $ReportName
    $rpt += Get-HTMLContentOpen -HeaderText RoleDefinitions -IsHidden    
        #$Roles = Get-HTMLAnchorLink -AnchorName $_.name.replace(' ','') -AnchorText $_.name
        $rpt += Get-HTMLContentTable ($RoleDefinitions | select Name, Description, IsCustom)
    $rpt += Get-HTMLContentClose
    $rpt += Get-HTMLContentOpen -HeaderText ("RBAC Role Definitions") -BackgroundShade 2 -IsHidden
     
        foreach ($RoleDefinition in $RoleDefinitions ) {
            
            $rpt +=  Get-HTMLContentOpen -HeaderText $RoleDefinition.Name  -BackgroundShade 1 -Anchor ($RoleDefinition.Name.Replace(' ','')) -IsHidden
                $rpt +=  Get-HTMLContenttext -Heading "Description" -Detail $RoleDefinition.Description 
                $rpt +=  Get-HTMLContentOpen -HeaderText "actions" 
                   $ofs = "<BR>" 
                   $actions = ([string]$RoleDefinition.Actions)
                   $Nonactions = ([string]$RoleDefinition.NotActions)
                    $ofs = "" 
                    $rpt +=  Get-HTMLContenttext -Heading "Actions" -Detail $Actions
                    $rpt +=  Get-HTMLContenttext -Heading "Not Actions" -Detail $Nonactions
                $rpt +=  get-htmlcontentclose
            $rpt +=  get-htmlcontentclose
        }
    $rpt += Get-HTMLContentClose
    
    $rpt +=  Get-HTMLContentOpen -HeaderText "Resource Groups & Roles" -BackgroundShade 2 -IsHidden
    foreach ($RGRole in $RGRoleAssignments) {
        $rpt +=  Get-HTMLContentOpen -HeaderText $RGRole.ResourceGroup -BackgroundShade 1 -IsHidden
            $rpt += Get-HTMLContentTable ($RGRole.RoleAssignment  | select DisplayName, RoleDefinitionName)
        $rpt += get-htmlcontentclose
    }
    $rpt += get-htmlcontentclose

    $rpt +=  Get-HTMLContentOpen -HeaderText "User Assigned Roles" -BackgroundShade 1 -IsHidden
        $rpt += get-htmlcontenttable ($UserAssignedRBAC) -GroupBy    displayname
    $rpt += get-htmlcontentclose
$rpt += get-htmlclosepage


Save-HTMLReport -ReportContent $rpt -ReportPath $ReportPath -ReportName $ReportName -ShowReport 
