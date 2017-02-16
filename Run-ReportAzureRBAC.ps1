#Login-AzureRmAccount 
#Import-Module azurerm
#Import-Module ReportHTML

#$RoleDefinitions = Get-AzureRmRoleDefinition 

 
#$AssignedRoles = Get-AzureRmRoleAssignment | group DisplayName 


$ResourceGroups = Get-AzureRmResourceGroup | select -First 10
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


$rpt = @()
$rpt += Get-HTMLOpenPage
    $rpt += Get-HTMLContentOpen -HeaderText RoleDefinitions -IsHidden
        
        #$Roles = Get-HTMLAnchorLink -AnchorName $_.name.replace(' ','') -AnchorText $_.name
        $rpt += Get-HTMLContentTable ($RoleDefinitions )
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
$rpt += get-htmlclosepage

Save-HTMLReport -ReportContent $rpt -ShowReport


#Get-AzureRmRoleAssignment -SignInName sameert@aaddemo.com | FL DisplayName, RoleDefinitionName, Scope

#Get-AzureRmRoleAssignment -SignInName sameert@aaddemo.com -ExpandPrincipalGroups | FL DisplayName, RoleDefinitionName, Scope
