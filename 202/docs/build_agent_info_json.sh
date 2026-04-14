#!/bin/sh

set -eu

# build_agent_info_json 输出符合 AgentInfo 键名风格的 JSON。

usage() {
    echo "Usage: $0 connector|finder|engager" >&2
    exit 1
}

if [ "$#" -ne 1 ]; then
    usage
fi

mode="$1"

case "$mode" in
    connector|finder|engager)
        ;;
    *)
        usage
        ;;
esac

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"

common_ask_file="$script_dir/common-ask.md"
common_action_file="$script_dir/common-action.md"
specific_ask_file="$script_dir/${mode}-ask.md"
specific_action_file="$script_dir/${mode}-action.md"

for file in \
    "$common_ask_file" \
    "$common_action_file" \
    "$specific_ask_file" \
    "$specific_action_file"
do
    if [ ! -f "$file" ]; then
        echo "missing prompt file: $file" >&2
        exit 1
    fi
done

common_ask_content="$(cat "$common_ask_file")"
common_action_content="$(cat "$common_action_file")"
specific_ask_content="$(cat "$specific_ask_file")"
specific_action_content="$(cat "$specific_action_file")"

plan_system_prompt="$(printf '%s\n%s' "$common_ask_content" "$specific_ask_content")"
system_prompt="$(printf '%s\n%s' "$common_action_content" "$specific_action_content")"

SYSTEM_PROMPT="$system_prompt" \
PLAN_SYSTEM_PROMPT="$plan_system_prompt" \
node <<'JS'
const agentInfo = {
  system_prompt: process.env.SYSTEM_PROMPT,
  plan_system_prompt: process.env.PLAN_SYSTEM_PROMPT,
};

process.stdout.write(`${JSON.stringify(agentInfo, null, 2)}\n`);
JS
