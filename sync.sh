#!/bin/bash
# sync.sh
# Bootstraps agentic:guild OS in a new destination project.
# It never overwrites an existing file: files that already exist are left alone.
# For projects already running agentic:guild, use the `update-agentic-guild` AI skill instead.
# Usage: ./sync.sh [--stealth] [--track-memory]

REPO_URL="https://raw.githubusercontent.com/jdugarte/agentic-guild/main"
REGISTRY_URL="$REPO_URL/playbooks/SYNC_REGISTRY.md"
TMP_REGISTRY="$(mktemp)"
TMP_DOWNLOAD="$(mktemp)"
trap 'rm -f "$TMP_REGISTRY" "$TMP_DOWNLOAD" .cursorrules.tmp' EXIT

STEALTH_MODE=false
TRACK_MEMORY=false
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --stealth) STEALTH_MODE=true; shift ;;
        --track-memory) TRACK_MEMORY=true; shift ;;
        *) shift ;;
    esac
done

if [ "$STEALTH_MODE" = true ] && [ "$TRACK_MEMORY" = true ]; then
  echo "ℹ️  Stealth Mode never tracks .agenticguild/ in git; ignoring --track-memory."
  TRACK_MEMORY=false
fi

if [ "$STEALTH_MODE" = true ]; then
  echo "🥷 Initializing agentic:guild Operating System in STEALTH MODE..."
else
  echo "🧠 Initializing agentic:guild Operating System..."
fi

# Downloads a URL into the shared temp file. Succeeds only when the download works and is not empty,
# so a failed download can never leave an empty file behind.
fetch_to_tmp() {
  curl -fsS "$1" -o "$TMP_DOWNLOAD" 2>/dev/null && [ -s "$TMP_DOWNLOAD" ]
}

# Helper function to create directory
ensure_dir() {
  local dir="$1"
  if [ ! -d "$dir" ]; then
    mkdir -p "$dir"
  fi
}

# 1. Fetch the Sync Registry (single source of truth for all file mappings)
echo "📋 Fetching Sync Registry..."
if ! curl -fsS "$REGISTRY_URL" -o "$TMP_REGISTRY" 2>/dev/null || [ ! -s "$TMP_REGISTRY" ]; then
  echo "❌ Failed to fetch SYNC_REGISTRY.md. Check your internet connection."
  exit 1
fi

# 2. Create necessary directories and git ignore rules
echo "📁 Building directory structure..."

EXCLUDE_FILE=".git/info/exclude"
if [ "$STEALTH_MODE" = true ]; then
  mkdir -p .git/info
  touch "$EXCLUDE_FILE"
  echo "📝 Securing agentic:guild files in .git/info/exclude selectively (Stealth Mode)..."
  if ! grep -q "# agentic:guild (Stealth Mode)" "$EXCLUDE_FILE"; then
    {
      echo ""
      echo "# agentic:guild (Stealth Mode)"
      echo ".agenticguild/*"
    } >> "$EXCLUDE_FILE"
  fi
else
  GITIGNORE_FILE=".gitignore"
  if [ -f "$GITIGNORE_FILE" ] && grep -q "\.agenticguild" "$GITIGNORE_FILE"; then
    echo "   ⏩ Leaving the existing .agenticguild rules in .gitignore untouched."
  else
    echo "📝 Adding the .agenticguild/ ignore rules to .gitignore..."
    if [ "$TRACK_MEMORY" = true ]; then
      {
        echo ""
        echo "# agentic:guild: ephemeral files only (sessions and logs are tracked)"
        echo ".agenticguild/current_state.md"
        echo ".agenticguild/review_ledger.md"
        echo ".agenticguild/backups/"
      } >> "$GITIGNORE_FILE"
    else
      {
        echo ""
        echo "# agentic:guild Transient Memory"
        echo ".agenticguild/*"
        echo "!.agenticguild/.gitkeep"
        echo "!.agenticguild/config.json"
        echo "!.agenticguild/source_package.json"
      } >> "$GITIGNORE_FILE"
    fi
  fi
fi

ensure_dir .cursor/skills
ensure_dir .agenticguild/active_sessions
ensure_dir .agenticguild/completed_sessions

# Write the settings file only when it does not exist yet; an existing one is never changed.
CONFIG_FILE=".agenticguild/config.json"
if [ -e "$CONFIG_FILE" ]; then
  echo "   ⏩ Keeping the existing $CONFIG_FILE (edit it by hand to change settings)."
else
  printf '{\n  "stealth_mode": %s,\n  "track_memory": %s\n}\n' "$STEALTH_MODE" "$TRACK_MEMORY" > "$CONFIG_FILE"
fi

if [ "$STEALTH_MODE" = false ]; then
  ensure_dir docs/ai
  ensure_dir docs/core
  ensure_dir docs/features
  ensure_dir docs/audit
  ensure_dir docs/guides
  ensure_dir docs/core/ADRs
  ensure_dir .github
fi

# Ensure .gitkeep exists so the folder structure survives git
touch .agenticguild/.gitkeep
touch .agenticguild/active_sessions/.gitkeep
touch .agenticguild/completed_sessions/.gitkeep

# 3. Download files according to the Sync Registry (never overwriting existing files)
echo "📥 Syncing files from registry..."
in_sync_block=false
while IFS= read -r line; do
  # Detect block markers
  if [[ "$line" == *"SYNC_REGISTRY [START]"* ]]; then in_sync_block=true; continue; fi
  if [[ "$line" == *"SYNC_REGISTRY [END]"* ]]; then in_sync_block=false; continue; fi
  if ! $in_sync_block; then continue; fi

  # Skip header and separator rows
  [[ "$line" != \|* ]] && continue
  [[ "$line" == *"Upstream Source"* ]] && continue
  [[ "$line" == *"---"* ]] && continue

  # Parse columns
  IFS='|' read -r _ source dest strategy _ <<< "$line"
  source=$(echo "$source" | xargs)
  dest=$(echo "$dest" | xargs)
  strategy=$(echo "$strategy" | xargs)
  [ -z "$source" ] && continue

  if [ -e "$dest" ]; then
    echo "   ⏩ Skipping $dest (already exists; use the update-agentic-guild skill to update it)"
    continue
  fi

  ensure_dir "$(dirname "$dest")"
  echo "   📄 Adding $dest ($strategy)..."
  if fetch_to_tmp "$REPO_URL/$source"; then
    mv "$TMP_DOWNLOAD" "$dest"
    TMP_DOWNLOAD="$(mktemp)"
    if [ "$STEALTH_MODE" = true ]; then
      if ! grep -qxF "$dest" "$EXCLUDE_FILE"; then echo "$dest" >> "$EXCLUDE_FILE"; fi
    fi
  else
    echo "   ⚠️  Could not download $source; skipped $dest."
  fi
done < "$TMP_REGISTRY"

# 4. Inject agentic:guild OS Rules into .cursorrules
echo "⚙️  Configuring .cursorrules..."
if fetch_to_tmp "$REPO_URL/templates/core/AGENTIC_GUILD_RULES.md"; then
  if [ ! -e ".cursorrules" ]; then
    echo "   ⚙️  Creating .cursorrules with agentic:guild OS..."
    cp "$TMP_DOWNLOAD" .cursorrules
    if [ "$STEALTH_MODE" = true ]; then
      if ! grep -qxF ".cursorrules" "$EXCLUDE_FILE"; then echo ".cursorrules" >> "$EXCLUDE_FILE"; fi
    fi
  elif ! grep -q "<agentic_guild_os>" ".cursorrules"; then
    echo "   ⚙️  Adding agentic:guild OS to the top of the existing .cursorrules (a backup is kept)..."
    ensure_dir .agenticguild/backups
    cp -p .cursorrules .agenticguild/backups/.cursorrules.bak
    { cat "$TMP_DOWNLOAD"; echo; cat .cursorrules; } > .cursorrules.tmp
    # Replace the file only after confirming that all of the original content is still there.
    if tail -c "$(wc -c < .cursorrules)" .cursorrules.tmp | cmp -s - .cursorrules; then
      mv .cursorrules.tmp .cursorrules
    else
      rm -f .cursorrules.tmp
      echo "   ⚠️  Could not add the rules safely; .cursorrules was left unchanged."
    fi
    if [ "$STEALTH_MODE" = true ]; then
      echo "   ⚠️  In stealth mode, .cursorrules blocks were added. Make sure to strip them out before committing changes if team does not want agentic:guild config."
    fi
  else
    echo "   ✅ agentic:guild OS rules already present in .cursorrules."
  fi
else
  echo "   ⚠️  Failed to fetch the agentic:guild rules. Skipping .cursorrules."
fi

# 5. Git Hook Installation
if [ "$STEALTH_MODE" = true ]; then
  echo "⚓ Skipping Git Hook installation in stealth mode to avoid disrupting team workflows."
else
  echo "⚓ Installing Git Hooks..."
  if fetch_to_tmp "$REPO_URL/templates/git-hooks/pre-commit-logic.sh"; then
    PRE_COMMIT_LOGIC="$(cat "$TMP_DOWNLOAD")"
    HOOK_FILE=".git/hooks/pre-commit"
    if [ -f "$HOOK_FILE" ]; then
      if ! grep -q "AGENTIC-GUILD PRE-COMMIT" "$HOOK_FILE"; then
        echo "   📝 Appending safety check to existing pre-commit hook..."
        echo "$PRE_COMMIT_LOGIC" >> "$HOOK_FILE"
      else
        echo "   ✅ agentic:guild pre-commit hook already present."
      fi
    else
      if [ -d ".git/hooks" ]; then
        echo "   🆕 Creating new pre-commit hook..."
        { echo "#!/bin/bash"; echo "$PRE_COMMIT_LOGIC"; } > "$HOOK_FILE"
        chmod +x "$HOOK_FILE"
      else
        echo "   ⚠️  .git/hooks directory not found. Are you in the root of a git repository?"
      fi
    fi
  else
    echo "   ⚠️  Failed to fetch pre-commit hook logic. Skipping git hook installation."
  fi
fi

echo "🚀 Sync complete. agentic:guild Operating System is online."
echo ""
echo "✅ agentic:guild installed."
echo "To see your new engineer in action, type this into your AI assistant right now:"
echo "  \"Who are you?\" or \"What is agentic:guild?\""
