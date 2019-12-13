#######################################################################################################################
#  Back up script, to take incremental backups since last full back up previous week via task scheduler               #
#  *To be used with the full backup script                                                                            #
#                                                                                                                     #
#                                                                                                                     #
#######################################################################################################################



####################
# create variables #
####################
$currentMonth = Get-Date -UFormat %m
$currentMonth = (Get-Culture).DateTimeFormat.GetMonthName($currentMonth)
$CurrentYear = (Get-Date).ToString('yyyy')
$CurrentWeek = Get-Date -UFormat %V
$CurrentDateTime = (Get-Date).ToString('yyyy_MM_dd HH_mm')
$SRCLocation = 'S:\' # Change lines 48/72 drive letter to match SRClocation drive letter
$DSTLocation = "F:\$CurrentWeek - $currentMonth $CurrentDateTime"
$LastFullBackUp = Get-ChildItem -Path 'F:\' |
Where-Object -FilterScript {
    $_.CreationTime -gt (Get-Date).AddDays(-7) -and $_.Name -like '*Full Back Up'
} |
Select-Object -ExpandProperty Fullname # Change "AddDays(-2)" to "AddDays(-7)" to retrieve last week full backup

##################################
# Compare Source and Destination #
##################################
$CompareSource = Get-ChildItem -Path "$SRCLocation" -Recurse
$CompareFullBackUp = Get-ChildItem -Path "$LastFullBackUp" -Recurse
$ModifiedObject = Compare-Object -ReferenceObject $CompareSource -DifferenceObject $CompareFullBackUp |
Where-Object -FilterScript {
    $_.sideIndicator -eq '<='
} |
Select-Object -Property inputobject

#######################################
# Sort files and folders to be copied #
#######################################
$ModifiedObject = $ModifiedObject | ForEach-Object -Process {
    $_.InputObject.FullName
}
$ModifiedObjectFolder = Get-Item $ModifiedObject |
Where-Object -FilterScript {
    $_.PSIsContainer -eq 'true'
} |
Select-Object -ExpandProperty fullname # Get folder fullpath
$ModifiedObjectFile = Get-ChildItem $ModifiedObject | Select-Object -ExpandProperty fullname # Get file fullpath

##################################
# Create hourly Directory folder #
##################################
$FolderExists = Test-Path $DSTLocation
If ($FolderExists -eq $False) {
    New-Item -ItemType directory -Path $DSTLocation -Force
}

########################################################################################
# Loop through objects to Copy new/modified files or new DIR since last full backup    #
########################################################################################
foreach ($object in $ModifiedObjectFolder) {
    $ModifiedObjectPath = $null # Null variable for use
    $ModifiedObjectPath = Split-Path $object
    $ModifiedObjectPath = "$ModifiedObjectPath" -replace '^S:', '' # Remove Drive Letter from directory path

    ###################################
    # Create directory in destination #
    ###################################
    $DestFolderExists = Test-Path -Path "$DSTLocation$ModifiedObjectPath"# Check if directory is already created
    If ($DestFolderExists -eq $False) {
        New-Item -ItemType directory -Path "$DSTLocation$ModifiedObjectPath" -Force
    }

    ###################################
    # Copy folder ACLs to destination #
    ###################################
    Get-Acl -Path $object |
    Where-Object -FilterScript {
        $_.Access |
        Where-Object -FilterScript {
            $_.IsInherited -eq $False 
        } 
    } |
    Set-Acl -Path "$DSTLocation$ModifiedObjectPath"
}

####################################
# Copy files to backup destination #
####################################
foreach ($object in $ModifiedObjectFile) {
    $ModifiedObjectName = $null # Null variable for use
    $ModifiedObjectPath = $null # Null variable for use

    $ModifiedObjectName = Split-Path -Path $object -Leaf # Store filename in variable
    $ModifiedObjectPath = Split-Path $object
    $ModifiedObjectPath = "$ModifiedObjectPath" -replace '^S:', '' # Remove Drive Letter from directory path

    Copy-Item -Path $object -Destination "$DSTLocation$ModifiedObjectPath\$ModifiedObjectName"

    #################################
    # Copy file ACLs to destination #
    #################################
    Get-Acl -Path $object |
    Where-Object -FilterScript {
        $_.Access |
        Where-Object -FilterScript {
            $_.IsInherited -eq $False 
        } 
    } |
    Set-Acl -Path "$DSTLocation$ModifiedObjectPath\$ModifiedObjectName"
}

########################################
#                                      #
########################################
