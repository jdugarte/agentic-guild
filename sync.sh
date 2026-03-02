#!/bin/bash
# sync.sh
# Bootstraps AgentCore OS in a new destination project.
# For projects already running AgentCore, use the `update-agentcore` AI skill instead.
# Usage: ./sync.sh

REPO_URL="https://raw.githubusercontent.com/jdugarte/AgentCore/main"
REGISTRY_URL="$REPO_URL/playbooks/SYNC_REGISTRY.md"
TMP_REGISTRY="/tmp/agentcore_sync_registry.md"

echo "🧠 Initializing AgentCore Operating System..."

# 1. Fetch the Sync Registry (single source of truth for all file mappings)
echo "📋 Fetching Sync Registry..."
curl -s "$REGISTRY_URL" > "$TMP_REGISTRY"
if [ ! -s "$TMP_REGISTRY" ]; then
  echo "❌ Failed to fetch SYNC_REGISTRY.md. Check your internet connection."
  exit 1
fi

# 2. Create necessary directories
echo "📁 Building directory structure..."
mkdir -p .cursor/skills
mkdir -p .agentcore/active_sessions
mkdir -p docs/{ai,core,features,audit,guides}
mkdir -p docs/core/ADRs
mkdir -p .github

# 3. Configure Gitignore for AI Memory
GITIGNORE_FILE=".gitignore"
if [ -f "$GITIGNORE_FILE" ]; then
  if ! grep -q ".agentcore/\*" "$GITIGNORE_FILE"; then
    echo "📝 Securing .agentcore/ memory folder in .gitignore..."
    {
      echo ""
      echo "# AgentCore Transient Memory"
      echo ".agentcore/*"
      echo "!.agentcore/.gitkeep"
    } >> "$GITIGNORE_FILE"
  fi
else
  echo "📝 Creating .gitignore to secure .agentcore/ memory..."
  {
    echo "# AgentCore Transient Memory"
    echo ".agentcore/*"
    echo "!.agentcore/.gitkeep"
  } > "$GITIGNORE_FILE"
fi

# Ensure .gitkeep exists so the folder structure survives git
touch .agentcore/.gitkeep
touch .agentcore/active_sessions/.gitkeep

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
  mkdir -p "$(dirname "$dest")"

  if [ "$strategy" == "init" ]; then
    if [ ! -f "$dest" ]; then
      echo "   📄 Initializing $dest..."
      curl -s "$REPO_URL/$source" > "$dest"
    else
      echo "   ⏩ Skipping $dest (already exists)"
    fi
  else
    echo "   📥 Syncing $dest..."
    curl -s "$REPO_URL/$source" > "$dest"
  fi
done < "$TMP_REGISTRY"

# 5. Remove obsolete skill directories (prevents AI from discovering defunct skills)
echo "🧹 Removing obsolete skills..."
in_obsolete_block=false
while IFS= read -r line; do
  if [[ "$line" == *"OBSOLETE_SKILLS [START]"* ]]; then in_obsolete_block=true; continue; fi
  if [[ "$line" == *"OBSOLETE_SKILLS [END]"* ]]; then in_obsolete_block=false; continue; fi
  if ! $in_obsolete_block; then continue; fi

  [[ "$line" != \|* ]] && continue
  [[ "$line" == *"Obsolete Path"* ]] && continue
  [[ "$line" == *"---"* ]] && continue

  IFS='|' read -r _ path _ <<< "$line"
  path=$(echo "$path" | xargs)
  [ -z "$path" ] && continue

  if [ -d "$path" ]; then
    echo "   🗑️  Removing obsolete $path..."
    rm -rf "$path"
  fi
done < "$TMP_REGISTRY"

# 6. Inject AgentCore OS Rules into .cursorrules
echo "⚙️  Configuring .cursorrules..."
AGENT_CORE_RULES=$(curl -s "$REPO_URL/templates/core/AGENT_CORE_RULES.md")
if [ -n "$AGENT_CORE_RULES" ]; then
  if [ ! -f ".cursorrules" ]; then
    echo "   ⚙️  Creating .cursorrules with AgentCore OS..."
    echo "$AGENT_CORE_RULES" > .cursorrules
  elif ! grep -q "<agentcore_operating_system>" ".cursorrules"; then
    echo "   ⚙️  Prepending AgentCore OS to existing .cursorrules..."
    { echo "$AGENT_CORE_RULES"; cat .cursorrules; } > .cursorrules.tmp && mv .cursorrules.tmp .cursorrules
  else
    echo "   ✅ AgentCore OS rules already present in .cursorrules."
  fi
fi

# 7. Git Hook Installation
echo "⚓ Installing Git Hooks..."
PRE_COMMIT_LOGIC=$(curl -s "$REPO_URL/templates/git-hooks/pre-commit-logic.sh")
if [ -n "$PRE_COMMIT_LOGIC" ]; then
  HOOK_FILE=".git/hooks/pre-commit"
  if [ -f "$HOOK_FILE" ]; then
    if ! grep -q "AGENTCORE PRE-COMMIT" "$HOOK_FILE"; then
      echo "   📝 Appending safety check to existing pre-commit hook..."
      echo "$PRE_COMMIT_LOGIC" >> "$HOOK_FILE"
    else
      echo "   ✅ AgentCore pre-commit hook already present."
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

# Cleanup
rm -f "$TMP_REGISTRY"

echo "🚀 Sync complete. AgentCore Operating System is online."
