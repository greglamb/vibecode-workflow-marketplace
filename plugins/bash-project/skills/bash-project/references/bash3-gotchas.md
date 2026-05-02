# Bash 3.2 Gotchas: Feature → Portable Alternative

This file is the long-form companion to `SKILL.md`. Read it whenever you need to do something the main file flagged as "Bash 4+ only," or when something works on your Linux box but breaks on macOS.

Every example here has been verified against `GNU bash, version 3.2.57(1)-release` — the version Apple ships on macOS.

## Table of contents

1. [Associative arrays](#associative-arrays)
2. [`mapfile` / `readarray`](#mapfile--readarray)
3. [Case-conversion expansions](#case-conversion-expansions)
4. [Empty arrays under `set -u`](#empty-arrays-under-set--u)
5. [`[[ =~ ]]` regex matching](#--regex-matching)
6. [Indirect variable expansion](#indirect-variable-expansion)
7. [`&>>` and combined redirections](#-and-combined-redirections)
8. [`wait -n` (waiting for any background job)](#wait--n-waiting-for-any-background-job)
9. [`coproc`](#coproc)
10. [`local` scoping traps](#local-scoping-traps)
11. [Brace expansion with variables](#brace-expansion-with-variables)
12. [`printf -v` into array elements](#printf--v-into-array-elements)
13. [`echo` portability](#echo-portability)
14. [`read -d ''` / null-delimited input](#read--d---null-delimited-input)
15. [`${parameter@operator}` transformations](#parameteroperator-transformations)
16. [BSD vs GNU coreutils cheat sheet](#bsd-vs-gnu-coreutils-cheat-sheet)

---

## Associative arrays

**Bash 4+:**
```bash
declare -A user
user[name]="alice"
user[email]="alice@example.com"
echo "${user[name]}"
```

**Bash 3.2 — pick one:**

### Option A: parallel indexed arrays (best for small, fixed schemas)

```bash
users_name=()
users_email=()

users_add() {
  users_name+=("$1")
  users_email+=("$2")
}

users_get_email_by_name() {
  local target="$1" i
  for i in "${!users_name[@]}"; do
    if [ "${users_name[$i]}" = "$target" ]; then
      printf '%s\n' "${users_email[$i]}"
      return 0
    fi
  done
  return 1
}
```

### Option B: namespaced variable names (best for "give me a key/value lookup")

```bash
# Set: key name must be a valid identifier suffix.
kv_set() {
  local namespace="$1" key="$2" value="$3"
  eval "__KV_${namespace}_${key}=\"\$value\""
}

kv_get() {
  local namespace="$1" key="$2"
  eval "printf '%s\n' \"\${__KV_${namespace}_${key}:-}\""
}

kv_set users alice "alice@example.com"
kv_get users alice   # → alice@example.com
```

Sanitize keys before constructing the variable name. `tr -c 'a-zA-Z0-9_' '_'` is enough for most uses.

### Option C: a sorted-text "database" (best for many entries)

```bash
db=""
db_set() { db="$(printf '%s\n' "$db" | grep -v "^$1	" ; printf '%s\t%s\n' "$1" "$2")"; }
db_get() { printf '%s\n' "$db" | awk -F'\t' -v k="$1" '$1==k {print $2; exit}'; }
```

Fine for tens of entries; switch to a real tool (sqlite3, jq with a JSON file) past hundreds.

---

## `mapfile` / `readarray`

**Bash 4+:**
```bash
mapfile -t lines < file.txt
```

**Bash 3.2:**
```bash
lines=()
while IFS= read -r line || [ -n "$line" ]; do
  lines+=("$line")
done < file.txt
```

The `|| [ -n "$line" ]` handles files that don't end in a newline — without it you silently drop the last line.

For command output, use process substitution to avoid the subshell trap:

```bash
lines=()
while IFS= read -r line; do
  lines+=("$line")
done < <(some_command)
```

If you pipe instead (`some_command | while ...`), the loop body runs in a subshell and `lines` won't survive — a classic Bash gotcha.

---

## Case-conversion expansions

**Bash 4+:** `${var^^}`, `${var,,}`, `${var^}`, `${var,}`

**Bash 3.2:**

```bash
upper() { printf '%s' "$1" | tr '[:lower:]' '[:upper:]'; }
lower() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }

# First letter only:
ucfirst() {
  local s="$1"
  printf '%s%s' "$(upper "${s:0:1}")" "${s:1}"
}
```

Avoid Perl/awk for this — the `tr` form is faster and dependency-free.

---

## Empty arrays under `set -u`

This is the single most-hit footgun in Bash 3.2.

**Broken:**
```bash
set -u
arr=()
echo "${arr[@]}"          # bash: arr[@]: unbound variable
```

**Working idioms:**

```bash
# Canonical: expand to nothing if unset, expand normally if set
echo "${arr[@]+"${arr[@]}"}"

# When passing to a function:
my_func "${arr[@]+"${arr[@]}"}"

# When iterating (the for loop handles empty correctly with this form):
for x in "${arr[@]+"${arr[@]}"}"; do
  ...
done
```

`"${arr[@]:-}"` looks tempting but **is wrong** — it expands an empty array to a single empty string, not to nothing. You'll silently pass an extra empty argument.

Bash 4.4+ relaxed this for `${arr[@]}`, which is why Linux developers often don't notice the bug until macOS users file an issue.

---

## `[[ =~ ]]` regex matching

Bash 3.2 has a notorious regex parser bug. The pattern, **when written as a literal in `[[ ]]`**, gets re-quoted by the parser in a way that breaks meta-characters.

**Broken in 3.2:**
```bash
[[ "abc123" =~ ^[a-z]+[0-9]+$ ]]   # may not match
```

**Working in 3.2:**
```bash
re='^[a-z]+[0-9]+$'
[[ "abc123" =~ $re ]]              # works — variable, unquoted
```

The rule: **always store the regex pattern in a variable, and reference it without quotes inside `[[ =~ ]]`.** Quoting the variable (`"$re"`) turns it into a literal-string match instead of a regex.

`BASH_REMATCH` works fine in 3.2 once the match succeeds:

```bash
re='^([a-z]+)-([0-9]+)$'
if [[ "user-42" =~ $re ]]; then
  printf 'name=%s id=%s\n' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
fi
```

---

## Indirect variable expansion

**Bash 4+:** namerefs (`declare -n`).

**Bash 3.2:** `${!name}` exists and works for reading:

```bash
foo="hello"
ref="foo"
echo "${!ref}"   # → hello
```

For writing, use `eval` with strict input validation:

```bash
set_var() {
  local name="$1" value="$2"
  case "$name" in
    *[!a-zA-Z0-9_]*) return 1 ;;   # reject anything that isn't a valid identifier char
  esac
  eval "${name}=\"\$value\""
}
```

For arrays specifically, `${!name}` does **not** give you the array — it gives the array's first element. Use `eval` for the full array:

```bash
get_array() {
  local name="$1"
  eval "printf '%s\n' \"\${${name}[@]}\""
}
```

---

## `&>>` and combined redirections

| Goal | Bash 4+ | Bash 3.2-portable |
|---|---|---|
| stdout + stderr to file (truncate) | `cmd &> file` | `cmd > file 2>&1` |
| stdout + stderr to file (append) | `cmd &>> file` | `cmd >> file 2>&1` |
| stderr to stdout, then pipe | `cmd \|& other` | `cmd 2>&1 \| other` |

Just always use the explicit `2>&1` form. It's clearer to read anyway.

---

## `wait -n` (waiting for any background job)

**Bash 4.3+:**
```bash
wait -n   # returns when any one job finishes
```

**Bash 3.2:** poll the PIDs.

```bash
# Run jobs, collect PIDs
pids=()
for url in "${urls[@]}"; do
  fetch "$url" &
  pids+=("$!")
done

# Wait for all (the easy case)
for pid in "${pids[@]}"; do
  wait "$pid" || log::warn "pid $pid failed"
done

# Wait for *any* one — poll
wait_any() {
  local pid
  while :; do
    for pid in "$@"; do
      if ! kill -0 "$pid" 2>/dev/null; then
        wait "$pid"
        return $?
      fi
    done
    sleep 0.1
  done
}
```

If you genuinely need bounded parallelism, `xargs -P N` is far simpler than rolling your own job pool — and it's portable.

---

## `coproc`

Bash 3.2 has no `coproc`. Use named pipes (`mkfifo`) for bidirectional communication, or two processes connected via pipes for one-direction flow. Honestly, if you're reaching for `coproc`, that's a sign the problem outgrew shell — but if you must:

```bash
fifo_in="$(mktemp -u)"; mkfifo "$fifo_in"
fifo_out="$(mktemp -u)"; mkfifo "$fifo_out"

helper < "$fifo_in" > "$fifo_out" &
helper_pid=$!

exec 3> "$fifo_in"
exec 4< "$fifo_out"

printf 'query 1\n' >&3
read -r response <&4

exec 3>&- 4<&-
rm -f "$fifo_in" "$fifo_out"
wait "$helper_pid"
```

---

## `local` scoping traps

`local` is supported in Bash 3.2 but with two traps:

1. **`local` masks the exit status of the right-hand side.** This is silent and lethal under `set -e`:

   ```bash
   foo() {
     local x="$(might_fail)"   # always succeeds — `local` returns 0
     echo "$x"
   }
   ```

   Fix: declare and assign separately.

   ```bash
   foo() {
     local x
     x="$(might_fail)"         # now `set -e` will catch the failure
     echo "$x"
   }
   ```

   Run shellcheck — it flags this as `SC2155`.

2. **`local -r` (readonly local) does not exist in Bash 3.2.** Use `local` and don't reassign.

---

## Brace expansion with variables

Brace expansion happens **before** variable expansion in the shell:

```bash
a=1; b=5
echo {$a..$b}     # → {1..5} (literal!), not 1 2 3 4 5
```

Use `seq` (portable on macOS and Linux):

```bash
for i in $(seq "$a" "$b"); do ...; done
```

Or a `while` loop if you need to avoid the subshell:

```bash
i=$a
while [ "$i" -le "$b" ]; do
  ...
  i=$((i + 1))
done
```

---

## `printf -v` into array elements

```bash
arr=()
printf -v 'arr[0]' '%s' "hello"   # broken in Bash 3.2 — silently does nothing
```

Workaround: use a scalar then assign.

```bash
printf -v tmp '%s' "hello"
arr[0]="$tmp"
```

---

## `echo` portability

`echo` behavior varies wildly. `echo -e`, `echo -n`, and backslash escapes are **not portable**. Use `printf` for everything:

```bash
printf '%s\n' "$line"           # echo "$line"
printf '%s' "$line"             # echo -n "$line"
printf '%b\n' 'hello\tworld'    # echo -e 'hello\tworld'
```

`printf` is a builtin in Bash 3.2, so there's no performance cost.

---

## `read -d ''` / null-delimited input

Works in 3.2 but with a quirk: the empty string `''` is interpreted as `\0` (null) only when written exactly as `-d ''`, and `read` returns 1 at EOF even when it successfully read a record. Standard idiom:

```bash
while IFS= read -r -d '' file; do
  printf 'found: %s\n' "$file"
done < <(find . -type f -print0)
```

The `|| [ -n "$file" ]` trick from the line-reading example doesn't apply here because null-delimited streams don't have the trailing-newline ambiguity.

---

## `${parameter@operator}` transformations

`@Q` (quoted), `@E` (escape-expanded), `@P` (prompt-expanded), `@A` (assignment-form), `@a` (attribute flags) are all Bash 4.4+. None work in 3.2.

Common replacements:

- `@Q` (shell-quote a string for re-evaluation): use `printf '%q ' "$var"` — `%q` exists in 3.2 and produces shell-quoted output.
- `@E` (expand backslash escapes): `printf '%b' "$var"`.
- `@P` (expand as a prompt string): no portable replacement; do without.

---

## BSD vs GNU coreutils cheat sheet

| Task | macOS (BSD) | Linux (GNU) | Portable approach |
|---|---|---|---|
| In-place edit | `sed -i '' 's/x/y/' f` | `sed -i 's/x/y/' f` | Use `platform::sed_inplace` |
| Read symlink (full chain) | n/a (`readlink` only follows one level) | `readlink -f f` | Use `platform::realpath` (loop calling `readlink`) |
| Date arithmetic | `date -j -v-1d +%F` | `date -d 'yesterday' +%F` | Use `platform::yesterday` |
| Parse arbitrary date | `date -j -f '%Y-%m-%d' "$d" +%s` | `date -d "$d" +%s` | `platform::date_to_epoch` |
| File size in bytes | `stat -f%z f` | `stat -c%s f` | `platform::file_size` |
| File mtime epoch | `stat -f%m f` | `stat -c%Y f` | `platform::file_mtime` |
| Base64 decode | `base64 -D` | `base64 -d` | `platform::b64_decode` |
| `find` with extended regex | `find -E . -regex '...'` | `find . -regextype posix-extended -regex '...'` | Avoid — use `grep -E` on a `find` listing |
| `grep` PCRE | not built-in | `grep -P` | Avoid PCRE; use ERE (`grep -E`) |
| `xargs` no-input behavior | runs command once with no args | runs command once with no args | Use `xargs -r` on Linux **only**; on macOS `xargs` already skips on empty input |
| `tac` (reverse cat) | absent | present | `tail -r` on macOS, or `awk '{a[NR]=$0} END {for(i=NR;i>0;i--) print a[i]}'` |
| `seq` | present | present | safe |
| `mktemp` template | `mktemp /tmp/foo.XXXXXX` works; `mktemp -t foo` differs | `mktemp` with no args works | always pass an explicit template ending in `XXXXXX` |
| `realpath` | absent (install via brew) | present | use `platform::realpath` |
| `timeout` | absent (install via brew as `gtimeout` or `timeout`) | present | document the dependency or implement via `&` + `kill` |

The full `lib/platform.sh` template in `assets/lib/platform.sh` covers most of these as drop-in helpers.
