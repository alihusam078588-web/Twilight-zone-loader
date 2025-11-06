// server.js - simple Express-free server using built-in http + fetch (Node 18+)
const http = require('http');
const url = require('url');

const PORT = process.env.PORT || 3000;
const LINKVERTISE_TOKEN = process.env.LINKVERTISE_TOKEN || '';

if (!LINKVERTISE_TOKEN) {
  console.error('Missing LINKVERTISE_TOKEN env var. Set it in Render dashboard.');
}

function sendHtml(res, status, html) {
  res.writeHead(status, { 'Content-Type': 'text/html; charset=utf-8' });
  res.end(html);
}

function sendText(res, status, text) {
  res.writeHead(status, { 'Content-Type': 'text/plain; charset=utf-8' });
  res.end(text);
}

const server = http.createServer(async (req, res) => {
  try {
    const parsed = url.parse(req.url, true);
    const pathname = parsed.pathname;
    const q = parsed.query;

    // health check
    if (pathname === '/health') {
      return sendText(res, 200, 'ok');
    }

    // main handler
    if (pathname === '/' || pathname === '/target') {
      const hash = q.hash || null;
      if (!hash) {
        return sendText(res, 403, 'No hash provided. Please open this via the Linkvertise link.');
      }

      if (!LINKVERTISE_TOKEN) {
        return sendText(res, 500, 'Server misconfigured: LINKVERTISE_TOKEN not set.');
      }

      // Verify with Linkvertise (POST)
      const apiUrl = `https://publisher.linkvertise.com/api/v1/anti_bypassing?token=${encodeURIComponent(LINKVERTISE_TOKEN)}&hash=${encodeURIComponent(hash)}`;
      let apiResp, apiBody;
      try {
        apiResp = await fetch(apiUrl, { method: 'POST' });
        // try parse JSON, fallback to text
        try { apiBody = await apiResp.json(); } catch(e) { apiBody = await apiResp.text(); }
      } catch (e) {
        console.error('Linkvertise fetch error:', e);
        return sendText(res, 502, 'Error contacting Linkvertise: ' + String(e));
      }

      // If Linkvertise responds OK and indicates success, show loadstring page
      const ok = apiResp.ok && apiBody && (apiBody.success === true || apiBody.verified === true || apiBody.valid === true);

      if (!ok) {
        // debug-friendly: show API status and body to help troubleshoot (safe: does not show your token)
        const debug = `Verification failed. Linkvertise status: ${apiResp.status}\nResponse body: ${JSON.stringify(apiBody)}`;
        console.warn(debug);
        return sendText(res, 403, 'Verification failed or hash expired. Please re-open the Linkvertise link.');
      }

      // VERIFIED — return a small HTML page containing the loadstring and copy button
      const loadstring = `loadstring(game:HttpGet("https://raw.githubusercontent.com/alihusam078588-web/Twilight-zone-loader/main/main.lua"))()`;
      const html = `<!doctype html>
<html>
<head><meta charset="utf-8"><title>Twilight Zone - Copy Loadstring</title>
<meta name="viewport" content="width=device-width,initial-scale=1">
<style>
body{font-family:system-ui,Segoe UI,Roboto,Arial;padding:18px;background:#f7f7f8}
.card{max-width:720px;margin:18px auto;background:#fff;padding:14px;border-radius:10px;box-shadow:0 6px 18px rgba(0,0,0,0.06)}
textarea{width:100%;height:90px;padding:10px;font-family:monospace;font-size:14px;border-radius:6px;border:1px solid #ddd}
button{margin-top:10px;padding:10px 14px;border-radius:8px;border:0;background:#0a84ff;color:#fff;font-weight:600;cursor:pointer}
.hint{margin-top:8px;color:#666;font-size:13px}
</style>
</head>
<body>
<div class="card">
<h2>Twilight Zone — copy the loadstring</h2>
<p>Paste this into your executor:</p>
<textarea id="ls" readonly>${loadstring}</textarea>
<div>
<button id="copyBtn">Copy loadstring</button>
</div>
<p class="hint">If copy doesn't work on your device, select the text and copy manually.</p>
</div>
<script>
const btn = document.getElementById('copyBtn');
const ta = document.getElementById('ls');
btn.addEventListener('click', async () => {
  try { await navigator.clipboard.writeText(ta.value); btn.textContent='Copied!'; setTimeout(()=>btn.textContent='Copy loadstring',2000); }
  catch(e){ ta.focus(); ta.select(); btn.textContent='Selected – press Copy'; setTimeout(()=>btn.textContent='Copy loadstring',3000); }
});
</script>
</body>
</html>`;
      return sendHtml(res, 200, html);
    }

    // unknown path
    sendText(res, 404, 'Not found');
  } catch (err) {
    console.error('Server error:', err);
    sendText(res, 500, 'Server error: ' + String(err));
  }
});

server.listen(PORT, () => {
  console.log(`Server listening on port ${PORT}`);
});
