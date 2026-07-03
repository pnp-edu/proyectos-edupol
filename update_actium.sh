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

# 3. Upload only Debug APK to Release (since it is >100MB and blocked by GitHub push limit)
echo "Uploading Debug APK to GitHub Release v1.0.0..."
/opt/homebrew/bin/gh release upload v1.0.0 "$DEST_DIR/actium-debug.apk" --clobber

# 4. Commit and push on main branch (tracking only actium-release.apk which is <100MB)
echo "Pushing updates to main branch..."
git checkout main
git add index.html script.js update_actium.sh .gitignore
git add -f apks/actium-release.apk
git commit -m "Auto-update Actium web page details and commit Release APK"
git push origin main

# 5. Update gh-pages branch (excluding the apks/ folder to keep build light)
echo "Updating gh-pages branch..."
git checkout gh-pages
git reset --hard origin/gh-pages
git reset --hard main
git rm -r --cached apks/ || true
git commit -m "Remove apks directory from gh-pages deployment branch" --allow-empty
git push -f origin gh-pages
git checkout -f main

echo "Successfully pushed changes to GitHub Pages!"
