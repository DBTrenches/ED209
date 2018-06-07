
create or alter proc ED209.Enforcer
    @Spid       varchar(10)
   ,@recipients varchar(500) = null
   ,@Subject    varchar(255) = null
   ,@Message    nvarchar(4000) = null
   ,@IsKill     bit = 1
   ,@ExtraInfo  nvarchar(max) = null
as
begin;

    set xact_abort on;

    begin try
        select top 1 @Message =
                         isnull(@Message, '')+'
<p><span style="font-family: ''courier new'', courier;">
========================================
Login: '                    +isnull(t.login_name, '')+'
DurationMins: '             +cast(isnull(t.total_elapsed_time_in_mins, '') as varchar(10))+'
MB_Used: '                  +isnull(cast(t.MB_CurrentAllocation as varchar(20)), '')+'
SqlText sample:
========================================
'                           +isnull(substring(t.Sqltext, 0, 2000), '')+'
========================================
</span></p>'
           ,@Spid             = t.session_id
           ,@recipients       = t.login_name
        from all_query_usage t
        where t.session_id = @Spid;

        set @Message = replace(@Message, char(10), '<br>');

        select @Subject = coalesce(@Subject, 'Your Session ('+@Spid+') has been killed');

        select @recipients = replace(@recipients, Setting1, '')+Setting2
        from ED209.ConfigSetting
        where @recipients like '%'+Setting1+'%'
            and ConfigID = 1; /*LoginDomainToReplace*/

        select @recipients = replace(@recipients, Setting1, Setting2)
        from ED209.ConfigSetting
        where @recipients like '%'+Setting1+'%'
            and ConfigID = 2; /*UsersToRedirect*/

        select @recipients = @recipients+';'+Setting1
        from ED209.ConfigSetting
        where ConfigID = 4; /*DefaultNotificationAddress*/

        select @Subject = @Subject+' [SafeMode]'
           ,@IsKill     = 0
        from ED209.ConfigSetting
        where ConfigID = 3 /*DefaultNotificationAddress*/
            and Setting1 = 1;

        if @IsKill = 1
        begin
            declare @sql varchar(10);

            select @sql = 'kill '+@Spid;

            exec (@sql);
        end;

        insert into ED209.Logs (LogDateTime, Spid, recipients, [Subject], [Message], IsKill, ExtraInfo)
        values
        (sysdatetime(), @Spid, @recipients, @Subject, @Message, @IsKill, @ExtraInfo);

        if not exists (
            select *
            from ED209.ConfigSetting
            where ConfigID = 6 /*IsDoNotMail*/
                and Setting1 = 1
        )
        begin
            exec msdb..sp_send_dbmail @recipients = @recipients 
               ,@subject = @Subject
               ,@body = @Message
               ,@body_format = 'html';
        end;
    end try
    begin catch
        if @@trancount > 0
        begin
            rollback transaction;
        end;

        -- exec ErrorHandler @NoLog = 0, @RaiseError = 1; -- TODO

        return;
    end catch;
end;
go
