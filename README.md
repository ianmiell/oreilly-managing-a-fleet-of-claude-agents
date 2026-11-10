# Managing a Fleet of Claude Agents

Course materials for the O'Reilly live training **Managing a Fleet of Claude Agents: Become a
Claude Code Power User on the Terminal**.

Most developers still use coding agents one session at a time, sitting and watching. This course
is about running several at once: isolating their work, moving between them without losing
track, and running them unattended in scripts and CI while keeping control of permissions, cost
and progress. Claude Code is the main tool, but the working methods apply to other terminal
coding agents, including Codex.

## The course

| Segment | Topic                                   | Exercise                                     |
|---------|-----------------------------------------|----------------------------------------------|
| 1       | From one session to many                | Three agents, three worktrees, one merge     |
| 2       | Power use: driving the fleet at speed   | [Clear a board of six agents](exercises/clear-the-board/) |
| 3       | Agents that run without you             |                                              |
| 4       | Watching and coordinating the fleet     |                                              |

## Prerequisites

- [Claude Code](https://code.claude.com/docs), signed in. Tested with Claude Code 2.1.322.
- git, and a local git setup that can create branches and worktrees
- A terminal
- Python 3 and [jq](https://jqlang.org/), for the exercises (nothing to `pip install`)

## What's here

```
exercises/
  clear-the-board/          # segment 2: triage six background agents
    clear-the-board.sh      # builds the demo repo and starts the agents
    demo-project/           # the small Python project the agents work on
```
