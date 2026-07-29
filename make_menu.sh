find . -name "*.html" -exec bash -c '
for file; do
  sed -i -E "s|<a href=\"#\">([^<]+)</a>|<a href=\"\1.html\">\1</a>|g" "$file"
  for html in *.html; do
    name="${html%.html}"
    sed -i "s|href=\"#\">$name</a>|href=\"$html\">$name</a>|g" "$file"
  done
done
' _ {} +