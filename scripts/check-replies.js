#!/usr/bin/env node
// check-replies.js: the reply vocabulary and the reply matrix of the skill transition tables.
//
// Every pause in a skill accepts exact words only (see VOCABULARY). This script
//   1. classifies a reply the same way the skills say the agent must (classify),
//   2. asserts invariants for every pause of every skill (no synonym is ever a word, STOP always stops,
//      a word that is not listed at a pause never routes anywhere but the OTHER row, no class appears twice),
//   3. checks that every skill spells the words it uses and carries the identical REPLIES and PAUSE PROMPT directives,
//   4. compares the routing of every accepted word at every pause with the golden matrix `scripts/flow-matrix.txt`.
// Change a table on purpose: run `node scripts/check-replies.js --update`, then read the diff of flow-matrix.txt.

const fs = require("fs");
const path = require("path");

const root = path.join(__dirname, "..");
const matrixFile = path.join(__dirname, "flow-matrix.txt");

const PR_URL = /^https?:\/\/\S+\/pull\/\d+\/?$/i;
const NUMS = "\\d+(?:\\s*,\\s*\\d+)*";

const VOCABULARY = {
  STOP: { re: /^stop$/i, examples: ["STOP"] },
  CONTINUE: { re: /^continue$/i, examples: ["CONTINUE"] },
  YES: { re: /^yes$/i, examples: ["YES"] },
  NO: { re: /^no$/i, examples: ["NO"] },
  OPEN: { re: /^open$/i, test: (m) => PR_URL.test(m), examples: ["OPEN", "https://github.com/o/r/pull/21"] },
  RETRY: { re: /^retry$/i, examples: ["RETRY"] },
  MANUAL: { re: /^manual$/i, examples: ["MANUAL"] },
  SKIP: { re: /^skip$/i, examples: ["SKIP"] },
  PASS: { re: /^again$/i, examples: ["AGAIN"] },
  FIX: {
    re: new RegExp(`^fix\\s+(?:all|${NUMS}|all\\s+except\\s+${NUMS})$`, "i"),
    examples: ["FIX 1,3", "FIX ALL", "FIX ALL EXCEPT 2"],
  },
  APPLY: { re: new RegExp(`^apply\\s+(?:all|${NUMS})$`, "i"), examples: ["APPLY 1,2", "APPLY ALL"] },
  ACCEPT: { re: new RegExp(`^accept\\s+${NUMS}$`, "i"), examples: ["ACCEPT 2", "ACCEPT 1,3"] },
  "ACCEPT-CHECK": { re: /^accept$/i, examples: ["ACCEPT"] },
};
const WORD_CLASSES = Object.keys(VOCABULARY);
const FREE_CLASSES = ["FINDINGS", "GUIDANCE", "CLOSED", "STOPPED"];
const FREE_MARKER = (c) => `~${c}`;

const NOT_WORDS = [
  "ok", "okay", "sure", "done", "green", "pushed", "resolved", "proceed", "go ahead", "yes please", "yes, continue",
  "continue and push", "continue please", "no thanks", "fix 1 and 2", "fix everything", "accept all", "accept 1 and 2",
  "apply 1 and 2", "again please", "open it", "it is open", "stopped", "y", "n",
];

function normalize(reply) {
  return reply.trim().replace(/[.!\s]+$/, "");
}

function wordClassOf(reply) {
  const m = normalize(reply);
  for (const cls of WORD_CLASSES) {
    const v = VOCABULARY[cls];
    if (v.re.test(m) || (v.test && v.test(m))) return cls;
  }
  return null;
}

function classify(reply, accepted) {
  const marker = /^~([A-Z]+)$/.exec(reply.trim());
  if (marker) return accepted.has(marker[1]) ? marker[1] : "OTHER";
  const cls = wordClassOf(reply);
  if (cls === "STOP") return "STOP";
  if (cls && accepted.has(cls)) return cls;
  return "OTHER";
}

function parseSkill(file) {
  const text = fs.readFileSync(file, "utf8");
  const steps = [];
  let current = null;
  let inExits = false;
  for (const line of text.split("\n")) {
    const s = /^\s*<step id="([^"]+)"/.exec(line);
    if (s) {
      current = { id: s[1], kind: null, rows: [] };
      steps.push(current);
      continue;
    }
    const e = /^\s*<exits kind="([^"]+)"/.exec(line);
    if (e && current) {
      current.kind = e[1];
      inExits = true;
      continue;
    }
    if (/^\s*<\/exits>/.test(line)) {
      inExits = false;
      continue;
    }
    if (inExits && current && line.trim()) {
      const row = line.trim();
      const m = /^ON (\S+) -> (.*?)(?: : .*)?$/.exec(row);
      if (m) current.rows.push({ cls: m[1], target: m[2].trim() });
    }
  }
  return { text, steps };
}

function directiveText(text, name) {
  const m = new RegExp(`^\\s*\\d+\\. ${name}: (.*)$`, "m").exec(text);
  return m ? m[1].trim() : null;
}

function wordDefinitions(text) {
  const block = /<reply_classes>([\s\S]*?)<\/reply_classes>/.exec(text);
  if (block) return block[1];
  return directiveText(text, "REPLY WORDS") || "";
}

const errors = [];
const fail = (msg) => errors.push(msg);

for (const cls of WORD_CLASSES) {
  for (const ex of VOCABULARY[cls].examples) {
    const matching = WORD_CLASSES.filter((c) => VOCABULARY[c].re.test(ex) || (VOCABULARY[c].test && VOCABULARY[c].test(ex)));
    if (matching.length !== 1) fail(`vocabulary: "${ex}" matches ${matching.length} classes (${matching.join(", ")}); every word must belong to exactly one class`);
  }
}

const skillDirs = fs.readdirSync(path.join(root, "skills")).sort();
const matrix = [];
const identical = { REPLIES: {}, "PAUSE PROMPT": {} };

for (const name of skillDirs) {
  const file = path.join(root, "skills", name, "SKILL.md");
  if (!fs.existsSync(file)) continue;
  const { text, steps } = parseSkill(file);
  if (!/<exits kind=/.test(text)) continue;

  const pauses = steps.filter((s) => ["QUESTION", "DECISION", "RESULT", "NESTED"].includes(s.kind));
  const usedClasses = new Set();
  for (const step of steps) for (const r of step.rows) usedClasses.add(r.cls);

  if (pauses.some((p) => p.kind !== "NESTED")) {
    for (const directive of Object.keys(identical)) {
      const body = directiveText(text, directive);
      if (!body) fail(`${name}: no "${directive}:" directive`);
      else (identical[directive][body] = identical[directive][body] || []).push(name);
    }
  }

  const defs = wordDefinitions(text);
  if (pauses.some((p) => p.kind !== "NESTED") && !defs) fail(`${name}: no reply words are defined (REPLY WORDS directive or <reply_classes> block)`);
  for (const cls of usedClasses) {
    if (WORD_CLASSES.includes(cls)) {
      for (const ex of VOCABULARY[cls].examples.filter((x) => !x.startsWith("http"))) {
        if (!defs.includes("`" + ex + "`")) fail(`${name}: reply class ${cls} is used in a table but its word \`${ex}\` is not spelled out in the reply words`);
      }
    } else if (["FINDINGS", "GUIDANCE"].includes(cls)) {
      if (!new RegExp(`\\b${cls}\\b`).test(defs)) fail(`${name}: reply class ${cls} is used in a table but not defined in the reply words`);
    } else if (!["OTHER", "CLOSED", "STOPPED"].includes(cls)) {
      fail(`${name}: reply class ${cls} is not in the vocabulary of check-replies.js`);
    }
  }
  if (/\bPROCEED\b/.test(text)) fail(`${name}: PROCEED is not a reply word; use CONTINUE`);

  for (const step of pauses) {
    const where = `${name} ${step.id}`;
    const classes = step.rows.map((r) => r.cls);
    const seen = new Set();
    for (const c of classes) {
      if (seen.has(c)) fail(`${where}: reply class ${c} has two rows; only the first could ever match`);
      seen.add(c);
    }
    const accepted = new Set(classes);
    const rowFor = (cls) => step.rows.find((r) => r.cls === cls);
    const route = (reply) => {
      const cls = classify(reply, accepted);
      const row = rowFor(cls);
      if (!row) return { cls, target: "(no row)" };
      return { cls, target: row.target };
    };

    if (step.kind === "NESTED") {
      for (const c of ["CLOSED", "STOPPED"]) matrix.push(`${name} ${step.id} | ${FREE_MARKER(c)} | ${route(FREE_MARKER(c)).target}`);
      continue;
    }

    const stopRow = rowFor("STOP");
    for (const reply of ["STOP", "stop", "Stop.", "  STOP!  "]) {
      const r = route(reply);
      if (!stopRow || r.cls !== "STOP" || r.target !== stopRow.target) fail(`${where}: "${reply}" must take the STOP row`);
    }

    for (const cls of WORD_CLASSES) {
      for (const ex of VOCABULARY[cls].examples) {
        const got = wordClassOf(ex);
        if (got !== cls) fail(`vocabulary: "${ex}" is read as ${got}, expected ${cls}`);
        for (const variant of [ex, ex.toLowerCase(), ex + ".", ex.toLowerCase() + "!"]) {
          const r = route(variant);
          const want = cls === "STOP" || accepted.has(cls) ? cls : "OTHER";
          if (r.cls !== want) fail(`${where}: "${variant}" is classified ${r.cls}, expected ${want}`);
          if (want === "OTHER" && rowFor("OTHER") && r.target !== "SAME") fail(`${where}: "${variant}" is not a word here, so it must take the OTHER row (SAME), not ${r.target}`);
        }
      }
    }

    for (const reply of NOT_WORDS) {
      const r = route(reply);
      if (r.cls !== "OTHER") fail(`${where}: "${reply}" is not a reply word but was classified ${r.cls}`);
    }
    for (const cls of FREE_CLASSES) {
      if (cls === "CLOSED" || cls === "STOPPED") continue;
      const r = route(FREE_MARKER(cls));
      if (!accepted.has(cls) && r.cls !== "OTHER") fail(`${where}: free text ${cls} is not listed here but was classified ${r.cls}`);
    }

    const reachable = [];
    for (const cls of classes) {
      if (cls === "OTHER") continue;
      const sample = WORD_CLASSES.includes(cls) ? VOCABULARY[cls].examples[0] : FREE_MARKER(cls);
      const r = route(sample);
      if (r.cls !== cls) fail(`${where}: the ${cls} row can never be reached (${sample} is classified ${r.cls})`);
      reachable.push([sample, r.target]);
    }
    for (const [sample, target] of reachable) matrix.push(`${name} ${step.id} | ${sample} | ${target}`);
    matrix.push(`${name} ${step.id} | banana | ${route("banana").target}`);
  }
}

for (const [directive, variants] of Object.entries(identical)) {
  const bodies = Object.keys(variants);
  if (bodies.length > 1) {
    fail(`the ${directive} directive differs between skills; it must be identical:\n` + bodies.map((b) => `  [${variants[b].join(", ")}] ${b.slice(0, 80)}...`).join("\n"));
  }
}

const golden = matrix.join("\n") + "\n";
if (process.argv.includes("--update")) {
  fs.writeFileSync(matrixFile, "# Golden reply matrix: skill step | reply | where it leads. Written by `node scripts/check-replies.js --update`; read the diff before committing.\n" + golden);
  console.log(`Wrote ${matrix.length} rows to scripts/flow-matrix.txt`);
} else if (!fs.existsSync(matrixFile)) {
  fail("scripts/flow-matrix.txt is missing; run node scripts/check-replies.js --update");
} else {
  const want = fs.readFileSync(matrixFile, "utf8").split("\n").filter((l) => l && !l.startsWith("#"));
  const got = matrix;
  const wantSet = new Set(want);
  const gotSet = new Set(got);
  for (const l of want) if (!gotSet.has(l)) fail(`matrix expects, tables no longer give: ${l}`);
  for (const l of got) if (!wantSet.has(l)) fail(`tables give, matrix does not expect: ${l}`);
}

if (errors.length > 0) {
  console.error(errors.join("\n"));
  process.exit(1);
}
