#!/bin/bash
# Runs as node on every boot, before tabsh starts.
# 1. Seeds the tabsh hooks for each agent into HOME once. Files the user
#    already has are never touched, and after the first boot nothing is
#    re-seeded, so edits and deletions stick.
# 2. Installs the latest Claude Code, Codex, Gemini CLI and OpenCode into the
#    volume (NPM_CONFIG_PREFIX), so every deploy and restart is up to date.
set -u
mark="$HOME/.tabsh/agents-seeded"
if [ ! -e "$mark" ]; then
  cp -r --update=none /usr/local/share/tabsh/home/. "$HOME/"
  mkdir -p "$HOME/.tabsh" && touch "$mark"
fi
# Not fatal: a registry outage leaves the previous versions in place.
timeout 240 npm i -g --no-fund --no-audit @anthropic-ai/claude-code@latest @openai/codex@latest \
  @google/gemini-cli@latest opencode-ai@latest || echo "agents: npm install failed, keeping installed versions"
