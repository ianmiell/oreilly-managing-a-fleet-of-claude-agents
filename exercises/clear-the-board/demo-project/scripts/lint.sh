#!/usr/bin/env bash
# Project lint: long lines, trailing whitespace, and public functions with no docstring.
# Prints one warning per line as FILE:LINE: MESSAGE and exits 1 if there are any.

set -u
cd "$(dirname "$0")/.." || exit 2

files=(logtool/*.py tests/*.py)
warnings=0

while IFS= read -r hit; do
    echo "$hit: line longer than 99 characters"
    warnings=$((warnings + 1))
done < <(grep -nE '.{100,}' "${files[@]}" | cut -d: -f1,2)

while IFS= read -r hit; do
    echo "$hit: trailing whitespace"
    warnings=$((warnings + 1))
done < <(grep -nE '[[:space:]]+$' "${files[@]}" | cut -d: -f1,2)

while IFS= read -r hit; do
    echo "$hit"
    warnings=$((warnings + 1))
done < <(python3 - "${files[@]}" <<'EOF'
import ast, sys
for path in sys.argv[1:]:
    if "/test_" in path:
        continue
    with open(path, encoding="utf-8") as handle:
        tree = ast.parse(handle.read(), path)
    for node in ast.walk(tree):
        if isinstance(node, ast.FunctionDef) and not node.name.startswith("_"):
            if ast.get_docstring(node) is None:
                print(f"{path}:{node.lineno}: function {node.name}() has no docstring")
EOF
)

if ((warnings > 0)); then
    echo "lint: $warnings warning(s)"
    exit 1
fi
echo "lint: clean"
