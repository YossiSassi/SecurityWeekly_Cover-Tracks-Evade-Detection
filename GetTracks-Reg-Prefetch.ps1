#Profiles
Get-ChildItem $env:userprofile\.. | select fullname

#profiles/SIDs from registry
get-childitem "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList" | select -ExpandProperty name

#Profile folders from registry (even if profile was deleted)
get-childitem "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList" | foreach {
    $d="HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\"+$_.pschildname; Get-ItemProperty -Path $d -Name ProfileImagePath | select ProfileImagePath}

#MRU /Terminal services
#current user
Get-ChildItem "HKCU:\Software\Microsoft\Terminal Server Client\Servers" -Recurse | select PSChildName

#Terminal services
#For all other users
$Profiles=(Get-ChildItem $env:userprofile\.. | select fullname)
$Profiles | foreach {
{
  $f=$_.FullName
  if ($f -ne $env:userprofile)
  {
    write-host "Checking $f..."
    reg load HKLM\Temp $f\ntuser.dat >$null
    if(Test-Path "HKLM:\TempTemp\Software\Microsoft\Terminal Server Client\Servers")
    {
        Get-ChildItem "HKLM:\TempTemp\Software\Microsoft\Terminal Server Client\Servers" -Recurse | select PSChildName
        }  
        [gc]::Collect()
        reg unload HKLM\TempTemp > $null
        }
    }
}

#RunMRU (win+R)
Get-ItemProperty -path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU"

#mmc
Get-ItemProperty -path "HKCU:\Software\Microsoft\Microsoft Management Console\Recent File List"

#paint
Get-ItemProperty -path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Applets\Paint\Recent File List"

#recent
$d=(Get-ItemProperty -path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" -name recent | select recent).recent
Get-ChildItem $d | Sort-Object lastwritetime

# Last Registry key the current user accessed
(Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Applets\Regedit\").lastkey

#prefetch
#enabled?
$pf=(Get-ItemProperty -path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" -name EnablePrefetcher).EnablePrefetcher
write-host $pf
switch ($pf) {
  0 {"prefetching disabled"}
  1 {"Prefetch enabled for application launch only"}
  2 {"Prefetch enabled for boot only"}
  3 {"Prefetch enabled (Default/optimal setting)"}#Note: not needed for SSD, performance-wise
}

#Check out prefetch folder
Get-ChildItem $env:windir\prefetch\

#Analyze content 
# Get WinPrefetchView.exe by NirSoft from https://www.nirsoft.net/utils/win_prefetch_view.html
Set-Location C:\temp
$proc = start cmd -ArgumentList '/c .\WinPrefetchView.exe /scomma "c:\temp\pf_data.txt"' -PassThru
$proc.WaitForExit()
$data = @();$data += 'FileName,CreatedTime,ModifiedTime,FileSize,ProcessEXE,ProcessPath,RunCounter,LastRun,MissingProcess'
$data += cat .\pf_data.txt
"total of $((cat .\pf_data.txt).count) entries found"
$data | Set-Content .\pf_data.txt; sleep -Milliseconds 500
$data = import-csv .\pf_data.txt
$data | where missingprocess -eq "yes"
$data | where missingprocess -eq "yes" | ft FileName,RunCounter -AutoSize 

# Where PowerShell execution policies Set? (Bypass script issue)
Get-WinEvent -FilterHashtable @{logname='Microsoft-Windows-PowerShell/Operational';id=4104;level=3} | 
where message -like "*Set-executionpolicy*" | 
foreach {$_ | select TimeCreated, LevelDisplayName, @{n='SetExecCommand';e={(([xml]($_).ToXml()).Event.EventData.Data.'#text')[2]}}}

# check MSconfig items - startup commands, autoruns, run once
function Get-RegKeyProperties {
param ([string]$RegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run")

$CurrentEAP = $ErrorActionPreference; $ErrorActionPreference = 'silentlycontinue'

# get actual registry values from path
$Values = Get-ItemProperty -Path $RegPath
 
# exclude default properties
$default = 'PSChildName','PSDrive','PSParentPath', 'PSPath','PSProvider'
 
# each value surfaces as object property
# get property (value) names
$keyNames = $Values | 
 Get-Member -MemberType *Property |
 Select-Object -ExpandProperty Name |
 Where-Object { $_ -notin $default } |
 Sort-Object
 
# dump key names , e.g. autostart programs
$RegPath
$keyNames | ForEach-Object {
   $values.$_
    }

$ErrorActionPreference = $CurrentEAP
}

Get-CimInstance win32_startupcommand | select name, command |fl
$RegRunKeys = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run\', `
 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce\', `                         
 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run', `                              
 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce\'                         

$RegRunKeys | foreach {Get-RegKeyProperties -RegPath $_}
