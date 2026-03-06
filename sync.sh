#!/bin/bash
# sync.sh
# Bootstraps agentic:guild OS in a new destination project.
# For projects already running agentic:guild, use the `update-agentic-guild` AI skill instead.
# Usage: ./sync.sh

REPO_URL="https://raw.githubusercontent.com/jdugarte/agentic-guild/main"
REGISTRY_URL="$REPO_URL/playbooks/SYNC_REGISTRY.md"
TMP_REGISTRY="/tmp/agenticguild_sync_registry.md"

STEALTH_MODE=false
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --stealth) STEALTH_MODE=true; shift ;;
        *) shift ;;
    esac
done

if [ "$STEALTH_MODE" = true ]; then
  echo "🥷 Initializing agentic:guild Operating System in STEALTH MODE..."
else
  echo "🧠 Initializing agentic:guild Operating System..."
fi

# 1. Fetch the Sync Registry (single source of truth for all file mappings)
echo "📋 Fetching Sync Registry..."
curl -s "$REGISTRY_URL" > "$TMP_REGISTRY"
if [ ! -s "$TMP_REGISTRY" ]; then
  echo "❌ Failed to fetch SYNC_REGISTRY.md. Check your internet connection."
  exit 1
fi

# 2. Create necessary directories and stealth tracking
echo "📁 Building directory structure..."

if [ "$STEALTH_MODE" = true ]; then
  mkdir -p .git/info
  EXCLUDE_FILE=".git/info/exclude"
  touch "$EXCLUDE_FILE"
  echo "📝 Securing agentic:guild files in .git/info/exclude selectively (Stealth Mode)..."
  
  # Ensure the exclude file has the section header
  if ! grep -q "# agentic:guild (Stealth Mode)" "$EXCLUDE_FILE"; then
    {
      echo ""
      echo "# agentic:guild (Stealth Mode)"
      echo ".agenticguild/*"
    } >> "$EXCLUDE_FILE"
  fi
  
  # Write stealth config
  mkdir -p .agenticguild
  echo '{"stealth_mode": true}' > .agenticguild/config.json
else
  GITIGNORE_FILE=".gitignore"
  if [ -f "$GITIGNORE_FILE" ]; then
    if ! grep -q ".agenticguild/\*" "$GITIGNORE_FILE"; then
      echo "📝 Securing .agenticguild/ memory folder in .gitignore..."
      {
        echo ""
        echo "# agentic:guild Transient Memory"
        echo ".agenticguild/*"
        echo "!.agenticguild/.gitkeep"
      } >> "$GITIGNORE_FILE"
    fi
  else
    echo "📝 Creating .gitignore to secure .agenticguild/ memory..."
    {
      echo "# agentic:guild Transient Memory"
      echo ".agenticguild/*"
      echo "!.agenticguild/.gitkeep"
    } > "$GITIGNORE_FILE"
  fi
  
  # Ensure stealth mode is explicitly turned off if previously set
  mkdir -p .agenticguild
  echo '{"stealth_mode": false}' > .agenticguild/config.json
fi

# Helper function to create directory
function ensure_dir() {
  local dir="$1"
  if [ ! -d "$dir" ]; then
    mkdir -p "$dir"
  fi
}

ensure_dir .cursor/skills
ensure_dir .agenticguild/active_sessions
ensure_dir .agenticguild/completed_sessions

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

# 4. Download files according to the Sync Registry
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

  # Ensure parent directory exists
  ensure_dir "$(dirname "$dest")"

  if [ "$strategy" == "init" ]; then
    if [ ! -f "$dest" ]; then
      echo "   📄 Initializing $dest..."
      curl -s "$REPO_URL/$source" > "$dest"
      if [ "$STEALTH_MODE" = true ]; then
        if ! grep -q "^$dest$" "$EXCLUDE_FILE"; then echo "$dest" >> "$EXCLUDE_FILE"; fi
      fi
    else
      echo "   ⏩ Skipping $dest (already exists)"
    fi
  else
    if [ "$STEALTH_MODE" = true ] && [ -f "$dest" ]; then
      echo "   🛡️  Stealth Mode: Skipping $dest (already exists) to avoid dirtying tracked files."
    else
      echo "   📥 Syncing $dest..."
      curl -s "$REPO_URL/$source" > "$dest"
      if [ "$STEALTH_MODE" = true ]; then
        if ! grep -q "^$dest$" "$EXCLUDE_FILE"; then echo "$dest" >> "$EXCLUDE_FILE"; fi
      fi
    fi
  fi
done < "$TMP_REGISTRY"

# 5. Inject agentic:guild OS Rules into .cursorrules
echo "⚙️  Configuring .cursorrules..."
AGENTIC_GUILD_RULES=$(curl -s "$REPO_URL/templates/core/AGENTIC_GUILD_RULES.md")
if [ -n "$AGENTIC_GUILD_RULES" ]; then
  if [ ! -f ".cursorrules" ]; then
    echo "   ⚙️  Creating .cursorrules with agentic:guild OS..."
    echo "$AGENTIC_GUILD_RULES" > .cursorrules
    if [ "$STEALTH_MODE" = true ]; then
      if ! grep -q "^.cursorrules$" "$EXCLUDE_FILE"; then echo ".cursorrules" >> "$EXCLUDE_FILE"; fi
    fi
  elif ! grep -q "<agentic_guild_os>" ".cursorrules"; then
    echo "   ⚙️  Prepending agentic:guild OS to existing .cursorrules..."
    { echo "$AGENTIC_GUILD_RULES"; cat .cursorrules; } > .cursorrules.tmp && mv .cursorrules.tmp .cursorrules
    if [ "$STEALTH_MODE" = true ]; then
      echo "   ⚠️  In stealth mode, .cursorrules blocks were added. Make sure to strip them out before committing changes if team does not want agentic:guild config."
    fi
  else
    echo "   ✅ agentic:guild OS rules already present in .cursorrules."
  fi
fi

# 7. Git Hook Installation
if [ "$STEALTH_MODE" = true ]; then
  echo "⚓ Skipping Git Hook installation in stealth mode to avoid disrupting team workflows."
else
  echo "⚓ Installing Git Hooks..."
  PRE_COMMIT_LOGIC=$(curl -s "$REPO_URL/templates/git-hooks/pre-commit-logic.sh")
  if [ -n "$PRE_COMMIT_LOGIC" ]; then
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

# Cleanup
rm -f "$TMP_REGISTRY"

echo "🚀 Sync complete. agentic:guild Operating System is online."
echo ""
echo "✅ agentic:guild installed."
echo "To see your new engineer in action, type this into your AI assistant right now:"
echo "  \"Who are you?\" or \"What is agentic:guild?\""
