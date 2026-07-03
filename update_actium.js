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

// 3. Git commit and push changes (including the new Actium APK files)
console.log('Pushing changes to GitHub...');
try {
  // Add index.html, script.js and the specific Actium APKs (excluding the fat actium-release.apk)
  execSync('git add index.html script.js', { stdio: 'inherit' });
  execSync('git add apks/actium-arm64-v8a-release.apk apks/actium-armeabi-v7a-release.apk apks/actium-x86_64-release.apk', { stdio: 'inherit' });
  if (fs.existsSync(path.join(destDir, 'actium-windows.zip'))) {
    execSync('git add apks/actium-windows.zip', { stdio: 'inherit' });
  }
  
  execSync('git commit -m "Auto-update Actium APKs and release date"', { stdio: 'inherit' });
  execSync('git push origin main', { stdio: 'inherit' });
  execSync('git branch -f gh-pages main', { stdio: 'inherit' });
  execSync('git push -f origin gh-pages', { stdio: 'inherit' });
  console.log('Successfully pushed changes to GitHub Pages!');
} catch (err) {
  console.error('Error pushing to GitHub:', err.message);
}
