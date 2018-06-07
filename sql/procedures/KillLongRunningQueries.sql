create or alter proc ED209.KillLongRunningQueries
as
begin
    set xact_abort on;

    begin try
        declare @Spid      int
           ,@TimeLimitMins int
           ,@Subject       varchar(255)
           ,@Message       nvarchar(4000);

        drop table if exists #spids;

        select *
           ,PecentOverlimit = (1.0 * s.timeinminutes / s.UserLimitMinutes) -1
        into #spids
        from ED209.LongRunningQueries s
        left join ED209.SpidHallPass  shp on s.session_id = shp.Spid
                                              and shp.Expires > getutcdate()
        where s.timeinminutes > s.UserLimitMinutes
            and shp.Spid is null;

        declare @ExtraInfo nvarchar(max) = (select * from #spids for json path, root('params'));

        while exists (select * from #spids s)
        begin
            select @Spid = s.session_id from #spids s;

            declare @LogInfo nvarchar(max) = (
                        select PolicyViolation = 'LongRunningQuery'
                           ,timeinminutes
                        from #spids
                        where session_id = @Spid
                        for json path, root('Info')
                    );

            if (select s.PecentOverlimit from #spids s where s.session_id = @Spid) between 0 and 0.5
            begin
                select @TimeLimitMins = cast(s.UserLimitMinutes as int)* 1.5-s.timeinminutes
                from #spids s
                where s.session_id = @Spid;

                select @Subject =
                    'LONG RUNNING QUERY ALERT - You have '+cast(@TimeLimitMins as varchar(10))
                    +' MINS to request override, or your session will be killed automatically. [Sent by ED209]'
                   ,@Message    =
                        N'Your query (session ID = '+cast(@Spid as varchar(5))
                        +N') has exceeded maximum allowed run time duration. 
						  
						      Your session will be killed automatically within '+cast(@TimeLimitMins as varchar(10))
                        +N' minutes, unless you request a 30 min hallpass by running the below: 
						  
						     exec DBAdmin.ED209.RequestHallPass @Spid = '+cast(@Spid as varchar(5))
                        +N' , @DurationMins = 30
						  

						     ---This service was brought to you by ED209. Have a nice day!---
						      ';

                exec ED209.Enforcer @Spid = @Spid -- varchar(10)
                   ,@Subject = @Subject           -- varchar(255)
                   ,@Message = @Message           -- nvarchar(4000)
                   ,@IsKill = 0
                   ,@ExtraInfo = @LogInfo;        -- bit
            end;
            else
            begin
                select @Subject = 'Your session ('+cast(@Spid as varchar(5))+') has been terminated for violating policy - [DURATION TOO LONG]. [Sent by ED209]'
                   ,@Message    = N'Your session has been killed.

						    ---This service was brought to you by ED209. Have a nice day!---
						      ';

                exec ED209.Enforcer @Spid = @Spid -- varchar(10)
                   ,@Subject = @Subject           -- varchar(255)
                   ,@Message = @Message           -- nvarchar(4000)
                   ,@IsKill = 1
                   ,@ExtraInfo = @LogInfo;        -- bit
            end;

            delete from #spids where session_id = @Spid;
        end;
    end try
    begin catch
        if @@trancount > 0
        begin
            rollback transaction;
        end;

        --exec ErrorHandler @NoLog = 0, @RaiseError = 0, @ExtraInfo = @ExtraInfo; -- TODO

        return;
    end catch;
end;
go
