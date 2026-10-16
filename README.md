# Sentinel One-Click Installers

**Drift prevention, one click away.** Pick your Sentinel edition, run the installer, and you have a local LLM/RAG drift-prevention gateway running on your machine.

## Which one?

| Edition | For | Installer |
|---|---|---|
| **Solo** | Individual developers | `install-solo.bat` / `install-solo.sh` |
| **Teams** | Shared team RAG services | `install-teams.bat` / `install-teams.sh` |
| **Sovereign** | Enterprise / air-gapped deployments | `install-sovereign.bat` / `install-sovereign.sh` |

## How to install

1. Download this repo (or clone it).
2. **Windows:** double-click the `.bat` for your edition. **Mac/Linux:** run `./install-<edition>.sh`.
3. Wait 10–20 minutes on first run (mostly compiling the Rust extension — it's unattended).
4. The gateway starts at `http://localhost:8000`. Your API key is printed at the end and saved in the product's `.env`.

## What you need

- **Python 3.10+**
- **Rust** (the installer will offer to install it if missing)
- **~2GB** free disk space

No Ollama, no model downloads — Sentinel is an API gateway, not a chatbot.

## After install

```bash
curl -X POST http://localhost:8000/v1/stabilize \
  -H "X-API-Key: <your-key>" \
  -H "Content-Type: application/json" \
  -d '{"tenant_id":"acme","text":"hello"}'
```

Health check: `http://localhost:8000/v1/health`

## Source

Each edition is bundled from its canonical repo:

- [axiom-zeta-sentinel-solo](https://github.com/Axiom-Zeta-Innovations-LLC/axiom-zeta-sentinel-solo)
- [axiom-zeta-sentinel-teams](https://github.com/Axiom-Zeta-Innovations-LLC/axiom-zeta-sentinel-teams)
- [axiom-zeta-sentinel-sovereign](https://github.com/Axiom-Zeta-Innovations-LLC/axiom-zeta-sentinel-sovereign)
