#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// 1. Copy files
const srcDir = '/Users/brayanizq/Documents/actiumapp/build/app/outputs/flutter-apk';
const destDir = '/Users/brayanizq/Documents/appstore/apks';

const filesToCopy = {
  'app-release.apk': 'actium-release.apk',
  'app-arm64-v8a-release.apk': 'actium-arm64-v8a-release.apk',
  'app-armeabi-v7a-release.apk': 'actium-armeabi-v7a-release.apk',
  'app-x86_64-release.apk': 'actium-x86_64-release.apk'
};

console.log('Copying APK files...');
for (const [src, dest] of Object.entries(filesToCopy)) {
  const srcPath = path.join(srcDir, src);
  const destPath = path.join(destDir, dest);
  if (fs.existsSync(srcPath)) {
    fs.copyFileSync(srcPath, destPath);
    console.log(`Copied ${src} -> ${dest}`);
  } else {
    console.warn(`Warning: Source file not found: ${srcPath}`);
  }
}

// 2. Update date in index.html
console.log('Updating last updated date in index.html...');
const htmlPath = '/Users/brayanizq/Documents/appstore/index.html';
let html = fs.readFileSync(htmlPath, 'utf8');

const now = new Date();
const months = ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'];
const formattedDate = `${now.getDate()} de ${months[now.getMonth()]} de ${now.getFullYear()}, ${now.toLocaleTimeString('es-ES', { hour: '2-digit', minute: '2-digit', hour12: true })}`;

// Function to update date inside a specific modal block
function updateModalDate(modalId) {
  const modalStartIdx = html.indexOf(`id="${modalId}"`);
  if (modalStartIdx === -1) return;
  
  // Find the next "Última actualización:"
  const updateLabel = '<li><strong>Última actualización:</strong>';
  const labelIdx = html.indexOf(updateLabel, modalStartIdx);
  if (labelIdx === -1) return;
  
  const endLiIdx = html.indexOf('</li>', labelIdx);
  if (endLiIdx === -1) return;
  
  const originalLine = html.substring(labelIdx, endLiIdx + 5);
  const newLine = `${updateLabel} ${formattedDate}</li>`;
  html = html.replace(originalLine, newLine);
}

updateModalDate('details-modal-actium-android');
updateModalDate('details-modal-actium-pc');

fs.writeFileSync(htmlPath, html, 'utf8');
console.log(`Updated date to: ${formattedDate}`);

// 3. Update GitHub Release
console.log('Updating GitHub Release v1.0.0...');
try {
  // Use gh release upload with --clobber flag to overwrite existing files
  for (const dest of Object.values(filesToCopy)) {
    const destPath = path.join(destDir, dest);
    if (fs.existsSync(destPath)) {
      console.log(`Uploading ${dest} to release v1.0.0...`);
      // Use the absolute path of gh if needed, but since they run it in terminal, gh will be in their path
      execSync(`gh release upload v1.0.0 "${destPath}" --clobber`, { stdio: 'inherit' });
    }
  }
} catch (err) {
  console.error('Error uploading to GitHub Release:', err.message);
}

// 4. Git commit and push changes
console.log('Pushing HTML changes to GitHub...');
try {
  execSync('git add index.html', { stdio: 'inherit' });
  execSync('git commit -m "Auto-update Actium release date"', { stdio: 'inherit' });
  execSync('git push origin main', { stdio: 'inherit' });
  execSync('git branch -f gh-pages main', { stdio: 'inherit' });
  execSync('git push -f origin gh-pages', { stdio: 'inherit' });
  console.log('Successfully pushed changes to GitHub Pages!');
} catch (err) {
  console.error('Error pushing to GitHub:', err.message);
}
