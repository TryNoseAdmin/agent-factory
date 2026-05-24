# Rule: Prefer Automation Over Manual Exploration

**Established:** Universal
**Severity:** MEDIUM

**Use MCP tools, hooks, scripts, and shell commands before reaching for Grep/Glob/Read.** If a tool exists for it, use it. Don't overcomplicate workflows when a better option is already wired up.

## Examples
- Query `code-review-graph` before grep-tracing imports
- Run `graphify --update` instead of manually auditing architecture drift
- Use shell one-liners over multi-step file reads when possible

Manual exploration is the fallback, not the default.
