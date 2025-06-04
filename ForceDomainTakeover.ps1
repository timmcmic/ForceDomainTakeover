
<#PSScriptInfo

.VERSION 1.0.1

.GUID 4d12d780-d14c-4a38-9c29-5e707d7d07b7

.AUTHOR Timothy McMichael

.COMPANYNAME Microsoft

.COPYRIGHT

.TAGS

.LICENSEURI

.PROJECTURI

.ICONURI

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES

# Modules that must be imported into the global environment prior to importing this module
RequiredModules = @(
    @{ModuleName = 'Microsoft.Graph.Authentication' ; ModuleVersion = '2.28.0'}
)

.PRIVATEDATA

#>

<# 

.DESCRIPTION 
 This script automates the process for external takeover / force takeover. 

#> 
Param(
    #Define General Paramters
    [Parameter(Mandatory=$true)]
    [string]$logFolderPath=,
    [Parameter(Mandatory=$false)]
    [string]$domainName="",
    #Define Microsoft Graph Parameters
    [Parameter(Mandatory = $false)]
    [ValidateSet("","China","Global","USGov","USGovDod")]
    [string]$msGraphEnvironmentName="Global",
    [Parameter(Mandatory=$false)]
    [string]$msGraphTenantID="",
    [Parameter(Mandatory=$false)]
    [string]$msGraphCertificateThumbprint="",
    [Parameter(Mandatory=$false)]
    [string]$msGraphApplicationID=""
)


#*****************************************************

Function new-LogFile
{
    [cmdletbinding()]

    Param
    (
        [Parameter(Mandatory = $true)]
        [string]$logFileName,
        [Parameter(Mandatory = $true)]
        [string]$logFolderPath
    )

    [string]$logFileSuffix=".log"
    [string]$fileName=$logFileName+$logFileSuffix

    # Get our log file path

    $logFolderPath = $logFolderPath+"\"+$logFileName+"\"
    
    #Since $logFile is defined in the calling function - this sets the log file name for the entire script
    
    $global:LogFile = Join-path $logFolderPath $fileName

    #Test the path to see if this exists if not create.

    [boolean]$pathExists = Test-Path -Path $logFolderPath

    if ($pathExists -eq $false)
    {
        try 
        {
            #Path did not exist - Creating

            New-Item -Path $logFolderPath -Type Directory
        }
        catch 
        {
            throw $_
        } 
    }
}

#*****************************************************
Function Out-LogFile
{
    [cmdletbinding()]

    Param
    (
        [Parameter(Mandatory = $true)]
        $String,
        [Parameter(Mandatory = $false)]
        [boolean]$isError=$FALSE
    )

    # Get the current date

    [string]$date = Get-Date -Format G

    # Build output string
    #In this case since I abuse the function to write data to screen and record it in log file
    #If the input is not a string type do not time it just throw it to the log.

    if ($string.gettype().name -eq "String")
    {
        [string]$logstring = ( "[" + $date + "] - " + $string)
    }
    else 
    {
        $logString = $String
    }

    # Write everything to our log file and the screen

    $logstring | Out-File -FilePath $global:LogFile -Append

    #Write to the screen the information passed to the log.

    if ($string.gettype().name -eq "String")
    {
        Write-Host $logString
    }
    else 
    {
        write-host $logString | select-object -expandProperty *
    }

    #If the output to the log is terminating exception - throw the same string.

    if ($isError -eq $TRUE)
    {
        #Ok - so here's the deal.
        #By default error action is continue.  IN all my function calls I use STOP for the most part.
        #In this case if we hit this error code - one of two things happen.
        #If the call is from another function that is not in a do while - the error is logged and we continue with exiting.
        #If the call is from a function in a do while - write-error rethrows the exception.  The exception is caught by the caller where a retry occurs.
        #This is how we end up logging an error then looping back around.

        write-error $logString
    }
}



#=====================================================================================
#Begin main function body.
#=====================================================================================

#Declare variables

$logFileName = "ForceDomainTakeover"
$outputFileName = $NULL

new-logfile -logFileName $logFileName -logFolderPath $logFolderPath

out-logfile -string "***********************************************************"
out-logfile -string "Starting ForceDomainTakeOver"
out-logfile -string "***********************************************************"

$outputFileName = $global:LogFile.replace(".log",".json")
out-logfile -string ("Defining output file: "+$outputFileName)


