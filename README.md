# AutomatingSQLInstallationUsingPowerShell

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
