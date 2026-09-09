/* Post-build: pull remaining inline data:image URIs out of _deploy/index.html into _deploy/images/ .
   Run AFTER build.ps1, BEFORE makezip.ps1.  node externalize-inline.js  */
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const root = __dirname;
const htmlPath = path.join(root, '_deploy', 'index.html');
const imgDir = path.join(root, '_deploy', 'images');
if (!fs.existsSync(htmlPath)) { console.error('no _deploy/index.html — run build.ps1 first'); process.exit(1); }

let html = fs.readFileSync(htmlPath, 'utf8');
const before = Buffer.byteLength(html);
const extOf = { 'image/png': 'png', 'image/jpeg': 'jpg', 'image/jpg': 'jpg', 'image/gif': 'gif', 'image/webp': 'webp', 'image/svg+xml': 'svg' };
const MIN = 2048; // leave tiny blobs inline

const seen = new Map();
let n = 0, kept = 0, bytesOut = 0;
html = html.replace(/data:(image\/[a-z0-9.+-]+);base64,([A-Za-z0-9+/=]+)/g, (m, mime, b64) => {
  const ext = extOf[mime.toLowerCase()];
  if (!ext) { kept++; return m; }
  let buf;
  try { buf = Buffer.from(b64, 'base64'); } catch { kept++; return m; }
  if (buf.length < MIN) { kept++; return m; }
  const hash = crypto.createHash('sha1').update(buf).digest('hex').slice(0, 16);
  const name = 'x_' + hash + '.' + ext;
  if (!seen.has(hash)) {
    fs.writeFileSync(path.join(imgDir, name), buf);
    seen.set(hash, name);
    bytesOut += buf.length;
    n++;
  }
  return 'images/' + name;
});

fs.writeFileSync(htmlPath, html, 'utf8');
const after = Buffer.byteLength(html);
console.log(`externalized ${n} unique images (${(bytesOut/1024/1024).toFixed(2)} MB) into _deploy/images/`);
console.log(`_deploy/index.html: ${(before/1024/1024).toFixed(2)} MB -> ${(after/1024).toFixed(0)} KB  (${kept} tiny blobs kept inline)`);
