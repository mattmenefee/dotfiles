# Emit one JSON object per message the user typed, for extract-corpus.sh to deduplicate, sort and
# render. Read with `jq -R` so one malformed line is skipped rather than ending the file.
#
# A message reaches the transcript in one of two shapes:
# - A "type":"user" record. Tool results are stored this way too, but their content holds
#   tool_result blocks, not text blocks, so they reduce to an empty string and drop out. Records the
#   harness or a program wrote (promptSource "system" or "sdk") are dropped, and a prompt suggestion
#   the user accepted is kept but marked, since its wording is the model's.
# - A queued_command attachment with humanTurn set, for a prompt typed while a turn was running.
#   Task notifications and peer-session messages use the same attachment without humanTurn.
# These fields are undocumented transcript internals, so a Claude Code update can empty either
# branch without an error; the record counts extract-corpus.sh prints are the check.
#
# Older records carry no promptSource, so harness text is also recognized by its opening: shell and
# local-command output, slash command invocations, task notifications, interruption markers and
# compaction summaries.
def harness_text:
  test("^\\s*(<(bash-input|bash-stdout|bash-stderr|local-command-stdout|command-name|command-message|task-notification|artifact-content-authored-by-others)[\\s>/]|\\[Request interrupted by user|This session is being continued)");

def text_of:
  if type == "string" then .
  elif type == "array" then [.[] | objects | select(.type == "text") | .text | strings] | join("\n")
  else ""
  end;

fromjson?
| objects
| select((.timestamp // "") >= $cutoff)
| if .type == "user" and .isMeta != true
     and ((.promptSource // "") | IN("system", "sdk") | not)
  then {uuid, timestamp, text: ((.message | objects | .content) // null | text_of),
        accepted: (.promptSource == "suggestion_accepted")}
  elif .type == "attachment" and (.attachment | objects | .type) == "queued_command"
     and .attachment.humanTurn == true
  then {uuid, timestamp, text: (.attachment.prompt | text_of), accepted: false}
  else empty
  end
| select((.text | length) > 0 and (.text | harness_text | not))
| . + {key: (.uuid // "\($session) \(.timestamp)"), project: $project, session: $session}
