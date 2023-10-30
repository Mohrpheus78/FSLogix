#######################################################################
# D. Mohrmann, 30.10.2023
# Delete folders from FSLogix profile you added to redirection.xml
#######################################################################

<#
.SYNOPSIS
Delete folders you added to the redirections.xml but are already inside the user profile disk
		
.DESCRIPTION
		
.EXAMPLE
	    
.NOTES
Place the script inside the folder where the redirections.xml is located and enter the path the the users profile disks
#>


# Root Verfolder for FSL profiles
$VHDRootFolder = "D:\FSLogix\Profiles"

# Order, deren Inhalt gelöscht werden soll

[XML]$xml = Get-Content "$PSScriptRoot\redirections.xml"
$SelectedValues = $xml.FrxProfileFolderRedirection.Excludes.Exclude | Where-Object { $_."#text" -like "AppData*" } | Select-Object -ExpandProperty "#text"

$Folders = @(
	$SelectedValues
)

Function Set-AlternatingRows {
    [CmdletBinding()]
   	Param(
       	[Parameter(Mandatory,ValueFromPipeline)]
        [string]$Line,
       
   	    [Parameter(Mandatory)]
       	[string]$CSSEvenClass,
       
        [Parameter(Mandatory)]
   	    [string]$CSSOddClass
   	)
	Begin {
		$ClassName = $CSSEvenClass
	}
	Process {
		If ($Line.Contains("<tr><td>"))
		{	$Line = $Line.Replace("<tr>","<tr class=""$ClassName"">")
			If ($ClassName -eq $CSSEvenClass)
			{	$ClassName = $CSSOddClass
			}
			Else
			{	$ClassName = $CSSEvenClass
			}
		}
		Return $Line
	}
}

function checkFileStatus($filePath)
    {
            $fileInfo = New-Object System.IO.FileInfo $filePath

        try 
        {
            $fileStream = $fileInfo.Open( [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read )
            $filestream.Close()
            return $false
        }
        catch
        {
            
            return $true
        }
    }

function Get-NextFreeDriveLetter {
 
    [CmdletBinding()]
    param (
        [string[]]$ExcludeDriveLetter = ('A-F', 'Z'), # Laufwerke ausschließen, die nicht verwendet werden sollen
 
        [switch]$Random,
 
        [switch]$All
    )
    
    $Drives = Get-ChildItem -Path Function:[a-z]: -Name
 
    if ($ExcludeDriveLetter) {
        $Drives = $Drives -notmatch "[$($ExcludeDriveLetter -join ',')]"
    }
 
    if ($Random) {
        $Drives = $Drives | Get-Random -Count $Drives.Count
    }
 
    if (-not($All)) {
        
        foreach ($Drive in $Drives) {
            if (-not(Test-Path -Path $Drive)){
                return $Drive
            }
        }
 
    }
    else {
        Write-Output $Drives | Where-Object {-not(Test-Path -Path $_)}
    }
}

function vhdmount($v) {
	try {
		$VHDNumber = Mount-DiskImage -ImagePath $v -NoDriveLetter -Passthru -ErrorAction Stop | Get-DiskImage
		$partition = Get-Partition -DiskNumber $VHDNumber.Number
		Set-Partition -PartitionNumber $partition.PartitionNumber -DiskNumber $VHDNumber.Number -NewDriveLetter $FreeDrive
		return "0"
	} catch {
		return "1"
	}
}
function vhdoptimize($v) {
try {
	foreach ($folder in $folders) {
		 if (Test-Path -Path $ProfileRoot\$folder -PathType Container) {
			Get-ChildItem -Path $ProfileRoot\$folder | Remove-Item -Recurse -Force -EA SilentlyContinue
			Write-Host "Content from '$ProfileRoot\$folder' deleted!"
		} else {
			Write-Host "'$ProfileRoot\$folder' doesn't exists or ist not a folder!"
		}
	}


$r = 0
} catch {
$r = 1
}
}

function vhddismount($v) {
try {
	Dismount-DiskImage $v -ErrorAction stop
	return "0"
} catch {
	return "1"
}
}

# Get the next free drive letter to mount the profile disk
$FreeDrive = Get-NextFreeDriveLetter 
$FreeDrive = $FreeDrive -replace ".$" 
$ProfileRoot = ($FreeDrive + ":" + "\" + 'Profile')

$vhds = (get-childitem $VHDRootFolder -recurse -Include *.vhd,*.vhdx).fullname 
[System.Collections.ArrayList]$info = @()
$t = 0
foreach ($vhd in $vhds) {
$locked = checkFileStatus -filePath $vhd
if ($locked -eq $true) {
"$vhd in use, skipping."
continue
}
Write-Host -Foregroundcolor Yellow "Mounting '$vhd'"
Write-Host `n
$mount = vhdmount -v $vhd
if ($mount -eq "1") {
$e = "Mounting $vhd failed "+(get-date).ToString()
break
}
$info.add((vhdoptimize -v $vhd)) | Out-Null
$dismount = vhddismount -v $vhd
if ($dismount -eq "1") {
$e = "Failed to dismount $vhd "+(get-date).ToString()
break
}
}

Write-Host `n
Read-Host "Press a key to exit"
