prompt_git_commit() {
  local full_diff
  local output

  # Capture the entire standard input first
  full_diff=$(cat)

  # Basic check for git diff format (presence of "diff --git")
  if [[ "$full_diff" == *'diff --git'* ]]; then
    output=$(
      cat <<EOF
create semantic commit message with the following criteria:
- just give me the commit message
- use nested list if needed for the body
- use '-' instead of '*' for the list
- use 2 spaces for the nested list
- body's lines must not be longer than 100 characters
- subject must not be sentence-case, start-case, pascal-case, upper-case

\`\`\`
$full_diff
\`\`\`
EOF
    )
    echo "$output" | xsel --clipboard
  else
    echo "Input is not a valid git diff."
  fi
}
