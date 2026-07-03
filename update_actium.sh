#!/usr/bin/env zsh

# 1. Copy files (local copy for backup, gitignored)
SRC_DIR="/Users/brayanizq/Documents/actiumapp/build/app/outputs/flutter-apk"
DEST_DIR="/Users/brayanizq/Documents/appstore/apks"

echo "Copying APK files..."
cp "$SRC_DIR/app-release.apk" "$DEST_DIR/actium-release.apk"
cp "$SRC_DIR/app-debug.apk" "$DEST_DIR/actium-debug.apk"

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

# 3. Upload to GitHub Release (since LFS/push limit blocks >100MB files on branches)
echo "Uploading APKs to GitHub Release v1.0.0..."
/opt/homebrew/bin/gh release upload v1.0.0 "$DEST_DIR/actium-release.apk" "$DEST_DIR/actium-debug.apk" --clobber

# 4. Commit and push on main branch (excluding the apks/ folder completely via gitignore)
echo "Pushing updates to main branch..."
git checkout main
git rm -r --cached apks/ || true
git add index.html script.js update_actium.sh .gitignore
git commit -m "Auto-update Actium web page details and upload assets to Release"
git push origin main

# 5. Update gh-pages branch
echo "Updating gh-pages branch..."
git checkout gh-pages
git merge main --no-edit
git push origin gh-pages
git checkout -f main

echo "Successfully pushed changes to GitHub Pages!"
