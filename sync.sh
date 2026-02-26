#!/bin/bash
# sync.sh
# Quickly downloads the universal AI Skills, Memory Scaffold, and Playbooks from the AgentCore Global Brain.
# Usage: ./sync.sh

REPO_URL="https://raw.githubusercontent.com/jdugarte/AgentCore/main"

echo "🧠 Initializing AgentCore Operating System..."

# 1. Create necessary directories
echo "📁 Building directory structure..."
mkdir -p .cursor/skills/{start-task,finish-branch,harvest-rules,status-check,code-review,audit-compliance,sync-docs,pr-description,roadmap-manage,roadmap-consult}
mkdir -p .agentcore/active_sessions
mkdir -p docs/{ai,core,features,audit,guides}
mkdir -p docs/core/ADRs
mkdir -p .github
mkdir -p docs/.agent-core-templates

# 2. Configure Gitignore for AI Memory
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

# 3. Download Playbooks
echo "📥 Syncing Playbooks & Protocols..."
curl -s "$REPO_URL/playbooks/AI_DEVELOPER_PROTOCOL.md" > docs/ai/AI_DEVELOPER_PROTOCOL.md
curl -s "$REPO_URL/playbooks/AI_WORKFLOW_PLAYBOOK.md" > docs/ai/AI_WORKFLOW_PLAYBOOK.md
curl -s "$REPO_URL/playbooks/EXPECTED_PROJECT_STRUCTURE.md" > docs/ai/EXPECTED_PROJECT_STRUCTURE.md
curl -s "$REPO_URL/templates/adr/0000-ADR-TEMPLATE.md" > docs/core/ADRs/0000-ADR-TEMPLATE.md

# 4. Download Universal XML Skills
echo "📥 Syncing Master XML Skills..."
curl -s "$REPO_URL/skills/start-task/SKILL.md" > .cursor/skills/start-task/SKILL.md
curl -s "$REPO_URL/skills/finish-branch/SKILL.md" > .cursor/skills/finish-branch/SKILL.md
curl -s "$REPO_URL/skills/status-check/SKILL.md" > .cursor/skills/status-check/SKILL.md
curl -s "$REPO_URL/skills/harvest-rules/SKILL.md" > .cursor/skills/harvest-rules/SKILL.md
curl -s "$REPO_URL/skills/code-review/SKILL.md" > .cursor/skills/code-review/SKILL.md
curl -s "$REPO_URL/skills/audit-compliance/SKILL.md" > .cursor/skills/audit-compliance/SKILL.md
curl -s "$REPO_URL/skills/sync-docs/SKILL.md" > .cursor/skills/sync-docs/SKILL.md
curl -s "$REPO_URL/skills/pr-description/SKILL.md" > .cursor/skills/pr-description/SKILL.md
curl -s "$REPO_URL/skills/roadmap-manage/SKILL.md" > .cursor/skills/roadmap-manage/SKILL.md
curl -s "$REPO_URL/skills/roadmap-consult/SKILL.md" > .cursor/skills/roadmap-consult/SKILL.md

# Remove obsolete/renamed skill directories (prevents AI from discovering defunct skills)
for obsolete in sync-schema-docs pr-description-clipboard; do
  if [ -d ".cursor/skills/$obsolete" ]; then
    echo "   🧹 Removing obsolete skill .cursor/skills/$obsolete..."
    rm -rf ".cursor/skills/$obsolete"
  fi
done

# 5. Download Templates (To temporary holding folder)
echo "📥 Syncing Governance Templates..."
curl -s "$REPO_URL/templates/pr/PULL_REQUEST_TEMPLATE.md" > .github/PULL_REQUEST_TEMPLATE.md
curl -s "$REPO_URL/templates/core/SPEC.md" > docs/.agent-core-templates/SPEC.md
curl -s "$REPO_URL/templates/core/SYSTEM_ARCHITECTURE.md" > docs/.agent-core-templates/SYSTEM_ARCHITECTURE.md
curl -s "$REPO_URL/templates/core/deterministic_coding_standards.md" > docs/.agent-core-templates/deterministic_coding_standards.md
curl -s "$REPO_URL/templates/core/TESTING_STRATEGY_MATRIX.md" > docs/.agent-core-templates/TESTING_STRATEGY_MATRIX.md
curl -s "$REPO_URL/templates/core/DATA_FLOW_MAP.md" > docs/.agent-core-templates/DATA_FLOW_MAP.md
curl -s "$REPO_URL/templates/core/AGENT_CORE_RULES.md" > docs/.agent-core-templates/AGENT_CORE_RULES.md
curl -s "$REPO_URL/templates/core/ROADMAP.md" > docs/.agent-core-templates/ROADMAP.md

# Memory Scaffold Templates
curl -s "$REPO_URL/templates/core/memory_scaffold/current_state.md" > docs/.agent-core-templates/current_state.md
curl -s "$REPO_URL/templates/core/memory_scaffold/blocker_log.md" > docs/.agent-core-templates/blocker_log.md
curl -s "$REPO_URL/templates/core/memory_scaffold/pending_refactors.md" > docs/.agent-core-templates/pending_refactors.md
curl -s "$REPO_URL/templates/core/memory_scaffold/task_template.md" > docs/.agent-core-templates/task_template.md

# 6. Safe Initialization (Only write if file doesn't exist to protect local context)
echo "🏗️ Initializing Missing Governance & Memory Files..."

declare -a core_files=("SPEC.md" "SYSTEM_ARCHITECTURE.md" "deterministic_coding_standards.md" "TESTING_STRATEGY_MATRIX.md" "DATA_FLOW_MAP.md")
for file in "${core_files[@]}"; do
  if [ ! -f "docs/core/$file" ]; then
    echo "   📄 Initializing docs/core/$file..."
    cp "docs/.agent-core-templates/$file" "docs/core/$file"
  fi
done

declare -a memory_files=("current_state.md" "blocker_log.md" "pending_refactors.md")
for file in "${memory_files[@]}"; do
  if [ ! -f ".agentcore/$file" ]; then
    echo "   🧠 Initializing .agentcore/$file..."
    cp "docs/.agent-core-templates/$file" ".agentcore/$file"
  fi
done

if [ ! -f ".agentcore/active_sessions/task_template.md" ]; then
  cp docs/.agent-core-templates/task_template.md .agentcore/active_sessions/task_template.md
fi

if [ ! -f "docs/ROADMAP.md" ]; then
  echo "   📄 Initializing docs/ROADMAP.md..."
  cp docs/.agent-core-templates/ROADMAP.md docs/ROADMAP.md
fi

# 7. Inject AgentCore OS Rules into .cursorrules
if [ -f "docs/.agent-core-templates/AGENT_CORE_RULES.md" ]; then
  if [ ! -f ".cursorrules" ]; then
    echo "   ⚙️ Creating .cursorrules with AgentCore OS..."
    cp docs/.agent-core-templates/AGENT_CORE_RULES.md .cursorrules
  elif ! grep -q "<agentcore_operating_system>" ".cursorrules"; then
    echo "   ⚙️ Prepending AgentCore OS to existing .cursorrules..."
    cat docs/.agent-core-templates/AGENT_CORE_RULES.md .cursorrules > .cursorrules.tmp && mv .cursorrules.tmp .cursorrules
  fi
fi

# Cleanup
rm -rf docs/.agent-core-templates

# 8. Git Hook Installation
echo "⚓ Installing Git Hooks..."
curl -s "$REPO_URL/templates/git-hooks/pre-commit-logic.sh" > .cursor/pre-commit-logic.sh

HOOK_FILE=".git/hooks/pre-commit"
if [ -f "$HOOK_FILE" ]; then
  if ! grep -q "AGENTCORE PRE-COMMIT" "$HOOK_FILE"; then
    echo "📝 Appending safety check to existing pre-commit hook..."
    cat .cursor/pre-commit-logic.sh >> "$HOOK_FILE"
  else
    echo "✅ AgentCore pre-commit hook already present."
  fi
else
  if [ -d ".git/hooks" ]; then
    echo "🆕 Creating new pre-commit hook..."
    echo "#!/bin/bash" > "$HOOK_FILE"
    cat .cursor/pre-commit-logic.sh >> "$HOOK_FILE"
    chmod +x "$HOOK_FILE"
  else
    echo "⚠️ .git/hooks directory not found. Are you in the root of a git repository?"
  fi
fi
rm -f .cursor/pre-commit-logic.sh

echo "🚀 Sync complete. AgentCore Operating System is online."
