<# 
    
    ##################################################################
    ### Automating SQL Server 2017 Enterprise Edition installation ###
    ##################################################################

    1. Download the SQL Server 2017 Enterprise Edition ISO
    2. Modify the ConfigurationFile.ini file (All you Need and Modify)  
            Note: The Location for the ConfigurationFile.ini is below:
                --> "C:\Program Files\Microsoft SQL Server\140\Setup Bootstrap\Log\***********\ConfigurationFile.ini"
            Note: Copy the ConfigurationFile.ini file from that directory to a new location. That will be the master copy of the file for others to use.

                ****** First, change quiet mode switch to true and delete the UIMode entry.
                        . QUIET="true" - Set up will not display any User Interface (UI);  
                        . QUIETSIMPLE="true" - Setup will display progress only, without any user interaction;
                        . IACCEPTSQLSERVERLICENSETERMS="True"
                        . SQLSYSADMINACCOUNTS="Domain\ServiceAccount"
                        . SECURITYMODE="SQL" - The default is Windows Authentication. Use "SQL" for Mixed Mode Authentication.
                        . TCPENABLED="1" - Specify 0 to disable or 1 to enable the TCP/IP protocol.
                        . NPENABLED="1"  - Specify 0 to disable or 1 to enable the Named Pipes protocol. 
                        . BROWSERSVCSTARTUPTYPE="Automatic" - Startup type for Browser Service.                            
                        . SAPWD="CHANGE THIS PASSWORD" 
                        . FEATURES=SQLENGINE,REPLICATION,FULLTEXT,RS 
                        . SQLCOLLATION="SQL_Latin1_General_CP1_CI_AS"
                        . SQLSVCACCOUNT="Domain\ServiceAccount" - Account for SQL Server service: Domain\User or system account.
                        . SQLSYSADMINACCOUNTS="Domain\User" - Windows account(s) to provision as SQL Server system administrators.
                        . SQLBACKUPDIR="D:\DBA\SQLBackup" - Default directory for the Database Engine backup files. 
                        . SQLUSERDBDIR="D:\DBA\SQLData" - Default directory for the Database Engine user databases. 
                        . SQLUSERDBLOGDIR="D:\DBA\SQLLog" - Default directory for the Database Engine user database logs.
                        . SQLTEMPDBDIR="D:\DBA\SQLTempDB" - Directory for Database Engine TempDB files. 
     3. Validating created instance by creating a test Database
     4. Configuring AOAG Feature enablement
     5. Configuraing TempDB to avoid transaction contentions
     6. Configuring all SQL Server Related Firewall rules
     7. Disabling SA account     
#>

<# The below PowerShell script is going to run an installer. As such, you must run this script as an admin. #>

##$server_list = Get-Content -path "D:\AutoInstallSQL\ServerList.txt" -ReadCount 1 
##foreach($i in $server_list){ Invoke-command -ComputerName $i -ScriptBlock {

$date = get-date 
$time = $Date.ToString("yyyyMMdd hh:mm:ss") 
Start-Transcript -path "G:\AutoInstallSQL\log1.txt"
Write-Host "$time : Starting the SQL Server 2017 Installation"
Write-Host "$time : Note:Typically SQL Server Install log is found at C:\Program Files\Microsoft SQL Server\[Version]\Setup Bootstrap\Log\[DateTimeStamp]\."
                    

$isoLocation = "G:\AutoInstallSQL\SW_DVD9_SQL_Svr_Enterprise_Edtn_2014w_SP1_64Bit_English_-2_MLF_X20-28966.ISO"
$pathToConfigurationFile = "G:\AutoInstallSQL\ConfigurationFile.ini"
$errorOutputFile = "G:\AutoInstallSQL\ErrorOutput.txt"
$standardOutputFile = "G:\AutoInstallSQL\StandardOutput.txt"


Write-Host "$time : Getting the name of the current user to replace in the copy ini file." 

$user = "$env:UserDomain\$env:USERNAME"

write-host "$time : $user" 

Write-Host "$time : Mounting SQL Server Image"
$drive = Mount-DiskImage -ImagePath $isoLocation 

Write-Host "$time : Getting Disk drive of the mounted image"
$disks = Get-WmiObject -Class Win32_logicaldisk -Filter "DriveType = '5'"


foreach ($disk in $disks){
 $driveLetter = $disk.DeviceID

}

if ($driveLetter)
{
 Write-Host "$time : Starting the install of SQL Server"
 Start-Process $driveLetter\Setup.exe "/ConfigurationFile=$pathToConfigurationFile"`
  -Wait `
  -RedirectStandardOutput $standardOutputFile `
  -RedirectStandardError  $errorOutputFile
}

$standardOutput = Get-Content $standardOutputFile -Delimiter "\r\n"

Write-Host "$time : $standardOutput"

$errorOutput = Get-Content $errorOutputFile -Delimiter "\r\n"

Write-Host "$time : $errorOutput"

Write-Host "$time : Dismounting the drive."

Dismount-DiskImage -InputObject $drive

####Dismount-DiskImage -ImagePath "G:\AutoInstallSQL\SW_DVD9_SQL_Svr_Enterprise_Edtn_2014w_SP1_64Bit_English_-2_MLF_X20-28966.ISO"

Write-Host "$time : If no red text then SQL Server Successfully Installed!"

########################################################
<# Powershell - Install Sql Server Management Studio  #>
########################################################

write-host "$time : SQL Server 2016 and above needs to install SSMS seperately"

### Set file and folder path for SSMS installer .exe
$folderpath="c:\windows\temp"
$filepath="$folderpath\SSMS-Setup-ENU.exe"
 
 
# start the SSMS installer
write-host "$time : Beginning SSMS 2017 install..." -nonewline
$Parms = " /Install /Quiet /Norestart /Logs log.txt"
$Prms = $Parms.Split(" ")
& "$filepath" $Prms | Out-Null
Write-Host "$time : SSMS installation complete" -ForegroundColor Green

#########################################
### Validation of SQL Server Instance ###
#########################################

Import-Module SQLPS -DisableNameChecking

$instanceName = invoke-sqlcmd -ServerInstance . -query "select @@servername" | select -expandproperty column1;

$server = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server -ArgumentList $instanceName

Write-Host "$time :  Trying to create a Test Database and Drop the Database"

Try 
     { 
         $dbName = "TestDB" 
         $db = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Database($server, $dbName) 
         $db.Create() 
 
 
         Start-Sleep -s 15 
 
 
         $server.KillDatabase($dbName)  
          
         Write-Host 'No errors found' 
     } 
     Catch  
     {  
         $err = $_.Exception 
         while ( $err.InnerException ) 
         { 
             $err = $err.InnerException; 
         }; 
         $exception = $err.Message; 
    
         Write-Host $exception; 
     } 




#If IsHadrEnabled = 1, Always On Availability Groups is enabled.
#If IsHadrEnabled = 0, Always On Availability Groups is disabled.

#######################################
#### Configuring SQL Server Tempdb ####
#######################################

write-host "$time : TempDB Configuration"
write-host "$time : Reason : The TempDB database is used to store temporary user created objects, temporary internal objects, 
and manage real time re-indexing. Each SQL Server environment consist of a single TempDB database, which all user databases will share.  
Due to this, TempDB can often become a point of contention when not properly configured."
Write-Host "$time : Configuring multiple data files for TempDB Configuration"
Write-Host "$time : A server with 2 duel core processors would recommend 4 TempDB data files.  
With that in mind, Microsoft recommends a maximum of 8 TempDB files per SQL Server with Multiple CPU Core Systems for better performance."

$instanceName = invoke-sqlcmd -ServerInstance .\Arc -query "select @@servername" | select -expandproperty column1;
invoke-sqlcmd -ServerInstance $instanceName -Database tempdb -Query "

USE [master]; 
GO 
ALTER DATABASE tempdb MODIFY FILE (NAME='tempdev', SIZE=1GB, FILEGROWTH = 100);
GO
USE [master];
GO
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev2', FILENAME = N'T:\SQLTemp\tempdev2.ndf' , SIZE = 1GB , FILEGROWTH = 100);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev3', FILENAME = N'T:\SQLTemp\tempdev3.ndf' , SIZE = 1GB , FILEGROWTH = 100);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev4', FILENAME = N'T:\SQLTemp\tempdev4.ndf' , SIZE = 1GB , FILEGROWTH = 100);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev5', FILENAME = N'T:\SQLTemp\tempdev5.ndf' , SIZE = 1GB , FILEGROWTH = 100);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev6', FILENAME = N'T:\SQLTemp\tempdev6.ndf' , SIZE = 1GB , FILEGROWTH = 100);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev7', FILENAME = N'T:\SQLTemp\tempdev7.ndf' , SIZE = 1GB , FILEGROWTH = 100);
ALTER DATABASE [tempdb] ADD FILE (NAME = N'tempdev8', FILENAME = N'T:\SQLTemp\tempdev8.ndf' , SIZE = 1GB , FILEGROWTH = 100);
GO
"


### Enabling SQL Server related Firewall Rules

Write-Host "$time : Enabling All SQL Server Related Firewall Rules for all SQL Server Services Communications"

Set-ExecutionPolicy -ExecutionPolicy RemoteSigned  
#Enabling SQL Server Ports
New-NetFirewallRule -DisplayName “SQL Server” -Direction Inbound –Protocol TCP –LocalPort 1433 -Action allow
New-NetFirewallRule -DisplayName “SQL Admin Connection” -Direction Inbound –Protocol TCP –LocalPort 1434 -Action allow
New-NetFirewallRule -DisplayName “SQL Database Management” -Direction Inbound –Protocol UDP –LocalPort 1434 -Action allow
New-NetFirewallRule -DisplayName “SQL Service Broker” -Direction Inbound –Protocol TCP –LocalPort 4022 -Action allow
New-NetFirewallRule -DisplayName “SQL Debugger/RPC” -Direction Inbound –Protocol TCP –LocalPort 135 -Action allow
#Enabling SQL Analysis Ports
New-NetFirewallRule -DisplayName “SQL Analysis Services” -Direction Inbound –Protocol TCP –LocalPort 2383 -Action allow
New-NetFirewallRule -DisplayName “SQL Browser” -Direction Inbound –Protocol TCP –LocalPort 2382 -Action allow
#Enabling Misc. Applications
New-NetFirewallRule -DisplayName “HTTP” -Direction Inbound –Protocol TCP –LocalPort 80 -Action allow
New-NetFirewallRule -DisplayName “SSL” -Direction Inbound –Protocol TCP –LocalPort 443 -Action allow
New-NetFirewallRule -DisplayName “SQL Server Browse Button Service” -Direction Inbound –Protocol UDP –LocalPort 1433 -Action allow
#Enable Windows Firewall
Set-NetFirewallProfile -DefaultInboundAction Block -DefaultOutboundAction Allow -NotifyOnListen True -AllowUnicastResponseToMulticast True
#Enable AOAG Firewall Rule
New-NetFirewallRule -DisplayName "MSSQL AOAG EP TCP" -Direction Inbound -LocalPort 5022 -Protocol TCP -Action Allow
New-NetFirewallRule -DisplayName "MSSQL AOAG EP TCP" -Direction Inbound -LocalPort 5023 -Protocol TCP -Action Allow


### Renaming sa Account and disabling it to secure the DB System ###

Write-Host "$time :  Disabling SA account"

invoke-sqlcmd -ServerInstance $server -Database master -Query "

--T-SQL to rename SA account
ALTER LOGIN SA WITH NAME = [xxxxxxxxxx]
GO

--T-SQL to disable SA account
ALTER LOGIN [xxxxxxxxxx] DISABLE;
GO
"

###}}


########################################################################################################
# To determine whether Always On Availability Groups is enabled . NOTE: Requires Restart of SQL Service .
#########################################################################################################

 Write-Host "$time : Checking AOAG feature Enablement"
 $instanceName = invoke-sqlcmd -ServerInstance .\Arc -query "select @@servername" | select -expandproperty column1;
 invoke-sqlcmd -ServerInstance $instanceName -Database master -Query "SELECT SERVERPROPERTY ('IsHadrEnabled')"  

 Enable-SqlAlwaysOn -ServerInstance "$instanceName"

Stop-Transcript








