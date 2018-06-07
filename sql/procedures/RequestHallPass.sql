
create or alter proc ED209.RequestHallPass
    @Spid         int
   ,@DurationMins int
as
begin;
    if @DurationMins > 360
    begin
        throw 500001, 'Max Duration 360 mins', 1;
    end;

    if exists (select * from ED209.SpidHallPass shp where shp.Spid = @Spid)
    begin
        update ED209.SpidHallPass
        set InsertedBy = system_user
           ,Expires = dateadd(minute, @DurationMins, getutcdate())
        where Spid = @Spid;
    end;
    else
    begin
        insert into ED209.SpidHallPass (Spid, Expires, InsertedBy)
        select @Spid, dateadd(minute, @DurationMins, getutcdate()), system_user;
    end;
end;
go
