#!/usr/bin/env python3
"""
validate_plugins.py - Read-only quality gate for Claude Code marketplace plugins.

Usage:
  python scripts/validate_plugins.py                # Validate all plugins
  python scripts/validate_plugins.py --json         # JSON output
  python scripts/validate_plugins.py --strict       # Warnings also fail
  python scripts/validate_plugins.py --plugin NAME  # Validate one plugin
"""

import argparse
import json
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).parent
REPO_ROOT = SCRIPT_DIR.parent
MARKETPLACE_JSON = REPO_ROOT / ".claude-plugin" / "marketplace.json"
PLUGINS_DIR = REPO_ROOT / "plugins"
REQUIRED_PLUGIN_FIELDS = ("name", "version", "description", "author")
SMART_PUNCTUATION = "“”‘’—"


class Finding:
    def __init__(self, severity, check, path, message, plugin=None, line=None):
        self.severity = severity
        self.check = check
        self.path = path
        self.message = message
        self.plugin = plugin
        self.line = line

    def to_dict(self):
        data = {
            "severity": self.severity,
            "check": self.check,
            "path": self.path,
            "message": self.message,
        }
        if self.plugin:
            data["plugin"] = self.plugin
        if self.line is not None:
            data["line"] = self.line
        return data


def rel(path):
    try:
        return path.relative_to(REPO_ROOT).as_posix()
    except ValueError:
        return path.as_posix()


def add(findings, severity, check, path, message, plugin=None, line=None):
    findings.append(Finding(severity, check, rel(path), message, plugin, line))


def load_json(path, findings, check="Invalid JSON"):
    try:
        with path.open("r", encoding="utf-8") as f:
            return json.load(f)
    except json.JSONDecodeError as exc:
        add(findings, "error", check, path, f"Invalid JSON: {exc}")
    except OSError as exc:
        add(findings, "error", check, path, f"Cannot read JSON: {exc}")
    return None


def read_text(path):
    try:
        return path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        return path.read_text(encoding="utf-8", errors="replace")


def frontmatter(text):
    if not text.startswith("---"):
        return None
    lines = text.splitlines()
    if not lines or lines[0].strip() != "---":
        return None
    for i in range(1, len(lines)):
        if lines[i].strip() == "---":
            return "\n".join(lines[1:i])
    return None


def parse_frontmatter(text):
    fm = frontmatter(text)
    if fm is None:
        return None
    result = {}
    lines = fm.splitlines()
    i = 0
    while i < len(lines):
        line = lines[i]
        if not line.strip() or line.lstrip().startswith("#") or line.startswith((" ", "\t", "-")):
            i += 1
            continue
        if ":" not in line:
            i += 1
            continue
        key, value = line.split(":", 1)
        key = key.strip()
        value = value.strip()
        if value in ("|", ">", "|-", ">-", "|+", ">+"):
            block = []
            i += 1
            while i < len(lines) and (lines[i].startswith((" ", "\t")) or not lines[i].strip()):
                block.append(lines[i].strip())
                i += 1
            result[key] = "\n".join(block).strip()
            continue
        result[key] = value.strip('"\'')
        i += 1
    return result


def validate_frontmatter(path, text, plugin, findings):
    fm_text = frontmatter(text)
    if fm_text is not None:
        try:
            import yaml
            yaml.safe_load(fm_text)
        except Exception as exc:
            add(findings, "error", "Invalid YAML frontmatter", path,
                f"YAML parsing failed: {exc}", plugin)



SUPPRESS_SMART_MARKER = "<!-- validator:allow-smart-punct -->"
SUPPRESS_BARE_FENCE_MARKER = "<!-- validator:allow-bare-fence -->"
# Pandoc-style fenced div opener (e.g. ::: {.callout-note}). Treat everything between
# matching ::: lines as a non-code container so the fence state machine ignores
# any ``` lines that the divs wrap.
import re as _re_validator

_HEREDOC_RE = _re_validator.compile(r"<<-?\s*['\"]?([A-Za-z_][A-Za-z0-9_]*)['\"]?")
_PANDOC_DIV_OPEN_RE = _re_validator.compile(r"^:{3,}\s*\S")
_PANDOC_DIV_CLOSE_RE = _re_validator.compile(r"^:{3,}\s*$")


def validate_code_fences(path, text, plugin, findings):
    # File-level suppression markers. They must appear anywhere in the file's text;
    # use these for legitimate documentation of forbidden characters (e.g. a smart-punct
    # codepoint catalog) or for third-party content (e.g. Pandoc-formatted markdown).
    suppress_smart = SUPPRESS_SMART_MARKER in text
    suppress_bare_fence = SUPPRESS_BARE_FENCE_MARKER in text

    inside = False
    opening_count = 0
    in_heredoc = False
    heredoc_terminator = ""
    pandoc_div_depth = 0

    for line_no, line in enumerate(text.splitlines(), 1):
        # Pandoc fenced divs (only meaningful outside a code fence).
        if not inside:
            if _PANDOC_DIV_CLOSE_RE.match(line.rstrip()) and pandoc_div_depth > 0:
                pandoc_div_depth -= 1
                continue
            if _PANDOC_DIV_OPEN_RE.match(line.rstrip()):
                pandoc_div_depth += 1
                continue
            if pandoc_div_depth > 0:
                # Inside a Pandoc div container at the prose level. Ignore fences entirely;
                # third-party content inside divs is not subject to our fence-language rule.
                continue

        # Heredoc handling (only meaningful inside a fenced code block).
        if in_heredoc:
            if line.strip() == heredoc_terminator:
                in_heredoc = False
                heredoc_terminator = ""
            continue

        stripped = line.lstrip()
        if not stripped.startswith("```"):
            # Detect heredoc OPEN inside a fenced code block so subsequent inner
            # fences (commonly inside `cat <<'EOF' ... EOF` markdown payloads) are ignored.
            if inside:
                m = _HEREDOC_RE.search(line)
                if m:
                    in_heredoc = True
                    heredoc_terminator = m.group(1)
                    continue
            if inside and (not suppress_smart) and any(ch in line for ch in SMART_PUNCTUATION):
                chars = "".join(ch for ch in SMART_PUNCTUATION if ch in line)
                add(findings, "warning", "Smart punctuation in code", path,
                    f"Smart punctuation inside fenced code block: {chars}", plugin, line_no)
            continue

        count = 0
        for ch in stripped:
            if ch == "`":
                count += 1
            else:
                break
        if count < 3:
            continue

        rest = stripped[count:].strip()
        if not inside:
            if rest == "" and not suppress_bare_fence:
                add(findings, "warning", "Bare opening fence", path,
                    "Outermost code fence has no language tag", plugin, line_no)
            inside = True
            opening_count = count
        elif count >= opening_count:
            inside = False
            opening_count = 0
        elif (not suppress_smart) and any(ch in line for ch in SMART_PUNCTUATION):
            chars = "".join(ch for ch in SMART_PUNCTUATION if ch in line)
            add(findings, "warning", "Smart punctuation in code", path,
                f"Smart punctuation inside fenced code block: {chars}", plugin, line_no)


def iter_files(root):
    if not root.exists():
        return []
    return [p for p in root.rglob("*") if p.is_file()]


#
# Agent body word-count thresholds. These match the size table in the
# plugin-master system prompt: target band 1,500-2,500 words, hard ceiling
# 3,000. The example-block check fires only above the target band, because
# lean-orchestrator agents (under the upper target) deliberately omit
# <example> blocks and delegate trigger detail to skills. Fat agents above
# the target band benefit from <example> blocks for routing clarity.
#
AGENT_EXAMPLES_THRESHOLD_WORDS = 2500
AGENT_OVER_TARGET_WORDS = 2500
AGENT_OVERSIZED_WORDS = 3000


def validate_agent(path, plugin, findings):
    text = read_text(path)
    validate_frontmatter(path, text, plugin, findings)
    fm_text = frontmatter(text)
    fm = parse_frontmatter(text) or {}
    if fm_text is None or "model: inherit" not in fm_text:
        add(findings, "error", "Agent missing model: inherit", path,
            "Agent frontmatter must contain model: inherit", plugin)
    if fm_text and any(line.strip() == "agent: true" for line in fm_text.splitlines()):
        add(findings, "error", "Deprecated agent: true", path,
            "Agent frontmatter contains legacy agent: true", plugin)
    description = fm.get("description", "")
    if len(description) > 1024:
        add(findings, "error", "Agent description too long", path,
            f"Agent description is {len(description)} characters; limit is 1024", plugin)
    if description and "PROACTIVELY" not in description:
        add(findings, "warning", "Agent missing PROACTIVELY", path,
            "Agent frontmatter description should contain PROACTIVELY", plugin)
    if description and "Provides" not in description:
        add(findings, "warning", "Agent missing Provides", path,
            "Agent frontmatter description should contain Provides", plugin)

    # Word count gates: lean orchestrators are exempt from the examples check
    # by design. Examples are expected only on fat agents above the target band.
    words = len(text.split())
    if words > AGENT_OVERSIZED_WORDS:
        add(findings, "warning", "Agent oversized", path,
            f"Agent has {words} words; ceiling is {AGENT_OVERSIZED_WORDS}", plugin)
    if words > AGENT_EXAMPLES_THRESHOLD_WORDS and "<example>" not in text:
        add(findings, "warning", "Agent missing examples", path,
            f"Agent has {words} words (>{AGENT_EXAMPLES_THRESHOLD_WORDS}); fat agents should contain at least one <example> block. Lean orchestrators under {AGENT_EXAMPLES_THRESHOLD_WORDS} words are exempt.",
            plugin)
    validate_code_fences(path, text, plugin, findings)


def validate_skill(path, plugin, findings):
    text = read_text(path)
    validate_frontmatter(path, text, plugin, findings)
    fm = parse_frontmatter(text)
    words = len(text.split())
    if fm is None:
        add(findings, "error", "Skill missing frontmatter", path,
            "SKILL.md must start with YAML frontmatter", plugin)
    else:
        description = fm.get("description", "")
        if len(description) > 1024:
            add(findings, "error", "Skill description too long", path,
                f"Skill description is {len(description)} characters; limit is 1024", plugin)
        if "PROACTIVELY" not in description:
            add(findings, "warning", "Skill missing PROACTIVELY", path,
                "Skill frontmatter description should contain PROACTIVELY", plugin)
        if "Provides" not in description:
            add(findings, "warning", "Skill missing Provides", path,
                "Skill frontmatter description should contain Provides", plugin)
    if words > 3000:
        add(findings, "error", "Skill oversized", path,
            f"SKILL.md has {words} words; limit is 3000", plugin)
    elif words > 2000:
        add(findings, "warning", "Skill over target", path,
            f"SKILL.md has {words} words; target is 2000", plugin)
    validate_code_fences(path, text, plugin, findings)


def validate_markdown_file(path, plugin, findings):
    text = read_text(path)
    validate_frontmatter(path, text, plugin, findings)
    validate_code_fences(path, text, plugin, findings)


def validate_plugin(entry, findings):
    name = entry.get("name", "<missing-name>")
    plugin_dir = PLUGINS_DIR / name
    if not plugin_dir.is_dir():
        add(findings, "error", "Missing plugin directory", plugin_dir,
            f"Registered plugin has no plugins/{name}/ directory", name)
        return

    plugin_json = plugin_dir / ".claude-plugin" / "plugin.json"
    if not plugin_json.exists():
        add(findings, "error", "Missing plugin.json", plugin_json,
            "Plugin is missing .claude-plugin/plugin.json", name)
        return

    data = load_json(plugin_json, findings)
    if not isinstance(data, dict):
        return

    for field in REQUIRED_PLUGIN_FIELDS:
        if field not in data:
            add(findings, "error", "Missing required fields", plugin_json,
                f"plugin.json missing required field: {field}", name)
    if data.get("name") != name:
        add(findings, "error", "Name mismatch", plugin_json,
            f"plugin.json name {data.get('name')!r} != marketplace name {name!r}", name)
    if entry.get("version") != data.get("version"):
        add(findings, "error", "Version mismatch", plugin_json,
            f"marketplace version {entry.get('version')!r} != plugin.json version {data.get('version')!r}", name)
    description = data.get("description", "")
    if isinstance(description, str) and len(description) > 1024:
        add(findings, "error", "Description too long", plugin_json,
            f"plugin.json description is {len(description)} characters; limit is 1024", name)

    for agent in sorted((plugin_dir / "agents").glob("**/*.md")):
        validate_agent(agent, name, findings)
    for skill in sorted((plugin_dir / "skills").glob("**/SKILL.md")):
        validate_skill(skill, name, findings)

    handled = {p.resolve() for p in (plugin_dir / "agents").glob("**/*.md")}
    handled.update(p.resolve() for p in (plugin_dir / "skills").glob("**/SKILL.md"))
    for md in sorted(plugin_dir.glob("**/*.md")):
        if md.resolve() not in handled:
            validate_markdown_file(md, name, findings)


def validate_orphans_and_dirs(registered, findings):
    if PLUGINS_DIR.exists():
        for path in iter_files(PLUGINS_DIR):
            if path.suffix in (".bak", ".tmp", ".draft"):
                add(findings, "error", "Orphan working files", path,
                    "Working file extension found under plugins/")
        for child in sorted(p for p in PLUGINS_DIR.iterdir() if p.is_dir()):
            if child.name.startswith("."):
                continue
            if child.name not in registered:
                add(findings, "warning", "Unregistered plugin directory", child,
                    "Directory under plugins/ is not registered in marketplace.json", child.name)


def run_validation(plugin_name=None):
    findings = []
    marketplace = load_json(MARKETPLACE_JSON, findings)
    if not isinstance(marketplace, dict):
        return findings, []
    plugins = marketplace.get("plugins", [])
    if not isinstance(plugins, list):
        add(findings, "error", "Invalid JSON", MARKETPLACE_JSON,
            "marketplace.json plugins field must be an array")
        return findings, []

    registered = {p.get("name") for p in plugins if isinstance(p, dict) and p.get("name")}
    if plugin_name:
        selected = [p for p in plugins if isinstance(p, dict) and p.get("name") == plugin_name]
        if not selected:
            add(findings, "error", "Missing plugin directory", PLUGINS_DIR / plugin_name,
                f"Plugin {plugin_name!r} is not registered in marketplace.json", plugin_name)
    else:
        selected = [p for p in plugins if isinstance(p, dict)]
        validate_orphans_and_dirs(registered, findings)

    for entry in selected:
        validate_plugin(entry, findings)
    return findings, selected


def print_human(findings, selected, strict):
    errors = [f for f in findings if f.severity == "error"]
    warnings = [f for f in findings if f.severity == "warning"]
    print("=== Plugin Validation ===")
    print(f"Plugins checked: {len(selected)}")
    print(f"Errors:          {len(errors)}")
    print(f"Warnings:        {len(warnings)}")
    print(f"Strict mode:     {'yes' if strict else 'no'}")
    if not findings:
        print("\nAll checks passed.")
        return
    print("\nSEVERITY  CHECK                         PATH                                          MESSAGE")
    print("-" * 120)
    for f in findings:
        line = f":{f.line}" if f.line is not None else ""
        path = (f.path + line)[:44]
        print(f"{f.severity.upper():<9} {f.check[:28]:<29} {path:<45} {f.message}")


def print_json(findings, selected, strict):
    errors = sum(1 for f in findings if f.severity == "error")
    warnings = sum(1 for f in findings if f.severity == "warning")
    print(json.dumps({
        "summary": {
            "plugins_checked": len(selected),
            "errors": errors,
            "warnings": warnings,
            "strict": strict,
            "passed": errors == 0 and (warnings == 0 or not strict),
        },
        "findings": [f.to_dict() for f in findings],
    }, indent=2))


def main():
    parser = argparse.ArgumentParser(description="Validate Claude Code marketplace plugins")
    parser.add_argument("--json", action="store_true", help="Output validation results as JSON")
    parser.add_argument("--strict", action="store_true", help="Treat warnings as failures")
    parser.add_argument("--plugin", help="Validate a single plugin by name")
    args = parser.parse_args()

    findings, selected = run_validation(args.plugin)
    if args.json:
        print_json(findings, selected, args.strict)
    else:
        print_human(findings, selected, args.strict)

    errors = any(f.severity == "error" for f in findings)
    warnings = any(f.severity == "warning" for f in findings)
    sys.exit(1 if errors or (args.strict and warnings) else 0)


if __name__ == "__main__":
    main()
