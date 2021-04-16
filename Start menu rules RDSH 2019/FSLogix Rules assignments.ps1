﻿# ******************************************************
# D. Mohrmann, S&L Firmengruppe, Twitter: @mohrpheus78
# FSLogix Rule assignments 
# ******************************************************

<#
.SYNOPSIS
This script uses the FSLogix Powershell Rules module to assign predefined FSL rules to users and/or groups. The templates are based on my blog post on mycugc.org
		
.DESCRIPTION
You have to install the module from the PSGallery. The script checks whether the PSGallery is a trusted repo. Otherwise you will be asked to trust the repo and install
the module. Put the script in a directory with the rules and run the script in an elevated Powershell session. The FSLogix rules editor must be installed!

.EXAMPLE
.\FSLogix Rules assignment.ps1

.NOTES
Run as admin! If you want to use other groups then Domain Users and Domain Admins, you have to customize the script. 
The script can be used in several languages, which is important because the system accounts have different names.
In German, the name for the local service is e.g. "LOKALER DIENST".


Version:		1.0
Author:         Dennis Mohrmann <@mohrpheus78>
Creation Date:  2021-04-08
Purpose/Change:	
2021-04-08		Inital version
2021-04-10      Added notes
2021-04-15      Changed the method to find out the groups
2021-04-16      
#>

Write-Host -ForegroundColor Gray "************************"
Write-Host -ForegroundColor Gray "FSLogix Rules Assignment"
Write-Host -ForegroundColor Gray "************************"
Write-Host ""

# Import/Istall FSL Rules module
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
IF (!(Get-Module -ListAvailable -Name FSLogix.PowerShell.Rules))
    {
        Write-Host -ForegroundColor Yellow "FSLogix Rules Powershell Module not installed!"
		$PSGallery =(Get-PSRepository -Name PSGallery).InstallationPolicy
        IF ($PSGallery -eq "Untrusted")
            {
            Write-Host -ForegroundColor Yellow "Unable to install the module, because PSGallery repository in not a trusted repo! Do you want to trust the PSGallery repo?"
            $Q = Read-Host "( Y / N )" 
	        IF ($Q -eq 'Y')
                {
                    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
                }
            ELSE {
                Write-Host -ForegroundColor Red "Aborted by the user!"
                BREAK
                 }    
	        }
    }

IF (!(Get-Module -ListAvailable -Name FSLogix.PowerShell.Rules))
{
    Install-Module FSLogix.PowerShell.Rules -Force | Import-Module FSLogix.PowerShell.Rules
}



# Define system accounts locale
$NETWORK = ((New-Object System.Security.Principal.SecurityIdentifier ('S-1-5-2')).Translate( [System.Security.Principal.NTAccount])).Value
$NETWORKSERVICE = ((New-Object System.Security.Principal.SecurityIdentifier ('S-1-5-20')).Translate( [System.Security.Principal.NTAccount])).Value
$LOCALSERVICE = ((New-Object System.Security.Principal.SecurityIdentifier ('S-1-5-19')).Translate( [System.Security.Principal.NTAccount])).Value
$SYSTEM = ((New-Object System.Security.Principal.SecurityIdentifier ('S-1-5-18')).Translate( [System.Security.Principal.NTAccount])).Value

# Define Domain group locale
[string] $krbtgtSID = (New-Object Security.Principal.NTAccount $env:userdomain\krbtgt).Translate([Security.Principal.SecurityIdentifier]).Value
$DomSID = $krbtgtSID.SubString(0, $krbtgtSID.LastIndexOf('-'))
$DomUsers = (Get-WmiObject -Query 'Select * FROM Win32_Group' | Where-Object {$_.SID -eq "$DomSID-513"}).Name
$DomAdmins = (Get-WmiObject -Query 'Select * FROM Win32_Group' | Where-Object {$_.SID -eq "$DomSID-512"}).Name

# Import PS module
Import-Module FSLogix.PowerShell.Rules

# Startmenü Layout Rule 
Add-FslAssignment -Path "$PSScriptRoot\Startmenu-Layout-Users.fxa" -WellKnownSID S-1-5-21domain-513 -GroupName "$env:USERDOMAIN\$DomUsers" -RuleSetApplies
Add-FslAssignment -Path "$PSScriptRoot\Startmenu-Layout-Users.fxa" -WellKnownSID S-1-5-21domain-512 -GroupName "$env:USERDOMAIN\$DomAdmins"

# Startmenü items Rule 
Add-FslAssignment -Path "$PSScriptRoot\Startmenu-Items.fxa" -WellKnownSID S-1-5-21domain-513 -GroupName "$env:USERDOMAIN\$DomUsers"
Add-FslAssignment -Path "$PSScriptRoot\Startmenu-Items.fxa" -WellKnownSID S-1-5-21domain-512 -GroupName "$env:USERDOMAIN\$DomAdmins" -RuleSetApplies

# Startmenü Win-X Admin Rule
Add-FslAssignment -Path "$PSScriptRoot\Startmenu-WinX-Admins.fxa" -WellKnownSID S-1-5-21domain-513 -GroupName "$env:USERDOMAIN\$DomUsers"
Add-FslAssignment -Path "$PSScriptRoot\Startmenu-WinX-Admins.fxa" -WellKnownSID S-1-5-21domain-512 -GroupName "$env:USERDOMAIN\$DomAdmins" -RuleSetApplies

# Startmenü Win-X User Rule
Add-FslAssignment -Path "$PSScriptRoot\Startmenu-WinX-Users.fxa" -WellKnownSID S-1-5-21domain-513 -GroupName "$env:USERDOMAIN\$DomUsers" -RuleSetApplies
Add-FslAssignment -Path "$PSScriptRoot\Startmenu-WinX-Users.fxa" -WellKnownSID S-1-5-21domain-512 -GroupName "$env:USERDOMAIN\$DomAdmins"

# Startmenü Windows-Sicherheit Rule
Add-FslAssignment -Path "$PSScriptRoot\Windows Security-Startmenu.fxa" -WellKnownSID S-1-5-21domain-513 -GroupName "$env:USERDOMAIN\$DomUsers" -RuleSetApplies
Add-FslAssignment -Path "$PSScriptRoot\Windows Security-Startmenu.fxa" -WellKnownSID S-1-5-21domain-512 -GroupName "$env:USERDOMAIN\$DomAdmins"
Add-FslAssignment -Path "$PSScriptRoot\Windows Security-Startmenu.fxa" -WellKnownSID S-1-5-2 -GroupName "$NETWORK"
Add-FslAssignment -Path "$PSScriptRoot\Windows Security-Startmenu.fxa" -WellKnownSID S-1-5-20 -GroupName "$NETWORKSERVICE"
Add-FslAssignment -Path "$PSScriptRoot\Windows Security-Startmenu.fxa" -WellKnownSID S-1-5-18 -GroupName "$SYSTEM"
Add-FslAssignment -Path "$PSScriptRoot\Windows Security-Startmenu.fxa" -WellKnownSID S-1-5-18 -GroupName "$LOCALSERVICE"