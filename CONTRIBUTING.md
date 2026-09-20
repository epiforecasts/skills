# Contributing

## Adding a skill

1. Create `skills/<skill-name>/SKILL.md`. Use kebab-case, and match the folder name to the `name`
   in the frontmatter.

2. Start `SKILL.md` with YAML frontmatter:

   ```yaml
   ---
   name: epinow2
   description: What the skill does, and when an agent should reach for it. This is the only
     part read when deciding whether to load the skill, so name the package, the task and the
     trigger.
   ---
   ```

3. Keep `SKILL.md` to the workflow itself. Anything long or lookup-shaped goes in
   `skills/<skill-name>/references/`; runnable code goes in `skills/<skill-name>/scripts/`.
   Reference them by relative path so the agent loads them only when needed.

4. Add the skill path to the `skills` array in `.claude-plugin/marketplace.json`, and a row to the
   table in `README.md`.

5. Open a pull request.

## Conventions

- Say what is out of scope, not just what is in scope. A skill that declines the wrong task is
  more useful than one that attempts it.
- Make modelling choices explicit and put them to the user rather than defaulting silently.
- Code follows the conventions of the package the skill wraps.
