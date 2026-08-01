#!/bin/sh

# 引数のチェック
if [ "$#" -lt 2 ]; then
  echo "使用方法: $0 <保存先ファイル> <プロンプト>"
  echo "例: $0 output.txt \"こんにちは！\""
  exit 1
fi

OUTPUT_FILE="$1"
shift
PROMPT="$*"

# APIリクエストを実行し、テキストのみ抽出してファイルに保存
curl -s "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash-lite:generateContent?key=${GEMINI_API_KEY}" \
  -H 'Content-Type: application/json' \
  -d '{
    "contents": [{
      "parts": [{"text": "'"${PROMPT}"'"}]
    }]
  }' | jq -r '.candidates[0].content.parts[0].text' > "${OUTPUT_FILE}"

echo "結果を ${OUTPUT_FILE} に書き込みました。"
