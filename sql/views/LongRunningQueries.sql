
create or alter view ED209.LongRunningQueries
as
select distinct r.session_id
   ,username         = s.nt_username
   ,program          = s.program_name
   ,starttime        = r.start_time
   ,timeinminutes    = r.total_elapsed_time / 60000
   ,DatabaseName     = db_name(r.database_id)
   ,status           = r.status
   ,trancount        = r.open_transaction_count
   ,UserLimitMinutes = coalesce(e1.UserLimit, e2.DefaultLimit)
from sys.dm_exec_requests r
join sys.sysprocesses     s on s.spid = r.session_id
outer apply (
    select UserLimit = cs.Setting2
    from ED209.ConfigSetting cs
    where cs.ConfigID = 5
        and s.nt_username = cs.Setting1
)                         e1
outer apply (
    select DefaultLimit = cs.Setting2
    from ED209.ConfigSetting cs
    where cs.ConfigID = 5
        and cs.Setting1 is null
) e2
outer apply (
    select JobName = concat('Job: ', j.name), CategoryName = c.name
    from msdb.dbo.sysjobs             j
    inner join msdb.dbo.syscategories c on c.category_id = j.category_id
    where j.job_id = try_convert(uniqueidentifier, try_convert(varbinary(16), (substring(s.program_name, charindex('0x', s.program_name, 0), 34)), 1))
) sj
where r.status in ('running', 'runnable', 'suspended')
    and ((sj.JobName not like '%cdc.%' and sj.CategoryName not like 'REPL-%') or sj.JobName is null)
    and s.spid not in (select shp.Spid from ED209.SpidHallPass shp where shp.Expires > getutcdate())
    and r.database_id > 5
    and r.command in (
         'BULK INSERT'
        ,'DELETE'
        ,'INSERT'
        ,'SELECT'
        ,'SELECT INTO'
        ,'UPDATE'
        ,'MERGE'
        ,'EXECUTE');
go
