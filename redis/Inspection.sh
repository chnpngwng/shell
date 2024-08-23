#!/bin/bash
# 检查是否安装了redis-cli工具
if ! command -v redis-cli &>/dev/null; then
    echo "redis-cli could not be found, please install it first."
    exit 1
fi
# 设置你的Redis地址和端口
REDIS_HOST="127.0.0.1"
REDIS_PORT=6379
# 登录的密码，如果没有设置密码，这一行可以注释掉
REDIS_PASSWORD="123456"
function check_redis() {
    local HOST=$1
    local PORT=$2
    local PASSWORD=$3
    # 执行INFO命令，获取Redis状态信息
    if [ -z "$PASSWORD" ]; then
        REDIS_INFO=$(redis-cli -h $HOST -p $PORT INFO)
    else
        REDIS_INFO=$(redis-cli -h $HOST -p $PORT -a $PASSWORD INFO)
    fi
    echo "Checking Redis on $HOST:$PORT"
    # 打印内存使用情况
    MEMORY_USED=$(echo "$REDIS_INFO" | grep "used_memory_human" | cut -d':' -f2)
    echo "Memory Used: $MEMORY_USED"
    # 打印连接数
    TOTAL_CONNECTIONS=$(echo "$REDIS_INFO" | grep "total_connections_received" | cut -d':' -f2)
    echo "Total Connections Received: $TOTAL_CONNECTIONS"
    # 打印当前连接数
    CURRENT_CONNECTIONS=$(echo "$REDIS_INFO" | grep "connected_clients" | cut -d':' -f2)
    echo "Currently Connected Clients: $CURRENT_CONNECTIONS"
    # 打印Key数量
    TOTAL_KEYS=$(redis-cli -h $HOST -p $PORT -a $PASSWORD DBSIZE)
    echo "Total Keys: $TOTAL_KEYS"
    # 打印角色，判断是否为主从结构或集群
    ROLE=$(echo "$REDIS_INFO" | grep "role" | cut -d':' -f2)
    echo "Role: $ROLE"
    if [ "$ROLE" = "master" ]; then
        echo "This is a master instance."
        # 打印已连接的从节点数量以及信息
        CONNECTED_SLAVES=$(echo "$REDIS_INFO" | grep "connected_slaves" | cut -d':' -f2)
        echo "Connected Slaves: $CONNECTED_SLAVES"
        for i in $(seq 0 $(($CONNECTED_SLAVES - 1))); do
            SLAVE_INFO=$(echo "$REDIS_INFO" | grep "^slave${i}:")
            echo "Slave ${i}: $SLAVE_INFO"
        done
    elif [ "$ROLE" = "slave" ]; then
        echo "This is a slave instance."
        # 打印主节点的信息
        MASTER_HOST=$(echo "$REDIS_INFO" | grep "master_host" | cut -d':' -f2)
        MASTER_PORT=$(echo "$REDIS_INFO" | grep "master_port" | cut -d':' -f2)
        echo "Connected to Master: $MASTER_HOST:$MASTER_PORT"
    fi
    echo "-----------------------------------------"
}
# 单机模式巡检
check_redis $REDIS_HOST $REDIS_PORT $REDIS_PASSWORD
# 如果有多个Redis实例（如主从结构或集群模式），可以增加相应的IP和端口
# 如：check_redis "192.168.1.1" 6380 "yourpassword"
# 集群模式巡检，通过集群节点遍历
# 获取集群节点列表
CLUSTER_NODES=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT -a $REDIS_PASSWORD CLUSTER NODES | awk '{print $2}' | awk -F@ '{print $1}')
for NODE in $CLUSTER_NODES; do
    NODE_IP=$(echo $NODE | cut -d':' -f1)
    NODE_PORT=$(echo $NODE | cut -d':' -f2)
    check_redis $NODE_IP $NODE_PORT $REDIS_PASSWORD
done
