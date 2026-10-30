#!/usr/bin/env bash
set -euo pipefail
cd "${PROJECT_DIR:?}"

: "${OPENCODE_WEB_DIR:?OPENCODE_WEB_DIR is required}"

PORT="${PORT:-3000}"
export PORT

# Verify source entrypoint exists inside PROJECT_DIR.
/usr/bin/time -p test -f index.html || { echo "start.sh: index.html not found in $PROJECT_DIR" >&2; exit 1; }

# Install dependencies and build when a package project is present. This static
# HTML project has no package.json, so there is nothing to install or build;
# source and built output both live inside PROJECT_DIR.
if /usr/bin/time -p test -f package.json; then
  /usr/bin/time -p npm ci --no-audit --no-fund || /usr/bin/time -p npm install --no-audit --no-fund
  if /usr/bin/time -p node -e 'process.exit(require("./package.json").scripts&&require("./package.json").scripts.build?0:1)' 2>/dev/null; then
    /usr/bin/time -p npm run build --if-present
  fi
fi

# Keep worker metadata and capture evidence out of source; write only metadata here.
mkdir -p "$OPENCODE_WEB_DIR"
/usr/bin/time -p /usr/bin/printf '%s' "{\"project\":\"$PROJECT_DIR\",\"directory\":\"$PROJECT_DIR\"}" > "$OPENCODE_WEB_DIR/deployment-output.json"

# Serve the static project in the foreground on PORT (default 3000).
exec /usr/bin/time -p node -e '
const http = require("node:http");
const fs = require("node:fs");
const path = require("node:path");
const root = process.env.PROJECT_DIR || process.cwd();
const port = Number(process.env.PORT || 3000);
const mime = { ".html": "text/html", ".css": "text/css", ".js": "application/javascript", ".json": "application/json", ".png": "image/png", ".jpg": "image/jpeg", ".svg": "image/svg+xml" };
const server = http.createServer((req, res) => {
  let file = path.join(root, req.url === "/" ? "index.html" : "." + decodeURI(req.url));
  try { file = path.resolve(file); } catch { res.writeHead(404); res.end("not found"); return; }
  if (file !== root && !file.startsWith(root + path.sep)) { res.writeHead(404); res.end("not found"); return; }
  fs.stat(file, (err, st) => {
    if (err) { res.writeHead(404); res.end("not found"); return; }
    if (st.isDirectory()) file = path.join(file, "index.html");
    fs.readFile(file, (err, data) => {
      if (err) { res.writeHead(404); res.end("not found"); return; }
      const ext = path.extname(file);
      res.setHeader("Content-Type", mime[ext] || "application/octet-stream");
      res.setHeader("Cache-Control", "no-cache");
      res.end(data);
    });
  });
});
server.listen(port, "0.0.0.0", () => console.log("mineshoot serving on :" + port));
'
