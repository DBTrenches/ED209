
create table ED209.Config (
    constraint PK_ED209_Config primary key clustered ( ConfigID )
   ,ConfigID   int         not null
   ,ConfigName varchar(50)
);
go
