# --- Frontend build ---
FROM node:20-bookworm-slim AS client-build

WORKDIR /app
COPY client/package.json ./client/
RUN cd client && npm install

COPY client/ ./client/
RUN cd client && npm run build

# --- API + automation ---
FROM node:20-bookworm-slim

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    chromium \
    fonts-liberation \
    ca-certificates \
    dbus \
  && rm -rf /var/lib/apt/lists/*

ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

WORKDIR /app

COPY package.json ./
COPY server/package.json ./server/

RUN npm install \
  && npm install --prefix server

COPY server/ ./server/
COPY automation/ ./automation/
COPY --from=client-build /app/client/dist ./client/dist

ENV NODE_ENV=production
ENV SERVE_STATIC=true
ENV PORT=5050
ENV WA_HEADLESS=true

EXPOSE 5050

HEALTHCHECK --interval=30s --timeout=5s --start-period=40s --retries=3 \
  CMD node -e "fetch('http://127.0.0.1:' + (process.env.PORT||5050) + '/api/health').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"

CMD ["node", "server/index.js"]
