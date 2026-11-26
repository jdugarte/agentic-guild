#!/bin/bash
# check-flow.sh — Validates the transition tables (<exits> blocks) of every skill that has them.
# Rules: every step has exactly one <exits>; kinds and reply classes come from a fixed list; every pause has STOP and OTHER rows
# (NESTED steps have CLOSED and STOPPED), STOP leads to END-STOPPED (or a close-step) and OTHER to SAME; AUTO exits end with a "WHEN otherwise" row; every target exists; every step is reachable from the first step by following rows;
# `only-from` gates hold; procedure entries carry a return; nested skills exist and end with both END and END-STOPPED.

set -e

cd "$(dirname "$0")/.."
failed=0

for skill in skills/*/SKILL.md; do
  grep -qE '^[[:space:]]*<exits kind=' "$skill" || continue

  if grep -nE '\[(PAUSE|AUTO-TRANSITION|END)[ \]-]' "$skill" > /dev/null; then
    echo "$skill: uses old [PAUSE]/[AUTO-TRANSITION]/[END] markers; use <exits> rows instead:"
    grep -nE '\[(PAUSE|AUTO-TRANSITION|END)[ \]-]' "$skill"
    failed=1
  fi

  errors=$(awk -v file="$skill" '
    function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }
    function err(msg) { print file ": " msg; bad = 1 }
    function addEdge(from, to) { n++; efrom[n] = from; eto[n] = to; targeted[to] = 1 }
    BEGIN {
      split("CONTINUE YES NO OPEN STOP FINDINGS GUIDANCE ACCEPT ACCEPT-CHECK RETRY MANUAL CLOSED STOPPED APPLY SKIP FIX PASS OTHER", c, " ")
      for (i in c) okclass[c[i]] = 1
      split("AUTO QUESTION DECISION RESULT NESTED", k, " ")
      for (i in k) okkind[k[i]] = 1
    }
    /^[ \t]*<phase id="/ {
      match($0, /id="[^"]*"/); phase = substr($0, RSTART + 4, RLENGTH - 5)
      next
    }
    /^[ \t]*<step id="/ {
      line = $0
      match(line, /id="[^"]*"/); step = substr(line, RSTART + 4, RLENGTH - 5)
      if (step in steps) err("duplicate step id " step)
      steps[step] = 1; order[++nsteps] = step; phaseOf[step] = phase
      if (match(line, /only-from="[^"]*"/)) onlyfrom[step] = " " substr(line, RSTART + 11, RLENGTH - 12) " "
      if (line ~ /close-step="true"/) closer[step] = 1
      if (line ~ /procedure="true"/) entry[step] = 1
      if (line ~ /procedure="true"|procedure-internal="true"/) inproc[step] = 1
      if (match(line, /nested-skill="[^"]*"/)) nested[step] = substr(line, RSTART + 14, RLENGTH - 15)
      next
    }
    /^[ \t]*<exits kind="/ {
      match($0, /kind="[^"]*"/); kind = substr($0, RSTART + 6, RLENGTH - 7)
      if (!(kind in okkind)) err("step " step ": unknown exits kind " kind)
      exitcount[step]++; inexits = 1; delete classesInStep; hasStop = 0; hasOther = 0; hasClosed = 0; hasStopped = 0; lastRow = ""; nrows = 0
      next
    }
    /^[ \t]*<\/exits>/ {
      inexits = 0
      if (("YES" in classesInStep) && ("CONTINUE" in classesInStep)) err("step " step ": a pause lists both YES and CONTINUE; they overlap, so list one")
      if (("YES" in classesInStep) && ("PASS" in classesInStep)) err("step " step ": a pause lists both YES and PASS; they overlap, so list one")
      if (kind == "AUTO") { if (lastRow !~ /^WHEN otherwise/) err("step " step ": AUTO exits must end with a WHEN otherwise row") }
      else if (kind == "NESTED") { if (!hasClosed || !hasStopped) err("step " step ": NESTED exits need ON CLOSED and ON STOPPED rows") }
      else if (kind in okkind) { if (!hasStop || !hasOther) err("step " step ": " kind " exits need ON STOP and ON OTHER rows") }
      next
    }
    inexits && NF > 0 {
      row = trim($0); nrows++; lastRow = row
      if (kind == "AUTO" && row !~ /^WHEN /) err("step " step ": AUTO rows must start with WHEN: " row)
      if (kind != "AUTO" && row !~ /^ON /) err("step " step ": pause rows must start with ON: " row)
      if (row ~ /^ON /) {
        split(row, w, " "); cls = w[2]
        if (!(cls in okclass)) err("step " step ": unknown reply class " cls)
        classesInStep[cls] = 1; usedClass[cls] = 1
        if (cls == "STOP") hasStop = 1
        if (cls == "OTHER") hasOther = 1
        if (cls == "CLOSED") hasClosed = 1
        if (cls == "STOPPED") hasStopped = 1
      }
      p = index(row, " -> ")
      if (p == 0) { err("step " step ": row has no target: " row); next }
      rest = substr(row, p + 4); split(rest, t, " "); target = t[1]
      if (row ~ /^ON OTHER /) { if (target != "SAME") err("step " step ": the OTHER row must go to SAME: " row) }
      if (row ~ /^ON STOP /) { stoprow[++nstop] = step ":" target }
      after = substr(rest, length(target) + 1)
      ret = ""
      if (match(after, /^ return [0-9A-Za-z.]+/)) ret = substr(after, 9, RLENGTH - 8)
      if (target == "SAME") {
        if (kind == "AUTO") err("step " step ": AUTO rows cannot target SAME")
      } else if (target == "RETURN") {
        rets[step] = 1
      } else if (target == "END" || target == "END-STOPPED") {
        ended = 1
      } else {
        rown++; rfrom[rown] = step; rtgt[rown] = target; rret[rown] = ret; rtext[rown] = row
        addEdge(step, target)
        if (ret != "") addEdge(step, ret)
      }
      next
    }
    END {
      for (i = 1; i <= nsteps; i++) { s = order[i]; if (exitcount[s] != 1) err("step " s ": needs exactly one exits block (has " exitcount[s] + 0 ")") }
      for (i = 1; i <= rown; i++) {
        tgt = rtgt[i]; r = rret[i]
        if (!(tgt in steps)) err("step " rfrom[i] ": target " tgt " is not a step (row: " rtext[i] ")")
        if (r != "" && !(r in steps)) err("step " rfrom[i] ": return step " r " does not exist")
        if ((tgt in inproc) && !(tgt in entry) && phaseOf[rfrom[i]] != phaseOf[tgt]) err("step " rfrom[i] ": " tgt " belongs to a procedure and cannot be entered from outside it")
        if ((tgt in entry) && r == "" && !(rfrom[i] in inproc)) err("step " rfrom[i] ": entering procedure " tgt " needs a return step (row: " rtext[i] ")")
        if (r != "" && !(tgt in entry)) err("step " rfrom[i] ": only procedure entries take a return (row: " rtext[i] ")")
      }
      for (s in rets) if (!(s in inproc)) err("step " s ": RETURN is only for procedure steps")
      for (i = 1; i <= n; i++) {
        fr = efrom[i]; to = eto[i]
        if ((to in onlyfrom) && index(onlyfrom[to], " " fr " ") == 0) err("step " fr " leads into " to ", but " to " accepts only: " onlyfrom[to])
      }
      for (i = 1; i <= nstop; i++) {
        split(stoprow[i], sr, ":")
        if (sr[2] != "END-STOPPED" && !(sr[2] in closer)) err("step " sr[1] ": the STOP row must go to END-STOPPED or to a close-step, not " sr[2])
      }
      seen[order[1]] = 1; queue[1] = order[1]; qh = 1; qt = 1
      while (qh <= qt) {
        cur = queue[qh++]
        for (i = 1; i <= n; i++) if (efrom[i] == cur && !(eto[i] in seen) && (eto[i] in steps)) { seen[eto[i]] = 1; queue[++qt] = eto[i] }
      }
      for (i = 2; i <= nsteps; i++) { s = order[i]; if (!(s in seen)) err("step " s " is unreachable from the first step") }
      for (s in nested) print "NESTED " s " " nested[s]
      for (cl in usedClass) print "CLASS " cl
      if (bad) print "BAD"
    }
  ' "$skill")

  if echo "$errors" | grep -q "^BAD"; then
    echo "$errors" | grep -v "^BAD" | grep -v "^NESTED" | grep -v "^CLASS"
    failed=1
  fi

  while read -r _ cls; do
    if ! grep -qE "^[[:space:]]*([A-Z-]+, )*${cls}(, [A-Z-]+)*:|class ${cls}[: )]|is ${cls}" "$skill"; then
      echo "$skill: reply class $cls is used in a table but never defined in the skill"
      failed=1
    fi
  done < <(echo "$errors" | grep "^CLASS")

  while read -r _ step name; do
    [ -n "$name" ] || continue
    target="skills/$name/SKILL.md"
    if [ ! -f "$target" ]; then
      echo "$skill: step $step runs nested skill $name, but $target does not exist"
      failed=1
    elif ! grep -qE -- '-> END( |$)' "$target" || ! grep -q -- '-> END-STOPPED' "$target"; then
      echo "$skill: step $step runs nested skill $name, but $target does not declare both END and END-STOPPED exits"
      failed=1
    fi
  done < <(echo "$errors" | grep "^NESTED")
done

exit $failed
