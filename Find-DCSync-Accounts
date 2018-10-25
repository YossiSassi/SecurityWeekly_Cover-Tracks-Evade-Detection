#Requires -Modules ActiveDirectory

#Set Report File
$DCSyncReport = 'c:\temp\DCSyncUsersReport.txt'

Import-Module activedirectory
$DCDN = ([adsi]'').distinguishedname 
cd "AD:\$DCDN"
$AllReplACLs = (Get-Acl).Access | where {$_.objectType -eq '1131f6ad-9c07-11d1-f79f-00c04fc2dcd2' -or $_.objectType -eq '1131f6aa-9c07-11d1-f79f-00c04fc2dcd2'}

# List entries with RID above 1000, to exclude default entries
Write-Host "Enumerating Domain ACLs..."
foreach ($ACL in $AllReplACLs)
{
    $User = New-Object System.Security.Principal.NTAccount($ACL.IdentityReference)
    "Found identity: $User"
    $SID = $User.Translate([System.Security.Principal.SecurityIdentifier])
    $RID = $SID.ToString().Split("-")[7]
    if ([int]$RID -gt 1000)
    {   
        if ($ACL.ObjectType -eq '1131f6ad-9c07-11d1-f79f-00c04fc2dcd2') {$Permission = "(Replicate Directory Changes - All)"} else {$Permission = "(Replicate Directory Changes)"}
        Write-Host "Potential issue: Sync AD permission granted to:" $ACL.IdentityReference $Permission  -ForegroundColor Cyan
        $ACL.IdentityReference | Out-File $DCSyncReport -Append
        }
}

# Getting Configuration NC permissions...
cd "AD:\CN=Configuration,$DCDN"
$AllReplACLs = (Get-Acl).Access | where {$_.objectType -eq '1131f6ad-9c07-11d1-f79f-00c04fc2dcd2' -or $_.objectType -eq '1131f6aa-9c07-11d1-f79f-00c04fc2dcd2'}

Write-Host "Enumerating Configuration NC ACLs..."
foreach ($ACL in $AllReplACLs)
{
    $User = New-Object System.Security.Principal.NTAccount($ACL.IdentityReference)
    "Found identity: $User" 
    $SID = $User.Translate([System.Security.Principal.SecurityIdentifier])
    $RID = $SID.ToString().Split("-")[7]
    if ([int]$RID -gt 1000)
    {       
        if ($ACL.ObjectType -eq '1131f6ad-9c07-11d1-f79f-00c04fc2dcd2') {$Permission = "(Replicate Directory Changes - All)"} else {$Permission = "(Replicate Directory Changes)"}
        Write-Host "Potential issue: Sync AD permission granted to:" $ACL.IdentityReference $Permission  -ForegroundColor Cyan
        $ACL.IdentityReference | Out-File $DCSyncReport -Append
        }
}
"DCSync Users Test finished at $(Get-Date)." | Out-File $DCSyncReport -Append
Write-Host "See report at $DCSyncReport." -ForegroundColor Yellow
