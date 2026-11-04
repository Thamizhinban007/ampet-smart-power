# AMPET — full stack (React frontend + Flask backend)

This is the full version: Dashboard / Zones / Nodes / Compare / Map pages,
backed by a real SQLite database (via SQLAlchemy), theft detection
(SAFE / SUSPECTED / THEFT DETECTED), and your ESP32 devices connecting
straight to it.

## Run the backend

```bash
pip install -r requirements.txt
python run.py
```

Runs on `http://0.0.0.0:5000`. First run auto-seeds one Feeder + one
Consumer node so there's something to look at immediately.

## Run the frontend

```bash
cd frontend
npm install
npm run dev
```

Open the URL it prints (usually `http://localhost:5173`). Its dev server
proxies `/api` and `/data` to `localhost:5000` automatically (see
`vite.config.ts`), so no extra config needed as long as the backend is
running on the same machine.

The Vite server is also available through this machine's LAN IP, for example
`http://10.136.105.32:5173`.

## Run everything at one address (recommended for a demo)

Build the frontend once, then start the backend:

```bash
cd frontend
npm.cmd install
npm.cmd run build
cd ..
python run.py
```

Now open `http://<this-machine's-LAN-IP>:5000/`. Flask serves the built
dashboard at `/` and the API remains available under `/api/...`.

On Windows, use `npm.cmd` if PowerShell reports that `npm.ps1` cannot run.

## Connect your ESP32

Your existing feeder sketch needs **no changes** — it already POSTs
`{current, power, energy}` to `/update_feeder`, which this backend
supports directly. Point `serverName` at:

```
http://<this-machine's-LAN-IP>:5000/update_feeder
```

A consumer device can POST the same shape (plus `voltage`) to
`/update_consumer`, or for a proper multi-node/multi-street setup, POST to
`/api/telemetry/<node_id>` instead — create the node first via
`POST /api/zones` and `POST /api/nodes`.

## Theft logic

`power_diff = feeder_power - consumer_power` (or the sum of a feeder's
linked consumers)

| Gap | Status |
|---|---|
| < 50 W | SAFE |
| 50–100 W | SUSPECTED |
| > 100 W | THEFT DETECTED |

## Optional: API key auth

Unset by default (fine for a hackathon on a private WiFi). To enable:

```bash
AMPET_API_KEY=your-key python run.py
```

Then also set `frontend/.env.local` with `VITE_API_KEY=your-key` before
running `npm run dev`, or your ESP32 needs to send `X-API-Key: your-key`
on every request.

## Production (later, not needed for the hackathon)

```bash
pip install gunicorn
gunicorn -w 4 -b 0.0.0.0:5000 wsgi:app
```

and `npm run build` to produce a static `frontend/dist` you can serve
from anywhere.
