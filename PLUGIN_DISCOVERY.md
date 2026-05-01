# Toleria Skill - Team Installation via Claude Code

## For Team Members - Claude Code Plugin Discovery

### Method 1: Claude Code Plugin Browser (Easiest - Recommended)

1. **Open Claude Code**
2. **Go to:** Plugins → Discover Plugins (or Browse Plugins)
3. **Search:** `toleria` or `toleria-knowledge-orchestrator`
4. **Click:** Install
5. **Restart** Claude Code
6. **Use:** Type `/toleria init-vault`

The skill is now available across all your projects.

### Method 2: One-Line Team Setup

Everyone on your team runs:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/DevelopersCoffee/toleria-knowledge-orchestrator-skill/main/setup-team.sh)
```

Or if behind firewall:

```bash
# Download first
curl -O https://raw.githubusercontent.com/DevelopersCoffee/toleria-knowledge-orchestrator-skill/main/setup-team.sh

# Run
bash setup-team.sh
```

### Method 3: Manual Git Clone

```bash
mkdir -p ~/.claude/plugins
cd ~/.claude/plugins
git clone https://github.com/DevelopersCoffee/toleria-knowledge-orchestrator-skill.git toleria
```

Restart Claude Code.

### Method 4: Copy-Paste Install (Offline)

If your team can't access GitHub:

1. Someone downloads: `toleria-knowledge-orchestrator-skill.zip`
2. Share via Slack/Email/Drive
3. Team members extract to: `~/.claude/skills/toleria`
4. Restart Claude Code

## Verify Installation

After installation, verify in Claude Code:

```
/toleria --version
```

Should respond:
```
Toleria Knowledge Orchestrator v1.0.0
Author: UC Guy (ucguy4u)
```

## First-Time Setup

After installation, each team member:

```bash
/toleria init-vault
```

Creates personal vault at: `~/Documents/Vault/`

## Team Sync Setup

### Option A: Shared Vault (Recommended for Teams)

All team members point to shared vault:

```bash
export VAULT_ROOT="/path/to/shared/vault"
/toleria scan-repo ~/workspace/my-project
```

Or configure in `~/.claude/settings.json`:

```json
{
  "env": {
    "VAULT_ROOT": "/Volumes/team-drive/toleria-vault"
  }
}
```

### Option B: Individual Vaults + Git Sync

Each person has own vault, synced via git:

```bash
# After /toleria init-vault
cd ~/Documents/Vault
git init
git remote add origin https://github.com/team/toleria-vault.git
git add .
git commit -m "Initial vault"
git push -u origin main
```

## Troubleshooting

### Skill Not Showing in Claude Code

1. **Check installation:**
   ```bash
   ls -la ~/.claude/skills/toleria
   # Should be a symlink or directory
   ```

2. **Restart Claude Code:**
   - Close completely
   - Reopen

3. **Check manifest:**
   ```bash
   cat ~/.claude/skills/toleria/manifest.json | grep -A3 '"name"'
   # Should show: "Toleria Knowledge Orchestrator"
   ```

### Vault Permission Issues

```bash
# Fix permissions
chmod 755 ~/Documents/Vault
chmod 755 ~/Documents/Vault/*
```

### Team Shared Vault Not Accessible

```bash
# Check network path
mount | grep "team-drive"

# Remount if needed
mount -a
```

## Plugin Registry Status

- ✅ **GitHub:** Public repo
- ✅ **Manifest:** Registered in manifest.json
- ⏳ **Claude Code Registry:** Pending submission
- ⏳ **Gemini Registry:** Pending submission
- ⏳ **Copilot Registry:** Pending submission

Once approved, `Method 1` (Plugin Browser) becomes primary install method.

## Plugin Metadata

```json
{
  "id": "toleria-knowledge-orchestrator",
  "name": "Toleria Knowledge Orchestrator",
  "version": "1.0.0",
  "author": {
    "name": "UC Guy",
    "email": "coffee.devloper@gmail.com"
  },
  "repository": "https://github.com/DevelopersCoffee/toleria-knowledge-orchestrator-skill",
  "platforms": ["claude-code", "gemini-cli", "copilot-cli", "standalone"]
}
```

## Support

- **Documentation:** [README.md](README.md)
- **Installation:** [INSTALL.md](INSTALL.md)
- **Issues:** [GitHub Issues](https://github.com/DevelopersCoffee/toleria-knowledge-orchestrator-skill/issues)
- **Author:** UC Guy (@ucguy4u)
- **Email:** coffee.devloper@gmail.com

---

**Version:** 1.0.0  
**Status:** Production Ready  
**Last Updated:** 2026-05-01
