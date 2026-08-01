#!/bin/bash

HOMEPAGE_ROOT="/home/takesue090/homepage"
TARGET_DIR="${1:-$HOMEPAGE_ROOT}"

if ! cd "$TARGET_DIR"; then
    echo "エラー: ディレクトリ $TARGET_DIR に移動できませんでした。"
    exit 1
fi

echo "全ファイルの検索用インデックスデータを生成中..."

# --- 1. 全ファイルのインデックスデータ（JSON形式）を生成 ---
# 隠しファイル、index.html、スクリプト自体を除外してルートからの相対パスを取得
ALL_FILES_JSON=$(find . -type f \
    ! -path '*/.*' \
    ! -name 'index.html' \
    ! -name 'make_menu.sh' | \
    sed 's|^\./||' | \
    sort | \
    jq -R . | jq -s .)

# jq がインストールされていない場合のフォールバック（簡易JSON配列化）
if [ -z "$ALL_FILES_JSON" ] || [ "$ALL_FILES_JSON" = "null" ]; then
    ALL_FILES_JSON="["
    first=1
    while read -r f; do
        clean_f=${f#./}
        [[ "$clean_f" =~ ^\. ]] && continue
        [ "$clean_f" = "index.html" ] && continue
        [ "$clean_f" = "make_menu.sh" ] && continue
        
        if [ $first -eq 1 ]; then
            ALL_FILES_JSON="${ALL_FILES_JSON}\"${clean_f}\""
            first=0
        else
            ALL_FILES_JSON="${ALL_FILES_JSON},\"${clean_f}\""
        fi
    done < <(find . -type f)
    ALL_FILES_JSON="${ALL_FILES_JSON}]"
fi

echo "各ディレクトリの index.html 生成を開始します..."

# --- 2. ディレクトリ構造をループ処理して index.html を生成 ---
find . -type d | while read -r dir; do
    clean_dir=${dir#./}
    [ "$clean_dir" = "." ] && clean_dir=""

    # 階層の深さを計算
    if [ -z "$clean_dir" ]; then
        depth=0
    else
        slashes=$(temp="${clean_dir//[^\/]/}"; echo "${#temp}")
        depth=$((slashes + 1))
    fi

    # ルートへの相対パスを作成
    rel_to_root=""
    for ((i=0; i<depth; i++)); do
        rel_to_root="../$rel_to_root"
    done
    [ -z "$rel_to_root" ] && rel_to_root="./"

    index_file="$dir/index.html"
    echo "生成中: $index_file"

    cat <<EOF > "$index_file"
<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Index of /${clean_dir}</title>
    <style>
        body { font-family: 'Helvetica Neue', Arial, sans-serif; line-height: 1.6; max-width: 900px; margin: 0 auto; padding: 20px; color: #333; background-color: #f8f9fa; }
        h1 { border-bottom: 2px solid #007bff; padding-bottom: 10px; color: #007bff; font-size: 1.6em; word-break: break-all; }
        .nav-links { margin-bottom: 20px; padding: 12px; background-color: #e9ecef; border-radius: 5px; display: flex; flex-wrap: wrap; gap: 10px; }
        .nav-links a { text-decoration: none; color: #fff; font-weight: bold; padding: 6px 12px; border-radius: 4px; font-size: 0.9em; }
        .btn-home-abs { background-color: #28a745; }
        .btn-home-rel { background-color: #007bff; }
        .btn-up { background-color: #6c757d; }
        .search-box { width: 100%; padding: 12px 15px; font-size: 1em; border: 2px solid #007bff; border-radius: 6px; box-sizing: border-box; margin-bottom: 20px; outline: none; }
        .search-box:focus { box-shadow: 0 0 8px rgba(0,123,255,0.4); }
        ul { list-style: none; padding: 0; margin: 0; }
        li { padding: 10px; border-bottom: 1px solid #dee2e6; display: flex; align-items: center; }
        li:hover { background-color: #e9ecef; }
        .icon { margin-right: 12px; font-size: 1.2em; width: 20px; text-align: center; }
        .file-link { text-decoration: none; color: #495057; font-weight: 500; flex-grow: 1; word-break: break-all; }
        .file-link:hover { color: #007bff; }
        .search-results-title { display: none; margin-top: 15px; font-weight: bold; color: #007bff; }
    </style>
</head>
<body>

    <h1>📁 Index of /${clean_dir}</h1>

    <div class="nav-links">
        <a href="file://${HOMEPAGE_ROOT}/index.html" class="btn-home-abs">🏠 ホーム (絶対パス)</a>
        <a href="${rel_to_root}index.html" class="btn-home-rel">🏠 ホーム (相対パス)</a>
EOF

    if [ "$depth" -gt 0 ]; then
        echo "        <a href=\"../index.html\" class=\"btn-up\">↩ 1つ上の階層へ</a>" >> "$index_file"
    fi

    # ルートの index.html にのみ検索窓を表示
    if [ "$depth" -eq 0 ]; then
        cat <<EOF >> "$index_file"
    </div>

    <!-- 全ファイル検索機能 -->
    <input type="text" id="searchInput" class="search-box" placeholder="🔍 全ファイルを検索... (例: .py, test, フォルダ名など)">
    
    <div id="searchResultsTitle" class="search-results-title">🔍 検索結果:</div>
    <ul id="searchResultsList"></ul>

    <hr style="margin: 20px 0; border: 0; border-top: 1px solid #ccc;">
    <h3>📂 ディレクトリ構造・ファイル一覧</h3>
    <ul id="defaultFileList">
EOF
    else
        cat <<EOF >> "$index_file"
    </div>
    <ul>
EOF
    fi

    # --- サブディレクトリ一覧 ---
    find "$dir" -maxdepth 1 -mindepth 1 -type d | sort | while read -r subdir; do
        sub_base=$(basename "$subdir")
        [[ "$sub_base" =~ ^\. ]] && continue
        echo "        <li><span class=\"icon\">📁</span><a class=\"file-link\" href=\"${sub_base}/index.html\">${sub_base}/</a></li>" >> "$index_file"
    done

    # --- ファイル一覧 ---
    find "$dir" -maxdepth 1 -mindepth 1 -type f | sort | while read -r file; do
        file_base=$(basename "$file")
        [[ "$file_base" =~ ^\. ]] && continue
        [ "$file_base" = "index.html" ] && continue
        [ "$file_base" = "make_menu.sh" ] && continue
        
        echo "        <li><span class=\"icon\">📄</span><a class=\"file-link\" href=\"${file_base}\">${file_base}</a></li>" >> "$index_file"
    done

    # ルートの index.html の場合のみ JavaScript（検索ロジック）を挿入
    if [ "$depth" -eq 0 ]; then
        cat <<EOF >> "$index_file"
    </ul>

    <script>
        const allFiles = ${ALL_FILES_JSON};
        const searchInput = document.getElementById('searchInput');
        const searchResultsList = document.getElementById('searchResultsList');
        const searchResultsTitle = document.getElementById('searchResultsTitle');
        const defaultFileList = document.getElementById('defaultFileList');

        searchInput.addEventListener('input', function() {
            const query = this.value.trim().toLowerCase();
            searchResultsList.innerHTML = '';

            if (query === '') {
                searchResultsTitle.style.display = 'none';
                defaultFileList.style.display = 'block';
                return;
            }

            searchResultsTitle.style.display = 'block';
            defaultFileList.style.display = 'none';

            const filteredFiles = allFiles.filter(file => file.toLowerCase().includes(query));

            if (filteredFiles.length === 0) {
                searchResultsList.innerHTML = '<li style="color: #6c757d;">一致するファイルは見つかりませんでした。</li>';
            } else {
                filteredFiles.forEach(file => {
                    const li = document.createElement('li');
                    li.innerHTML = \`<span class="icon">📄</span><a class="file-link" href="\${file}">\${file}</a>\`;
                    searchResultsList.appendChild(li);
                });
            }
        });
    </script>
EOF
    else
        echo "    </ul>" >> "$index_file"
    fi

    cat <<EOF >> "$index_file"
    <footer style="margin-top: 30px; padding-top: 10px; border-top: 1px solid #dee2e6; font-size: 0.8em; color: #6c757d; text-align: center;">
        自動生成日時: $(date '+%Y-%m-%d %H:%M:%S')
    </footer>
</body>
</html>
EOF

done

echo "すべての処理が完了しました！"
