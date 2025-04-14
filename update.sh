#!/bin/bash
# 更新脚本

REPO_OWNER=$1
REPO_NAME=$2
TARGET_DIR="/usr/local/bin" # 安装目录
BACKUP_DIR="/tmp/calc_backup"

# 清理环境
cleanup() {
    rm -rf "$BACKUP_DIR"
    exit $1
}

# 创建备份
echo "创建备份..."
mkdir -p "$BACKUP_DIR"
cp "$TARGET_DIR/calculator.sh" "$BACKUP_DIR" || cleanup 1

# 下载最新版本
echo "下载新版本..."
files=(
    "calculator_latest.sh"
)

for file in "${files[@]}"; do
    url="https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/main/${file}"
    if ! curl -sL "$url" -o "$TARGET_DIR/${file}.new"; then
        echo "下载失败: $file"
        cleanup 1
    fi
done

# 验证文件
echo "验证文件完整性..."
for file in "${files[@]}"; do
    if [ ! -s "$TARGET_DIR/${file}.new" ]; then
        echo "文件损坏: $file"
        cleanup 1
    fi
done

# 替换文件
echo "应用更新..."
for file in "${files[@]}"; do
    mv "$TARGET_DIR/${file}.new" "$TARGET_DIR/$file"
    chmod +x "$TARGET_DIR/$file"
done

echo "清理旧文件..."
cleanup 0