prompt_ts_type() {
  local response_object
  local output

  # Capture the entire standard input first
  response_object=$(cat)

  output=$(
    cat <<EOF
Create typescript type with this criteria:
- never use \`interface Something {...}\`
- always use \`type Something = {...}\`
- never create multiple types. Make one that is nested
- never give me fucking examples. just response with the type
- use \`Array<>\` instead of \`{...}[]\`

\`\`\`
$response_object
\`\`\`
EOF
  )
  echo "$output" | xsel --clipboard
}
