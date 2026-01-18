# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**notifyApi** is a microservice API that provides Telegram notifications and Arweave file uploads. It includes:
- `POST /sendBot` - Send messages to Telegram bots
- `POST /upload_img` - Upload images to Arweave via Turbo
- `POST /upload_logo_meta_ario` - Upload logo + metadata to Arweave via Turbo

## Development Commands

```bash
# Install dependencies
npm install

# Development with auto-restart (uses nodemon)
npm run dev

# Production run
npm start

# Docker build and run
docker build -t notify-api .
docker run -d -p 8848:8848 --env-file .env --name notify-api --restart unless-stopped notify-api

# Server deployment scripts
./deploy.sh          # First-time deployment (includes setup)
./quick-deploy.sh    # Quick deploy (assumes .env exists)
```

## Architecture

### Request Flow

1. **CORS Check** (app.js:72-92) - Origin validated against `ALLOWED_DOMAINS`
2. **Domain Validation** (app.js:14-69) - Extracts domain from `origin`/`referer` headers
3. **API Key Validation** (app.js:119-140) - Supports `X-API-Key` or `Authorization: Bearer`
4. **Telegram Forward** (app.js:143-179) - POST to Telegram Bot API with HTML parsing mode

### Security Layers

- **Domain whitelist**: Only `pandatool.org` and subdomains allowed (see `ALLOWED_DOMAINS` in app.js:8)
- **API key authentication**: Single key from `API_KEY` env var (default: UUID for dev)
- **CORS restriction**: Same whitelist applied at CORS layer

### Key Design Decisions

- **Silent failures**: Telegram API errors are logged but return 200 to client (app.js:171-178)
- **No origin/referer blocking**: Requests without these headers get 403 (app.js:47-52)
- **Test key bypass**: Currently commented out (app.js:15-21) but was designed to allow `X-Test-Key` header to bypass domain validation
- **Single-file architecture**: All middleware, routes, and logic in `app.js`

### Environment Variables

Required for Telegram:
- `API_KEY` - Request authentication (default UUID for dev only)
- `NOTIFY_BOT_CHAT_ID` - Telegram target chat ID
- `NOTIFY_BOT_URL` - Telegram Bot API base URL (e.g., `https://api.telegram.org/bot<TOKEN>/`)

Required for Arweave uploads:
- `VERTIFIED_TOKEN` - Secret token for `/upload_img` endpoint (passed as `?secret=` query param)

Optional:
- `PORT` - Server port (default: 8848)
- `TURBO_PRIVATE_KEY` - Solana private key for Turbo/Arweave (has default for dev)

### Unauthenticated Endpoints

- `GET /` - Service status and version info
- `GET /health` - Health check (bypasses domain validation)

### Authenticated Endpoints

All require API key via `X-API-Key` or `Authorization: Bearer` header:

- `POST /sendBot` - Send message to Telegram Bot
  - Body: `{ "message": "text" }`
  - Supports HTML in message

- `POST /upload_img` - Upload image to Arweave
  - Requires additional `?secret=VERTIFIED_TOKEN` query param
  - Multipart form data with `file` field
  - Max file size: 100KB
  - Returns: `{ code: 200, imgURI: "https://arweave.net/..." }`

- `POST /upload_logo_meta_ario` - Upload logo + metadata to Arweave
  - Multipart form data with `file` field + form fields:
    - `mainnet`, `tokenAddress`, `channelPlatform` (required)
    - `imgType`, `description`, `website`, `telegram`, `twitter`, `discord`, `qqGroup`, `whitepaper`, `contact`, `payNeworkId`, `payTx` (optional)
  - Max file size: 100KB
  - Uploads image first, then JSON metadata with image URL
  - Returns: `{ code: 200, metaURI: "https://arweave.net/..." }`

### Deployment

The service is designed for Docker deployment. The `deploy.sh` script handles:
- Checking prerequisites (Docker, Git)
- Creating `.env` from `env.example` if needed
- Building and running the container with `--restart unless-stopped`

Port 8848 must be open in firewall (ufw/firewalld/iptables).
