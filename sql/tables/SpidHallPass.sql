
create table ED209.SpidHallPass (
    constraint PK_SpidHallPass primary key clustered ( Spid )
   ,Spid       int          not null
   ,Expires    datetime2(7) not null
   ,InsertedBy varchar(100) not null
        constraint DF_USER default (suser_sname())
);
go
