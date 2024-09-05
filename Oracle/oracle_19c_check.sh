#!/bin/bash

# 设置Oracle环境变量
export ORACLE_HOME=/u01/app/oracle/product/19.0.0/dbhome_1
export ORACLE_SID=cdb19c
export PATH=$PATH:$ORACLE_HOME/bin
echo "=========================主机层面=================================="
cat /etc/system-release
cat /etc/redhat-releas
sqlplus -version
opatch lspatches
host_ip=$(ifconfig -a | grep inet | grep -v 127.0.0.1 | grep -v inet6 | awk '{print $2}' | tr -d "addr:")
mkdir /home/$host_ip
mkdir /home/$host_ip/$(date +'%Y%m%d')
cur_time=$(date '+%Y-%m-%d %H:%M:%S')
echo " 现在是时间：$cur_time，服务器ip: $host_ip,巡检记录情况！"
echo "**系统负载信息以及系统运行时间等信息 "
uptime
echo "************* *******************"
echo "***********磁盘使用情况******************* "
df -h
echo "*********** *******************"
echo "内存使用情况** "
free -m
free -h （可以这个）
echo "内存使用情况** "
echo "CPU使用情况** "
vmstat
echo "***********CPU使用情况*************"
echo "******************磁盘使用告警*********************** "
df -Ph | grep -vE '^Filesystem|tmpfs|cdrom' | awk '{ print $5,$1 }' | while read output; do
    echo $output
    used=$(echo $output | awk '{print $1}' | sed s/%//g)
    partition=$(echo $output | awk '{print $2}')
    if [ $used -ge 40 ]; then #预警界限，使用的百分比
        echo " 警告！警告！ $host_ip：上的分区："$partition" 已使用 $used% $(date)，请注意清理！ "
    fi
    echo " 恭喜！$host_ip：磁盘空间正常！使用为$used "
done
crontab -l
# 定义函数用于打印分隔线
print_divider() {
    echo "=========================数据库层面=================================="
}
# 检查Oracle服务
print_divider
echo "===== Oracle Services ====="
ps -ef | grep pmon | grep -v grep
if [ $? -eq 0 ]; then
    echo "Oracle services are running."
else
    echo "Oracle services are not running."
fi
echo ""
print_divider
# 检查监听状态
echo "===== Listener Status ====="
lsnrctl status
echo ""
print_divider
# 登录数据库进行进一步检查
sqlplus -s / as sysdba <<EOF
SET PAGESIZE 1000
SET LINESIZE 200
SET FEEDBACK OFF
SET ECHO OFF
PROMPT ===== 检查版本信息 =====
COL BANNER FORMAT A60 WORD_WRAP
SELECT BANNER FROM V\$VERSION;
PROMPT
PROMPT ===== 检查实例状态 =====
COL INSTANCE_NAME FORMAT A20
COL STATUS FORMAT A10
SELECT INSTANCE_NAME, STATUS FROM V\$INSTANCE;
PROMPT
PROMPT ===== 检查数据库状态 =====
COL NAME FORMAT A20
COL LOG_MODE FORMAT A10
COL OPEN_MODE FORMAT A15
COL DATABASE_ROLE FORMAT A15
SELECT NAME, LOG_MODE, OPEN_MODE, DATABASE_ROLE FROM V\$DATABASE;
PROMPT
PROMPT ===== 检查连接数 =====
COL ACTIVE_SESSIONS FORMAT A20
SELECT COUNT(0) AS ACTIVE_SESSIONS
FROM V\$SESSION
WHERE USERNAME IS NOT NULL AND STATUS = 'ACTIVE';
PROMPT
PROMPT ===== 检查字符集 =====
select userenv('language') from dual;
PROMPT
PROMPT ===== 检查归档打开状态 =====
COL NAME FORMAT A30
COL OPEN_MODE FORMAT A20
COL LOG_MODE FORMAT A20
SELECT NAME, OPEN_MODE, LOG_MODE FROM V\$DATABASE;
ARCHIVE LOG LIST;
PROMPT
PROMPT ===== 查看归档是否有限制=====
COL PARAMETER FORMAT A40
COL VALUE FORMAT A10
SELECT NAME AS PARAMETER, VALUE FROM V\$PARAMETER
WHERE NAME IN ('log_archive_max_logfiles', 'log_archive_max_size');
PROMPT
PROMPT ===== 查看归档配额 =====
COL PARAMETER FORMAT A40
COL VALUE FORMAT A10
SELECT NAME AS PARAMETER, VALUE FROM V\$SYSTEM_PARAMETER
WHERE NAME LIKE 'db_recovery_file_dest%' OR NAME = 'log_archive_max_processes';
PROMPT ===== 检查归档日志的大小 =====
set lines 9999
SELECT SUM(BLOCKS*BLOCK_SIZE)/1024/1024 AS "ARCHIVE LOG SIZE (MB)" FROM V\$ARCHIVED_LOG;
PROMPT
--当前的归档日志信息
SELECT * FROM V\$ARCHIVED_LOG;
PROMPT
PROMPT ===== 归档日志监控=====
set line 100
select trunc(FIRST_TIME) datum,
       count(*) total,
       round(10 * sum(blocks * block_size) / 1024 / 1024 ) / 10 MB
  from v\$archived_log
 group by trunc(FIRST_TIME)
 order by 1;
PROMPT
PROMPT ===== 检查是否有锁表 =====
select DISTINCT b.object_name,to_char(nvl(c.sql_exec_start,c.prev_exec_start),'yyyymmdd hh24:mi:ss') exec_time,C.STATUS,OSUSER,MACHINE,PROGRAM,NVL(SQL_ID,PREV_SQL_ID) SQL_ID,STATE,BLOCKING_SESSION_STATUS,EVENT,WAIT_CLASS_ID
,'alter system disconnect session '''||c.SID||','||SERIAL#||',@'||A.INST_ID||''' immediate;' disconnectSQL --执行解锁语句
  from GV\$LOCKED_OBJECT a,DBA_OBJECTS b,gv\$session c
 where a.object_id=b.object_id and a.inst_id=c.inst_id and a.session_id=c.sid
   --and OBJECT_NAME ='TB_TEST' --指定表
--and nvl(c.sql_exec_start,c.prev_exec_start)<sysdate-1/24 --超过1小时
   order by 2;
PROMPT
PROMPT ===== 检查Oracle在线日志状态 =====
select 
group#,status,type,member 
from v\$logfile;
PROMPT
PROMPT ===== 检查表空间是否自动扩展 =====
SELECT
    TABLESPACE_NAME,
    FILE_NAME,
    AUTOEXTENSIBLE,
    INCREMENT_BY
FROM
    DBA_DATA_FILES
WHERE
    AUTOEXTENSIBLE = 'YES';
PROMPT
PROMPT ===== 检查一些扩展异常的对象 =====
select Segment_Name,
Segment_Type,
TableSpace_Name, 
(Extents / Max_extents) * 100 Percent
From sys.DBA_Segments
Where Max_Extents != 0
and (Extents / Max_extents) * 100 >= 95
order By Percent;
PROMPT
PROMPT ===== 检查数据库的等待事件=====
set pages 80
set lines 120
col event for a40
select sid, event, p1, p2, p3, WAIT_TIME, SECONDS_IN_WAIT
from v\$session_wait
where event not like 'SQL%'
and event not like 'rdbms%';
PROMPT
PROMPT ===== 检查Disk Read最高的SQL语句的获取=====
SELECT SQL_TEXT
FROM (SELECT * FROM V\$SQLAREA ORDER BY DISK_READS)
WHERE ROWNUM <= 5;
PROMPT
PROMPT ===== 查找前十条性能差的sql=====
set lines 9999
SELECT *
FROM (SELECT PARSING_USER_ID 
EXECUTIONS,
SORTS,
COMMAND_TYPE,
DISK_READS, 
SQL_TEXT
FROM V\$SQLAREA
ORDER BY DISK_READS DESC)
WHERE ROWNUM < 10;
PROMPT
PROMPT ===== 检查运行很久的SQL=====
COLUMN USERNAME FORMAT A12
COLUMN OPNAME FORMAT A16
COLUMN PROGRESS FORMAT A8
SELECT USERNAME,
       SID,
       OPNAME,
       ROUND(SOFAR * 100 / TOTALWORK, 0) || '%' AS PROGRESS,
       TIME_REMAINING,
       SQL_TEXT
FROM V\$SESSION_LONGOPS, V\$SQL
WHERE TIME_REMAINING <> 0
AND SQL_ADDRESS = ADDRESS
AND SQL_HASH_VALUE = HASH_VALUE;
PROMPT
PROMPT ===== 检查碎片程度高的表=====
SELECT segment_name table_name, COUNT(*) extents
FROM dba_segments
WHERE owner NOT IN ('SYS', 'SYSTEM')
GROUP BY segment_name
HAVING COUNT(*) = (SELECT MAX(COUNT(*))
                     FROM dba_segments
                    GROUP BY segment_name);
PROMPT
-- 检查数据文件与空间类使用情况
PROMPT ===== 检查数据文件与空间类使用情况 =====
PROMPT ===== 各种文件数量 =====
select count(*) from v\$tempfile;
select count(*) from v\$datafile;
PROMPT
PROMPT ===== 数据文件状态 =====
select  t.online_status,count(*)
from dba_data_files  t
group by  t.online_status ;
PROMPT
PROMPT ===== 检查内存的命中率 =====
 select 1 - ((physical.value - direct.value - lobs.value) / logical.value)
 "Buffer Cache Hit Ratio" 
 from v\$sysstat physical,v\$sysstat direct,v\$sysstat lobs,v\$sysstat logical
 where physical.name = 'physical reads'
 and direct.name='physical reads direct'
 and lobs.name='physical reads direct (lob)'
 and logical.name='session logical reads';
select   (1-(sum(getmisses)/sum(gets)))  "Dictionary Hit Ratio"
from  v\$rowcache;
PROMP
PROMPT ===== 检查共享池命中率 =====
select sum(pinhits) / sum(pins) * 100 from v\$librarycache;
PROMPT
PROMPT ===== 查看表占用存储及表行数 =====
set lines 9999
SELECT /*+ PARALLEL(8) */ a.owner "用户",A.TABLE_NAME "表名",b.TABLESPACE_NAME "表空间名",B.UNITS/1024/1024/1024 "占用多少GB",A.NUM_ROWS "行数（非实时，可通过表分析更新）",A.PARTITIONED "是否为分区表"
FROM all_TABLES A 
LEFT JOIN (SELECT  SUM(BYTES) UNITS,OWNER,SEGMENT_NAME,max(TABLESPACE_NAME) TABLESPACE_NAME 
     FROM dba_SEGMENTS GROUP BY SEGMENT_NAME,OWNER)B 
ON  (a.TABLE_NAME=b.SEGMENT_NAME  and a.owner=b.owner) 
WHERE UNITS is not null
 ORDER BY 4 DESC;
PROMPT
PROMPT ===== 查看表空间大小 =====
set linesize 200;
col TABLESPACE_NAME  for a30;
select a.TABLESPACE_NAME tbs_name,
round(a.BYTES/1024/1024) Total_MB,
round((a.BYTES-nvl(b.BYTES, 0)) /1024/1024) Used_MB,
round((1-((a.BYTES-nvl(b.BYTES,0))/a.BYTES))*100,2) Pct_USED,
nvl(round(b.BYTES/1024/1024), 0) Free_MB ,
auto
from   (select   TABLESPACE_NAME
sum(BYTES) BYTES,
max(AUTOEXTENSIBLE) AUTO
from     sys.dba_data_files
group by TABLESPACE_NAME) a,
(select   TABLESPACE_NAME,
sum(BYTES) BYTES
from     sys.dba_free_space
group by TABLESPACE_NAME) b
where  a.TABLESPACE_NAME = b.TABLESPACE_NAME (+)
order  by ((a.BYTES-b.BYTES)/a.BYTES) desc;
PROMPT
PROMPT ===== 查看表空间实际使用率 =====
set linesize 200;
col owner  for a30;
SELECT owner,TABLE_NAME,ROUND((BLOCKS*8192/1024/1024),2)"理论大小M",
ROUND((NUM_ROWS*AVG_ROW_LEN/1024/1024),2)"实际大小M",
ROUND( (BLOCKS * 8192 / 1024 / 1024) - (NUM_ROWS * AVG_ROW_LEN / 1024 / 1024),2) "Data lower than HWM in MB" , 
to_char(round((NUM_ROWS*AVG_ROW_LEN/1024/1024)/(BLOCKS*8192/1024/1024),3)*100,'fm999990.99999')||'%' "实际使用率%" 
FROM dba_TABLES where  (NUM_ROWS*AVG_ROW_LEN/1024/1024)/(BLOCKS*8192/1024/1024)<0.6
AND OWNER NOT IN ('SYS', 'SYSTEM', 'SYSMAN', 'DMSYS', 'OLAPSYS', 'XDB','EXFSYS', 'CTXSYS','WMSYS', 'DBSNMP', 'ORDSYS', 'OUTLN', 'TSMSYS', 'MDSYS','OGG')
AND BLOCKS NOT IN ('0') ORDER BY 3 DESC; 
PROMPT
-- 检查SGA
PROMPT ===== SGA SIZE =====
-- SGA 各部分大小
show sga;
SELECT * FROM V\$SGAINFO;
-- SGA设置大小 
show parameter sga_target;
-- SGA各个池大小
COL name FORMAT a32;
SELECT pool, name, bytes/1024/1024 M
  FROM v\$sgastat
WHERE pool IS NULL
    OR pool != 'shared pool'
    OR (pool = 'shared pool' AND
       (name IN
       ('dictionary cache', 'enqueue', 'library
       cache', 'parameters', 'processes', 'sessions', 'free memory')))
ORDER BY pool DESC NULLS FIRST, name;
PROMPT
-- 检查PGA
PROMPT ===== 检查PGA =====
show parameters area_size;
PROMPT
PROMPT ===== 查看buffer cache 命中率 =====
select 1 - (sum(decode(name, 'physical reads', value, 0)) /
        (sum(decode(name, 'db block gets', value, 0)) +
        (sum(decode(name, 'consistent gets', value, 0))))) "Buffer Hit Ratio"
from v\$sysstat;
select name,
       physical_reads,
       (consistent_gets + db_block_gets) logic_reads,
       1 - (physical_reads) / (consistent_gets + db_block_gets) hit_radio
from v\$buffer_pool_statistics;
PROMPT
PROMPT ===== 查看cache =====
show parameter cache;
-- 各种读取的统计
-- Database read buffer cache hit ratio =
-- -1 – (physical reads / (db block gets + consistent gets))
SELECT to_char(value,'9999999999999'), name FROM V\$SYSSTAT WHERE name IN
('physical reads', 'db block gets', 'consistent gets');
SELECT 'Database Buffer Cache Hit Ratio ' "Ratio"
        , ROUND((1-
        ((SELECT SUM(value) FROM V\$SYSSTAT WHERE name = 'physical reads')
        / ((SELECT SUM(value) FROM V\$SYSSTAT WHERE name = 'db block gets')
        + (SELECT SUM(value) FROM V\$SYSSTAT WHERE name = 'consistent gets')
        ))) * 100)||'%' "Percentage"
        FROM DUAL;
PROMPT
PROMPT ===== 查询解析比率 =====
SELECT 'Soft Parses ' "Ratio",
ROUND(((SELECT SUM(value)
FROM V\$SYSSTAT
WHERE name = 'parse count (total)') -
(SELECT SUM(value)
FROM V\$SYSSTAT
WHERE name = 'parse count (hard)')) /
(SELECT SUM(value) FROM V\$SYSSTAT WHERE name = 'execute count') * 100,
2) || '%' "Percentage"
FROM DUAL
UNION
SELECT 'Hard Parses ' "Ratio",
ROUND((SELECT SUM(value)
FROM V\$SYSSTAT
WHERE name = 'parse count (hard)') /
(SELECT SUM(value) FROM V\$SYSSTAT WHERE name = 'execute count') * 100,
2) || '%' "Percentage"
FROM DUAL
UNION
SELECT 'Parse Failures ' "Ratio",
ROUND((SELECT SUM(value)
FROM V\$SYSSTAT
WHERE name = 'parse count (failures)') /
(SELECT SUM(value)
FROM V\$SYSSTAT
WHERE name = 'parse count (total)') * 100,
5) || '%' "Percentage"
FROM DUAL
PROMPT
PROMPT ===== 检查日志的切换频率 =====
select sequence#,
to_char(first_time, 'yyyymmdd_hh24:mi:ss') firsttime,
round((first_time - lag(first_time) over(order by first_time)) * 24 * 60,2) minutes
from v\$log_history
where 1=1
order by first_time, minutes;
PROMPT
PROMPT ===== 检查redo大小 =====
select max(lebsz) from x\$kccle;
PROMPT
PROMPT ===== 查看user commit次数 =====
select to_number(value,99999999999) from v\$sysstat where name='user commits';
PROMPT
PROMPT ===== 检查数据文件状态 =====
COLUMN FILE_NAME FORMAT A60 WORD_WRAPPED
COLUMN STATUS FORMAT A10
SELECT FILE_ID, FILE_NAME, STATUS FROM DBA_DATA_FILES;
PROMPT
PROMPT ===== 检查等待事件=====
SELECT * FROM (
    SELECT EVENT, TOTAL_WAITS, TIME_WAITED
    FROM V\$SYSTEM_EVENT
    ORDER BY TIME_WAITED DESC)
WHERE ROWNUM <= 5;
PROMPT
PROMPT ===== 检查无效对象 =====
SELECT OBJECT_NAME, OBJECT_TYPE, STATUS
FROM DBA_OBJECTS
WHERE STATUS = 'INVALID';
PROMPT
PROMPT ===== 检查备份状态 =====
col status for a10
col input_type for a20
col INPUT_BYTES_DISPLAY for a10
col OUTPUT_BYTES_DISPLAY for a10
col TIME_TAKEN_DISPLAY for a10
select input_type,
       status,
       to_char(start_time,
               'yyyy-mm-dd hh24:mi:ss'),
       to_char(end_time,
               'yyyy-mm-dd hh24:mi:ss'),
       input_bytes_display,
       output_bytes_display,
       time_taken_display,
       COMPRESSION_RATIO
  from v\$rman_backup_job_details
 where start_time > date '2021-07-01'
 order by 3 desc;
PROMPT
EXIT;
EOF
rman target / <<EOF
list backup of database;
EXIT;
EOF
print_divider
echo "================ End of Oracle 19c Health Check ================"
