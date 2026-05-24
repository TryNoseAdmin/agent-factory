# Agent-Factory State Schema & Management

**Location:** `<project>/.project-state.json`
**Updated:** On every skill completion
**Persistence:** Committed to git after major phases
**Scope:** Shared across ALL skills in a session

---

## State Object Structure

```json
{
  "session_id": "uuid-unique-per-session",
  "feature_name": "kebab-case-feature-name",
  "feature_branch": "feature/kebab-case-feature-name",
  "current_phase": "plan",
  "status": "in_progress",
  "started_at": "2026-03-26T10:30:00Z",

  "timestamps": {
    "session_start": "2026-03-26T10:30:00Z",
    "phase_started": "2026-03-26T10:30:00Z",
    "last_updated": "2026-03-26T10:35:00Z",
    "phase_estimates": {
      "plan": "30m",
      "build": "2h",
      "review": "20m",
      "qa": "30m",
      "ship": "10m"
    }
  },

  "planning": {
    "plan_doc": "docs/plans/TASK-XXX-plan.md",
    "approach": "selected approach from brainstorm",
    "estimated_effort": "medium",
    "success_criteria": []
  },

  "tickets": [
    {
      "id": "TASK-001",
      "title": "Implement search filter",
      "status": "in_progress",
      "acceptance_criteria": [
        "[ ] Filter works with 5+ categories",
        "[ ] Performance < 2s",
        "[ ] Mobile responsive"
      ]
    }
  ],

  "current_ticket": {
    "id": "TASK-001",
    "title": "Implement search filter",
    "description": "Add ability to filter items by category...",
    "acceptance_criteria": [
      "[ ] Filter works with 5+ categories",
      "[ ] Performance < 2s",
      "[ ] Mobile responsive"
    ],
    "status": "in_progress",
    "branch": "feature/task-001-search-filter"
  },

  "codebase_context": {
    "branch": "feature/task-001-search-filter",
    "git_hash": "abc123def456",
    "files_modified": [
      "src/components/FilterChips.tsx",
      "src/lib/search.ts"
    ],
    "files_added": [],
    "files_deleted": [],
    "lines_added": 245,
    "lines_deleted": 12
  },

  "tasks": [
    {
      "id": "1",
      "description": "Add FilterChips component",
      "status": "completed",
      "subtasks": [
        { "desc": "Create component structure", "status": "completed" },
        { "desc": "Add styling with CSS tokens", "status": "completed" },
        { "desc": "Implement click handlers", "status": "completed" }
      ],
      "effort_estimate": "45m",
      "time_spent": "52m"
    },
    {
      "id": "2",
      "description": "Add filter logic to search API",
      "status": "in_progress",
      "subtasks": [
        { "desc": "Update search endpoint", "status": "in_progress" },
        { "desc": "Add database query optimization", "status": "pending" },
        { "desc": "Add caching", "status": "pending" }
      ],
      "effort_estimate": "1h",
      "time_spent": "25m"
    },
    {
      "id": "3",
      "description": "Write E2E tests",
      "status": "pending",
      "subtasks": [],
      "effort_estimate": "45m",
      "time_spent": "0m"
    }
  ],

  "progress": {
    "plan_completion_pct": 100,
    "build_completion_pct": 65,
    "tests_passed": 18,
    "tests_total": 32,
    "tests_passing_pct": 56,
    "qa_issues_found": 3,
    "qa_issues_fixed": 1,
    "qa_issues_pending": 2
  },

  "review_feedback": [
    {
      "id": "RF-001",
      "reviewer": "orchestrate-review",
      "severity": "high",
      "category": "performance",
      "issue": "Search query not memoized, causing unnecessary re-renders",
      "file": "src/hooks/useSearch.ts",
      "line": 42,
      "suggestion": "Wrap query in useMemo hook",
      "status": "unfixed",
      "suggested_fix": "const memoQuery = useMemo(() => query, [query]);",
      "can_auto_fix": true
    },
    {
      "id": "RF-002",
      "reviewer": "orchestrate-design",
      "severity": "medium",
      "category": "design",
      "issue": "Filter pill colors don't match design system",
      "suggestion": "Use var(--color-primary) instead of hardcoded hex",
      "status": "unfixed",
      "can_auto_fix": true
    },
    {
      "id": "RF-003",
      "reviewer": "orchestrate-review",
      "severity": "low",
      "category": "testing",
      "issue": "Missing edge case test for empty results",
      "suggestion": "Add test: expect(results).toBe([]); when no filters match",
      "status": "unfixed",
      "can_auto_fix": false
    }
  ],

  "qa_results": {
    "qa_score": 72,
    "status": "needs_fixes",
    "total_failures": 5,
    "failures_by_category": {
      "functional": [
        {
          "test": "filter_by_category",
          "status": "failed",
          "error": "Expected 12 results, got 10",
          "severity": "high"
        },
        {
          "test": "filter_with_multiple_categories",
          "status": "failed",
          "error": "TypeError: cannot read property 'length' of undefined",
          "severity": "critical"
        }
      ],
      "performance": [
        {
          "metric": "filter_response_time",
          "target": "< 2s",
          "actual": "3.2s",
          "severity": "medium"
        }
      ],
      "accessibility": [],
      "visual": [
        {
          "issue": "Filter pill text not visible on mobile",
          "severity": "medium"
        }
      ]
    },
    "recommendation": "fix_blocker_issues",
    "next_action": "Run orchestrate-debug on TypeError, then orchestrate-build to fix"
  },

  "design_validation": {
    "score": 68,
    "status": "needs_iteration",
    "issues": [
      {
        "issue": "Color tokens not used",
        "severity": "medium",
        "files_affected": ["src/components/FilterChips.tsx"]
      }
    ],
    "brand_compliance": false,
    "accessibility_compliant": true,
    "feedback": "Use CSS custom properties from design system for all colors"
  },

  "blockers": [
    {
      "id": "BLK-001",
      "description": "TypeError in filter logic - undefined property access",
      "severity": "critical",
      "status": "active",
      "reported_by": "orchestrate-qa",
      "created_at": "2026-03-26T10:55:00Z",
      "details": "Line 42 in src/hooks/useSearch.ts - result can be undefined",
      "action_required": "orchestrate-debug must investigate and fix"
    },
    {
      "id": "BLK-002",
      "description": "Performance regression - filter response > 2s",
      "severity": "high",
      "status": "active",
      "reported_by": "orchestrate-qa",
      "created_at": "2026-03-26T10:55:00Z",
      "details": "Optimize database query or add caching",
      "action_required": "orchestrate-build to optimize"
    }
  ],

  "debug_info": {
    "last_error": "TypeError: Cannot read property 'length' of undefined",
    "last_error_trace": "at Object.<anonymous> (src/hooks/useSearch.ts:42:15)",
    "reproduction_steps": [
      "1. Click filter by 'category A'",
      "2. System returns results",
      "3. Click filter by 'category B'",
      "4. Error thrown"
    ],
    "root_cause": "result variable not validated before accessing .length",
    "fix_attempted": false,
    "fix_code_suggested": null,
    "confidence_score": null,
    "investigation_complete": false
  },

  "memory": {
    "past_bugs": [
      {
        "pattern": "undefined property access",
        "fix": "Always validate object before accessing properties",
        "effectiveness": "high",
        "occurrences": 3,
        "last_seen": "2026-03-20"
      }
    ],
    "past_fixes": [
      {
        "issue_type": "query_performance",
        "solution": "Add pagination and caching",
        "effectiveness": "high",
        "applied_count": 5
      }
    ],
    "review_patterns": [
      {
        "pattern": "Hardcoded colors instead of CSS tokens",
        "occurrences": 8,
        "confidence": "high"
      }
    ],
    "qa_failure_patterns": [
      {
        "pattern": "Timeout errors on complex filters",
        "root_cause": "Missing database index",
        "solution": "Add index on filtered column",
        "confidence": "medium"
      }
    ]
  },

  "history": [
    {
      "timestamp": "2026-03-26T10:30:00Z",
      "phase": "plan",
      "action": "orchestrate-plan generated TASK-XXX-plan.md",
      "result": "success",
      "details": "Feature planning complete, 3 acceptance criteria defined"
    },
    {
      "timestamp": "2026-03-26T10:35:00Z",
      "phase": "build",
      "action": "orchestrate-build started implementation",
      "result": "in_progress",
      "details": "Task 1 completed (FilterChips component), Task 2 in progress"
    },
    {
      "timestamp": "2026-03-26T10:50:00Z",
      "phase": "qa",
      "action": "orchestrate-qa ran tests",
      "result": "failure",
      "details": "5 failures found: 2 critical functional, 1 performance, 1 design, 1 visual"
    },
    {
      "timestamp": "2026-03-26T10:55:00Z",
      "phase": "debug",
      "action": "Blocker created - TypeError in filter logic",
      "result": "escalated",
      "details": "Awaiting orchestrate-debug investigation"
    }
  ],

  "metadata": {
    "version": "1.0",
    "created_by": "orchestrate-plan",
    "last_updated_by": "orchestrate-qa",
    "skill_versions": {
      "orchestrate-plan": "1.0.0",
      "orchestrate-build": "1.0.0",
      "orchestrate-review": "1.0.0",
      "orchestrate-qa": "1.0.0",
      "orchestrate-debug": "1.0.0"
    }
  }
}
```

---

## State Initialization

**When starting new feature:**

```json
{
  "session_id": "generate-uuid",
  "feature_name": "from-user-request",
  "feature_branch": "feature/{feature_name}",
  "current_phase": "plan",
  "status": "not_started",
  "started_at": "now",
  "timestamps": {"session_start": "now", "last_updated": "now"},
  "tickets": [],
  "tasks": [],
  "progress": {"plan_completion_pct": 0},
  "review_feedback": [],
  "qa_results": {"qa_score": 0},
  "blockers": [],
  "debug_info": {},
  "memory": {"past_bugs": [], "past_fixes": [], "review_patterns": [], "qa_failure_patterns": []},
  "history": [{"timestamp": "now", "phase": "init", "action": "session_started", "result": "success"}]
}
```

---

## State Update Rules

**RULE 1: Read-then-modify pattern**
```
const state = readState()
state.progress.build_completion_pct = 65
state.last_updated = now()
state.history.push({timestamp: now(), action: "...", result: "success"})
saveState(state)
```

**RULE 2: Immutable history**
- History is append-only
- Never modify past entries
- Every action recorded

**RULE 3: Atomic operations**
- Read entire state
- Modify relevant fields
- Save entire state
- Never partial updates

**RULE 4: Timestamps on every change**
- `last_updated` must be updated
- History entry must be added
- No silent changes

---

## Reading State in Skills

**Every skill starts with:**

```python
state = read_state_file('<project>/.project-state.json')

# Check prerequisites
if not state.get('plan_doc'):
    raise StateError("Plan not generated yet. Run orchestrate-plan first.")

if state['current_phase'] != 'build':
    raise StateError(f"Expected phase 'build', found '{state['current_phase']}'")

# Now proceed with skill logic
```

---

## Updating State in Skills

**Every skill ends with:**

```python
# Update state
state['current_phase'] = 'review'
state['status'] = 'completed'
state['progress']['build_completion_pct'] = 100
state['last_updated'] = now()

# Add history
state['history'].append({
    'timestamp': now(),
    'phase': 'build',
    'action': 'Feature implementation completed',
    'result': 'success',
    'details': 'All tasks done, 32/32 tests passing'
})

# Persist
save_state_file(state, '<project>/.project-state.json')

# Commit
os.system('git add <project>/.project-state.json')
os.system('git commit -m "chore: update state after build phase"')
```

---

## State Validation

**On every read:**
1. Check file exists
2. Validate JSON structure
3. Check required fields
4. Verify phase consistency
5. Check for orphaned blockers

**On every write:**
1. Validate no fields deleted
2. Verify history is append-only
3. Ensure timestamps are ISO8601
4. Check phase is valid
5. Save atomically

---

## Debugging State

**View current state:**
```bash
cat <project>/.project-state.json | jq .
```

**View history:**
```bash
cat <project>/.project-state.json | jq '.history | reverse | .[0:10]'
```

**View blockers:**
```bash
cat <project>/.project-state.json | jq '.blockers[] | select(.status == "active")'
```

**Reset to clean state:**
```bash
git checkout <project>/.project-state.json  # restore from last commit
```

---

**Last Updated:** 2026-05-24
**Enforcement Level:** MANDATORY (Zero Tolerance)
