> ⚠️ **DEPRECATED** — This skill has been superseded by the agent-orchestrator architecture.
> Use `/orchestrate-*` skills instead. This file is kept for backward compatibility and will be removed in a future release.
> See `.agents/skills/orchestrate-*/SKILL.md` for the new thin orchestrators and `.agents/agents/agent-*.md` for domain agents.

# NOSE Orchestrator — System Brain (v2)

```yaml
name: nose-orchestrator
version: 2.0.0
type: system
description: >
  Autonomous workflow orchestrator for NOSE development.
  Reads global state, decides next skill, triggers flows automatically,
  handles failures, and manages feedback loops.
enforcement_level: mandatory
policy: "Zero hallucination, Zero tolerance"
```

---

## 📋 PURPOSE

The orchestrator is the **decision engine** that:
- ✅ Reads from global state (`.agents/nose-state.json`)
- ✅ Decides which skill to run next
- ✅ Triggers skills automatically
- ✅ Manages feedback loops (review → fix → review)
- ✅ Handles blockers and failures
- ✅ Escalates unrecoverable issues to user
- ✅ Maintains complete audit trail

**Core principle:** Never run skills blindly. Always check state first.

---

## 🔍 STATE DEPENDENCIES

**Reads from state:**
```
- session_id
- feature_name
- current_phase
- status
- ticket_notion_url
- ticket_notion_page_id
- tickets
- current_ticket
- progress (all metrics)
- review_feedback (severity, count)
- qa_results (qa_score, failures)
- blockers (active list)
- debug_info
- memory (past patterns)
```

**Writes to state:**
```
- current_phase (updated)
- status (updated)
- next_action (new)
- last_updated (timestamp)
- history (append entry)
```

---

## 🚀 EXECUTION FLOW

### INITIALIZATION

```python
def initialize():
  state = read_state('.agents/nose-state.json')

  if not state.get('session_id'):
    create_new_session(feature_name=user_input)
    state['session_id'] = generate_uuid()
    state['current_phase'] = 'plan'
    state['status'] = 'not_started'
    save_state(state)

  return state
```

---

### DECISION LOGIC (CORE FLOW)

```python
def orchestrate():
  state = read_state()

  # === PHASE: PLAN ===
  if state['current_phase'] == 'init':
    return trigger_skill('nose-plan', state)

  # === PHASE: BUILD ===
  elif state['current_phase'] == 'plan' and state['status'] == 'completed':
    state['current_phase'] = 'build'
    state['status'] = 'in_progress'
    save_state(state)
    return trigger_skill('nose-build', state)

  elif state['current_phase'] == 'build':
    # Check if all tasks complete
    if all_tasks_complete(state):
      state['current_phase'] = 'build'
      state['status'] = 'completed'
      save_state(state)
      # Move to review
      return orchestrate()  # Re-run to go to review
    else:
      # Continue building
      pending_tasks = get_pending_tasks(state)
      if pending_tasks:
        return trigger_skill('nose-build', state, mode='continue')

  # === PHASE: REVIEW ===
  elif state['current_phase'] == 'build' and state['status'] == 'completed':
    state['current_phase'] = 'review'
    state['status'] = 'in_progress'
    save_state(state)
    return trigger_skill('nose-review', state)

  elif state['current_phase'] == 'review':
    critical_issues = get_issues_by_severity(state, severity=['critical', 'high'])

    if critical_issues:
      # Create blocker and go back to build
      create_blocker(state, critical_issues)
      state['current_phase'] = 'build'
      state['status'] = 'in_progress'
      save_state(state)
      log_history(state, 'review_failed_critical', 'Going back to build to fix critical issues')
      return trigger_skill('nose-build', state, mode='fix')

    elif not all_issues_resolved(state):
      # Medium/low issues exist but not critical
      return trigger_skill('nose-review', state, mode='check_remaining')

    else:
      # All issues resolved, move to QA
      state['current_phase'] = 'review'
      state['status'] = 'completed'
      save_state(state)
      return orchestrate()  # Re-run to go to QA

  # === PHASE: QA ===
  elif state['current_phase'] == 'review' and state['status'] == 'completed':
    state['current_phase'] = 'qa'
    state['status'] = 'in_progress'
    save_state(state)
    return trigger_skill('nose-qa', state)

  elif state['current_phase'] == 'qa':
    qa_score = state['qa_results']['qa_score']
    critical_failures = state['qa_results']['failures_by_category']['functional']

    if qa_score < 85 or critical_failures:
      # Go to debug
      create_blocker(state, f'QA score {qa_score}/100, need >= 85')
      state['current_phase'] = 'debug'
      state['status'] = 'in_progress'
      save_state(state)
      log_history(state, 'qa_failed', f'QA score {qa_score}, triggering debug')
      return trigger_skill('nose-debug', state, errors=critical_failures)

    elif qa_score >= 85:
      # QA passed, move to ship
      state['current_phase'] = 'qa'
      state['status'] = 'completed'
      save_state(state)
      return orchestrate()  # Re-run to go to ship

  # === PHASE: DEBUG ===
  elif state['current_phase'] == 'debug':
    # nose-debug will provide root_cause and fix
    debug_result = state['debug_info']

    if debug_result.get('fix_attempted') and debug_result.get('confidence_score', 0) > 70:
      # Fix looks good, go back to build to apply it
      state['current_phase'] = 'build'
      state['status'] = 'in_progress'
      save_state(state)
      log_history(state, 'debug_complete_fix_ready', f"Root cause: {debug_result['root_cause']}")
      return trigger_skill('nose-build', state, mode='apply_debug_fix')

    elif debug_result.get('confidence_score', 0) < 70:
      # Not confident, escalate to user
      return escalate_to_user(state, 'Debug confidence < 70, manual review needed')

  # === PHASE: SHIP ===
  elif state['current_phase'] == 'qa' and state['status'] == 'completed':
    state['current_phase'] = 'ship'
    state['status'] = 'in_progress'
    save_state(state)
    return trigger_skill('nose-ship', state)

  elif state['current_phase'] == 'ship':
    if state['status'] == 'completed':
      # PR merged, go to release
      return orchestrate()  # Re-run to go to release

  # === PHASE: RELEASE ===
  elif state['current_phase'] == 'qa' and state['status'] == 'completed':
    state['current_phase'] = 'release'
    state['status'] = 'in_progress'
    save_state(state)
    return trigger_skill('nose-release', state)

  elif state['current_phase'] == 'release':
    if state['status'] == 'completed':
      log_history(state, 'feature_complete', f'Feature {state["feature_name"]} shipped to production')
      return {
        'success': True,
        'feature': state['feature_name'],
        'total_time': calculate_total_time(state),
        'message': f'✅ Feature {state["feature_name"]} complete and released'
      }
```

---

## 🔄 FEEDBACK LOOPS

### Review Feedback Loop

```python
def handle_review_feedback_loop():
  state = read_state()

  critical = filter_by_severity(state['review_feedback'], 'critical')
  high = filter_by_severity(state['review_feedback'], 'high')

  if critical or high:
    # Create blocker for each critical issue
    for issue in critical + high:
      create_blocker(state, {
        'description': issue['issue'],
        'severity': issue['severity'],
        'reported_by': 'nose-review',
        'action_required': 'nose-build must fix'
      })

    # Go back to build
    state['current_phase'] = 'build'
    state['status'] = 'in_progress'
    save_state(state)
    log_history(state, 'review_loop_triggered', f'Found {len(critical)} critical, {len(high)} high severity issues')

    # Trigger build in fix mode
    return trigger_skill('nose-build', state, mode='fix_review_issues')
```

### QA Feedback Loop

```python
def handle_qa_feedback_loop():
  state = read_state()
  qa_score = state['qa_results']['qa_score']

  if qa_score < 85:
    failures = state['qa_results']['failures_by_category']

    # Determine fix approach
    if failures['functional']:
      # Critical - needs debug + fix
      create_blocker(state, f'QA functional test failures: {len(failures["functional"])}')
      state['current_phase'] = 'debug'
      return trigger_skill('nose-debug', state, errors=failures['functional'])

    elif failures['performance']:
      # Performance issue
      create_blocker(state, f'QA performance regression: {failures["performance"]}')
      state['current_phase'] = 'build'
      return trigger_skill('nose-build', state, mode='optimize_performance')

    elif failures['visual']:
      # Visual regression
      create_blocker(state, f'QA visual regression detected')
      state['current_phase'] = 'build'
      return trigger_skill('nose-design', state, mode='fix_visual_issues')

  else:
    # QA passed
    state['qa_results']['status'] = 'passed'
    save_state(state)
    log_history(state, 'qa_passed', f'QA score {qa_score}/100')
```

---

## ⚠️ BLOCKER MANAGEMENT

### Create Blocker

```python
def create_blocker(state, description):
  blocker_id = f"BLK-{len(state['blockers']) + 1:03d}"

  state['blockers'].append({
    'id': blocker_id,
    'description': description,
    'severity': 'high',
    'status': 'active',
    'created_at': now(),
    'reported_by': 'nose-orchestrator',
    'action_required': '(depends on blocker type)'
  })

  save_state(state)
  log_history(state, 'blocker_created', f'{blocker_id}: {description}')
```

### Resolve Blocker

```python
def resolve_blocker(state, blocker_id):
  for blocker in state['blockers']:
    if blocker['id'] == blocker_id:
      blocker['status'] = 'resolved'
      blocker['resolved_at'] = now()
      break

  save_state(state)
  log_history(state, 'blocker_resolved', blocker_id)
```

### Active Blockers

```python
def get_active_blockers(state):
  return [b for b in state['blockers'] if b['status'] == 'active']

# If blockers exist, pause orchestration
def check_blockers():
  state = read_state()
  active = get_active_blockers(state)

  if active:
    critical = [b for b in active if b['severity'] == 'critical']
    if critical:
      return escalate_to_user(state, f'Critical blocker(s): {critical}')

    # Continue but be aware of blockers
    log_and_continue(state, f'Active blockers: {len(active)}')
```

---

## 🛑 FAILURE HANDLING

### Skill Execution Failure

```python
def execute_skill(skill_name, state, **kwargs):
  try:
    result = skill.invoke(skill_name, state, **kwargs)

    if result.get('error'):
      handle_skill_error(state, skill_name, result['error'])

    return result

  except Exception as e:
    handle_skill_exception(state, skill_name, str(e))
```

### Error Recovery

```python
def handle_skill_error(state, skill_name, error):
  # 1. Log error
  log_history(state, 'skill_error', f'{skill_name}: {error}')

  # 2. Create blocker
  create_blocker(state, f'{skill_name} failed: {error}')

  # 3. Attempt retry (max 2)
  retry_count = state.get('error_retry_count', 0)
  if retry_count < 2:
    state['error_retry_count'] = retry_count + 1
    save_state(state)
    log_history(state, 'retrying_skill', f'{skill_name} (attempt {retry_count + 2})')
    # Retry
    return execute_skill(skill_name, state)

  # 4. Escalate to user
  escalate_to_user(state, f'{skill_name} failed after 2 retries: {error}')
```

### Max Retries

```python
if state.get('error_retry_count', 0) >= 2:
  escalate_to_user(state, 'Max retries exceeded, manual intervention required')
```

---

## 📊 METRICS & PROGRESS

### Calculate Progress

```python
def calculate_progress(state):
  progress = {
    'feature': state['feature_name'],
    'current_phase': state['current_phase'],
    'status': state['status'],
    'plan_completion_pct': state['progress']['plan_completion_pct'],
    'build_completion_pct': state['progress']['build_completion_pct'],
    'tests_passing_pct': state['progress']['tests_passing_pct'],
    'qa_score': state['qa_results'].get('qa_score', 0),
    'blockers_active': len(get_active_blockers(state)),
    'time_elapsed': calculate_elapsed(state['started_at']),
    'estimated_time_remaining': estimate_remaining(state)
  }

  return progress
```

### Log Progress

```python
def log_progress():
  state = read_state()
  progress = calculate_progress(state)

  print(f"""
  🚀 NOSE Orchestrator Progress
  ├─ Feature: {progress['feature']}
  ├─ Phase: {progress['current_phase']} ({progress['status']})
  ├─ Build: {progress['build_completion_pct']}%
  ├─ Tests: {progress['tests_passing_pct']}%
  ├─ QA Score: {progress['qa_score']}/100
  ├─ Blockers: {progress['blockers_active']} active
  ├─ Time: {progress['time_elapsed']}
  └─ Est. Remaining: {progress['estimated_time_remaining']}
  """)
```

---

## 🧠 LEARNING & MEMORY

### Remember Past Patterns

```python
def learn_from_iteration(state):
  # When QA fails with similar pattern
  if is_similar_qa_failure(state):
    past_fix = find_similar_past_fix(state)
    if past_fix:
      log_history(state, 'memory_used', f'Applied past fix: {past_fix}')
      return apply_past_fix(state, past_fix)

  # When review finds similar issue
  if is_repeated_review_issue(state):
    log_history(state, 'repeated_pattern_detected', 'This issue has appeared 3+ times')
    escalate_to_user(state, 'Repeated pattern detected, needs design change')
```

---

## 🎯 TRIGGER CRITERIA

### When to trigger each skill

| Trigger | Skill | Condition |
|---------|-------|-----------|
| Session start | nose-plan | phase == 'init' |
| Plan complete | nose-build | phase == 'plan' AND status == 'completed' |
| Build in progress | nose-build (continue) | phase == 'build' AND tasks_incomplete |
| Build complete | nose-review | phase == 'build' AND status == 'completed' |
| Review finds issues | nose-build (fix) | review_feedback with critical/high AND phase == 'review' |
| All issues fixed | nose-qa | phase == 'review' AND status == 'completed' |
| QA fails | nose-debug | qa_score < 85 AND phase == 'qa' |
| Debug succeeds | nose-build (fix) | debug_info.confidence_score > 70 |
| QA passes | nose-ship | qa_score >= 85 AND phase == 'qa' |
| PR merged | nose-release | phase == 'ship' AND pr_merged == true |
| Release complete | feature_complete | phase == 'release' AND status == 'completed' |

---

## 🚫 SAFETY RULES (NON-NEGOTIABLE)

```
1. ALWAYS read state before ANY decision
2. NEVER assume skill success without state validation
3. ALWAYS update state after skill execution
4. NEVER skip blockers - escalate if unresolvable
5. ALWAYS log history - audit trail is mandatory
6. NEVER retry more than 2 times - escalate after
7. ALWAYS validate state integrity on read
8. NEVER modify history - append only
9. ALWAYS confirm user approval before critical actions
10. NEVER run multiple skills in parallel without coordination
```

---

## 📡 USER INTERACTION

### Escalate to User

```python
def escalate_to_user(state, reason):
  log_history(state, 'escalated_to_user', reason)

  print(f"""
  ⚠️  NOSE Orchestrator — USER ACTION REQUIRED
  ════════════════════════════════════════════
  Reason: {reason}
  Current Phase: {state['current_phase']}
  Status: {state['status']}
  Feature: {state['feature_name']}

  Please review state at: .agents/nose-state.json
  Then provide instruction to proceed.
  """)

  # Wait for user
  instruction = input("→ Your instruction: ")

  if 'continue' in instruction.lower():
    return orchestrate()  # Resume
  elif 'fix' in instruction.lower():
    return escalate_fix_instruction(state, instruction)
  else:
    log_history(state, 'user_override', instruction)
```

---

## 🔧 TESTING & VALIDATION

### Test State Integrity

```python
def validate_state(state):
  checks = [
    ('session_id' in state, 'Missing session_id'),
    ('feature_name' in state, 'Missing feature_name'),
    (state['current_phase'] in VALID_PHASES, f'Invalid phase: {state["current_phase"]}'),
    (state['status'] in VALID_STATUSES, f'Invalid status: {state["status"]}'),
    (isinstance(state['history'], list), 'History must be list'),
    (state['history'][-1]['timestamp'], 'Last history missing timestamp'),
  ]

  for check, message in checks:
    if not check:
      raise StateValidationError(message)
```

---

## 📝 OUTPUT EXAMPLE

When orchestrator completes a feature:

```json
{
  "success": true,
  "feature": "search-filter",
  "branch": "feature/search-filter",
  "total_phases": 6,
  "total_time_minutes": 87,
  "final_metrics": {
    "qa_score": 92,
    "test_coverage": 98,
    "review_cycles": 2,
    "qa_iterations": 1,
    "bugs_found_and_fixed": 3
  },
  "timeline": [
    {"phase": "plan", "duration": "15m"},
    {"phase": "build", "duration": "35m"},
    {"phase": "review", "duration": "12m (2 cycles)"},
    {"phase": "qa", "duration": "15m (1 iteration)"},
    {"phase": "ship", "duration": "8m"},
    {"phase": "release", "duration": "2m"}
  ],
  "message": "✅ Feature search-filter complete and released to production"
}
```

---

## 🚀 USAGE

### Run Orchestrator

```bash
# Start feature
/nose-orchestrator --feature "add search filters"

# Orchestrator will:
# 1. Create session + state
# 2. Trigger nose-plan
# 3. When plan done → trigger nose-build
# 4. When build done → trigger nose-review
# 5. When review done → trigger nose-qa
# 6. Manage feedback loops automatically
# 7. Escalate blockers to user
# 8. Complete when feature shipped
```

### Resume Feature

```bash
# If interrupted, orchestrator resumes from state
/nose-orchestrator --feature "search-filter"

# Reads .agents/nose-state.json
# Continues from current_phase
```

---

**Status:** ACTIVE
**Version:** 2.0.0
**Policy:** Zero Hallucination, Zero Tolerance
