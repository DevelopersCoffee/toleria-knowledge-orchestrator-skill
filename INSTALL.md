# Toleria Skill - Installation Guide

## For Your Local Machine (One-Time Setup)

### Quick Install (Recommended)

```bash
git clone https://github.com/DevelopersCoffee/toleria-knowledge-orchestrator-skill.git
cd toleria-knowledge-orchestrator-skill
./install.sh
```

Done. Skill available in Claude Code, Gemini, Copilot, Codex immediately.

### Manual Install

```bash
# 1. Copy to central location
mkdir -p ~/.agents/skills
cp -r toleria-knowledge-orchestrator-skill ~/.agents/skills/toleria

# 2. Create symlinks (choose your platforms)
mkdir -p ~/.claude/skills
ln -s ~/.agents/skills/toleria ~/.claude/skills/toleria

mkdir -p ~/.gemini/skills
ln -s ~/.agents/skills/toleria ~/.gemini/skills/toleria

mkdir -p ~/.copilot/skills
ln -s ~/.agents/skills/toleria ~/.copilot/skills/toleria

# 3. Verify
ls -la ~/.claude/skills/toleria
```

## For Your Team - Claude Code Plugin Method

### Option 1: Via Claude Code Plugin Browser (Easiest)

1. Open Claude Code
2. Go to **Plugins** → **Browse Plugins**
3. Search: `toleria-knowledge-orchestrator`
4. Click **Install**
5. Restart Claude Code
6. Use: `/toleria init-vault`

### Option 2: Via Git Clone (For Development)

```bash
# Clone to plugins directory
mkdir -p ~/.claude/plugins
cd ~/.claude/plugins
git clone https://github.com/DevelopersCoffee/toleria-knowledge-orchestrator-skill.git toleria

# Restart Claude Code
# Then use: /toleria init-vault
```

### Option 3: Via npm (Coming Soon)

```bash
npm install -g @developercoffee/toleria-skill
claude-setup toleria
```

### Option 4: Share install.sh with Team

Send team the `install.sh` script:

```bash
# Team members run:
curl -O https://raw.githubusercontent.com/DevelopersCoffee/toleria-knowledge-orchestrator-skill/main/install.sh
chmod +x install.sh
./install.sh
```

## Verify Installation

### In Claude Code

```
/toleria --version
# Shows: Toleria v1.0.0
```

### In Terminal

```bash
~/.agents/skills/toleria/toleria.sh init-vault
# Creates: ~/Documents/Vault
```

### Check Symlinks

```bash
ls -la ~/.claude/skills/
# Should show: toleria -> ~/.agents/skills/toleria
```

## Uninstall

### Quick Uninstall

```bash
cd ~/path/to/toleria-knowledge-orchestrator-skill
./install.sh --uninstall
```

### Manual Uninstall

```bash
# Remove symlinks
rm ~/.claude/skills/toleria
rm ~/.gemini/skills/toleria
rm ~/.copilot/skills/toleria
rm ~/.codex/skills/toleria

# Remove central installation
rm -rf ~/.agents/skills/toleria
```

## Troubleshooting

### Skill not showing in Claude Code

```bash
# Restart Claude Code and check:
ls -la ~/.claude/skills/toleria

# Should be a symlink, not a directory
# If it's a directory, remove and recreate:
rm -rf ~/.claude/skills/toleria
ln -s ~/.agents/skills/toleria ~/.claude/skills/toleria
```

### Permission denied

```bash
# Make scripts executable
chmod +x ~/.agents/skills/toleria/*.sh
```

### Vault not initializing

```bash
# Check vault directory exists
mkdir -p ~/Documents/Vault

# Check permissions
chmod 755 ~/Documents/Vault

# Try init again
/toleria init-vault
```

## Next Steps

1. **Initialize vault:**
   ```bash
   /toleria init-vault
   ```

2. **Bootstrap workspace:**
   ```bash
   /toleria bootstrap.sh --vault-root ~/Documents/Vault --workspace ~/workspace
   ```

3. **Scan projects:**
   ```bash
   /toleria scan-repo ~/workspace/my-project
   ```

4. **Query knowledge:**
   ```bash
   /toleria query stack PYTHON_DJANGO_POSTGRES
   ```

## Support

- **Docs:** See [README.md](README.md)
- **Issues:** Open GitHub issue
- **Author:** UC Guy (@ucguy4u)
- **Email:** coffee.devloper@gmail.com
- **Org:** [DevelopersCoffee](https://github.com/DevelopersCoffee)

---

**Version:** 1.0.0  
**Status:** Production Ready  
**Last Updated:** 2026-05-01
