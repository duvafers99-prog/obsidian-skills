# CLAUDE.md

Guidance for AI assistants (Claude Code, Codex, OpenCode, and other skills-compatible agents) working in this repository.

## What this repository is

`obsidian-skills` is a **content repository**, not an application. It packages a set of [Agent Skills](https://agentskills.io/specification) that teach an agent how to create and edit Obsidian vault file formats. There is **no source code to compile, no test suite, no build step, and no dependencies to install**. Each skill is plain Markdown plus a small amount of JSON manifest metadata.

The skills are also distributed as a Claude Code plugin (`obsidian`) through a marketplace defined in `.claude-plugin/`.

## Repository structure

```
.
├── README.md                  # User-facing install instructions + skill index
├── LICENSE                    # MIT
├── .claude-plugin/
│   ├── marketplace.json       # Marketplace entry (plugin list, owner)
│   └── plugin.json            # Plugin manifest (name, version, description, keywords)
└── skills/
    ├── obsidian-markdown/
    │   ├── SKILL.md
    │   └── references/        # CALLOUTS.md, EMBEDS.md, PROPERTIES.md
    ├── obsidian-bases/
    │   ├── SKILL.md
    │   └── references/        # FUNCTIONS_REFERENCE.md
    ├── json-canvas/
    │   ├── SKILL.md
    │   └── references/        # EXAMPLES.md
    ├── obsidian-cli/
    │   └── SKILL.md
    └── defuddle/
        └── SKILL.md
```

### The five skills

| Skill | File extension(s) | Purpose |
|-------|-------------------|---------|
| `obsidian-markdown` | `.md` | Obsidian Flavored Markdown: wikilinks, embeds, callouts, properties (frontmatter), tags, comments, math, Mermaid, footnotes |
| `obsidian-bases` | `.base` | Database-like YAML views of notes: filters, formulas, summaries, table/cards/list/map views |
| `json-canvas` | `.canvas` | [JSON Canvas 1.0](https://jsoncanvas.org/) files: nodes, edges, groups, connections |
| `obsidian-cli` | — | Driving a running Obsidian instance via the `obsidian` CLI; plugin/theme dev loop |
| `defuddle` | — | Extracting clean Markdown from web pages with the Defuddle CLI (token-saving alternative to WebFetch) |

## Anatomy of a skill

Every skill lives in `skills/<skill-name>/` and follows the Agent Skills specification:

- **`SKILL.md`** — required. Starts with YAML frontmatter, then the skill body.
- **`references/`** — optional. Long-form supporting docs the `SKILL.md` links to and defers detail into, so the main file stays scannable.

### SKILL.md frontmatter

```yaml
---
name: skill-name              # must match the directory name; lowercase-hyphenated
description: One or two sentences describing what the skill does AND when to use it.
---
```

The `description` is the single most important field — it is what an agent matches against to decide whether to load the skill. Write it to cover both **what** the skill does and **when** to invoke it (file extensions, user phrasings, trigger keywords). See any existing `SKILL.md` for the established voice, e.g. `defuddle` explicitly states a negative trigger ("Do NOT use for URLs ending in .md").

### SKILL.md body conventions

These patterns are consistent across the existing skills — match them when adding or editing content:

- Lead with a short **Workflow** section: a numbered, imperative checklist (Create → Configure → **Validate** → Test). Validation/verification is always an explicit step.
- Use compact **reference tables** for enumerable things (operators, attributes, color presets, function signatures).
- Use fenced code blocks with the right language tag (`yaml`, `json`, `markdown`, `bash`) for every example.
- Show **WRONG vs CORRECT** pairs for common mistakes, with brief inline comments explaining why.
- Keep the main `SKILL.md` scannable; push exhaustive detail (full function lists, long examples) into `references/`.
- End with a **References** section linking to official Obsidian/spec docs and to the local `references/` files.
- Prefer `--` style em-dashes and concise prose; avoid filler.

## How to make changes

### Adding a new skill

1. Create `skills/<skill-name>/SKILL.md` with valid frontmatter (`name` matching the directory).
2. Add `references/` files only if the main file would otherwise get too long.
3. Add a row to the **Skills** table in `README.md`.
4. If the skill should ship with the plugin, update the `description` in `.claude-plugin/plugin.json` (and bump `version` if releasing — see below).

### Editing an existing skill

- Keep edits faithful to the format conventions above.
- When you change behavior described in a `SKILL.md`, check whether its `references/` files and the `README.md` skill table need matching updates.
- The content documents real Obsidian/spec behavior. Do not invent syntax — cross-check against the linked official docs (`help.obsidian.md`, `jsoncanvas.org`, `agentskills.io`). When unsure, say so rather than guessing.

### Versioning

`.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json` both carry a `version` (currently `1.0.1`) and must stay in sync. Bump it for releases that change the published plugin.

## Validation

There is no automated CI or linter in this repo. Before committing, validate by hand:

- **Frontmatter**: every `SKILL.md` has valid YAML frontmatter with `name` (matching the directory) and `description`.
- **JSON manifests**: `.claude-plugin/*.json` parse as valid JSON; `version` matches across both files.
- **Internal links**: relative links from a `SKILL.md` into its `references/` resolve to real files.
- **Code examples**: any `yaml`/`json` example you add or edit is itself valid and parses. The skills themselves teach the validation rules (e.g. Bases YAML quoting, Canvas ID uniqueness and edge-reference integrity) — apply those same rules to examples in the docs.

## Git workflow

- Active development branch for this work: `claude/claude-md-docs-991r5k`. Develop, commit, and push there; do not push to `main` without explicit permission.
- Use `git push -u origin <branch-name>`.
- Do not open a pull request unless explicitly asked.
- History shows changes land on `main` via reviewed PRs (see `git log`). Keep commit messages clear and descriptive.

## Conventions summary

- This is documentation/content — clarity, accuracy, and consistency with the existing skill voice matter more than anything.
- Match the formatting patterns of neighboring files rather than introducing new structure.
- Keep `README.md`, the plugin manifests, and the skills mutually consistent when any one of them changes.
