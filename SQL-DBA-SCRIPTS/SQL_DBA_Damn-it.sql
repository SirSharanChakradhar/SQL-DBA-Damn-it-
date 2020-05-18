EXEC sp_BlitzFirst -- first run this to find why server is running slow rightnow
EXEC sp_Blitz @CheckUserDatabaseObjects = 0, @CheckServerInfo = 9;
--EXEC dbo.sp_Blitz @OutputType = 'SCHEMA'
EXEC sp_BlitzLock
EXEC sp_BlitzWho 
EXEC sp_who
EXEC sp_who2
EXEC sp_BlitzInMemoryOLTP
EXEC sp_BlitzIndex --per db
EXEC sp_BlitzIndex @mode = 4 
EXEC sp_BlitzCache
EXEC dbo.sp_BlitzIndex @DatabaseName='test1a', @SchemaName='dbo', @TableName='Sales';
ALTER TABLE [MPAU].[dbo].[PFCICFRC] REBUILD;
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
select * from sys.dm_exec_procedure_stats --information about the procedures, when the procedure is last run, when the procedure is cached, how much time it took to execute etc.
select * from sys.dm_os_performance_counters
select * from sys.dm_db_index_usage_stats
SELECT DB_NAME([ddips].[database_id]) AS [DatabaseName] , OBJECT_NAME([ddips].[object_id]) AS [TableName] ,* FROM [sys].[dm_db_index_physical_stats](DB_ID(), NULL, NULL, NULL, NULL) AS ddips
select * from sys.dm_exec_cached_plans -- Cached query plans available to SQL Server
select * from sys.dm_exec_sessions -- Sessions in SQL Server
select * from sys.dm_exec_connections -- Connections to SQL Server
select * from sys.dm_db_index_usage_stats -- Seeks, scans, lookups per index
SELECT * FROM sys.dm_io_virtual_file_stats(DB_ID(N'Staging'), 2)-- IO statistics for databases and log files
select * from sys.dm_tran_active_transactions -- Transaction state for an instance of SQL Server
SELECT r.session_id,r.status,r.command,t.text,DB_NAME(database_ID) FROM sys.dm_exec_requests AS r CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) AS t   -- Returns TSQL code for eachdb
SELECT r.session_id,r.status,r.command,DB_NAME(database_ID),* FROM sys.dm_exec_requests AS r CROSS APPLY sys.dm_exec_query_plan(r.sql_handle) t -- Returns query plan
select * from sys.dm_os_wait_stats -- Returns information what resources SQL is waiting on
select * from sys.dm_os_performance_counters -- Returns performance monitor counters related to SQL Server

select * from sys.sql_expression_dependencies

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

DBCC CHECKALLOC ('database')
DBCC CHECKFILEGROUP ('filegroup')
DBCC CHECKTABLE ('table')
DBCC CLEANTABLE ('database','table')
DBCC CHECKCATALOG ('database')
DBCC CHECKCONSTRAINTS ('table', 'constraint')
DBCC CHECKIDENT ('table')
DBCC HELP ('select')-- tells you parameters
--https://docs.microsoft.com/en-us/sql/t-sql/database-console-commands/dbcc-transact-sql?view=sql-server-2017#Anchor_2
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--ola hallengren--
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--"""Incremental Statistics"""
--Are you using incremental statistics? I have a new version of IndexOptimize with support for incremental statistics. Heres how it works:
--The stored procedure will check sys.dm_db_incremental_stats_properties for each partition.
EXECUTE dbo.IndexOptimize
@Databases = '',--USER_DATABASES
@UpdateStatistics = 'ALL',
@OnlyModifiedStatistics = 'Y'



--"""Online Resumable Index Rebuilds"""
--Microsoft introduced online resumable index rebuilds in SQL Server 2017. This feature let's you resume an index rebuild, if it would get aborted. Here's to use it:

EXECUTE dbo.IndexOptimize
@Databases = 'USER_DATABASES',
@FragmentationLow = NULL,
@FragmentationMedium = 'INDEX_REORGANIZE,INDEX_REBUILD_ONLINE,INDEX_REBUILD_OFFLINE',
@FragmentationHigh = 'INDEX_REBUILD_ONLINE,INDEX_REBUILD_OFFLINE',
@Resumable = 'Y'

---"""SQL Server Smart Differential and Transaction Log Backup"""
--Microsoft has introduced support in DMVs for checking how much of a database that has been modified since the last (non copy-only) full backup, and how much transaction log that has been generated since the last log backup.
--I am now utilizing this in DatabaseBackup, to perform smart differential and transaction log backups.
--Heres how it can be used to perform a differential backup if less than 50% of the database has been modified, and a full backup if 50% or more of the database has been modified.

EXECUTE dbo.DatabaseBackup
@Databases = 'USER_DATABASES',
@Directory = 'C:\Backup',
@BackupType = 'DIFF',
@ChangeBackupType = 'Y',
@ModificationLevel = 50

--Heres how it can be used to perform a transaction log backup if 1 GB of log has been generated since the last log backup, or if it has not been backed up for 300 seconds. This enables you to do more frequent log backups of 
--databases with high activity, and in periods of high activity.

EXECUTE dbo.DatabaseBackup
@Databases = 'USER_DATABASES',
@Directory = 'C:\Backup',
@BackupType = 'LOG',
@LogSizeSinceLastLogBackup = 1024,
@TimeSinceLastLogBackup = 300

--"""SQL Server Backup on Linux"""
--Backup on SQL Server 2017 on Linux is now supported. Here's how to use it:

EXECUTE dbo.DatabaseBackup
@Databases = 'USER_DATABASES',
@Directory = '/var/opt/mssql/backup',
@BackupType = 'FULL',
@Verify = 'Y',
@Compress = 'Y',
@CheckSum = 'Y'

---"""Striping of backups to Azure Blob Storage"""
--The SQLCAT - team has a blog post about how you can optimize performance when backing up to Azure Blob Storage. You can stripe the backups to multiple files, and use the options MAXTRANSFERSIZE, and BLOCKSIZE.

EXECUTE dbo.DatabaseBackup @Databases = 'USER_DATABASES',
@URL = 'https://myaccount.blob.core.windows.net/mycontainer',
@BackupType = 'FULL',
@Compress = 'Y',
@Verify = 'Y',
@NumberOfFiles = 8,
@MaxTransferSize = 4194304,
@BlockSize = 65536


--"""Working with Availability Groups"""
--One of the most requested features for a long time has been the ability to select availability groups. I have added this now. Here is how it works:

EXECUTE dbo.DatabaseBackup
@AvailabilityGroups = 'AG1',
@Directory = 'C:\Backup',
@BackupType = 'FULL'

EXECUTE dbo.DatabaseBackup
@AvailabilityGroups = 'AG1, AG2',
@Directory = 'C:\Backup',
@BackupType = 'FULL'

EXECUTE dbo.DatabaseBackup
@AvailabilityGroups = 'ALL_AVAILABILITY_GROUPS, -AG1',
@Directory = 'C:\Backup',
@BackupType = 'FULL'

--Now what if you want to select all user databases that are not in availability groups? For this scenario I have added a new keyword in the @Databases parameter.

EXECUTE dbo.DatabaseBackup
@Databases = 'USER_DATABASES, -AVAILABILITY_GROUP_DATABASES',
@Directory = 'C:\Backup',
@BackupType = 'FULL'

--It works the same way in DatabaseBackup, DatabaseIntegrityCheck, and IndexOptimize.


--"""Intelligent Index Maintenance"""
--The SQL Server Maintenance Solution lets you intelligently rebuild or reorganize only the indexes that are fragmented. In the IndexOptimize procedure, you can define a preferred index maintenance operation for each fragmentation group. 
--Take a look at this code:

EXECUTE dbo.IndexOptimize @Databases = 'USER_DATABASES',
@FragmentationLow = NULL,
@FragmentationMedium = 'INDEX_REORGANIZE,INDEX_REBUILD_ONLINE,INDEX_REBUILD_OFFLINE',
@FragmentationHigh = 'INDEX_REBUILD_ONLINE,INDEX_REBUILD_OFFLINE',
@FragmentationLevel1 = 5,
@FragmentationLevel2 = 30
--In this example, indexes that have a high fragmentation level will be rebuilt, online if possible. Indexes that have a medium fragmentation level will be reorganized. Indexes that have a low fragmentation level will remain untouched.


--"""Update Statistics"""
--The IndexOptimize procedure can also be used to update statistics. You can choose to update all statistics, statistics on indexes only, or statistics on columns only. You can also choose to update the statistics only if any rows have been modified 
--since the most recent statistics update.

EXECUTE dbo.IndexOptimize @Databases = 'USER_DATABASES',
@FragmentationLow = NULL,
@FragmentationMedium = 'INDEX_REORGANIZE,INDEX_REBUILD_ONLINE,INDEX_REBUILD_OFFLINE',
@FragmentationHigh = 'INDEX_REBUILD_ONLINE,INDEX_REBUILD_OFFLINE',
@FragmentationLevel1 = 5,
@FragmentationLevel2 = 30,
@UpdateStatistics = 'ALL',
@OnlyModifiedStatistics = 'Y'

--"""Solve -'No Current Database'- Issues"""
--Most DBAs have experienced the error message “BACKUP LOG cannot be performed because there is no current database backup” or “Cannot perform a differential backup for database, because a current database backup does not exist”. These errors usually 
--occur when you have created a new database or changed the database recovery model from Simple to Full. The answer is to determine, before you run the backup, whether a differential or transaction log backup can be performed. You can use the 
--DatabaseBackup procedure’s @ChangeBackupType option to change the backup type dynamically if a differential or transaction log backup cannot be performed.

--Here’s an example of how to use the @ChangeBackupType option:

EXECUTE dbo.DatabaseBackup
@Databases = 'USER_DATABASES',
@Directory = 'C:\Backup',
@BackupType = 'LOG',
@Verify = 'Y',
@ChangeBackupType = 'Y',
@CleanupTime = 24


--"""Back up to Multiple FilesBack up to Multiple Files"""
--Databases are becoming larger and larger. You can tune the performance of SQL Server backup compression, by using multiple backup files, and the BUFFERCOUNT and MAXTRANSFERSIZE options. The DatabaseBackup procedure supports these options:

EXECUTE dbo.DatabaseBackup
@Databases = 'USER_DATABASES',
@Directory = 'C:\Backup, D:\Backup, E:\Backup, F:\Backup',
@BackupType = 'FULL',
@Compress = 'Y',
@BufferCount = 50,
@MaxTransferSize = 4194304,
@NumberOfFiles = 4,
@CleanupTime = 24

--"""Run Integrity Checks of Very Large Databases"""
-- In the DatabaseIntegrityCheck procedure you can choose do the checks on the database level, the filegroup level, or the table level. It also supports limiting the checks to the physical structures of the database:
EXECUTE dbo.DatabaseIntegrityCheck
@Databases = 'USER_DATABASES',
@CheckCommands = 'CHECKDB',
@PhysicalOnly = 'Y'


---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--db size
SELECT      sys.master_files.name,  
            CONVERT(VARCHAR,SUM(size)*8/1024)+' MB' AS [Total disk space_MB] ,CONVERT(VARCHAR,(SUM(size)*8/1024)/1024)+' GB' AS [Total disk space_GB]  
FROM        sys.databases   
JOIN        sys.master_files  
ON          sys.databases.database_id=sys.master_files.database_id  
GROUP BY    sys.master_files.name
ORDER BY    sys.master_files.name 

--table size

SELECT 
    t.NAME AS TableName,
    s.Name AS SchemaName,
    p.rows AS RowCounts,
    SUM(a.total_pages) * 8 AS TotalSpaceKB, 
    CAST(ROUND(((SUM(a.total_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) AS TotalSpaceMB,
    SUM(a.used_pages) * 8 AS UsedSpaceKB, 
    CAST(ROUND(((SUM(a.used_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) AS UsedSpaceMB, 
    (SUM(a.total_pages) - SUM(a.used_pages)) * 8 AS UnusedSpaceKB,
    CAST(ROUND(((SUM(a.total_pages) - SUM(a.used_pages)) * 8) / 1024.00, 2) AS NUMERIC(36, 2)) AS UnusedSpaceMB
FROM 
sys.tables t INNER JOIN sys.indexes i ON t.OBJECT_ID = i.object_id
INNER JOIN sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
LEFT OUTER JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE    t.NAME NOT LIKE 'dt%'     AND t.is_ms_shipped = 0    AND i.OBJECT_ID > 255 
GROUP BY t.Name, s.Name, p.Rows
ORDER BY t.Name

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
select * from sys.databases
select * from sys.indexes 
select * from sys.partitions
select * from sys.master_files
select * from sys.tables
select * from sys.allocation_units
----------INDEX-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--calculate the size of individual index on a table
SELECT [DatabaseName],[ObjectId],[ObjectName],[IndexId],[IndexDescription],CONVERT(DECIMAL(16, 1), (SUM([avg_record_size_in_bytes] * [record_count]) / (1024.0 * 1024))) AS [IndexSize(MB)],
[lastupdated] AS [StatisticLastUpdated],[AvgFragmentationInPercent]
FROM (
 SELECT DISTINCT DB_Name(Database_id) AS 'DatabaseName',OBJECT_ID AS ObjectId,Object_Name(Object_id) AS ObjectName,Index_ID AS IndexId,Index_Type_Desc AS IndexDescription,avg_record_size_in_bytes,record_count,
STATS_DATE(object_id, index_id) AS 'lastupdated',CONVERT([varchar](512), round(Avg_Fragmentation_In_Percent, 3)) AS 'AvgFragmentationInPercent'
    FROM sys.dm_db_index_physical_stats(db_id(), NULL, NULL, NULL, 'detailed')
	WHERE OBJECT_ID IS NOT NULL  AND Avg_Fragmentation_In_Percent <> 0    ) T
GROUP BY DatabaseName,ObjectId,ObjectName,IndexId,IndexDescription,lastupdated,AvgFragmentationInPercent

SELECT
OBJECT_SCHEMA_NAME(i.OBJECT_ID) AS SchemaName,
OBJECT_NAME(i.OBJECT_ID) AS TableName,
i.name AS IndexName,
i.index_id AS IndexID,
8 * SUM(a.used_pages) AS 'Indexsize(KB)'
FROM sys.indexes AS i
JOIN sys.partitions AS p ON p.OBJECT_ID = i.OBJECT_ID AND p.index_id = i.index_id
JOIN sys.allocation_units AS a ON a.container_id = p.partition_id
GROUP BY i.OBJECT_ID,i.index_id,i.name
ORDER BY OBJECT_NAME(i.OBJECT_ID),i.index_id

-- List all Objects and Indexes per Filegroup / Partition and Allocation Type 
SELECT DS.name AS DataSpaceName ,AU.type_desc AS AllocationDesc ,AU.total_pages / 128 AS TotalSizeMB 
,AU.used_pages / 128 AS UsedSizeMB ,AU.data_pages / 128 AS DataSizeMB ,SCH.name AS SchemaName 
,OBJ.type_desc AS ObjectType ,OBJ.name AS ObjectName ,IDX.type_desc AS IndexType 
,IDX.name AS IndexName 
FROM sys.data_spaces AS DS 
INNER JOIN sys.allocation_units AS AU ON DS.data_space_id = AU.data_space_id 
INNER JOIN sys.partitions AS PA ON (AU.type IN (1, 3) 
AND AU.container_id = PA.hobt_id) 
OR (AU.type = 2 AND AU.container_id = PA.partition_id) 
INNER JOIN sys.objects AS OBJ ON PA.object_id = OBJ.object_id 
INNER JOIN sys.schemas AS SCH ON OBJ.schema_id = SCH.schema_id 
LEFT JOIN sys.indexes AS IDX ON PA.object_id = IDX.object_id AND PA.index_id = IDX.index_id 
ORDER BY DS.name ,SCH.name ,OBJ.name ,IDX.name

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
with cte_recent as
(
select SCHEMA_NAME(b.schema_id) +'.'+object_name(b.object_id) as tbl_name,
(select MAX(last_user_dt) from (values (last_user_seek),(last_user_scan),(last_user_lookup)) as all_val(last_user_dt)) as access_datetime FROM sys.dm_db_index_usage_stats a
right outer join sys.tables b on a.object_id =  b.object_id)
select tbl_name,max(access_datetime) as recent_datetime  from cte_recent
group by tbl_name
order by recent_datetime desc , 1


-- Missing Index Script
SELECT TOP 25
dm_mid.database_id AS DatabaseID,
dm_migs.avg_user_impact*(dm_migs.user_seeks+dm_migs.user_scans) Avg_Estimated_Impact,
dm_migs.last_user_seek AS Last_User_Seek,
OBJECT_NAME(dm_mid.OBJECT_ID,dm_mid.database_id) AS [TableName],
'CREATE INDEX [IX_' + OBJECT_NAME(dm_mid.OBJECT_ID,dm_mid.database_id) + '_'
+ REPLACE(REPLACE(REPLACE(ISNULL(dm_mid.equality_columns,''),', ','_'),'[',''),']','') 
+ CASE
WHEN dm_mid.equality_columns IS NOT NULL
AND dm_mid.inequality_columns IS NOT NULL THEN '_'
ELSE ''
END
+ REPLACE(REPLACE(REPLACE(ISNULL(dm_mid.inequality_columns,''),', ','_'),'[',''),']','')
+ ']'
+ ' ON ' + dm_mid.statement
+ ' (' + ISNULL (dm_mid.equality_columns,'')
+ CASE WHEN dm_mid.equality_columns IS NOT NULL AND dm_mid.inequality_columns 
IS NOT NULL THEN ',' ELSE
'' END
+ ISNULL (dm_mid.inequality_columns, '')
+ ')'
+ ISNULL (' INCLUDE (' + dm_mid.included_columns + ')', '') AS Create_Statement
FROM sys.dm_db_missing_index_groups dm_mig
INNER JOIN sys.dm_db_missing_index_group_stats dm_migs
ON dm_migs.group_handle = dm_mig.index_group_handle
INNER JOIN sys.dm_db_missing_index_details dm_mid
ON dm_mig.index_handle = dm_mid.index_handle
WHERE dm_mid.database_ID = DB_ID()
ORDER BY Avg_Estimated_Impact DESC
GO


-- Unused Index Script
SELECT TOP 25
o.name AS ObjectName
, i.name AS IndexName
, i.index_id AS IndexID
, dm_ius.user_seeks AS UserSeek
, dm_ius.user_scans AS UserScans
, dm_ius.user_lookups AS UserLookups
, dm_ius.user_updates AS UserUpdates
, p.TableRows
, 'DROP INDEX ' + QUOTENAME(i.name)
+ ' ON ' + QUOTENAME(s.name) + '.'
+ QUOTENAME(OBJECT_NAME(dm_ius.OBJECT_ID)) AS 'drop statement'
FROM sys.dm_db_index_usage_stats dm_ius
INNER JOIN sys.indexes i ON i.index_id = dm_ius.index_id 
AND dm_ius.OBJECT_ID = i.OBJECT_ID
INNER JOIN sys.objects o ON dm_ius.OBJECT_ID = o.OBJECT_ID
INNER JOIN sys.schemas s ON o.schema_id = s.schema_id
INNER JOIN (SELECT SUM(p.rows) TableRows, p.index_id, p.OBJECT_ID
FROM sys.partitions p GROUP BY p.index_id, p.OBJECT_ID) p
ON p.index_id = dm_ius.index_id AND dm_ius.OBJECT_ID = p.OBJECT_ID
WHERE OBJECTPROPERTY(dm_ius.OBJECT_ID,'IsUserTable') = 1
AND dm_ius.database_id = DB_ID()
AND i.type_desc = 'nonclustered'
AND i.is_primary_key = 0
AND i.is_unique_constraint = 0
ORDER BY (dm_ius.user_seeks + dm_ius.user_scans + dm_ius.user_lookups) ASC
GO


-- Script - Find Details for Statistics of Whole Database
SELECT DISTINCT
OBJECT_NAME(s.[object_id]) AS TableName,
c.name AS ColumnName,
s.name AS StatName,
STATS_DATE(s.[object_id], s.stats_id) AS LastUpdated,
DATEDIFF(d,STATS_DATE(s.[object_id], s.stats_id),getdate()) DaysOld,
dsp.modification_counter,
s.auto_created,
s.user_created,
s.no_recompute,
s.[object_id],
s.stats_id,
sc.stats_column_id,
sc.column_id
FROM sys.stats s
JOIN sys.stats_columns sc
ON sc.[object_id] = s.[object_id] AND sc.stats_id = s.stats_id
JOIN sys.columns c ON c.[object_id] = sc.[object_id] AND c.column_id = sc.column_id
JOIN sys.partitions par ON par.[object_id] = s.[object_id]
JOIN sys.objects obj ON par.[object_id] = obj.[object_id]
CROSS APPLY sys.dm_db_stats_properties(sc.[object_id], s.stats_id) AS dsp
WHERE OBJECTPROPERTY(s.OBJECT_ID,'IsUserTable') = 1
AND (s.auto_created = 1 OR s.user_created = 1)
ORDER BY DaysOld;

EXEC sp_updatestats;
GO

select * from sys.sql_expression_dependencies


