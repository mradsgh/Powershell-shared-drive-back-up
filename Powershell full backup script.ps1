#######################################################################################################################
#  Powershell Back up script, to take full backup of a shared drive, to be run via task scheduler                    #
#                                                                                                                     #
#                                                                                                                     #
#                                                                                                                     #
#######################################################################################################################



####################
# Create variables #
####################
$currentMonth = Get-Date -UFormat %m
$currentMonth = (Get-Culture).DateTimeFormat.GetMonthName($currentMonth)
$CurrentYear = (Get-Date).ToString('yyyy')
$CurrentWeek = Get-Date -UFormat %V
$CurrentDate = (Get-Date).AddDays(-7)
$SRCLocation = 'F:'
$DSTLocation = "S:\$currentMonth $CurrentYear - Full Back Up"

###################################
# Create back up Directory folder #
###################################
$FolderExists = Test-Path $DSTLocation
If ($FolderExists -eq $False) {
  New-Item -ItemType directory -Path $DSTLocation -Force
}

###################################################
# Copy Source share folder to Back up Destination #
###################################################
Robocopy.exe /E /ZB /COPYALL /MT /XO /R:1 /W:1 /TS /FP /V /X "$SRCLocation" "$DSTLocation" /LOG:"$DSTLocation\BackUp_Log_File.log"

# Robocopy Source options:
# /E       = Copy Subfolders, including Empty Subfolders.
# /ZB      = Use restartable mode; if access denied use Backup mode.
# /COPYALL = Copy ALL file info
# /XO      = eXclude Older - if destination file exists and is the same date or newer than the source - don't bother to overwrite it.
# /R:1     = Number of Retries on failed copies - default is 1 million.
# /W:1     = Wait time between retries - default is 30 seconds
# /MT      = Multithreaded copying

# Robocopy Logging options:
# /V         = Produce Verbose output log, showing skipped files.
# /TS        = Include Source file Time Stamps in the output.
# /FP        = Include Full Pathname of files in the output.
# /X         = Report all eXtra files, not just those selected & copied.
# /LOG:file  = Output status to LOG file (append to existing log).


########################################
#                                      #
######################################## 
