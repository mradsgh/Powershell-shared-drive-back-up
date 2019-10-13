#######################################################################################################################
#  Back up script, to take incremental backups since last full back up previous week via task scheduler               #
#  *To be used with the full backup script                                                                            #
#                                                                                                                     #
#                                                                                                                     #
#######################################################################################################################



####################
# create variables #
####################
$currentMonth = Get-Date -UFormat %m;$CurrentMonth = (Get-Culture).DateTimeFormat.GetMonthName($CurrentMonth)
$CurrentYear = (Get-Date).ToString('yyyy')
$CurrentWeek = Get-Date -UFormat %V
$CurrentDateTime = (Get-Date).ToString('yyyy_MM_dd HH_mm')
$SRCLocation = "S:\" # Line 45 change drive letter to match SRClocation drive letter
$DSTLocation = "F:\$CurrentWeek - $CurrentMonth $CurrentDateTime"
$LastFullBackUp = Get-ChildItem "F:\" | Where-Object {$_.CreationTime -gt (Get-Date).AddDays(-7) -and $_.Name -like "*Full Back Up"} | select -Expand Fullname # Change "AddDays(-2)" to "AddDays(-7)" to retrieve last week full backup

##################################
# Compare Source and Destination #
##################################
$CompareSource = Get-ChildItem –Path "$SRCLocation" -Recurse
$CompareFullBackUp = Get-ChildItem –Path "$LastFullBackUp" -Recurse
$ModifiedObject = Compare-Object -ReferenceObject $CompareSource -DifferenceObject $CompareFullBackUp | ?{$_.sideIndicator -eq "<="} |select inputobject

#######################################
# Sort files and folders to be copied #
#######################################
$ModifiedObject = $ModifiedObject | ForEach { $_.InputObject.FullName}
$ModifiedObjectFolder = Get-item $ModifiedObject | ?{$_.PSIsContainer -eq "true"} | select -expand fullname # Get folder fullpath
$ModifiedObjectFile = Get-ChildItem $ModifiedObject | select -expand fullname # Get file fullpath

##################################
# Create hourly Directory folder #
##################################
$FolderExists = Test-Path $DSTLocation
If ($FolderExists -eq $False) 
{New-Item -ItemType directory -Path $DSTLocation -Force}

########################################################################################
# Loop through objects to Copy new/modified files or new DIR since last full backup    #
########################################################################################
foreach ($object in $ModifiedObjectFolder)
{
$ModifiedObjectPath = $null # Null variable for use
$ModifiedObjectPath = Split-Path $object;$ModifiedObjectPath = "$ModifiedObjectPath" -replace "^S:", "" # Remove Drive Letter from directory path

###################################
# Create directory in destination #
###################################
$DestFolderExists = Test-Path "$DSTLocation$ModifiedObjectPath"# Check if directory is already created
If ($DestFolderExists -eq $False) 
{New-Item -ItemType directory -Path "$DSTLocation$ModifiedObjectPath" -Force}

###################################
# Copy folder ACLs to destination #
###################################
Get-Acl -Path $object | where { $_.Access | where { $_.IsInherited -eq $false } } | Set-Acl -Path "$DSTLocation$ModifiedObjectPath"
}

####################################
# Copy files to backup destination #
####################################
foreach ($object in $ModifiedObjectFile)
{
$ModifiedObjectName=$null # Null variable for use
$ModifiedObjectPath = $null # Null variable for use

$ModifiedObjectName = Split-Path $object -Leaf # Store filename in variable
$ModifiedObjectPath = Split-Path $object;$ModifiedObjectPath = "$ModifiedObjectPath" -replace "^S:", "" # Remove Drive Letter from directory path

Copy-Item -Path $object "$DSTLocation$ModifiedObjectPath\$ModifiedObjectName"

#################################
# Copy file ACLs to destination #
#################################
Get-Acl -Path $object | where { $_.Access | where { $_.IsInherited -eq $false } } | Set-Acl -Path "$DSTLocation$ModifiedObjectPath\$ModifiedObjectName"
}

########################################
#                                      #
########################################