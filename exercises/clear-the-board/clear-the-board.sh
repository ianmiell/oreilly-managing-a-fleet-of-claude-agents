#!/usr/bin/env bash
#
# clear-the-board.sh: set up the "clear a board of six agents" exercise.
#
# Builds a small demo project (logtool) in its own git repo, with a local
# "origin", then starts six background Claude Code agents on it. Each agent
# works in its own worktree, on a task chosen to end in a different state.
#
# Usage:
#   ./clear-the-board.sh setup   [--dir DIR] [--model MODEL] [--no-agents]
#   ./clear-the-board.sh start   [--dir DIR] [--model MODEL]
#   ./clear-the-board.sh status  [--dir DIR]
#   ./clear-the-board.sh cleanup [--dir DIR] [--yes]
#
#   setup     build the demo repo in DIR (default: ./board-demo), then start
#             the six agents. --no-agents stops after building, and prints
#             the claude commands that 'start' would run.
#   start     start the six agents in a demo repo that setup already built
#   status    show this exercise's agents and their states
#   cleanup   stop and remove this exercise's agents, then delete DIR
#
#   --model   the agents' model, e.g. sonnet (cheaper than the default)
#
# Requires: git, python3, jq, and Claude Code (signed in).

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
TEMPLATE="$SCRIPT_DIR/demo-project"
TESTED_VERSION="2.1.322"
MARKER=".clear-the-board"

DIR="board-demo"
MODEL=""
LAUNCH=1
YES=0

die() { echo "error: $*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || die "$1 is not installed (needed for $2)"; }
usage() { sed -n '9,24p' "$0" | sed -E 's/^# ?//'; }

# --- the six agents ----------------------------------------------------------
# Each runs in acceptEdits mode: file edits go through, but any shell command
# not on its allow-list stops and asks you. The allow-lists are what make each
# agent end up in its intended state.

GIT_TOOLS="Bash(git status*),Bash(git diff*),Bash(git log*),Bash(git add *),Bash(git commit *)"
TEST_TOOLS="Bash(python3 -m unittest*)"

launch_agents() {
    # docs: finishes, then asks to push. The right answer is no.
    launch docs "$GIT_TOOLS,$TEST_TOOLS,Bash(python3 -m logtool*)" \
        "Bring README.md up to date with what the code actually does: check every command and option it mentions against logtool/cli.py. Commit it, then push your branch to origin."

    # tests: should just finish cleanly.
    launch tests "$GIT_TOOLS,$TEST_TOOLS" \
        "Add unit tests for every public function in logtool/parser.py, using unittest from the standard library. Done when 'python3 -m unittest' passes. Commit your work."

    # lint: has to ask to run scripts/lint.sh, which isn't on its allow-list. Approve it.
    launch lint "$GIT_TOOLS,$TEST_TOOLS" \
        "Run scripts/lint.sh and fix every warning it reports, then run it again to check it's clean. Commit the fixes."

    # flag: deliberately vague, so it should stop and ask which command and what 'verbose' means.
    launch flag "$GIT_TOOLS,$TEST_TOOLS" \
        "Add a verbose option. If anything about this is unclear, ask me before you change any code."

    # speed: impossible (Python takes longer than that to start), so it fails or does something silly.
    launch speed "$GIT_TOOLS,$TEST_TOOLS,Bash(python3 *),Bash(time *)" \
        "Make the test suite run in under 1 millisecond of wall-clock time, measured with 'time python3 -m unittest' from the shell. Commit when it does."

    # refactor: a long list of small jobs, so it's still working when the exercise starts.
    launch refactor "$GIT_TOOLS,$TEST_TOOLS,Bash(python3 -m logtool*)" \
        "Work through TODO.md from top to bottom. For each item: make the change, run 'python3 -m unittest', and commit before moving on to the next. Keep going until every item is done."
}

launch() {
    local name=$1 tools=$2 prompt=$3
    local args=(--bg -w "$name" -n "$name" --permission-mode acceptEdits --allowedTools "$tools")
    if [[ -n $MODEL ]]; then
        args+=(--model "$MODEL")
    fi
    if ((LAUNCH)); then
        echo "--- starting $name"
        (cd "$REPO" && claude "${args[@]}" -- "$prompt")
    else
        printf '(cd %s && claude' "$(quote "$REPO")"
        local arg
        for arg in "${args[@]}" -- "$prompt"; do
            printf ' %s' "$(quote "$arg")"
        done
        printf ')\n\n'
    fi
}

# Quote an argument for printing as a shell command, only if it needs it.
quote() {
    if [[ $1 =~ ^[A-Za-z0-9_./:=-]+$ ]]; then
        printf '%s' "$1"
    else
        printf "'%s'" "${1//\'/\'\\\'\'}"
    fi
}

# --- commands ----------------------------------------------------------------

check_version() {
    local version
    version=$(claude --version 2>/dev/null | awk '{print $1}')
    echo "Claude Code $version (this exercise was tested with $TESTED_VERSION)"
    if [[ $(printf '%s\n%s\n' "$TESTED_VERSION" "$version" | sort -V | head -1) != "$TESTED_VERSION" ]]; then
        echo "warning: your Claude Code is older than $TESTED_VERSION; run 'claude update' if anything fails" >&2
    fi
}

is_trusted() {
    # Read-only check of the trust flag Claude Code keeps per folder in ~/.claude.json.
    [[ -f $HOME/.claude.json ]] || return 1
    [[ $(jq -r --arg p "$REPO" '.projects[$p].hasTrustDialogAccepted // false' "$HOME/.claude.json") == true ]]
}

ensure_trusted() {
    # Background agents only start in a folder you've told Claude Code you trust,
    # and a brand-new folder isn't trusted, even inside one that is.
    is_trusted && return
    cat <<EOF

Claude Code won't start background agents in a folder you haven't trusted yet:
    $REPO
It will now open there once. Accept the trust prompt, then type /exit to come back here.
EOF
    read -r -p "Press Enter to open Claude Code... "
    (cd "$REPO" && claude) || true
    if ! is_trusted; then
        die "the folder still isn't trusted. Run 'claude' in $REPO, accept the prompt, then: $0 start --dir $DIR"
    fi
}

cmd_setup() {
    need git "the demo repo"
    need python3 "the demo project's tests"
    need claude "the agents"
    need jq "checking folder trust and the agent list"
    [[ -d $TEMPLATE ]] || die "can't find $TEMPLATE; run this script from a clone of the course repo"
    [[ -e $DIR ]] && die "$DIR already exists. Run '$0 cleanup --dir $DIR' first, or choose another --dir."
    check_version

    echo "Building the demo repo in $DIR"
    mkdir -p "$DIR"
    touch "$DIR/$MARKER"
    git init -q --bare -b main "$DIR/origin.git"
    cp -R "$TEMPLATE" "$REPO"
    (
        cd "$REPO"
        git init -q -b main
        # The agents commit, so the repo needs an identity if you have no global one.
        if ! git config user.email >/dev/null; then
            git config user.name "Fleet exercise"
            git config user.email "fleet-exercise@example.invalid"
        fi
        git add -A
        git commit -q -m "logtool 0.1"
        git remote add origin "$DIR/origin.git"
        git push -q -u origin main
        python3 -m unittest -q 2>/dev/null || die "the demo project's tests fail before any agent has touched it"
        find . -name __pycache__ -prune -exec rm -rf {} +
    )

    if ((LAUNCH)); then
        cmd_start
    else
        cat <<EOF
--no-agents: the repo is ready. To start the six agents, run:

    $0 start --dir $DIR

which runs these commands for you:

EOF
        launch_agents
    fi
}

cmd_start() {
    need claude "the agents"
    need jq "checking folder trust and the agent list"
    [[ -f $DIR/$MARKER && -d $REPO ]] || die "no demo repo at $DIR; run '$0 setup' first"
    if [[ $(exercise_sessions | jq length) != 0 ]]; then
        die "this exercise's agents have already been started; see '$0 status --dir $DIR'"
    fi
    ensure_trusted
    echo "Starting six background agents (each gets its own worktree under $REPO/.claude/worktrees/)"
    launch_agents
    cat <<EOF

All six are running. Give them about five minutes, then clear the board:

    claude agents                     # the board (or open agent view)
    $0 status --dir $DIR
    claude attach <name>              # open one; press ← to go back to the board
    claude logs <name>                # its recent output, without attaching
    cd $REPO && git diff main...worktree-<name>

When you've finished:  $0 cleanup --dir $DIR
EOF
}

exercise_sessions() {
    # This exercise's sessions: anything started under the demo repo.
    claude agents --json --all --cwd "$REPO"
}

cmd_status() {
    need jq "reading the agent list"
    [[ -d $REPO ]] || die "no demo repo at $REPO"
    local json
    json=$(exercise_sessions)
    if [[ $(jq length <<<"$json") == 0 ]]; then
        echo "No agents left for this exercise. The board is clear."
        return
    fi
    { echo "NAME STATE ID"; jq -r '.[] | [.name // "-", .state // "-", .id] | @tsv' <<<"$json"; } | column -t
    echo
    echo "Worktrees:"
    git -C "$REPO" worktree list
}

cmd_cleanup() {
    need jq "reading the agent list"
    [[ -d $DIR ]] || die "nothing to clean up at $DIR"
    [[ -f $DIR/$MARKER ]] || die "$DIR wasn't made by this script, so it won't be deleted"

    local ids=()
    if [[ -d $REPO ]]; then
        while IFS= read -r id; do
            [[ -n $id ]] && ids+=("$id")
        done < <(exercise_sessions | jq -r '.[].id')
    fi

    echo "This stops and removes ${#ids[@]} agent(s) and deletes $DIR, including any work in it."
    if ((!YES)); then
        read -r -p "Continue? [y/N] " answer
        [[ $answer == [yY]* ]] || { echo "Nothing changed."; exit 0; }
    fi

    local failed=()
    for id in ${ids[@]+"${ids[@]}"}; do
        claude stop "$id" >/dev/null 2>&1 || true
    done
    # The exercise's work is thrown away, so delete the worktrees first; then
    # 'claude rm' has no unpushed commits left to protect.
    if [[ -d $REPO ]]; then
        git -C "$REPO" worktree list --porcelain | awk '/^worktree /{print $2}' | tail -n +2 |
            while IFS= read -r tree; do git -C "$REPO" worktree remove --force "$tree" || true; done
    fi
    for id in ${ids[@]+"${ids[@]}"}; do
        claude rm "$id" >/dev/null 2>&1 || failed+=("$id")
    done
    rm -rf "$DIR"
    echo "Deleted $DIR."
    if ((${#failed[@]})); then
        echo "Couldn't remove these sessions; run 'claude rm <id>' on each to see why: ${failed[*]}" >&2
        exit 1
    fi
}

# --- arguments ---------------------------------------------------------------

[[ $# -gt 0 ]] || { usage; exit 1; }
COMMAND=$1
shift
while [[ $# -gt 0 ]]; do
    case $1 in
        --dir) DIR=${2:?--dir needs a value}; shift 2 ;;
        --model) MODEL=${2:?--model needs a value}; shift 2 ;;
        --no-agents) LAUNCH=0; shift ;;
        --yes | -y) YES=1; shift ;;
        -h | --help) usage; exit 0 ;;
        *) die "unknown option: $1 (try --help)" ;;
    esac
done

case $DIR in
    /*) ;;
    *) DIR="$PWD/$DIR" ;;
esac
DIR=${DIR%/}
REPO="$DIR/logtool"

case $COMMAND in
    setup) cmd_setup ;;
    start) cmd_start ;;
    status) cmd_status ;;
    cleanup) cmd_cleanup ;;
    -h | --help | help) usage ;;
    *) die "unknown command: $COMMAND (try --help)" ;;
esac
