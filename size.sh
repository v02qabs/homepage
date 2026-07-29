#!/bin/bash

# 引数が指定されているかチェック
if [ $# -eq 0 ]; then
    echo "使用方法: $0 <ファイル名>"
    exit 1
fi

FILE="$1"

# ファイルが存在するかチェック
if [ ! -f "$FILE" ]; then
    echo "エラー: ファイル '${FILE}' が存在しません。"
    exit 1
fi

# ファイルサイズを取得（バイト単位）
# macOSとLinuxの両方に対応するための分岐
if stat -f%z "$FILE" >/dev/null 2>&1; then
    # macOS用
    FILESIZE=$(stat -f%z "$FILE")
else
    # Linux用
    FILESIZE=$(stat -c%s "$FILE")
fi

# 10MB = 10 * 1024 * 1024 バイト = 10485760 バイト
LIMIT=$((10 * 1024 * 1024))

# 判定
if [ "$FILESIZE" -ge "$LIMIT" ]; then
    echo "10MB以上です。"
else
	echo "10MB以下です。"
fi
