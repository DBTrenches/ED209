[cmdletbinding()]Param (
     [Parameter(Mandatory=$true)]$Server
    ,[Parameter(Mandatory=$true)]$Database
)

$conn = @{
    Server = $Server
    Database = $Database
}

$query = @"
drop table if exists ED209.Logs;
go
drop table if exists ED209.SpidHallPass;
go
drop table if exists ED209.ConfigSetting;
go
drop table if exists ED209.Config;
go
drop view if exists ED209.LongRunningQueries;
go
drop proc if exists ED209.Enforcer;
go
drop proc if exists ED209.RequestHallPass;
go
drop proc if exists ED209.KillLongRunningQueries;
go
drop schema if exists ED209;
go
"@

Invoke-Sqlcmd @conn -Query $query

if(Get-Command Publish-TaskFromConfig -ErrorAction SilentlyContinue){
    Invoke-Sqlcmd @conn "exec scheduler.DisableTask @task = '$Database-ED209.KillLongRunningQueries';"
}

Invoke-Sqlcmd @conn -Query "exec msdb_delete_job @job_name = '$Database-ED209.KillLongRunningQueries';" -ErrorAction SilentlyContinue
