> ⚠️ **DEPRECATED** — This skill has been superseded by the agent-orchestrator architecture.
> Use `/orchestrate-*` skills instead. This file is kept for backward compatibility and will be removed in a future release.
> See `.agents/skills/orchestrate-*/SKILL.md` for the new thin orchestrators and `.agents/agents/agent-*.md` for domain agents.

# NOSE Debug Agent — Systematic Root Cause Analysis (v2)

```yaml
name: nose-debug
version: 2.0.0
type: core
description: >
  Systematic debugging with root cause investigation.
  Reproduces issues, isolates problems, diagnoses root cause,
  and applies verified fixes with high confidence.
enforcement_level: mandatory
policy: "Zero hallucination, Iron Law: no fixes without root cause"
allowed_tools: [Read, Grep, Glob, Bash, Agent, mcp__playwright__browser_navigate, mcp__playwright__browser_click, mcp__playwright__browser_type, mcp__playwright__browser_snapshot, mcp__playwright__browser_take_screenshot, mcp__playwright__browser_evaluate, mcp__playwright__browser_console_messages, mcp__playwright__browser_verify_text_visible, mcp__playwright__browser_verify_element_visible, mcp__playwright__browser_resize, mcp__playwright__browser_close]
```

---

## 🎯 PURPOSE

Debug errors without guessing. Never apply fixes blindly.

**Iron Law:** No fix is attempted until root cause is identified with > 70% confidence.

---

## 📋 INPUT SCHEMA

**Required:**
```json
{
  "error_message": "string (full error message)",
  "error_trace": "string (stack trace or error log)",
  "reproduction_steps": ["step1", "step2", "step3"],
  "context": {
    "file": "src/hooks/useSearch.ts",
    "line": 42,
    "code_snippet": "const results = data.filter(...)"
  }
}
```

**Optional:**
```json
{
  "related_files": ["src/lib/search.ts", "src/api/routes.ts"],
  "environment": "local|staging|production",
  "frequency": "always|sometimes|rare",
  "first_seen": "2026-03-26T10:55:00Z"
}
```

---

## 🔍 EXECUTION PHASES

### PHASE 1: REPRODUCE THE ISSUE

**Goal:** Verify the issue exists and is reproducible

```python
def phase_1_reproduce(state, input):
  state['debug_info']['investigation_complete'] = False

  steps = input['reproduction_steps']
  error_msg = input['error_message']

  print(f"🔍 Reproducing issue: {error_msg}")

  # Step 1: Setup test environment
  setup_test_env(state['codebase_context']['branch'])

  # Step 2: Execute reproduction steps
  for i, step in enumerate(steps):
    print(f"  [{i+1}] {step}")
    result = execute_step(step)

    if not result['success']:
      log_history(state, 'reproduction_failed', f'Failed at step {i+1}')
      return escalate(state, f'Could not reproduce issue at step {i+1}')

  # Step 3: Verify error appears
  if not verify_error_appears(error_msg):
    return escalate(state, 'Error did not appear during reproduction')

  # Success
  log_history(state, 'issue_reproduced', 'Issue successfully reproduced locally')

  return {
    'phase': 'reproduce',
    'status': 'complete',
    'reproduced': True,
    'frequency': determine_frequency(state)  # always|sometimes|rare
  }
```

**Frontend Issue Reproduction (Playwright MCP):**
If the issue is UI/frontend related, reproduce it in a real browser:
```
mcp__playwright__browser_navigate(url="http://localhost:3000")
mcp__playwright__browser_click(element="[data-testid='search-btn']")
mcp__playwright__browser_type(element="[data-testid='search-input']", text="rose")
mcp__playwright__browser_click(element="[data-testid='filter-floral']")
mcp__playwright__browser_console_messages()  # check for JS errors
mcp__playwright__browser_take_screenshot(path="/tmp/debug-repro.png")  # visual evidence
```

---

### PHASE 2: ISOLATE THE PROBLEM

**Goal:** Narrow down to the exact code causing the issue

```python
def phase_2_isolate(state, input):
  error_trace = input['error_trace']
  context_file = input['context']['file']
  context_line = input['context']['line']

  print(f"🎯 Isolating problem in {context_file}:{context_line}")

  # Step 1: Parse stack trace
  stack_frames = parse_stack_trace(error_trace)
  print(f"  Stack frames: {len(stack_frames)}")

  # Step 2: Identify most relevant frame
  relevant_frame = stack_frames[0]  # Top of stack = most relevant
  print(f"  Most relevant: {relevant_frame['file']}:{relevant_frame['line']}")

  # Step 3: Read affected code section
  code = read_code_section(relevant_frame['file'],
                          relevant_frame['line'] - 5,
                          relevant_frame['line'] + 10)

  print(f"  Affected code: {code}")

  # Step 4: Identify the exact problematic line
  problematic_line = analyze_code_for_issues(code, error_msg=input['error_message'])
  print(f"  Problem line: {problematic_line}")

  # Step 5: Check call site
  caller = find_caller(relevant_frame['file'], relevant_frame['line'])
  print(f"  Called from: {caller}")

  # Step 6: Trace data flow
  data_flow = trace_data_flow(relevant_frame['file'],
                             relevant_frame['line'],
                             input_var=relevant_frame.get('variable'))
  print(f"  Data flow: {data_flow}")

  state['debug_info']['isolated_file'] = relevant_frame['file']
  state['debug_info']['isolated_line'] = relevant_frame['line']
  state['debug_info']['code_section'] = code
  state['debug_info']['data_flow'] = data_flow

  return {
    'phase': 'isolate',
    'status': 'complete',
    'isolated_file': relevant_frame['file'],
    'isolated_line': relevant_frame['line'],
    'data_flow': data_flow
  }
```

---

### PHASE 3: IDENTIFY ROOT CAUSE

**Goal:** Determine WHY the code is failing

```python
def phase_3_root_cause(state, input):
  isolated_file = state['debug_info']['isolated_file']
  isolated_line = state['debug_info']['isolated_line']
  code = state['debug_info']['code_section']
  error_msg = input['error_message']

  print(f"🔬 Identifying root cause...")

  # Analyze error pattern
  error_type = extract_error_type(error_msg)  # TypeError, ReferenceError, etc.
  print(f"  Error type: {error_type}")

  # Common patterns
  if 'Cannot read property' in error_msg or 'undefined' in error_msg:
    root_cause = analyze_undefined_access(code)
    # e.g., "Variable 'results' is undefined at this point"

  elif 'null' in error_msg or 'NaN' in error_msg:
    root_cause = analyze_null_safety(code)
    # e.g., "API returns null but code assumes object"

  elif 'timeout' in error_msg.lower():
    root_cause = analyze_performance(isolated_file)
    # e.g., "N+1 query in loop, missing index on database"

  elif 'TypeError' in error_type:
    root_cause = analyze_type_mismatch(code, error_msg)
    # e.g., "Expected array, got string"

  else:
    root_cause = general_analysis(code, error_msg)

  # Step 2: Check for similar patterns in memory
  past_pattern = find_similar_in_memory(state['memory'], root_cause)
  if past_pattern:
    print(f"  🧠 Similar pattern in memory: {past_pattern['solution']}")
    confidence = 0.95  # Higher confidence if we've seen it before
  else:
    confidence = calculate_confidence(root_cause)

  print(f"  Root cause: {root_cause}")
  print(f"  Confidence: {confidence * 100}%")

  if confidence < 0.7:
    return escalate(state, f'Root cause confidence < 70%: {root_cause}')

  state['debug_info']['root_cause'] = root_cause
  state['debug_info']['root_cause_confidence'] = confidence

  return {
    'phase': 'root_cause',
    'status': 'complete',
    'root_cause': root_cause,
    'confidence': confidence,
    'similar_past_issue': past_pattern
  }
```

**Common Root Causes:**

```
1. Undefined/null reference
   - Variable used before definition
   - API returns null, code assumes object
   - Optional chaining missing (.?)

2. Type mismatch
   - Expected array, got string
   - Expected object, got primitive
   - Type assertion missing

3. Logic error
   - Off-by-one in loop
   - Wrong comparison operator
   - Missing validation

4. Data state issue
   - Race condition (async/await)
   - Stale cache
   - Missing initialization

5. External dependency
   - API timeout
   - Database query slow
   - Missing environment variable

6. Edge case
   - Empty array not handled
   - Special character not escaped
   - Boundary condition missed
```

---

### PHASE 4: GENERATE FIX

**Goal:** Create a fix for the identified root cause

```python
def phase_4_fix(state, input):
  root_cause = state['debug_info']['root_cause']
  isolated_file = state['debug_info']['isolated_file']
  isolated_line = state['debug_info']['isolated_line']
  code = state['debug_info']['code_section']

  print(f"💡 Generating fix...")

  # Map root cause to fix pattern
  if 'undefined' in root_cause.lower():
    fix_code = generate_null_safety_fix(code, isolated_line)
    fix_type = 'add_null_check'
    # if (!data) return;
    # if (data?.length) instead of data.length

  elif 'type' in root_cause.lower():
    fix_code = generate_type_fix(code, isolated_line)
    fix_type = 'add_type_validation'
    # const results = Array.isArray(data) ? data : [data];

  elif 'performance' in root_cause.lower():
    fix_code = generate_performance_fix(isolated_file)
    fix_type = 'optimize_query'
    # Add database index, caching, pagination

  elif 'logic' in root_cause.lower():
    fix_code = generate_logic_fix(code, isolated_line)
    fix_type = 'fix_logic'
    # Correct loop condition, comparison, etc.

  else:
    fix_code = generate_generic_fix(code, root_cause)
    fix_type = 'custom'

  print(f"  Fix type: {fix_type}")
  print(f"  Fix code:\n{fix_code}")

  state['debug_info']['fix_code'] = fix_code
  state['debug_info']['fix_type'] = fix_type

  return {
    'phase': 'fix_generation',
    'status': 'complete',
    'fix_code': fix_code,
    'fix_type': fix_type,
    'affected_file': isolated_file,
    'affected_line': isolated_line
  }
```

**Example Fixes:**

```javascript
// BEFORE (undefined access)
const results = data.filter(item => item.active);

// AFTER (null-safe)
const results = data?.length ? data.filter(item => item.active) : [];

---

// BEFORE (type mismatch)
function process(items) {
  return items.map(x => x.value);  // Fails if items is string
}

// AFTER (type-safe)
function process(items) {
  const arr = Array.isArray(items) ? items : [items];
  return arr.map(x => x.value);
}

---

// BEFORE (N+1 query)
for (const perfume of perfumes) {
  const notes = db.query(`SELECT * FROM notes WHERE perfume_id = ${perfume.id}`);
}

// AFTER (optimized)
const allNotes = db.query(`
  SELECT n.*, p.id
  FROM notes n
  JOIN perfumes p ON n.perfume_id = p.id
  WHERE p.id IN (${perfumeIds})
`);
```

---

### PHASE 5: VALIDATE FIX

**Goal:** Test that the fix actually resolves the issue

```python
def phase_5_validate(state, input):
  fix_code = state['debug_info']['fix_code']
  isolated_file = state['debug_info']['isolated_file']
  error_msg = input['error_message']
  reproduction_steps = input['reproduction_steps']

  print(f"✅ Validating fix...")

  # Step 1: Apply fix
  apply_fix(isolated_file, fix_code)
  print(f"  Fix applied to {isolated_file}")

  # Step 2: Re-reproduce issue
  for step in reproduction_steps:
    execute_step(step)

  # Step 3: Verify error is gone
  error_still_appears = verify_error_appears(error_msg)

  if error_still_appears:
    log_history(state, 'fix_failed_error_persists', 'Applied fix but error still appears')
    return rollback_and_escalate(state, 'Fix did not resolve the issue')

  # Step 4: Run related tests
  test_results = run_tests_for_file(isolated_file)

  if not test_results['all_pass']:
    failed_tests = [t for t in test_results['tests'] if not t['passed']]
    log_history(state, 'fix_broke_tests', f'{len(failed_tests)} tests now failing')
    return rollback_and_escalate(state, 'Fix broke existing tests')

  # Step 5: Verify no new issues
  linter_issues = run_linter(isolated_file)
  if linter_issues:
    return escalate(state, f'Fix introduced linter issues: {linter_issues}')

  # Success!
  state['debug_info']['fix_attempted'] = True
  state['debug_info']['fix_validated'] = True
  state['debug_info']['confidence_score'] = 95

  log_history(state, 'fix_validated', f'Fix successfully resolved issue')

  return {
    'phase': 'validate',
    'status': 'complete',
    'fix_valid': True,
    'tests_pass': test_results['all_pass'],
    'confidence': 95
  }
```

---

## 🚫 SAFETY GATES

**Gate 1: Only fix when root cause found**
```python
if root_cause_confidence < 0.7:
  escalate(state, 'Root cause confidence too low, manual review needed')
```

**Gate 2: Only apply fix if validated**
```python
if not fix_validated:
  escalate(state, 'Fix did not pass validation, manual review needed')
```

**Gate 3: Only commit if confidence > 80**
```python
if confidence_score < 0.8:
  escalate(state, 'Overall fix confidence < 80%, needs manual approval')
```

---

## 📤 OUTPUT SCHEMA

```json
{
  "success": true,
  "root_cause": "API returns undefined for empty result set, code assumes array",
  "root_cause_confidence": 0.92,
  "reproduction_status": "successfully_reproduced",
  "isolation_file": "src/hooks/useSearch.ts",
  "isolation_line": 42,
  "fix_type": "add_null_check",
  "fix_code": "const results = data?.length ? data.filter(...) : [];",
  "fix_validated": true,
  "tests_passing": 32,
  "tests_total": 32,
  "confidence_score": 95,
  "time_spent_minutes": 12,
  "phases_completed": [
    "reproduce",
    "isolate",
    "root_cause",
    "fix_generation",
    "validate"
  ],
  "recommendation": "fix_ready_for_merge"
}
```

---

## 🚀 USAGE

### Trigger from QA

```bash
/nose-debug \
  --error "TypeError: Cannot read property 'length' of undefined" \
  --trace "at Object.<anonymous> (src/hooks/useSearch.ts:42:15)" \
  --steps "[
    'Click filter by floral notes',
    'System returns results',
    'Click filter by woody notes',
    'Error thrown'
  ]" \
  --file "src/hooks/useSearch.ts" \
  --line 42
```

### Trigger from Review

```bash
/nose-debug \
  --error "Performance regression in search" \
  --context "Search query takes 3.2s, target is 2s" \
  --steps "[
    'Load search page',
    'Type query',
    'Click filter',
    'Measure response time'
  ]"
```

---

## 🧠 LEARNING INTEGRATION

**Before generating fix:**
```python
similar_past_issue = memory.find_similar_bug(root_cause)

if similar_past_issue:
  print(f"Found similar past issue: {similar_past_issue}")
  print(f"Past fix success rate: {similar_past_issue['effectiveness']}")

  # Use proven fix
  fix_code = similar_past_issue['solution']
  confidence = 0.95
```

**After fix validated:**
```python
# Store for future reference
state['memory']['past_bugs'].append({
  'pattern': root_cause,
  'fix': fix_code,
  'effectiveness': 'high',
  'date': now(),
  'files_affected': [isolated_file]
})
```

---

## 🛑 ESCALATION CRITERIA

Escalate to user if:
- ❌ Cannot reproduce issue
- ❌ Root cause confidence < 70%
- ❌ Multiple possible root causes
- ❌ Fix fails validation
- ❌ Fix breaks existing tests
- ❌ Fix introduces new linter issues
- ❌ Confidence score < 80%

---

**Status:** ACTIVE
**Version:** 2.0.0
**Iron Law:** No fixes without root cause (confidence > 70%)
**Policy:** Zero Hallucination, Zero Tolerance
