# epiforecasts skills

Agent skills for working with [epiforecasts](https://github.com/epiforecasts) packages and  analysis workflows.

A skill is a folder of instructions a coding agent loads when a task matches its description.
Each one here lives in `skills/<name>/` with a `SKILL.md` at its root.

## Install

In Claude Code, the repo is a plugin marketplace:

```
/plugin marketplace add epiforecasts/skills
/plugin install epiforecasts
```

Skills then load automatically when a task matches. Otherwise copy the skill folder into
wherever your agent looks for skills — `.claude/skills/` for Claude Code, and the equivalent
for other agents that read the same format.

## Skills

| Skill | Package | What it does |
|---|---|---|
| [`epinow2-routine-nowcast`](skills/epinow2-routine-nowcast) | EpiNow2 | Estimate Rt and nowcast infections from routine surveillance data, making the delay, transmission and truncation choices explicit. |

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## Licence

MIT. See [LICENSE](LICENSE).
