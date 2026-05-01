# Publishing Toleria Skills to Community

Guide for publishing Toleria skills to skills.sh registry and broader community.

## Distribution Channels

### 1. skills.sh Registry (Primary)

skills.sh is the official package manager for Claude Code skills.

**Submit skill:**

```bash
# 1. Create GitHub release
git tag v1.0.0
git push origin v1.0.0

# 2. Create release notes
# Title: Toleria Digital Twin v1.0.0
# Body: Features, installation, usage examples

# 3. Submit to skills registry
# Email: skills@developers.coffee
# Provide:
#   - Skill name: toleria-digital-twin
#   - Repo URL: https://github.com/DevelopersCoffee/toleria-knowledge-orchestrator-skill
#   - Version: 1.0.0
#   - Brief description

# 4. Wait for community review (1-2 weeks)

# 5. Once approved, available via:
#   skills.sh install toleria-digital-twin
```

### 2. GitHub Releases

Host releases directly on GitHub for easy download.

**Create release:**

```bash
# Tag the version
git tag -a v1.0.0 -m "Toleria Skills v1.0.0: Core skills + Digital Twin"

# Push tag
git push origin v1.0.0

# Create release (via GitHub UI or gh CLI)
gh release create v1.0.0 --title "Toleria v1.0.0" --body "$(cat RELEASE_NOTES.md)"
```

### 3. GitHub Marketplace

Publish as GitHub App for direct integration.

**Steps:**

1. Register as GitHub App
2. Configure webhook for skill discovery
3. Publish to GitHub Marketplace
4. Users can install: `https://github.com/apps/toleria-digital-twin`

### 4. NPM Registry

Publish as npm package for JavaScript environments.

**Publish:**

```bash
# Create package.json
cat > package.json << 'EOF'
{
  "name": "toleria-digital-twin",
  "version": "1.0.0",
  "description": "Extract and continuously sync codebase knowledge",
  "repository": "github:DevelopersCoffee/toleria-knowledge-orchestrator-skill",
  "author": "Toleria Team",
  "license": "MIT",
  "files": [
    "skills/digital-twin/*"
  ]
}
EOF

# Publish
npm publish
```

Then users can install:

```bash
npm install -g toleria-digital-twin
```

### 5. Homebrew (macOS)

Distribute via Homebrew for macOS users.

**Create formula:**

```bash
# formulae/toleria-digital-twin.rb
class ToleriaTwin < Formula
  desc "Extract and continuously sync codebase knowledge to Toleria vault"
  homepage "https://github.com/DevelopersCoffee/toleria-knowledge-orchestrator-skill"
  url "https://github.com/DevelopersCoffee/toleria-knowledge-orchestrator-skill/archive/v1.0.0.tar.gz"
  sha256 "abc123def456..."
  version "1.0.0"

  depends_on "bash" => :build
  depends_on "jq" => :runtime

  def install
    bin.install "skills/digital-twin/extract-and-sync.sh" => "toleria-digital-twin"
  end
end
```

**Publish to homebrew-toleria tap:**

```bash
git clone https://github.com/DevelopersCoffee/homebrew-toleria
cp formulae/toleria-digital-twin.rb homebrew-toleria/Formula/
git add Formula/toleria-digital-twin.rb
git commit -m "Add toleria-digital-twin v1.0.0"
git push
```

Install:

```bash
brew tap DevelopersCoffee/toleria
brew install toleria-digital-twin
```

---

## Publishing Checklist

- [ ] Code complete and tested (all 14 tests passing)
- [ ] Documentation complete (README, SETUP, SKILL.md)
- [ ] manifest.json has correct metadata
- [ ] install-skill.sh works (test installation)
- [ ] SKILLS_REGISTRY.md updated
- [ ] Git repo is public
- [ ] License specified (MIT)
- [ ] Author/contact info in manifest
- [ ] Example usage in README
- [ ] Test cases included
- [ ] No hardcoded credentials
- [ ] Cross-platform compatible (Darwin/Linux/Windows)

---

## Marketing & Announcements

### Announcement channels

1. **GitHub**
   - Release notes with features, improvements, fixes
   - Tag maintainers/collaborators
   - Link to documentation

2. **Social media**
   - Twitter/X: `#claudecode #devtools #opensource`
   - LinkedIn: Developer audience
   - Reddit: r/devtools, r/programming

3. **Developer communities**
   - Dev.to: "Introducing Toleria Digital Twin"
   - Hacker News: "Show HN: Toleria Skills"
   - Product Hunt: Launch day
   - Indie Hackers: Project post

4. **Technical blogs**
   - Your blog: Architecture, design decisions
   - Guest posts: Dev publications
   - Newsletter: If available

5. **Documentation sites**
   - ReadTheDocs: Host documentation
   - GitHub Pages: Static site
   - Docs.rs (if Rust)

### Sample announcement

```markdown
# Announcing Toleria Digital Twin

Extract and continuously sync your codebase knowledge to a searchable vault.

## Features

- One-go extraction: Scan entire repo, extract 30+ knowledge items
- Incremental updates: Only new/changed files processed
- Continuous sync: Optional daily/hourly automatic updates
- Idempotent: Safe to run multiple times
- Query API: Fast JSON lookups via jq

## Get Started

```bash
skills.sh install toleria-digital-twin
/toleria-digital-twin --repo ~/workspace/your-project
```

## Status

Production ready. 14 tests passing. Used on BrewPress (19 Python modules).

## Links

- [GitHub](https://github.com/DevelopersCoffee/toleria-knowledge-orchestrator-skill)
- [Installation Guide](./SETUP.md)
- [API Reference](./SKILL_REFERENCE.md)
```

---

## Maintenance & Updates

### Release schedule

- **Patch (1.0.x)** — Bug fixes, every 2 weeks
- **Minor (1.x.0)** — New features, every month
- **Major (2.0.0)** — Breaking changes, as needed

### Changelog

Keep `CHANGELOG.md`:

```markdown
# Changelog

## [1.0.1] - 2026-05-15
### Fixed
- Extraction hangs on large files (>10MB)
- Idempotency check fails on Windows path separators

## [1.0.0] - 2026-05-01
### Added
- Initial release: Extract + continuous sync
- Support for Python, JavaScript, TypeScript, Go, Markdown
- Cross-platform (Darwin, Linux, Windows)
- 14 test cases
```

### Issue triage

Monitor and respond to:
- GitHub Issues (bugs, feature requests)
- Discussions (questions, ideas)
- PRs (community contributions)

Target response time: 24 hours for issues.

---

## Community Contribution

Welcome community contributions.

**Contributing:**

1. Fork repo
2. Create feature branch: `git checkout -b feature/my-skill`
3. Implement skill with tests
4. Submit PR with:
   - Description of skill
   - Features & use cases
   - Test results
   - Documentation

5. Community review (3+ days)
6. Merge & release

**Contributor agreement:** MIT license (no CLA required)

---

## Monitoring & Analytics

Track adoption:

```bash
# skills.sh installs
skills.sh analytics toleria-digital-twin

# GitHub stars, forks, issues
gh repo view DevelopersCoffee/toleria-knowledge-orchestrator-skill

# npm downloads (if published)
npm info toleria-digital-twin downloads

# Documentation views
# (via ReadTheDocs or Vercel analytics)
```

---

## Success Metrics

Target for v1.0:
- [ ] 1K+ installations (skills.sh + direct)
- [ ] 10+ GitHub stars
- [ ] 2-3 community contributions
- [ ] 0 critical issues (at 1-month mark)
- [ ] 50+ questions/discussions resolved

Target for v1.1+:
- [ ] 5K+ installations
- [ ] Multi-repo aggregation
- [ ] Web UI
- [ ] Team collaboration
- [ ] External integrations

---

## Legal & Licensing

### License

Toleria skills: **MIT License**

Permission to:
- Use commercially
- Modify
- Distribute
- Use privately

Requirements:
- Include license notice
- State changes

### Copyright

```
Copyright (c) 2026 DevelopersCoffee

Permission is hereby granted, free of charge...
```

---

## Support Channels

Once published, provide:

1. **GitHub Issues** — Bug reports, features
2. **GitHub Discussions** — Questions, ideas
3. **Email** — contact@developers.coffee
4. **Slack** — #toleria-skills (if channel exists)
5. **Docs** — README, SETUP, API reference

---

**Status:** Ready for community publishing.

Next: Submit to skills.sh registry (1-2 weeks review time).
