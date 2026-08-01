#!/bin/bash

# ~/homepage のサイズをKB単位で取得
DIR_SIZE=$(du -sk ~/homepage 2>/dev/null | awk '{print $1}')

# ディレクトリ存在チェック
if [ -z "$DIR_SIZE" ]; then
    echo "エラー: ~/homepage ディレクトリが存在しないか読み込めません。"
    exit 1
fi

# 500MB = 500 * 1024 KB = 524288 KB
LIMIT_KB=524288

if [ "$DIR_SIZE" -ge "$LIMIT_KB" ]; then
    echo "エラー: 500MB以上のため、アップロード出来ません。"
    echo "現在のサイズ: $((DIR_SIZE / 1024)) MB"
    exit 1
else
    echo "OK"
fi
