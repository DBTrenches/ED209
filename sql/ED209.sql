
if not exists (select * 
               from sys.schemas 
               where [name] = 'ED209')
begin
    exec (N'create schema ED209 authorization dbo;');
end;
go
