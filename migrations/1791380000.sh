#!/bin/bash
# Fork: install pre-refresh-pacman hook for omarchy-personal (ADR-003 without editing pacman-stable.conf).

hook_src="${OMARCHY_PATH}/config/omarchy/hooks/pre-refresh-pacman.d/omarchy-personal-repo"
hook_dst="${HOME}/.config/omarchy/hooks/pre-refresh-pacman.d/omarchy-personal-repo"

[[ -f $hook_src ]] || exit 0
mkdir -p "$(dirname "$hook_dst")"
install -m 0755 "$hook_src" "$hook_dst"
