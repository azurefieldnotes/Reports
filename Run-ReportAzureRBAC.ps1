#Requires –Modules AzureRM
#Requires –Modules ReportHTML
#Requires -Modules AzureRMHelpers

param
(
    $LeftLogo,
    $RightLogo, 
    $reportPath,
    $ReportName='AzureRBAC',
    [switch]$ReloadData
)



Test-AzureRmAccountTokenExpiry

if ($ReloadData) {
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
$rpt += Get-HTMLOpenPage
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


if ([string]::IsNullOrEmpty($reportPath)) {
    Save-HTMLReport -ReportContent $rpt -ReportPath $ReportPath -ReportName $ReportName -ShowReport 
}
else
{
    Save-HTMLReport -ReportContent $rpt -ReportName $ReportName -ShowReport 
}

