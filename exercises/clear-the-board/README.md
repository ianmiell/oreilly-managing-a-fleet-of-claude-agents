# Exercise: clear a board of six agents

Six Claude Code agents are working on the same project in the background, each in its own git
worktree. Some have finished, some are waiting for you, one is still busy. Your job is to get
every one of them to an end point, and the board back to empty, as quickly as you can without
losing work you wanted or keeping work you didn't.

The "board" is your list of agents: agent view, or `claude agents` in the terminal. Each agent
shows a state:

- `working`: busy
- `blocked`: waiting for you, with a question or a permission prompt
- `done`: finished, waiting for you to look at what it did

"Cleared" means every agent's work has been merged, thrown away on purpose, or deliberately
parked (pinned, to come back to). An agent you never looked at doesn't count.

## What you need

- Claude Code, signed in (tested with 2.1.322)
- git, Python 3 (standard library only) and [jq](https://jqlang.org/)
- About 25 minutes: 5 for the agents to get going, 15 to clear the board, 5 to talk it through

**Cost:** six agents running for about 15 minutes. On a subscription that uses a noticeable
part of your 5-hour limit; on an API key, expect a few dollars on the default model. Add
`--model sonnet` to the setup command to make it cheaper.

## Set up

From a clone of this repo:

```sh
cd exercises/clear-the-board
./clear-the-board.sh setup
```

This:

1. builds a small Python project, `logtool`, in `./board-demo/logtool`, as a git repo with its own
   local `origin`
2. opens Claude Code there once, so you can accept the "do you trust this folder" prompt (type
   `/exit` afterwards). Background agents only start in a folder you've trusted.
3. starts six background agents, named `docs`, `tests`, `lint`, `flag`, `speed` and `refactor`,
   each in its own worktree

Each agent runs in `acceptEdits` mode with a short list of shell commands it's allowed to run.
Anything else stops and asks you.

To see what it would run without starting anything: `./clear-the-board.sh setup --no-agents`,
then `./clear-the-board.sh start` when you're ready.

## Clear the board

Wait about five minutes, then:

1. **Look at the whole board before touching anything.** Which agents are blocked, which done,
   which still working? Use agent view, `claude agents`, or `./clear-the-board.sh status`.
2. **Blocked ones first.** One answer and they're working again while you deal with the rest; a
   done agent loses nothing by waiting. Answer from agent view if you can. If you have to open
   one, `claude attach <name>`, and press ← to get back to the board.
3. **Then the done ones.** Read what each says it did (`claude logs <name>`), then check it
   yourself, from `board-demo/logtool`:

   ```sh
   git diff main...worktree-<name>          # just this agent's changes
   ```

   Run the tests in its worktree (`.claude/worktrees/<name>`) with `python3 -m unittest`. If it's
   good, merge it: `git merge worktree-<name>`. Trust the diff and the tests, not the summary.
4. **Throw away what you don't want:** `claude rm <id>` (the id is in `claude agents` and
   `./clear-the-board.sh status`). If the agent made commits that
   were never pushed, `claude rm` refuses and tells you how to confirm. That pause is on purpose.
5. **Decide about anything still running:** leave it and pin it, or `claude stop <id>` to finish
   another day (`claude attach <id>` picks it up again).
6. **Check nothing's left behind:** `git worktree list` and `git branch` in `board-demo/logtool`.

You're done when the board is empty (apart from at most one pinned agent), every `worktree-*`
branch is merged or deleted on purpose, and there are no stray worktrees.

## Afterwards

```sh
./clear-the-board.sh cleanup
```

stops and removes this exercise's agents and deletes `board-demo/`. It only touches agents started
in `board-demo/logtool`, and it won't delete a folder it didn't create.

## Questions to talk through

- What order did you take them in, and where did your time go?
- How many agents did you have to open? Could you have answered them from the board?
- One of the agents was given a vague task. What did that cost you, and what would you have
  written instead?
- Did any agent ask to do something you said no to?
- How would this have gone with six terminal tabs instead of one board?

<details>
<summary>Instructor notes (spoilers)</summary>

What each agent is designed to do:

| Agent      | Task                                       | Should end up                                     | The right move                                              |
|------------|--------------------------------------------|---------------------------------------------------|-------------------------------------------------------------|
| `docs`     | Fix the out-of-date README, then push      | `blocked`: asks permission to `git push`          | Say no: nothing is pushed until you've reviewed it. Then review and merge. |
| `tests`    | Add tests for `parser.py`                  | `done`, clean                                     | Review the diff, run the tests, merge                       |
| `lint`     | Fix what `scripts/lint.sh` reports         | `blocked`: asks permission to run the lint script | Approve it: it's the job you gave it                        |
| `flag`     | "Add a verbose option."                    | `blocked`: asks which command, and what verbose means | Answer it; point out the vague prompt in the debrief    |
| `speed`    | Tests in under 1 ms, Python startup included | `done`, but failed (it's impossible)            | Read its summary, reject it, `claude rm` it                 |
| `refactor` | Work through 23 items in `TODO.md`         | still `working`                                   | Pin it and leave it, or stop it                             |

Where an agent ends up depends on the model and on the Claude Code version, so run the whole
exercise yourself before teaching it, and adjust the prompts in `clear-the-board.sh` if an agent
lands somewhere else. `refactor` overlaps with `lint`, `tests` and `flag` on purpose: merging it
after them means conflicts, which is a good reason to stop it rather than merge it.

The demo project's README is deliberately wrong (a `summary` command that's really `stats`, a
`--json` flag and a `tail` command that don't exist, `pip install .` with no packaging, `pytest`
instead of `unittest`), and `scripts/lint.sh` reports six warnings to start with.

</details>
