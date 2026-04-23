# Windows Setup Guide (Docker Desktop + Google Gemini)

This guide covers running SupoClip on **Windows** using Docker Desktop and **Google Gemini** as the AI provider.

---

## Prerequisites

### 1. Docker Desktop

1. Download [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop/).
2. Run the installer and follow the prompts.
3. When asked, enable the **WSL 2** backend (recommended). If you do not already have WSL 2, the installer will prompt you to install the WSL 2 Linux kernel update.
4. Restart your machine when prompted.
5. Launch **Docker Desktop** from the Start menu and wait until the whale icon in the system tray stops animating — Docker is ready when the icon is steady.

> **WSL 2 note:** Docker Desktop on Windows works best with the WSL 2 backend enabled. This is the default for most installations on Windows 10 version 2004+ and Windows 11. To verify: open Docker Desktop → Settings → General → confirm "Use the WSL 2 based engine" is checked.

### 2. Git

Install [Git for Windows](https://git-scm.com/download/win). This also gives you **Git Bash**, which can run the Unix `./start.sh` script if you prefer that over PowerShell.

### 3. API Keys

| Key | Purpose | Where to get |
|-----|---------|--------------|
| `ASSEMBLY_AI_API_KEY` | Video transcription (required) | https://www.assemblyai.com/ |
| `GOOGLE_API_KEY` | Google Gemini AI analysis (required with Gemini) | https://aistudio.google.com/app/apikey |

---

## Quick Start

### Step 1 — Clone the repository

**PowerShell or cmd:**
```powershell
git clone https://github.com/chidozxe/supoclip.git
cd supoclip
```

### Step 2 — Create your `.env` file

**PowerShell:**
```powershell
Copy-Item .env.example .env
```

**cmd (Command Prompt):**
```cmd
copy .env.example .env
```

Now open `.env` in any text editor (Notepad, VS Code, etc.) and fill in your keys. At minimum, set these values:

```env
# Required: Video transcription
ASSEMBLY_AI_API_KEY=your_assemblyai_key_here

# Required: Google Gemini AI
LLM=google-gla:gemini-3-flash-preview
GOOGLE_API_KEY=your_google_api_key_here

# Optional but recommended: change before sharing or deploying
BETTER_AUTH_SECRET=change_this_in_production
```

> **Tip:** Do not add quotes around values unless the value itself contains spaces. For example: `GOOGLE_API_KEY=AIzaSy...` not `GOOGLE_API_KEY="AIzaSy..."`.

### Step 3 — Start SupoClip

**Option A — PowerShell script (recommended on Windows):**
```powershell
.\start.ps1
```

If PowerShell blocks the script, run this first to allow local scripts:
```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

**Option B — Git Bash / WSL terminal:**
```bash
./start.sh
```

**Option C — Pure `docker compose` (works everywhere):**
```powershell
docker compose up -d --build
```

### Step 4 — Open the app

After containers start (first build takes 5–10 minutes), open your browser:

| Service | URL |
|---------|-----|
| Frontend (main app) | http://localhost:3000 |
| Backend API | http://localhost:8000 |
| API documentation | http://localhost:8000/docs |

Create an account, paste a YouTube URL, and start clipping!

---

## Managing the Stack

### View logs
```powershell
docker compose logs -f
```

### Stop all services
```powershell
docker compose down
```

### Rebuild after editing `.env` or code changes
```powershell
docker compose up -d --build
```

### Reset everything (deletes all data)
```powershell
docker compose down -v
docker compose up -d --build
```

---

## Windows Troubleshooting

### PowerShell execution policy error

```
.\start.ps1 cannot be loaded because running scripts is disabled on this system.
```

Fix:
```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

### Line-ending issues (`\r\n` vs `\n`)

Windows Git may check out files with Windows line endings (`CRLF`), which can break shell scripts inside Linux containers. Fix:

```powershell
git config --global core.autocrlf false
```

Then re-clone or run:
```powershell
git rm --cached -r .
git reset --hard
```

Alternatively, force Unix endings with a `.gitattributes` file (already included in the repo).

### Port already in use

If `docker compose up` fails with a port conflict:

1. Find what is using the port:
   ```powershell
   netstat -ano | findstr :3000
   netstat -ano | findstr :8000
   ```
2. Stop the conflicting process (use Task Manager or `taskkill /PID <pid> /F`) or change the port in `docker-compose.yml`.

### Docker Desktop: WSL 2 integration not working

1. Open Docker Desktop → Settings → Resources → WSL Integration.
2. Enable the toggle for your WSL distro (e.g., Ubuntu).
3. Click **Apply & Restart**.

If you see `error during connect: ... pipe/docker_engine`:
- Make sure Docker Desktop is running (whale in system tray).
- Try restarting Docker Desktop.

### Containers exit immediately / backend keeps restarting

Check logs for the specific service:
```powershell
docker compose logs backend
docker compose logs worker
```

Common causes:
- Missing or incorrect API keys in `.env` — recheck `ASSEMBLY_AI_API_KEY` and `GOOGLE_API_KEY`.
- Wrong `LLM` value — must be `google-gla:gemini-3-flash-preview` (not `gemini-flash` or similar).

### "Videos stay queued / never process"

```powershell
docker compose logs -f worker
docker compose logs redis
```

- Ensure `GOOGLE_API_KEY` is valid — test it at https://aistudio.google.com/app/apikey.
- Restart the worker: `docker compose restart worker`.

### Docker Desktop uses too much memory / CPU

Open Docker Desktop → Settings → Resources → Advanced and lower the CPU/memory limits. A minimum of **4 GB RAM** and **2 CPUs** is recommended for smooth video processing.

### Antivirus / firewall blocking Docker

Some Windows security software blocks Docker networking. Add exceptions for:
- `%PROGRAMFILES%\Docker\Docker\resources\bin\docker.exe`
- The Docker Desktop application folder

### File permissions in volumes

If you see permission errors when Docker tries to write to mounted volumes, make sure Docker Desktop has access to the drive:

1. Docker Desktop → Settings → Resources → File sharing.
2. Add the drive or folder where you cloned the repo.

---

## Getting a Google API Key

1. Go to https://aistudio.google.com/app/apikey.
2. Sign in with a Google account.
3. Click **Create API key**.
4. Copy the key and paste it as `GOOGLE_API_KEY=<your_key>` in `.env`.

The free tier of Google AI Studio is sufficient for personal use.

---

## Next Steps

- [Configuration reference](./configuration.md) — all environment variables explained.
- [App Guide](./app-guide.md) — how to use the UI.
- [Troubleshooting](./troubleshooting.md) — general troubleshooting beyond Windows-specific issues.
- [Architecture](./architecture.md) — how the services fit together.
