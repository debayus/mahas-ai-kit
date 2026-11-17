#!/usr/bin/env python3
"""Builds a setup from the kit templates the way the setup skill would, with stub values.

Usage: build_setup.py <kit root> <destination> [options]
  --tier lite|standard       which core pieces to generate (default standard)
  --options a,b,c            option blocks to keep (branch, pr, direct, read, supabase,
                             firebase, sql, golden, e2e, load, coverage)
  --modules a,b              module templates to add (git-flow, ticket, testing, database)
  --no-format                leave out the format hook (a repo without a formatter)
  --no-pipeline              knowledge layer only: no agents, process skills, commands, workflow

The result is checked by verify.sh in tests/run.sh. It proves that the templates
resolve to a setup that passes, for each combination of choices.
"""
import argparse, json, os, re, stat, sys

VALUES = {
    'PROJECT_NAME': 'Mock',
    'TOPIC': 'testing', 'TOPIC_TITLE': 'Testing', 'DOC': 'testing',
    'KEY_FILE': 'README.md', 'PROOF_FILE': 'README.md',
    'TEST_GUIDE': 'Load the `stack-testing` skill',
    'STACK_SKILLS': 'Load the `stack-testing` skill before touching tests.',
    'DEFAULT_BRANCH': 'main',
    'MODEL_PLANNER': 'fable', 'MODEL_DESIGN': 'opus', 'MODEL_BUILD': 'sonnet', 'MODEL_REVIEW': 'opus',
    'ANALYZE_CMD': 'make analyze', 'FORMAT_CHECK_CMD': 'make format-check',
    'FORMAT_FILE_CMD': 'make format FILE="$f"', 'TEST_CMD': 'make test',
    'DATE': '2026-01-01', 'COMMIT': 'abc1234',
}
LITE = {
    'agents': ['planner', 'reviewer'],
    'skills': ['process-planning', 'process-code-review', 'stack-skill'],
    'commands': ['plan', 'review-changes'],
}


def resolve(text, keep):
    """Keep an option block only if one of its names is in `keep`."""
    out, on = [], True
    for line in text.splitlines(keepends=True):
        m = re.match(r'\s*<!-- option: (.*?) -->', line)
        if m:
            on = bool(set(m.group(1).split()) & keep)
            continue
        if re.match(r'\s*<!-- /option', line):
            on = True
            continue
        if on:
            out.append(line)
    return ''.join(out)


def fill(text):
    return re.sub(r'\{\{([A-Z_]+)\}\}', lambda m: VALUES.get(m.group(1), 'stub value'), text)


def listing(folder):
    """Folder entries without hidden files (macOS writes ._name files on some drives)."""
    return sorted(n for n in os.listdir(folder) if not n.startswith('.'))


def write(path, text, executable=False):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w') as f:
        f.write(text)
    if executable:
        os.chmod(path, os.stat(path).st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)


def main():
    p = argparse.ArgumentParser()
    p.add_argument('kit'); p.add_argument('dest')
    p.add_argument('--tier', default='standard')
    p.add_argument('--options', default='')
    p.add_argument('--modules', default='')
    p.add_argument('--no-format', action='store_true')
    p.add_argument('--no-pipeline', action='store_true')
    a = p.parse_args()
    keep = set(filter(None, a.options.split(',')))
    keep.add(a.tier)  # core templates key some blocks by tier
    modules = set(filter(None, a.modules.split(',')))
    setup = os.path.join(a.kit, 'skills', 'setup')
    lite = a.tier == 'lite'
    files = {}  # destination path (relative) -> text

    def take(root, kind, name):
        text = fill(resolve(open(os.path.join(root, kind, name + '.md')).read(), keep))
        if kind == 'skills':
            name = 'stack-testing' if name == 'stack-skill' else name
            files[f'.claude/skills/{name}/SKILL.md'] = text
        else:
            files[f'.claude/{kind}/{name}.md'] = text

    core = os.path.join(setup, 'templates')
    for kind in ('agents', 'skills', 'commands'):
        for fn in listing(os.path.join(core, kind)):
            name = fn[:-3]
            if lite and name not in LITE[kind]:
                continue
            if a.no_pipeline and name != 'stack-skill':
                continue
            take(core, kind, name)
    for mod in sorted(modules):
        mroot = os.path.join(setup, 'modules', mod, 'templates')
        for kind in listing(mroot):
            for fn in listing(os.path.join(mroot, kind)):
                # The pr command exists only with the pr option.
                if fn == 'pr.md' and 'pr' not in keep:
                    continue
                take(mroot, kind, fn[:-3])

    # A skill that was not generated: delete the lines that refer to it (SKILL.md Step 6).
    have = {p.split('/')[2] for p in files if p.startswith('.claude/skills/')}
    for path, text in files.items():
        kept = []
        for line in text.splitlines(keepends=True):
            named = set(re.findall(r'`((?:stack|process)-[a-z0-9-]+)`', line))
            if named and not named <= have:
                continue
            kept.append(line)
        files[path] = ''.join(kept)

    files['CLAUDE.md'] = fill(open(os.path.join(core, 'docs', 'CLAUDE.md')).read())
    files['.claude/.agent/README.md'] = fill(open(os.path.join(core, 'docs', 'agent-README.md')).read())
    files['.claude/.agent/testing.md'] = '# Testing\n\n## Test levels\n\nstub\n'
    files['.claude/README.md'] = fill(open(os.path.join(core, 'docs', 'claude-README.md')).read())
    files['README.md'] = '# Mock\n'
    if not lite and not a.no_pipeline:
        wf = os.path.join(core, 'workflows', 'engineer-pipeline.js')
        files['.claude/workflows/engineer-pipeline.js'] = fill(open(wf).read())

    hooks = json.load(open(os.path.join(core, 'hooks', 'settings-hooks.json')))
    if a.no_format:
        del hooks['hooks']['PostToolUse']
    files['.claude/settings.json'] = json.dumps(hooks, indent=2) + '\n'
    version = json.load(open(os.path.join(a.kit, '.claude-plugin', 'plugin.json')))['version']
    files['.claude/kit.json'] = json.dumps({'kit': version, 'tier': a.tier, 'modules': {}}, indent=2) + '\n'

    for path, text in files.items():
        write(os.path.join(a.dest, path), text)
    for fn in listing(os.path.join(core, 'hooks')):
        if fn.endswith('.json') or (a.no_format and fn == 'format-on-edit.sh'):
            continue
        text = fill(open(os.path.join(core, 'hooks', fn)).read())
        write(os.path.join(a.dest, '.claude', 'hooks', fn), text, executable=fn.endswith('.sh'))


if __name__ == '__main__':
    sys.exit(main())
