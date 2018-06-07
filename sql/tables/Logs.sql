
create table ED209.Logs (
    LogDateTime datetime2(0)   not null
   ,Spid        int
   ,recipients  varchar(500)
   ,[Subject]   varchar(255)
   ,[Message]   nvarchar(4000)
   ,IsKill      bit
   ,IsDoNotMail bit
   ,ExtraInfo   nvarchar(max)
);
go
create clustered index CK_ED209_Logs_LogDateTime 
    on ED209.Logs ( LogDateTime );
go
