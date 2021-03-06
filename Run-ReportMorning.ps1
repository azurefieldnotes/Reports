
#requires -version 2.0

<#
 -----------------------------------------------------------------------------
 Script: MorningReport.ps1
 Version: 1.0
 Author: Jeffery Hicks
    http://jdhitsolutions.com/blog
    http://twitter.com/JeffHicks
    http://www.ScriptingGeek.com
 Date: 1/9/2012
 Keywords:
 Comments:

 Prepare a morning system status report

 "Those who forget to script are doomed to repeat their work."

  ****************************************************************
  * DO NOT USE IN A PRODUCTION ENVIRONMENT UNTIL YOU HAVE TESTED *
  * THOROUGHLY IN A LAB ENVIRONMENT. USE AT YOUR OWN RISK.  IF   *
  * YOU DO NOT UNDERSTAND WHAT THIS SCRIPT DOES OR HOW IT WORKS, *
  * DO NOT USE IT OUTSIDE OF A SECURE, TEST SETTING.             *
  ****************************************************************
 -----------------------------------------------------------------------------
 #>
 
<#
.Synopsis
Create System Report
.Description
Create a system status report with information gathered from WMI. The 
default output are pipelined objects. But you can also use -TEXT to write
a formatted text report, suitable for sending to a file or printer, or 
-HTML to create HTML code. You will need to pipe the results to Out-File 
if you want to save it.
.Parameter Computername
The name of the computer to query. The default is the localhost.
.Parameter ReportTitle
The title for your report. This parameter has an alias of 'Title'.
.Parameter Hours
The number of hours to search for errors and warnings. 
The default is 24.
.Parameter HTML
Create HTML report. You must pipe to Out-File to save the results.
.Parameter Text
Create a formatted text report
.Example
PS C:\Scripts\> .\MorningReport | Export-Clixml ("c:\work\{0:yyyy-MM-dd}_{1}.xml" -f (get-date),$env:computername)
Preparing morning report for SERENITY
...Operating System
...Computer System
...Services
...Logical Disks
...Network Adapters
...System Event Log Error/Warning since 01/09/2012 09:47:26
...Application Event Log Error/Warning since 01/09/2012 09:47:26

Run a morning report and export it to an XML file with a date stamped file name.
.Example
PS C:\Scripts\> .\MorningReport Quark -Text | Out-file c:\work\quark-report.txt
Run a morning report for a remote computer and save the results to an text file.
.Example
PS C:\Scripts\> .\MorningReport -html -hours 30 | Out-file C:\work\MyReport.htm
Run a morning report for the local computer and get last 30 hours of event log information. Save as an HTML report.
.Link
http://jdhitsolutions.com/blog/2012/01/the-powershell-morning-report/
.Link
Get-WMIObject
ConvertTo-HTML
.Inputs
String
.Outputs
Custom object, text or HTML code
#>

[cmdletbinding(DefaultParameterSetName="object")]

Param(
[Parameter(Position=0,ValueFromPipeline=$True)]
[ValidateNotNullOrEmpty()]
[string]$Computername=$env:computername,
[ValidateNotNullOrEmpty()]
[alias("title")]
[string]$ReportTitle="System Report",
[ValidateScript({$_ -ge 1})]
[int]$Hours=1,
$ReportOutputPath
)

#script internal version number used in output
[string]$reportVersion="1.0.8"

#region ReportHelpers
Function Test-Report 
{
	param (
		$TestName,
		$HTMLReport,
		$ReportPath
	)
	if ($ReportPath -eq $null -or $ReportPath -eq '') {$ReportOutputPath  = $env:temp}
	if ($TestName -eq $null -or $TestName -eq '') {$TestName = 'random'}
	$rptFile = join-path $ReportOutputPath ($TestName.replace(" ","") + "-$TestName" + ".mht")
	$HTMLReport | Set-Content -Path $rptFile -Force
   	sleep 1
   	Invoke-Item $rptFile
}

Function Import-ReportHTML {
Param (
	[Version]$version
)
	try {Import-Module ReportHtml}
	catch {Write-error "Install ReportHTML module.  Install-module -name ReportHTML. Details here http://www.azurefieldnotes.com/2016/08/04/powershellhtmlreportingpart1/"}
	finally {
		$RMV= (get-module | ? {$_.name -eq 'ReportHTML'}).version 
		if ($RMV -ge $version) {
			Write-Output "ReportHTML module Version $RMV found"
		} else {
			write-output "Pretty please update the ReportHTML module.  Update-module -name ReportHTML"
		}
	}
}
#endregion
Import-ReportHTML -version '1.0.0.13'

#Region Logos
#convert required image to Base64 and put strings here
$Logo1 = "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"
$logo2 = "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"
#endregion
if (!$ReportOutputPath)  {$ReportOutputPath = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent} 



If ($computername -eq $env:computername) {
 #local computer so no ping test is necessary
 $OK=$True
}
elseIf (($computername -ne $env:computername) -AND (Test-Connection -ComputerName $computername -quiet -Count 2)) {
 #not local computer and it can be pinged so proceed
 $OK=$True
}

If ($OK) {

    Try {
        $os=Get-WmiObject Win32_operatingSystem -ComputerName $computername -ErrorAction Stop
        #set a variable to indicate WMI can be reached
        $wmi=$True
    }
    Catch {
        Write-Warning "WMI failed to connect to $($computername.ToUpper())"
    }
    
    if ($wmi) {
        Write-Host "Preparing morning report for $($os.CSname)" -ForegroundColor Cyan

        #OS Summary
        Write-Host "...Operating System" -ForegroundColor Cyan
        $osdata=$os | Select @{Name="Computername";Expression={$_.CSName}},
        @{Name="OS";Expression={$_.Caption}},
        @{Name="ServicePack";Expression={$_.CSDVersion}},
        free*memory,totalv*,NumberOfProcesses,
        @{Name="LastBoot";Expression={$_.ConvertToDateTime($_.LastBootupTime)}},
        @{Name="Uptime";Expression={(Get-Date) - ($_.ConvertToDateTime($_.LastBootupTime))}}
        
        #Computer system
        Write-Host "...Computer System" -ForegroundColor Cyan
        $cs=Get-WmiObject -Class Win32_Computersystem -ComputerName $computername
        $csdata=$cs | Select Status,Manufacturer,Model,SystemType,Number*
        
        #services
        Write-Host "...Services" -ForegroundColor Cyan
        #get services via WMI and group into a hash table
        $wmiservices=Get-WmiObject -class Win32_Service -ComputerName $computername    
        $services=$wmiservices | Group State -AsHashTable 
        
        #get services set to auto start that are not running
        $failedAutoStart=$wmiservices | Where { ($_.startmode -eq "Auto") -AND ($_.state -ne "Running")} 
        
        #Disk Utilization
        Write-Host "...Logical Disks" -ForegroundColor Cyan
        $disks=Get-WmiObject -Class Win32_logicaldisk -Filter "Drivetype=3" -ComputerName $computername
        $diskData=$disks | Select DeviceID,
        @{Name="SizeGB";Expression={$_.size/1GB -as [int]}},
        @{Name="FreeGB";Expression={"{0:N2}" -f ($_.Freespace/1GB)}},
        @{Name="PercentFree";Expression={"{0:P2}"  -f ($_.Freespace/$_.Size)}}
        
        #NetworkAdapters
        Write-Host "...Network Adapters" -ForegroundColor Cyan
        #get NICS that have a MAC address only
        $nics=Get-WmiObject -Class Win32_NetworkAdapter -filter "MACAddress Like '%'" -ComputerName $Computername
        $nicdata=$nics | Foreach {
         $tempHash=@{Name=$_.Name;DeviceID=$_.DeviceID;AdapterType=$_.AdapterType;MACAddress=$_.MACAddress}
         #get related configuation information
         $config=$_.GetRelated() | where {$_.__CLASS -eq "Win32_NetworkadapterConfiguration"}
         #add to temporary hash
         $tempHash.Add("IPAddress",$config.IPAddress)
         $tempHash.Add("IPSubnet",$config.IPSubnet)
         $tempHash.Add("DefaultGateway",$config.DefaultIPGateway)
         $tempHash.Add("DHCP",$config.DHCPEnabled)
         #convert lease information if found
         if ($config.DHCPEnabled -AND $config.DHCPLeaseObtained) {
            $tempHash.Add("DHCPLeaseExpires",($config.ConvertToDateTime($config.DHCPLeaseExpires)))
            $tempHash.Add("DHCPLeaseObtained",($config.ConvertToDateTime($config.DHCPLeaseObtained)))
            $tempHash.Add("DHCPServer",$config.DHCPServer)
         }
         
         New-Object -TypeName PSObject -Property $tempHash
         
         }

        #Event log errors and warnings in the last $Hours hours
        $last=(Get-Date).AddHours(-$Hours)
        #System Log
        Write-Host "...System Event Log Error/Warning since $last" -ForegroundColor Cyan
        $syslog=Get-EventLog -LogName System -ComputerName $computername -EntryType Error,Warning -After $last
        $syslogdata=$syslog | Select TimeGenerated,EventID,Source,Message
        
        #Application Log
        Write-Host "...Application Event Log Error/Warning since $last" -ForegroundColor Cyan
        $applog=Get-EventLog -LogName Application -ComputerName $computername -EntryType Error,Warning -After $last
        $applogdata=$applog | Select TimeGenerated,EventID,Source,Message
        
    } #if wmi is ok
 }   
    #write results depending on parameter set
    $footer="Report v{3} run {0} by {1}\{2}" -f (Get-Date),$env:USERDOMAIN,$env:USERNAME,$reportVersion
    
$rpt = @()
$rpt += get-htmlopen -TitleText $ReportTitle
        
     #insert navigation bookmarks
$nav = @() 
$nav += (get-HTMLAnchorLink -AnchorName 'System Summary') + ' | '
$nav += (get-HTMLAnchorLink -AnchorName 'Services') + ' | '
$nav += (get-HTMLAnchorLink -AnchorName 'Failed Auto Start') + ' | '
$nav += (get-HTMLAnchorLink -AnchorName 'Disks') + ' | '
$nav += (get-HTMLAnchorLink -AnchorName 'Network') + ' | '
$nav += (get-HTMLAnchorLink -AnchorName 'System Log') + ' | '
$nav += (get-HTMLAnchorLink -AnchorName 'Application Log')

$rpt += $nav
$rpt += Get-HtmlContentOpen -HeaderText 'System Summary'
$rpt += get-HTMLContentTableVertical $osdata 
$rpt += Get-HtmlContentTable -Fixed -ArrayOfObjects $csdata 
$rpt += Get-HtmlContentClose
$rpt += $nav
$rpt += Get-HtmlContentOpen -HeaderText Services -IsHidden
$rpt += Get-HtmlContenttable ($services.Keys | % { $services.$_ | Select State, Name,Displayname,State,StartMode} | sort Name ) -GroupBy State
$rpt += Get-HtmlContentclose
$rpt += $nav
$rpt += Get-HtmlClose


#
#$fragments+=ConvertTo-Html -Fragment -PreContent "<H2><a name='Services'>Services</a></H2>"
#        $services.keys | foreach {
#         $fragments+= ConvertTo-Html -Fragment -PreContent "<H3>$_</H3>"
#         $fragments+=$services.$_ | Select Name,Displayname,StartMode| ConvertTo-HTML -Fragment
#         #insert navigation link after each section
#         $fragments+=$nav
#        } 
#               
#        $fragments+=$failedAutoStart | Select Name,Displayname,StartMode,State | 
#         ConvertTo-Html -Fragment -PreContent "<h3><a name='NoAutoStart'>Failed Auto Start</a></h3>"
#         $fragments+=$nav
#        
#        $fragments+=$diskdata | ConvertTo-HTML -Fragment -PreContent "<H2><a name='Disks'>Disk Utilization</a></H2>"
#        $fragments+=$nav
#        
#        #convert nested object array properties to strings
#        $fragments+=$nicdata | Select Name,DeviceID,DHCP*,AdapterType,MACAddress,
#         @{Name="IPAddress";Expression={$_.IPAddress | Out-String}},
#         @{Name="IPSubnet";Expression={$_.IPSubnet | Out-String}},
#         @{Name="IPGateway";Expression={$_.DefaultGateway | Out-String}}  |
#          ConvertTo-HTML -Fragment -PreContent "<H2><a name='Network'>Network Adapters</a></H2>"
#        $fragments+=$nav
#        
#        $fragments+=$syslogData | ConvertTo-HTML -Fragment -PreContent "<H2><a name='SysLog'>System Event Log Summary</a></H2>"
#        $fragments+=$nav
#        
#        $fragments+=$applogData | ConvertTo-HTML -Fragment -PreContent "<H2><a name='AppLog'>Application Event Log Summary</a></H2>"
#        $fragments+=$nav
#                
#        Write $fragments | clip
#        ConvertTo-Html -Head $head -Title $ReportTitle -PreContent ($fragments | out-String) -PostContent "<br><I>$footer</I>"
#    }
#    elseif ($TEXT) {
#        #prepare formatted text
#        $ReportTitle
#        "-"*($ReportTitle.Length)
#        "System Summary"
#        $osdata | Out-String
#        $csdata | format-List | Out-String
#        Write "Services"
#        $services.keys | foreach {
#         $services.$_ | Select Name,Displayname,StartMode,State
#        } | Format-List | Out-String
#        Write "Failed Autostart Services"
#        $failedAutoStart | Select Name,Displayname,StartMode,State
#        Write "Disk Utilization"
#        $diskdata | Format-table -AutoSize | Out-String
#        Write "Network Adapters"
#        $nicdata | Format-List | Out-String
#        Write "System Event Log Summary"
#        $syslogdata | Format-List | Out-String
#        Write "Application Event Log Summary"
#        $applogdata | Format-List | Out-String
#        Write $Footer
#    }
#    else {
#        #Write data to the pipeline as part of a custom object
#               
#        New-Object -TypeName PSObject -Property @{
#         OperatingSystem=$osdata
#         ComputerSystem=$csdata
#         Services=$services.keys | foreach {$services.$_ | Select Name,Displayname,StartMode,State}
#         FailedAutoStart=$failedAutoStart | Select Name,Displayname,StartMode,State
#         Disks=$diskData
#         Network=$nicData
#         SystemLog=$syslogdata
#         ApplicationLog=$applogdata
#         ReportVersion=$reportVersion
#         RunDate=Get-Date
#         RunBy="$env:USERDOMAIN\$env:USERNAME"
#        }
#    }
#    
#} #if OK
#
#else {
#    #can't ping computer so fail
#    Write-Warning "Failed to ping $computername"
#}
Test-Report -HTMLReport $rpt  -TestName $ReportTitle.Replace(' ','')
##end of script