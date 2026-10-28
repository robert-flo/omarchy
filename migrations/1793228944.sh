echo "Add the ravn-omarchy-overlay source lines to an existing ~/.bashrc"

# One-time bridge (fork-docs ADR-013, guide/01-introduccion.md): homes seeded
# from an older stub lack the 2 overlay extension points that default/bashrc
# now has. New homes get them from the stub; this only patches existing files.
# The lines are guarded with [[ -r ... ]], so they do nothing until the overlay
# is installed. User content is never removed. Idempotent.

bashrc="$HOME/.bashrc"
anchor_env='[[ -r /usr/share/omarchy/default/bash/env-bootstrap ]] && source /usr/share/omarchy/default/bash/env-bootstrap'
line_env='[[ -r /usr/share/ravn/omarchy/bash/env ]] && source /usr/share/ravn/omarchy/bash/env'
anchor_rc='source "$OMARCHY_PATH/default/bash/rc"'
line_rc='[[ -r /usr/share/ravn/omarchy/bash/rc ]] && source /usr/share/ravn/omarchy/bash/rc'
cut='[[ $- != *i* ]] && return'

# Symlinked ~/.bashrc belongs to someone else's dotfiles repo: don't edit it.
if [[ -L $bashrc ]]; then
  echo "WARNING: ~/.bashrc is a symlink; not editing it. Add these lines yourself:" >&2
  printf '  %s\n' "$line_env" "$line_rc" >&2
  exit 0
fi
# No ~/.bashrc: the stub (default/bashrc via /etc/skel) covers new homes.
if [[ ! -f $bashrc ]]; then
  echo "No ~/.bashrc; nothing to do"
  exit 0
fi

# Exact match after trimming indentation and trailing whitespace/CR.
has_line() {
  awk -v want="$1" '{ sub(/^[ \t]+/, ""); sub(/[ \t\r]+$/, "") } $0 == want { found = 1; exit } END { exit !found }' "$bashrc"
}
if has_line "$line_env" && has_line "$line_rc"; then
  echo "$HOME/.bashrc already sources the overlay"
  exit 0
fi

tmp=$(mktemp "$bashrc.tmp.XXXXXX")
trap 'rm -f "$tmp"' EXIT
awk -v ae="$anchor_env" -v le="$line_env" -v ar="$anchor_rc" -v lr="$line_rc" -v cut="$cut" '
  function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t\r]+$/, "", s); return s }
  { l[NR] = $0; t = trim($0)
    if (t == le) has_le = 1
    if (t == lr) has_lr = 1
    if (t == ae && !pos_ae) pos_ae = NR
    if (t == ar && !pos_ar) pos_ar = NR
    if (t == cut && !pos_cut) pos_cut = NR }
  END {
    # env: after its anchor; else before the non-interactive cut; else first.
    if (!has_le && !pos_ae && !pos_cut) print le
    for (i = 1; i <= NR; i++) {
      if (!has_le && !pos_ae && pos_cut == i) print le
      print l[i]
      if (!has_le && pos_ae == i) print le
      if (!has_lr && pos_ar == i) print lr
    }
    # rc: after its anchor; else at the end.
    if (!has_lr && !pos_ar) print lr
  }' "$bashrc" >"$tmp"

backup_dir="$HOME/.cache/ravn-piloto"
mkdir -p "$backup_dir"
backup="$backup_dir/bashrc.bak-$(date +%Y%m%d%H%M%S)"
cp -p "$bashrc" "$backup"
chmod --reference="$bashrc" "$tmp" 2>/dev/null || true
chown --reference="$bashrc" "$tmp" 2>/dev/null || true
mv -f "$tmp" "$bashrc"
trap - EXIT
echo "Added overlay lines to ~/.bashrc (backup: $backup)"
