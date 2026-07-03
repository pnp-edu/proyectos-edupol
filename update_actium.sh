#!/usr/bin/env zsh

# 1. Copy files
SRC_DIR="/Users/brayanizq/Documents/actiumapp/build/app/outputs/flutter-apk"
DEST_DIR="/Users/brayanizq/Documents/appstore/apks"

echo "Copying APK files..."
cp "$SRC_DIR/app-release.apk" "$DEST_DIR/actium-release.apk"
cp "$SRC_DIR/app-arm64-v8a-release.apk" "$DEST_DIR/actium-arm64-v8a-release.apk"
cp "$SRC_DIR/app-armeabi-v7a-release.apk" "$DEST_DIR/actium-armeabi-v7a-release.apk"
cp "$SRC_DIR/app-x86_64-release.apk" "$DEST_DIR/actium-x86_64-release.apk"

# 2. Update date in index.html
echo "Updating last updated date in index.html..."
HTML_PATH="/Users/brayanizq/Documents/appstore/index.html"

# Compute Spanish date
MONTHS=("enero" "febrero" "marzo" "abril" "mayo" "junio" "julio" "agosto" "septiembre" "octubre" "noviembre" "diciembre")
DAY=$(date +%-d)
MONTH_IDX=$(($(date +%-m) - 1))
MONTH=${MONTHS[$MONTH_IDX]}
YEAR=$(date +%Y)
TIME=$(date +"%I:%M %p")

FORMATTED_DATE="$DAY de $MONTH de $YEAR, $TIME"

python3 -c "
import os
html_path = '$HTML_PATH'
with open(html_path, 'r', encoding='utf-8') as f:
    html = f.read()

date_str = '$FORMATTED_DATE'
update_label = '<li><strong>Última actualización:</strong>'

def update_modal(modal_id, html_content):
    start_idx = html_content.find(f'id=\"{modal_id}\"')
    if start_idx == -1: return html_content
    label_idx = html_content.find(update_label, start_idx)
    if label_idx == -1: return html_content
    end_idx = html_content.find('</li>', label_idx)
    if end_idx == -1: return html_content
    old_line = html_content[label_idx:end_idx+5]
    new_line = f'{update_label} {date_str}</li>'
    return html_content.replace(old_line, new_line)

html = update_modal('details-modal-actium-android', html)
html = update_modal('details-modal-actium-pc', html)

with open(html_path, 'w', encoding='utf-8') as f:
    f.write(html)
"

echo "Updated date to: $FORMATTED_DATE"

# 3. Commit and push on main branch
echo "Pushing updates to main branch..."
git checkout main
git add index.html script.js update_actium.sh .gitignore
git add -f apks/actium-arm64-v8a-release.apk apks/actium-armeabi-v7a-release.apk apks/actium-x86_64-release.apk apks/actium-windows.zip
git commit -m "Auto-update Actium APKs and release date on main"
git push origin main

# 4. Update gh-pages branch WITHOUT the apks directory
echo "Updating gh-pages branch (excluding apks/ folder)..."
git checkout gh-pages
git merge main --no-edit
git rm -r --cached apks/ || true
git commit -m "Remove apks directory from gh-pages deployment branch" --allow-empty
git push origin gh-pages
git checkout -f main

echo "Successfully pushed changes to GitHub Pages!"
