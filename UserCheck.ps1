<#------------------------------------------------------------------------------
    Jason McClary
    mcclarj@mail.amc.edu
    06 Oct 2016

    
    Description:
    Check that all servers have correct users logged in.
    
    Arguments:
    None
        
    Tasks:
    - Check that all servers have correct users logged in
    - Send single alert that user is logged out
    - Send all clear that user is logged back in


--------------------------------------------------------------------------------
                                CONSTANTS
------------------------------------------------------------------------------#>
set-variable hashServerLogginList -option Constant -value "serverLogon.txt"
set-variable monitorLog -option Constant -value "Warns.txt"
#set-variable emailSendList -option Constant -value "C:\Scripts\ED_Fax\emailSendList.txt"

<#------------------------------------------------------------------------------
                                Script Variables
------------------------------------------------------------------------------#>
$PSEmailServer = "mail.amc.edu"
$sendFrom = "edmadr01@mail.amc.edu"
#$sendTo =  Get-Content $emailSendList
$mailPriority = "Normal"
$mailSubject = "NOT SET"
$mailBody = "EMPTY"

<#------------------------------------------------------------------------------
                                FUNCTIONS
------------------------------------------------------------------------------#>

    
<#------------------------------------------------------------------------------
                                    MAIN
------------------------------------------------------------------------------#>
#Make a hash table
$Servers = Get-Content -Path $hashServerLogginList | ConvertFrom-StringData

# Check for monitor log file - if not there set up a blank
IF (!(Test-Path $monitorLog)){
    "SERVER NAMES" > $monitorLog
}

# Load log file for previous alerts and start loggin new alerts
$warnedServers = Get-Content $monitorLog
$newWarnedList= @("SERVER NAMES")


ForEach($server in $Servers.KEYS.GetEnumerator()) {
    IF(Test-Connection -count 1 -quiet $server){
        # Find what users are logged on to this server
        $queryResults = (qwinsta /server:$Server | foreach { (($_.trim() -replace "\s+",","))} | ConvertFrom-Csv)
        
        # Get the name of the required loggon for this server
        $neededUser = $Servers.$server
        
        $correctLoggon = $TRUE
        ForEach ($queryResult in $queryResults) { 
            $RDPUser = $queryResult.USERNAME 
            $sessionType = $queryResult.SESSIONNAME
            
            # ignore standard / normal loggons
            IF (($RDPUser -ne $NULL) -and ($SessionType -ne "console") -and ($SessionType -ne "services") -and ($SessionType -ne "rdp-tcp") -and ($RDPUser -ne "65536")) {
                # find loggons with names not numbers
                IF ($RDPUser -match "[a-z]") { $loggedOnUser = $RDPUser }
                ELSEIF ($sessionType -match "[a-z]") { $loggedOnUser = $sessionType }
                
                IF($loggedOnUser -eq $neededUser) { $correctLoggon = $FALSE }
            }
        }

        IF ($correctLoggon) {
            $writeToLog = $TRUE
            $newWarnedList = $newWarnedList += $server
            ForEach ($warnedServer in $warnedServers){
                IF ($warnedServer -eq $server) {
                    $writeToLog = $FALSE
                }
            }
            
            IF ($writeToLog){
                "$neededUser is not logged into $server."    
            }       
        }
        
        IF (($warnedServers.Contains($server)) -and !($newWarnedList.Contains($server))) { "Send all clear for $server" }
        $newWarnedList > $monitorLog
    }
}