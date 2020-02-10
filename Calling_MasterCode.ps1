$RemoteComputers = @("SQLInstance1","SQLInstance2")
ForEach ($Computer in $RemoteComputers)
{
     Try
         {
             Invoke-Command -ComputerName $Computer -ScriptBlock {Get-ChildItem "G:\AutoInstallSQL\Master_Code\AutoInstallSQLServer_MasterCode.ps1"} 
         }
     Catch
         {
             Add-Content G:\AutoInstallSQL\Master_Code\Unavailable_SQLInstances.txt $Computer
         }
}