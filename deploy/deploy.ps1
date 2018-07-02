[cmdletbinding()]Param (
     [Parameter(Mandatory=$true)]$Server
    ,[Parameter(Mandatory=$true)]$Database
    ,$here = $PSScriptRoot
    ,[switch]$overrideNetTest
)

if(Get-Command Test-NetConnection -ErrorAction SilentlyContinue){
    if(Test-NetConnection -ComputerName $Server -Port 1433){
        $go = (Invoke-Sqlcmd -ServerInstance $Server `
                    -Query "select db_name(db_id('$Database')) as db;" `
              ).db -eq $Database
    }

}else {
    if($overrideNetTest){
        $go = $true
    }else{
        $go = $false
        Write-Warning "Missing Test-NetConnection command. Cannot validate connection to SQL Server."
        Write-Warning "Manually validate your connection string and re-run with the '-overrideNetTest' flag."
    }
}

$conn = @{
    Server = $Server
    Database = $Database
}

$files = @"
Order,Path,Type,Name
0,$here\..\sql\ED209.sql,Schema,ED209
1,$here\..\sql\tables\Logs.sql,tables,Logs
2,$here\..\sql\tables\SpidHallPass.sql,tables,SpidHallPass
3,$here\..\sql\tables\Config.sql,tables,Config
4,$here\..\sql\tables\ConfigSetting.sql,tables,ConfigSetting
5,$here\..\sql\views\LongRunningQueries.sql,views,LongRunningQueries
6,$here\..\sql\procedures\Enforcer.sql,procedures,Enforcer
7,$here\..\sql\procedures\RequestHallPass.sql,procedures,RequestHallPass
8,$here\..\sql\procedures\KillLongRunningQueries.sql,procedures,KillLongRunningQueries
"@ | ConvertFrom-Csv

$edAlreadyExists = (Invoke-Sqlcmd @conn `
                        -Query "select isnull(schema_id('ED209'),0) as id;" `
                   ).id -ne 0

$files | Sort-Object -Property "Order" | % {
    #Test-Path $_.path
    if($edAlreadyExists -and $_.Type -eq "tables"){
    }else{
        Write-Verbose $_.Name
        Invoke-Sqlcmd @conn -InputFile $_.Path
    }
}

if($edAlreadyExists){
    while($deployConfig -notin ("Y","N")){
        $deployConfig = Read-Host "ED209 has already been deployed here. Redeploy the Config Values? [Y/N]"
    }
}else{
    $deployConfig = "Y"
}

if($deployConfig -eq "Y"){
    Write-Verbose "Deploying Config Values"

    $config = gc "$here\config\config.json" | ConvertFrom-Json
    $configSetting = gc "$here\config\configSetting.json" | ConvertFrom-Json

    if(($config.Count -gt 0) -and ($configSetting.Count -gt 0)){
        Invoke-Sqlcmd @conn -Query "delete ED209.ConfigSetting;"
        Invoke-Sqlcmd @conn -Query "delete ED209.Config;"

        $config | %{
            $id = $_.ConfigID
            $name = $_.ConfigName
            Invoke-Sqlcmd @conn -Query "Insert ED209.Config(ConfigID,ConfigName) values ($id,'$name');"
        }

        $configSetting | % {
            $id = $_.ConfigID
            $s1 = $_.Setting1
            $s2 = $_.Setting2
            Invoke-Sqlcmd @conn -Query "Insert ED209.ConfigSetting(ConfigID,Setting1,Setting2) values ($id,'$s1','$s2');"
        }
    }
}

if(Get-Command Publish-TaskFromConfig -ErrorAction SilentlyContinue){
    try{
        Publish-TaskFromConfig @conn -config "$here/task/SchedulerTask.json"
    }
    catch {
        Copy-Item -Path "$here/task/SchedulerTask.example.json" -Destination "$here/task/SchedulerTask.json"
        notepad "$here/task/SchedulerTask.json"
        Write-Warning "Scheduler solution has been deployed but no CONFIG file found in repo."
        Write-Warning "Please update the SchedulerTask.json and publish with the below command"
        Write-Host "    Publish-TaskFromConfig -server '$server' -database '$database' -config '$here/task/SchedulerTask.json'" -ForegroundColor Green
    }
}else{
    try {
        Invoke-Sqlcmd @conn -InputFile "$here/task/AgentJob.sql"
    }
    catch {
        Copy-Item -Path "$here/task/AgentJob.example.sql" -Destination "$here/task/AgentJob.sql"
        ssms "$here/task/AgentJob.sql"
        Write-Warning "Job not deployed, please update Write-Warning AgentJob.sql with the appropriate values and deploy."
    }
}
