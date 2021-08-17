-- Execute in master database

CREATE LOGIN StreamAnalyticsUser WITH PASSWORD = 'Password.1!!';

-- Execute in Streaming_Pool database

CREATE USER StreamAnalyticsUser FOR LOGIN StreamAnalyticsUser;
EXEC sp_addrolemember 'db_owner', 'StreamAnalyticsUser';

CREATE TABLE dbo.telcodata (
    RecordType varchar(10) NULL,
    FileNum varchar(10) NULL,
    SwitchNum varchar(20) NULL,
    CallingNum varchar(20) NULL,
    CallingIMSI varchar(30) NULL,
    CalledNum varchar(20) NULL,
    CalledIMSI varchar(30) NULL,
    DateS varchar(10) NULL
);