#!/bin/bash

# 提示用户将文件放在 /root 目录下
echo "请将所有相关文件（sdata.lic 和 dayuan-sdata-business-1.0.jar）放在 /root 目录下。"

# 定义文件和对应的目标目录数组
FILES=(
    "/root/sdata.lic"
    "/root/sdata.lic"
    "/root/dayuan-sdata-business-1.0.jar"
)
TARGET_DIRS=(
    "/home/sdata/tomcat/webapps/"
    "/home/sdata/tomcat/webapps/storage_area/private/preset/license/licensefile/"
    "/home/sdata/tomcat/webapps/sdata/WEB-INF/lib/"
)
TOMCAT_USER="sdata" # 启动 Tomcat 的用户

# 存储已复制文件的数组
COPIED_FILES=()

# 逐个处理文件和目标目录
for i in "${!FILES[@]}"; do
    FILE="${FILES[$i]}"
    TARGET_DIR="${TARGET_DIRS[$i]}"

    # 检查目标目录是否存在，不存在则创建
    if [ ! -d "$TARGET_DIR" ]; then
        mkdir -p "$TARGET_DIR"
    fi

    # 检查文件是否存在并强制复制
    if [ -f "$FILE" ]; then
        cp -f "$FILE" "$TARGET_DIR"
        echo "强制复制 $FILE 到 $TARGET_DIR"
        COPIED_FILES+=("$TARGET_DIR/$(basename "$FILE")")

        # 如果是 dayuan-sdata-business-1.0.jar，变更所有者和组为 sdata:sdata
        if [ "$FILE" == "/root/dayuan-sdata-business-1.0.jar" ]; then
            chown -R sdata:sdata "$TARGET_DIR/dayuan-sdata-business-1.0.jar"
            echo "已变更 $TARGET_DIR/dayuan-sdata-business-1.0.jar 的所有者和组为 sdata:sdata"
        fi
    else
        echo "文件 $FILE 不存在，跳过复制。"
    fi
done

# 启动 Tomcat，变更到指定用户
sudo -u "$TOMCAT_USER" /home/sdata/tomcat/bin/restart-om.sh

# 打印完成信息
echo "所有文件复制完成，dayuan-sdata-business-1.0.jar 的权限设置完成，并启动了 Tomcat。"

# 打印已复制文件的目标目录
echo "目标目录下的复制文件："
for file in "${COPIED_FILES[@]}"; do
    echo "$file"
done
