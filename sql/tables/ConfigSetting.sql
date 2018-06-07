
create table ED209.ConfigSetting (
    ConfigID int           not null
        constraint FK_ED209_Config  
        foreign key  
             references ED209.Config ( ConfigID )
   ,Setting1 nvarchar(155)
   ,Setting2 nvarchar(155)
);
go
create unique clustered index UQ_CIX_ED209_Config 
    on ED209.ConfigSetting ( ConfigID
        ,Setting1
        ,Setting2 );
go
