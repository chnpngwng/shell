#!/bin/bash

host="112.116.65.46"

port="3307"

userName="root"

password="3er4#ER$"

dbname="mysql"

base='/usr/local/mysql'

##数据文件位置##
echo "================= mysql配置信息 ==============================="
echo "========= 基本配置信息 ==========="
lower_case_table_names="show variables like 'lower_case_table_names';"
lower_case_table_names_val=$(${base}/bin/mysql -h${host} -u${userName} -p${password} ${dbname} -P${port} -e "${lower_case_table_names}")
echo "不区分大小写：" $(echo ${lower_case_table_names_val} | cut -d' ' -f4)
_port="show variables like 'port';"
_port_val=$(${base}/bin/mysql -h${host} -u${userName} -p${password} ${dbname} -P${port} -e "${_port}")
echo "端口：" $(echo ${_port_val} | cut -d' ' -f4)
socket="show variables like 'socket';"
socket_val=$(${base}/bin/mysql -h${host} -u${userName} -p${password} ${dbname} -P${port} -e "${socket}")
echo "socket的值：" $(echo ${socket_val} | cut -d' ' -f4)
skip_name_resolve="show variables like 'skip_name_resolve';"
skip_name_resolve_val=$(${base}/bin/mysql -h${host} -u${userName} -p${password} ${dbname} -P${port} -e "${skip_name_resolve}")
echo "域名解析skip_name_resolve：" $(echo ${skip_name_resolve_val} | cut -d' ' -f4)
character_set_server="show variables like 'character_set_server';"
character_set_server_val=$(${base}/bin/mysql -h${host} -u${userName} -p${password} ${dbname} -P${port} -e "${character_set_server}")
echo "数据库字符集character_set_server：" $(echo ${character_set_server_val} | cut -d' ' -f4)
interactive_timeout="show variables like 'interactive_timeout';"
interactive_timeout_val=$(${base}/bin/mysql -h${host} -u${userName} -p${password} ${dbname} -P${port} -e "${interactive_timeout}")
echo "交互式连接超时时间(mysql工具、mysqldump等)interactive_timeout(秒)：" $(echo ${interactive_timeout_val} | cut -d' ' -f4)
wait_timeout="show variables like 'wait_timeout';"
wait_timeout_val=$(${base}/bin/mysql -h${host} -u${userName} -p${password} ${dbname} -P${port} -e "${wait_timeout}")
echo "非交互式连接超时时间，默认的连接mysql api程序,jdbc连接数据库等wait_timeout(秒)：" $(echo ${wait_timeout_val} | cut -d' ' -f4)
query_cache_type="show variables like 'query_cache_type';"
query_cache_type_val=$(${base}/bin/mysql -h${host} -u${userName} -p${password} ${dbname} -P${port} -e "${query_cache_type}")
echo "查询缓存query_cache_type：" $(echo ${query_cache_type_val} | cut -d' ' -f4)
innodb_version="show variables like 'innodb_version';"
innodb_version_val=$(${base}/bin/mysql -h${host} -u${userName} -p${password} ${dbname} -P${port} -e "${innodb_version}")
echo "数据库版本：" $(echo ${innodb_version_val} | cut -d' ' -f4)
trx_isolation="show variables like 'tx_isolation';"
trx_isolation_val=$(${base}/bin/mysql -h${host} -u${userName} -p${password} ${dbname} -P${port} -e "${trx_isolation}")
echo "mysql5.6隔离级别trx_isolation：" $(echo ${trx_isolation_val} | cut -d' ' -f4)
transaction_isolation="show variables like 'transaction_isolation';"
transaction_isolation_val=$(${base}/bin/mysql -h${host} -u${userName} -p${password} ${dbname} -P${port} -e "${transaction_isolation}")
echo "隔离级别transaction_isolation：" $(echo ${transaction_isolation_val} | cut -d' ' -f4)
datadir="show variables like '%datadir%';"
datadir_val=$(${base}/bin/mysql -h${host} -u${userName} -p${password} ${dbname} -P${port} -e "${datadir}")
echo "mysql 数据文件存放位置：" $(echo ${datadir_val} | cut -d' ' -f4)
echo "========= 连接数配置信息 ==========="
max_connections="show variables like 'max_connections';"
max_connections_val=$(${base}/bin/mysql -h${host} -u${userName} -p${password} ${dbname} -P${port} -e "${max_connections}")
echo "最大连接数（max_connections）：" $(echo ${max_connections_val} | cut -d' ' -f4)
Max_used_connections="show status like 'Max_used_connections';"
Max_used_connections_val=$(${base}/bin/mysql -h${host} -u${userName} -p${password} ${dbname} -P${port} -e "${Max_used_connections}")
echo "当前连接数（Max_used_connections）：" $(echo ${Max_used_connections_val} | cut -d' ' -f4)
max_connect_errors="show variables like 'max_connect_errors';"
max_connect_errors_val=$(${base}/bin/mysql -h${host} -u${userName} -p${password} ${dbname} -P${port} -e "${max_connect_errors}")
echo "最大错误连接数（max_connect_errors）：" $(echo ${max_connect_errors_val} | cut -d' ' -f4)
echo "========= binlog配置信息 ==========="
sync_binlog="show variables like 'sync_binlog';"
sync_binlog_val=$(${base}/bin/mysql -h${host} -u${userName} -p${password} ${dbname} -P${port} -e "${sync_binlog}")
echo "sync_binlog(0|1|n，查看是否采用双1模式)：" $(echo ${sync_binlog_val} | cut -d' ' -f4)
binlog_format="show variables like 'binlog_format';"
binlog_format_val=$(${base}/bin/mysql -h${host} -u${userName} -p${password} ${dbname} -P${port} -e "${binlog_format}")
echo "binlog格式：" $(echo ${binlog_format_val} | cut -d' ' -f4)
log_bin="show variables like 'log-bin';"
log_bin_val=$(${base}/bin/mysql -h${host} -u${userName} -p${password} ${dbname} -P${port} -e "${log-bin}")
echo "binlog文件（log-bin）：" $(echo ${log_bin_val} | cut -d' ' -f4)
expire_logs_days="show variables like 'expire_logs_days';"
expire_logs_days_val=$(${base}/bin/mysql -h${host} -u${userName} -p${password} ${dbname} -P${port} -e "${expire_logs_days}")
echo "binlog文件过期时间：" $(echo ${expire_logs_days_val} | cut -d' ' -f4)
binlog_cache_size="show variables like 'binlog_cache_size';"
binlog_cache_size_val=$(${base}/bin/mysql -h${host} -u${userName} -p${password} ${dbname} -P${port} -e "${binlog_cache_size}")
echo "binlog_cache_size：" $(echo ${binlog_cache_size_val} | cut -d' ' -f4)
max_binlog_cache_size="show variables like 'max_binlog_cache_size';"
max_binlog_cache_size_val=$(${base}/bin/mysql -h${host} -u${userName} -p${password} ${dbname} -P${port} -e "${max_binlog_cache_size}")
echo "max_binlog_cache_size：" $(echo ${max_binlog_cache_size_val} | cut -d' ' -f4)
max_binlog_size="show variables like 'max_binlog_size';"
max_binlog_size_val=$(${base}/bin/mysql -h${host} -u${userName} -p${password} ${dbname} -P${port} -e "${max_binlog_size}")
echo "binlog文件大小：" $(echo ${max_binlog_size_val} | cut -d' ' -f4)
master_info_repository="show variables like 'master_info_repository';"
master_info_repository_val=$(${base}/bin/mysql -h${host} -u${userName} -p${password} ${dbname} -P${port} -e "${master_info_repository}")
echo "master_info_repository(table|file,建议用table)：" $(echo ${master_info_repository_val} | cut -d' ' -f4)
relay_log_info_repository="show variables like 'relay_log_info_repository';"
relay_log_info_repository_val=$(${base}/bin/mysql -h${host} -u${userName} -p${password} ${dbname} -P${port} -e "${relay_log_info_repository}")
echo "relay_log_info_repository(table|file,建议用table)：" $(echo ${relay_log_info_repository_val} | cut -d' ' -f4)
relay_log_recovery="show variables like 'relay_log_recovery';"
relay_log_recovery_val=$(${base}/bin/mysql -h${host} -u${userName} -p${password} ${dbname} -P${port} -e "${relay_log_recovery}")
echo "relay_log_info_repository(建议开启)：" $(echo ${relay_log_recovery_val} | cut -d' ' -f4)
echo "========= GTID配置信息 ==========="
gtid_mode="show variables like 'gtid_mode';"
gtid_mode_val=$(${base}/bin/mysql -h${host} -u${userName} -p${password} ${dbname} -P${port} -e "${gtid_mode}")
echo "是否开启gtid_mode：" $(echo ${gtid_mode_val} | cut -d' ' -f4)
enforce_gtid_consistency="show variables like 'enforce_gtid_consistency';"
enforce_gtid_consistency_val=$(${base}/bin/mysql -h${host} -u${userName} -p${password} ${dbname} -P${port} -e "${enforce_gtid_consistency}")
echo "enforce_gtid_consistency是否开启：" $(echo ${enforce_gtid_consistency_val} | cut -d' ' -f4)
echo "（MySQL官方解释说当启用enforce_gtid_consistency功能的时候，MySQL只允许能够保障事务安全，并且能够被日志记录的SQL语句被执行，像create table … select 和 create temporary table语句，以及同时更新事务表和非事务表的SQL语句或事务都不允许执行）"
log_slave_updates="show variables like 'log_slave_updates';"
log_slave_updates_val=$(${base}/bin/mysql -h${host} -u${userName} -p${password} ${dbname} -P${port} -e "${log_slave_updates}")
echo "级联复制是否开启log_slave_updates：" $(echo ${log_slave_updates_val} | cut -d' ' -f4)
echo "======== innodb配置信息 ========="
innodb_data_home_dir="show variables like 'innodb_data_home_dir';"
innodb_data_home_dir_val=$(${base}/bin/mysql -h${host} -u${userName} -p${password} ${dbname} -P${port} -e "${innodb_data_home_dir}")
echo "innodb_data_home_dir：" $(echo ${innodb_data_home_dir_val} | cut -d' ' -f4)
innodb_buffer_pool_size="show variables like 'innodb_buffer_pool_size';"
innodb_buffer_pool_size_val=$(${base}/bin/mysql -h${host} -u${userName} -p${password} ${dbname} -P${port} -e "${innodb_buffer_pool_size}")
echo "innodb_buffer_pool_size（不超过内存的75%）：" $(echo ${innodb_buffer_pool_size_val} | cut -d' ' -f4)
innodb_buffer_pool_instances="show variables like 'innodb_buffer_pool_instances';"
innodb_buffer_pool_instances_val=$(${base}/bin/mysql -h${host} -u${userName} -p${password} ${dbname} -P${port} -e "${innodb_buffer_pool_instances}")
echo "innodb_buffer_pool_instances(innodb_buffer_pool_size小于8G实例个数建议为1)：" $(echo ${innodb_buffer_pool_instances_val} | cut -d' ' -f4)
innodb_log_file_size="show variables like 'innodb_log_file_size';"
innodb_log_file_size_val=$(${base}/bin/mysql -h${host} -u${userName} -p${password} ${dbname} -P${port} -e "${innodb_log_file_size}")
echo "redo文件的大小innodb_log_file_size：" $(echo ${innodb_log_file_size_val} | cut -d' ' -f4)
innodb_log_files_in_group="show variables like 'innodb_log_files_in_group';"
innodb_log_files_in_group_val=$(${base}/bin/mysql -h${host} -u${userName} -p${password} ${dbname} -P${port} -e "${innodb_log_files_in_group}")
echo "redo文件的个数innodb_log_files_in_group：" $(echo ${innodb_log_files_in_group_val} | cut -d' ' -f4)
innodb_flush_log_at_trx_commit="show variables like 'innodb_flush_log_at_trx_commit';"
innodb_flush_log_at_trx_commit_val=$(${base}/bin/mysql -h${host} -u${userName} -p${password} ${dbname} -P${port} -e "${innodb_flush_log_at_trx_commit}")
echo "innodb_flush_log_at_trx_commit（0|1|2，跟sync_binlog双1）：" $(echo ${innodb_flush_log_at_trx_commit_val} | cut -d' ' -f4)
innodb_io_capacity="show variables like 'innodb_io_capacity';"
innodb_io_capacity_val=$(${base}/bin/mysql -h${host} -u${userName} -p${password} ${dbname} -P${port} -e "${innodb_io_capacity}")
echo "innodb_io_capacity（机械硬盘200，固态2000，闪存20000）：" $(echo ${innodb_io_capacity_val} | cut -d' ' -f4)
transaction_isolation="show variables like 'transaction_isolation';"
transaction_isolation_val=$(${base}/bin/mysql -h${host} -u${userName} -p${password} ${dbname} -P${port} -e "${transaction_isolation}")
echo "隔离级别transaction_isolation：" $(echo ${transaction_isolation_val} | cut -d' ' -f4)
trx_isolation="show variables like 'tx_isolation';"
trx_isolation_val=$(${base}/bin/mysql -h${host} -u${userName} -p${password} ${dbname} -P${port} -e "${trx_isolation}")
echo "mysql5.6隔离级别trx_isolation：" $(echo ${trx_isolation_val} | cut -d' ' -f4)
innodb_max_undo_log_size="show variables like 'innodb_max_undo_log_size';"
innodb_max_undo_log_size_val=$(${base}/bin/mysql -h${host} -u${userName} -p${password} ${dbname} -P${port} -e "${innodb_max_undo_log_size}")
echo "undo大小innodb_max_undo_log_size：" $(echo ${innodb_max_undo_log_size_val} | cut -d' ' -f4)
innodb_undo_tablespaces="show variables like 'innodb_undo_tablespaces';"
innodb_undo_tablespaces_val=$(${base}/bin/mysql -h${host} -u${userName} -p${password} ${dbname} -P${port} -e "${innodb_max_undo_log_size}")
echo "undo个数innodb_undo_tablespaces：" $(echo ${innodb_undo_tablespaces_val} | cut -d' ' -f4)
echo "========= rep配置信息 ==========="
slave_parallel_type="show variables like 'slave-parallel-type';"
slave_parallel_type_val=$(${base}/bin/mysql -h${host} -u${userName} -p${password} ${dbname} -P${port} -e "${slave_parallel_type}")
echo "slave复制模式：" $(echo ${slave_parallel_type_val} | cut -d' ' -f4)
slave_parallel_workers="show variables like 'slave-parallel-workers';"
slave_parallel_workers_val=$(${base}/bin/mysql -h${host} -u${userName} -p${password} ${dbname} -P${port} -e "${slave_parallel_workers}")
echo "slave并发复制：" $(echo ${slave_parallel_workers_val} | cut -d' ' -f4)
echo "================= 内存配置情况 ==============================="
mem_dis_1="show variables like 'innodb_buffer_pool_size';"
mem_dis_1_val=$(${base}/bin/mysql -h${host} -u${userName} -p${password} ${dbname} -P${port} -e "${mem_dis_1}")
mem_dis_1_val_1=$(echo ${mem_dis_1_val} | cut -d' ' -f4)
mem_dis_1_val_2=$(echo | awk "{print $mem_dis_1_val_1/1024/1024}")
echo "InnoDB 数据和索引缓存：" $mem_dis_1_val_1
mem_dis_2="show variables like 'innodb_log_buffer_size';"
mem_dis_2_val=$(${base}/bin/mysql -h${host} -u${userName} -p${password} ${dbname} -P${port} -e "${mem_dis_2}")
mem_dis_2_val_1=$(echo ${mem_dis_2_val} | cut -d' ' -f4)
mem_dis_2_val_2=$(echo | awk "{print $mem_dis_2_val_1/1024/1024}")
echo "InnoDB 日志缓冲区：" $mem_dis_2_val_1
mem_dis_3="show variables like 'binlog_cache_size';"
mem_dis_3_val=$(${base}/bin/mysql -h${host} -u${userName} -p${password} ${dbname} -P${port} -e "${mem_dis_3}")
mem_dis_3_val_1=$(echo ${mem_dis_3_val} | cut -d' ' -f4)
mem_dis_3_val_2=$(echo | awk "{print $mem_dis_3_val_1/1024/1024}")
echo "二进制日志缓冲区：" $mem_dis_3_val_1
mem_dis_4="show variables like 'thread_cache_size';"
mem_dis_4_val=$(${base}/bin/mysql -h${host} -u${userName} -p${password} ${dbname} -P${port} -e "${mem_dis_4}")
echo "连接线程缓存：" $(echo $mem_dis_4_val | cut -d' ' -f4)
mem_dis_5="show variables like 'query_cache_size';"
mem_dis_5_val=$(${base}/bin/mysql -h${host} -u${userName} -p${password} ${dbname} -P${port} -e "${mem_dis_5}")
echo "查询缓存：" $(echo ${mem_dis_5_val} | cut -d' ' -f4)
mem_dis_6="show variables like 'table_open_cache';"
mem_dis_6_val=$(${base}/bin/mysql -h${host} -u${userName} -p${password} ${dbname} -P${port} -e "${mem_dis_6}")
echo "表缓存：" $(echo ${mem_dis_6_val} | cut -d' ' -f4)
mem_dis_7="show variables like 'table_definition_cache';"
mem_dis_7_val=$(${base}/bin/mysql -h${host} -u${userName} -p${password} ${dbname} -P${port} -e "${mem_dis_7}")
echo "表定义缓存：" $(echo ${mem_dis_7_val} | cut -d' ' -f4)
mem_dis_8="show variables like 'max_connections';"
mem_dis_8_val=$(${base}/bin/mysql -h${host} -u${userName} -p${password} ${dbname} -P${port} -e "${mem_dis_8}")
echo "最大线程数：" $(echo ${mem_dis_8_val} | cut -d' ' -f4)
mem_dis_9="show variables like 'thread_stack';"
mem_dis_9_val=$(${base}/bin/mysql -h${host} -u${userName} -p${password} ${dbname} -P${port} -e "${mem_dis_9}")
echo "线程栈信息使用内存：" $(echo ${mem_dis_9_val} | cut -d' ' -f4)
mem_dis_10="show variables like 'sort_buffer_size';"
mem_dis_10_val=$(${base}/bin/mysql -h${host} -u${userName} -p${password} ${dbname} -P${port} -e "${mem_dis_10}")
echo "排序使用内存：" $(echo ${mem_dis_10_val} | cut -d' ' -f4)
mem_dis_11="show variables like 'join_buffer_size';"
mem_dis_11_val=$(${base}/bin/mysql -h${host} -u${userName} -p${password} ${dbname} -P${port} -e "${mem_dis_11}")
echo "Join操作使用内存：" $(echo ${mem_dis_11_val} | cut -d' ' -f4)
mem_dis_12="show variables like 'read_buffer_size';"
mem_dis_12_val=$(${base}/bin/mysql -h${host} -u${userName} -p${password} ${dbname} -P${port} -e "${mem_dis_12}")
echo "顺序读取数据缓冲区使用内存：" $(echo ${mem_dis_12_val} | cut -d' ' -f4)
mem_dis_13="show variables like 'read_rnd_buffer_size';"
mem_dis_13_val=$(${base}/bin/mysql -h${host} -u${userName} -p${password} ${dbname} -P${port} -e "${mem_dis_13}")
echo "随机读取数据缓冲区使用内存：" $(echo ${mem_dis_13_val} | cut -d' ' -f4)
mem_dis_14="show variables like 'tmp_table_size';"
mem_dis_14_val=$(${base}/bin/mysql -h${host} -u${userName} -p${password} ${dbname} -P${port} -e "${mem_dis_14}")
echo "临时表使用内存：" $(echo ${mem_dis_14_val} | cut -d' ' -f4)
echo "================= QPS ==============================="
Questions1="show global status like 'Questions';"
Questions1_val=$(${base}/bin/mysql -h${host} -u${userName} -p${password} ${dbname} -P${port} -e "${Questions1}")
sleep 1
Questions2="show global status like 'Questions';"
Questions2_val=$(${base}/bin/mysql -h${host} -u${userName} -p${password} ${dbname} -P${port} -e "${Questions2}")
echo "QPS：$(($(echo ${Questions2_val} | cut -d' ' -f4) - $(echo ${Questions1_val} | cut -d' ' -f4)))"
echo "================= TPS ==============================="
Com_commit="show  global status like 'Com_commit';"
Com_commit_val=$(${base}/bin/mysql -h${host} -u${userName} -p${password} ${dbname} -P${port} -e "${Com_commit}")
Com_rollback="show global status like 'Com_rollback';"
Com_rollback_val=$(${base}/bin/mysql -h${host} -u${userName} -p${password} ${dbname} -P${port} -e "${Com_rollback}")
echo "TPS：" $(($(echo ${Com_commit_val} | cut -d' ' -f4) + $(echo ${Com_rollback_val} | cut -d' ' -f4)))
##缓存命中率##
echo "================= 缓存命中情况 ==============================="
cache_hits="show global status like 'QCache_hits';"
hits=$(${base}/bin/mysql -h${host} -u${userName} -p${password} ${dbname} -P${port} -e "${cache_hits}")
hits_val=$(echo ${hits} | cut -d' ' -f4)
echo "缓存命中次数：" ${hits_val}
cache_not_hits="show global status like  'Qcache_inserts';"
not_hits=$(${base}/bin/mysql -h${host} -u${userName} -p${password} ${dbname} -P${port} -e "${cache_not_hits}")
not_hits_val=$(echo ${not_hits} | cut -d' ' -f4)
echo "缓存未命中次数：" ${not_hits_val}
cache_hits_rate_1=$(($hits_val - $not_hits_val))
cache_hits_rate_2=$(echo | awk "{print $cache_hits_rate_1/$hits_val * 100}")
echo "缓存命中率：" ${cache_hits_rate_2} "%"
echo "================= 主从复制 ============================="
slave_parallel_type="show variables like 'slave-parallel-type';"
slave_parallel_type_val=$(${base}/bin/mysql -h${host} -u${userName} -p${password} ${dbname} -P${port} -e "${slave_parallel_type}")
echo "slave复制模式：" $(echo ${slave_parallel_type_val} | cut -d' ' -f4)
slave_parallel_workers="show variables like 'slave-parallel-workers';"
slave_parallel_workers_val=$(${base}/bin/mysql -h${host} -u${userName} -p${password} ${dbname} -P${port} -e "${slave_parallel_workers}")
echo "slave并发复制：" $(echo ${slave_parallel_workers_val} | cut -d' ' -f4)
${base}/bin/mysql -h${host} -u${userName} -p${password} ${dbname} -P${port} -e "show master status\G;"
${base}/bin/mysql -h${host} -u${userName} -p${password} ${dbname} -P${port} -e "show slave status\G;"
echo "================= 半同步复制 ==============================="
${base}/bin/mysql -h${host} -u${userName} -p${password} ${dbname} -P${port} -e "show variables like '%semi%';"
echo "================= 慢查询 ==============================="
slow_query_log_file=$(${base}/bin/mysql -h${host} -u${userName} -p${password} ${dbname} -P${port} -e "show variables like 'slow_query_log_file';" | grep 'slow' | awk '{print $2}')
slow_query_log=$(${base}/bin/mysql -h${host} -u${userName} -p${password} ${dbname} -P${port} -e "show variables like 'slow_query_log';" | grep 'slow' | awk '{print $2}')
long_query_time=$(${base}/bin/mysql -h${host} -u${userName} -p${password} ${dbname} -P${port} -e "show variables like 'long_query_time';" | grep 'long_query_time' | awk '{print $2}')
log_queries_not_using_indexes=$(${base}/bin/mysql -h${host} -u${userName} -p${password} ${dbname} -P${port} -e "show variables like 'log_queries_not_using_indexes';" | grep 'log_queries_not_using_indexes' | awk '{print $2}')
if [ ${slow_query_log} == "ON" ]; then
    echo "慢查询状态(slow_query_log)：${slow_query_log} ;long_query_time(s) : ${long_query_time};log_queries_not_using_indexes: ${log_queries_not_using_indexes};慢查询top10，如下："
    mysqldumpslow -s c -t 10 ${slow_query_log_file}
else
    echo "慢查询状态(slow_query_log)：${slow_query_log} ，未开启慢查询。"
fi
##等待事件##
echo "================= 数据库大小 ==============================="
${base}/bin/mysql -h${host} -u${userName} -p${password} ${dbname} -P${port} -e "SELECT
table_schema,
sum( data_length )/ 1024 / 1024 / 1024 AS data_length,
sum( index_length )/ 1024 / 1024 / 1024 AS index_length,
sum( data_length + index_length )/ 1024 / 1024 / 1024 AS sum_data_index
FROM
information_schema.TABLES
WHERE
table_schema NOT IN ( 'mysql', 'information_schema', 'performance_schema', 'sys' )
GROUP BY
table_schema;"
echo "================= 数据碎片 ==============================="
${base}/bin/mysql -h${host} -u${userName} -p${password} ${dbname} -P${port} -e "SELECT
TABLE_SCHEMA,
TABLE_NAME,
ENGINE,
concat( splinter, 'G' ) '碎片(G)'
FROM
(
SELECT
TABLE_SCHEMA,
TABLE_NAME,
ENGINE,
ROUND(( DATA_LENGTH + INDEX_LENGTH - TABLE_ROWS * AVG_ROW_LENGTH )/ 1024 / 1024 / 1024 ) splinter
FROM
information_schema.TABLES
WHERE
TABLE_TYPE = 'BASE TABLE'
) a
WHERE
splinter > 1
ORDER BY
splinter DESC;"
echo "================= 锁查询 ==============================="
${base}/bin/mysql -h${host} -u${userName} -p${password} ${dbname} -P${port} -e "SELECT
r.trx_isolation_level,
r.trx_id waiting_trx_id,
r.trx_mysql_thread_id waiting_trx_thread,
r.trx_state waiting_trx_state,
lr.lock_mode waiting_trx_lock_mode,
lr.lock_type waiting_trx_lock_type,
lr.lock_table waiting_trx_lock_table,
lr.lock_index waiting_trx_lock_index,
r.trx_query waiting_trx_query,
b.trx_id blocking_trx_id,
b.trx_mysql_thread_id blocking_trx_thread,
b.trx_state blocking_trx_state,
lb.lock_mode blocking_trx_lock_mode,
lb.lock_type blocking_trx_lock_type,
lb.lock_table blocking_trx_lock_table,
lb.lock_index blocking_trx_lock_index,
b.trx_query blocking_query
FROM
information_schema.innodb_lock_waits w
INNER JOIN information_schema.innodb_trx b ON b.trx_id = w.blocking_trx_id
INNER JOIN information_schema.innodb_trx r ON r.trx_id = w.requesting_trx_id
INNER JOIN information_schema.innodb_locks lb ON lb.lock_trx_id = w.blocking_trx_id
INNER JOIN information_schema.innodb_locks lr ON lr.lock_trx_id = w.requesting_trx_id \G;"
echo "================= 等待事件 ==============================="
top_event_10="select event_name, count_star, sum_timer_wait from performance_schema.events_waits_summary_global_by_event_name where count_star > 0 order by sum_timer_wait desc limit 10;"
echo "等待事件 TOP 10："
${base}/bin/mysql -h${host} -u${userName} -p${password} ${dbname} -P${port} -e "${top_event_10}"
echo "==================最近一周的错误日志 =========================="
_time=$(date -d '6 days ago' +%Y-%m-%d)\|$(date -d '5 days ago' +%Y-%m-%d)\|$(date -d '4 days ago' +%Y-%m-%d)\|$(date -d '3 days ago' +%Y-%m-%d)\|$(date -d '2 days ago' +%Y-%m-%d)\|$(date -d '1 days ago' +%Y-%m-%d)\|$(date -d '0 days ago' +%Y-%m-%d)
log_error=$(${base}/bin/mysql -h${host} -u${userName} -p${password} ${dbname} -P${port} -e "show variables like 'log_error';" | grep 'log_error' | awk '{print $2}')
#grep -i -E 'error' /home/logs/mysql/mysqld.err* | grep -E '2019-03-28|2019-06-14'
grep -i -E "error" ${log_error} | grep -E "${_time}"
