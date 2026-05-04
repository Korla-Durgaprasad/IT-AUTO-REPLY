# AUTO-REPLY

Full-stack demo app to **schedule WhatsApp Web messages** with a React UI, Express + MongoDB backend, **node-cron** scheduling, and **Puppeteer** automation.

**Disclaimer:** Instagram and Snapchat automation are restricted by official APIs — this project only automates **WhatsApp Web**. Instagram/Snapchat cards are UI-only (“Coming Soon”).

---

## Structure

| Folder | Role |
|--------|------|
| `client/` | React + Vite + Tailwind |
| `server/` | Express, Mongoose, cron scheduler |
| `automation/` | Puppeteer WhatsApp script (`whatsapp.js`) |

**Puppeteer** is installed at the **repository root** so `automation/whatsapp.js` can `import 'puppeteer'` when loaded by the server.

---

## Prerequisites

- **Node.js** 18+
- **MongoDB** running locally or a cloud URI (`MONGO_URI`)

---

## Setup

### 1. Install dependencies

From the project root:

```bash
npm run install:all
```

This runs `npm install` at the root (Puppeteer), then installs `server/` and `client/` packages.

### 2. Environment

Copy the server example and edit as needed:

```bash
copy server\.env.example server\.env
```

On macOS/Linux:

```bash
cp server/.env.example server/.env
```

Adjust `MONGO_URI` if your MongoDB is not on `localhost`.

### 3. WhatsApp Web login (first run)

- Set `WA_HEADLESS=false` in `server/.env` so Chromium opens and you can **scan the QR code**.
- Session data is stored under `automation/.wa-session` (or `WA_USER_DATA_DIR` if set).

---

## Run (development)

**Terminal 1 — MongoDB** (if local):

```bash
mongod
```

**Terminal 2 — app** (from project root):

```bash
npm run dev
```

- **Frontend:** http://localhost:5173  
- **API:** http://localhost:5050  
- The Vite dev server **proxies** `/api` to the backend.

Or run API and UI separately:

```bash
npm run dev:server
npm run dev:client
```

---

## Production build (same machine)

Build the SPA, then run the API with static hosting enabled so **one URL** serves UI + `/api`:

```bash
npm run build --prefix client
npm run start:prod
```

Requires root `npm install` (for `cross-env`). Alternatively:

**Linux / macOS:**

```bash
npm run build --prefix client
NODE_ENV=production SERVE_STATIC=true node server/index.js
```

**Windows (PowerShell):**

```powershell
npm run build --prefix client
$env:NODE_ENV="production"; $env:SERVE_STATIC="true"; node server/index.js
```

Open `http://localhost:5050` — the React app calls `/api` on the same origin.

---

## Deployment

### Why not “pure” serverless?

WhatsApp automation uses a **long‑running browser** (Puppeteer) and a **persistent session** folder. Platforms like Vercel/Netlify **cannot** run this backend as-is. Deploy the **Node + MongoDB + Chromium** stack on a **VPS**, **Docker host**, or a **container PaaS** that allows long processes and disk.

You may still host the **static frontend** on a CDN and set `VITE_API_URL` to your API origin — but you must handle **CORS** on the server (`cors({ origin: [...] })`) for that origin.

### Option A — Docker Compose (recommended)

From the project root (Docker Desktop on Windows, or Docker Engine on Linux):

```bash
docker compose up -d --build
```

- **App + UI:** http://localhost:5050  
- **MongoDB:** internal service `mongo` (no public port in the sample file)

Logs: `docker compose logs -f app`

**WhatsApp QR in Docker:** the sample runs **headless** (`WA_HEADLESS=true`). To log in, typical approaches are: log in once on a desktop with the same session copied into the `wa_session` volume, or run the stack on a machine where you can temporarily use non-headless / pairing tools your team accepts. Production QR flows vary by host.

### Option B — Bare VPS (Ubuntu)

1. Install Node 20+, MongoDB, and Chromium (`apt install chromium`).
2. Clone the repo, `npm run install:all`, `npm run build --prefix client`.
3. Set `MONGO_URI`, `PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium`, `PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true`, `NODE_ENV=production`, `SERVE_STATIC=true`.
4. Run under **systemd** or **PM2**: `node server/index.js`.
5. Optionally put **Nginx** in front for TLS termination and proxy to `127.0.0.1:5050`.

### Option C — Railway / Fly.io / Render

Use the included **Dockerfile**. Attach a **persistent volume** for `WA_USER_DATA_DIR` (WhatsApp session) and set `MONGO_URI` to a managed MongoDB (Atlas, etc.). Ensure the platform allows **Chromium** (enough RAM; no overly aggressive sleep on idle for the worker).

---

## Features (implemented)

- Form: user phone, target phone, **date** + **hour/minute** time pickers, message with **character counter** and emoji-capable textarea  
- Platform cards: WhatsApp (live), Instagram / Snapchat (**Coming Soon**)  
- **Message preview** modal  
- **Countdown** to the next scheduled send  
- **Dashboard:** scheduled / sent / failed lists; cancel upcoming jobs  
- **Repeat:** once / daily / weekly (creates the next job after a successful send)  
- **Optional browser notification** ~1 minute before send (permission + checkbox)  
- Scheduler runs **every minute**; failed sends **retry** up to **3** times with **1 minute** between attempts  
- **Not logged in** detection: automation throws a clear error if the QR screen is still showing  

---

## Environment variables (reference)

| Variable | Where | Purpose |
|----------|--------|---------|
| `MONGO_URI` | `server/.env` | MongoDB connection string |
| `PORT` | `server/.env` | API port (default `5050`) |
| `WA_HEADLESS` | `server/.env` | `false` = show browser for QR |
| `WA_USER_DATA_DIR` | `server/.env` | Optional WhatsApp session directory |
| `VITE_API_URL` | `client/.env` | Optional API base if not using Vite proxy |
| `SERVE_STATIC` | `server/.env` | `true` = serve `client/dist` from Express |
| `NODE_ENV` | — | `production` enables static serving (with `SERVE_STATIC`) |
| `PUPPETEER_EXECUTABLE_PATH` | `server/.env` | e.g. `/usr/bin/chromium` in Docker/Linux |
| `PUPPETEER_SKIP_CHROMIUM_DOWNLOAD` | build/runtime | `true` when using system Chromium |

---

## Legal / ethical use

Automating WhatsApp Web may violate WhatsApp’s Terms of Service. Use only on accounts you control, for legitimate purposes, and at your own risk. This code is for learning and self-hosted experimentation.
