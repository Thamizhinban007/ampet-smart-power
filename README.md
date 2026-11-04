# AMPET - Smart Power Monitoring & Theft Detection

An end-to-end power-monitoring platform built around ESP32 nodes, a Flask API, a React dashboard, and a Flutter companion app. Feeder and consumer nodes report current, power, energy, and voltage; the backend compares feeder output with the sum of consumer load to flag likely theft.

## Repository layout

| Folder | What it contains |
| --- | --- |
| `server/` | Flask + SQLAlchemy API and the React 19 / TypeScript dashboard |
| `firmware/feeder/` | ESP32 feeder firmware (`ampet_feeder_fixed.ino`) |
| `firmware/consumer/` | ESP32 consumer firmware with I2C LCD output |
| `mobile-app/` | Flutter companion app for live usage, cost estimates, and history |

## Theft detection

The backend compares feeder power with the total consumer power on the same zone:

| Delta | Status |
| --- | --- |
| `< 50 W` | SAFE |
| `50-100 W` | SUSPECTED |
| `> 100 W` | THEFT DETECTED |

An optional API key can protect telemetry ingestion.

## Dashboard

The React app includes Dashboard, Zones, Nodes, Compare, and Map pages, with zone/node CRUD, telemetry ingestion, an AI insights panel, and a Leaflet network map. The built frontend can be served directly by Flask for single-address demos.

## Running the server

```bash
cd server
pip install -r requirements.txt
python run.py
```

The API listens on `http://0.0.0.0:5000`. The first run seeds one feeder and one consumer node so the dashboard has data.

Frontend development:

```bash
cd server/frontend
npm install
npm run dev
```

## Flashing the firmware

1. Open the relevant `.ino` file in Arduino IDE.
2. Set `YOUR_WIFI_SSID`, `YOUR_WIFI_PASSWORD`, and `YOUR_SERVER_IP` in the file.
3. Install the ESP32 board package and the `LiquidCrystal_I2C` library for the consumer node.
4. Flash and open the serial monitor.

The committed firmware uses placeholders only. Do not commit real Wi-Fi credentials.

## Mobile app

```bash
cd mobile-app
flutter pub get
flutter run
```

## Status

Working prototype built for demonstration and academic evaluation. The commit history starts from a cleaned, source-only snapshot: datasets, databases, virtual environments, build output, and credentials are not included.
