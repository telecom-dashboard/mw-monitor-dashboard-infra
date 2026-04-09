from fastapi import FastAPI, HTTPException
from fastapi.responses import HTMLResponse
import ipaddress, os, socket

app = FastAPI(title="CIDR Buddy")

@app.get("/health")
def health():
    return {"status": "ok", "host": socket.gethostname(), "env": os.getenv("APP_ENV", "dev")}

@app.get("/api/cidr")
def cidr(cidr: str):
    try:
        net = ipaddress.ip_network(cidr, strict=False)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    usable = max(net.num_addresses - (2 if net.version == 4 and net.prefixlen < 31 else 0), 0)
    return {
        "input": cidr,
        "network": str(net.network_address),
        "prefix": net.prefixlen,
        "netmask": str(net.netmask),
        "broadcast": str(net.broadcast_address) if net.version == 4 else None,
        "usable_hosts": usable,
        "total_addresses": net.num_addresses,
        "version": net.version,
        "is_private": net.is_private,
    }

@app.get("/", response_class=HTMLResponse)
def home():
    return """
    <!doctype html>
    <html>
    <head>
      <title>CIDR Buddy</title>
      <style>
        body{font-family:Arial;max-width:760px;margin:40px auto;padding:0 16px}
        input,button{padding:10px;font-size:16px} pre{background:#f4f4f4;padding:16px;border-radius:8px}
      </style>
    </head>
    <body>
      <h1>CIDR Buddy</h1>
      <p>Small and useful. Not hello world.</p>
      <input id="cidr" value="10.10.11.0/24" style="width:260px">
      <button onclick="go()">Calculate</button>
      <pre id="out">Ready.</pre>
      <script>
        async function go(){
          const v=document.getElementById('cidr').value;
          const r=await fetch('/api/cidr?cidr='+encodeURIComponent(v));
          document.getElementById('out').textContent =
            JSON.stringify(await r.json(), null, 2);
        }
        go();
      </script>
    </body>
    </html>
    """