#!/bin/bash
# Claude Code status line. Two rows everywhere:
#   ~/path/to/cwd  branch <git state>          (truncated from the left to fit 100 columns)
#   model effort  ctx gauge  one gauge per usage limit  [plugin badges]
# Plus, ONLY when cwd is inside a LifeOS context (SL_LIFEOS_DIRS below, or a `.lifeos`
# marker file in cwd or any parent), three more rows:
#   LifeOS │ 🇺🇸 CITY, ST  HH:MM  🌤 72°F │ SESSION [│ ascent]
#   STATE  HEALTH ▓▓ 50%  RHYTHMS ▓ 38%  ...   (same gauge renderer, ramp inverted)
#   🧠  <memory-loop health one-liner>
# Shared base with the work dotfiles' statusline — keep the two in sync; the LifeOS
# section at the bottom is the only intended difference.
# Receives session JSON on stdin (schema: https://code.claude.com/docs/en/statusline).
# Wired via ~/.claude/settings.json:  "statusLine": {"type": "command", "command": "$HOME/.claude/statusline.sh"}
# Must always exit 0 -- Claude Code hides the whole bar on non-zero exit.

# ${#var} counts bytes, not characters, outside a UTF-8 locale, and the left-truncation below
# has to be right about how wide the line is. Claude Code does not guarantee the locale.
export LC_CTYPE=C.utf8

WIDTH=100 # line 1 is truncated to this

input=$(cat)
command -v jq >/dev/null 2>&1 || {
    printf 'jq missing'
    exit 0
}

cfg=${CLAUDE_CONFIG_DIR:-$HOME/.claude}

# Usage limits come from ~/.claude/usage-cache.json, not from stdin: stdin's .rate_limits only
# ever carries five_hour and seven_day, while the cache's .usage.limits[] also has the
# model-scoped weekly window (Fable) and whatever else the plan exposes. Fall back to stdin's
# .rate_limits when the cache is missing. /dev/null makes --slurpfile yield [] rather than fail.
uc=$cfg/usage-cache.json
[ -f "$uc" ] || uc=/dev/null

# One jq call, fields joined by US (0x1f) -- unlike tab, bash `read` keeps empty fields intact.
# The separator is written as jq's "\u001f" escape so no raw control byte sits in this file for an
# editor to silently drop. `limits` is a ";"-joined list of "label:pct"; both sources are
# enumerated rather than hardcoded, since windows come and go with the plan and reset
# independently.
IFS=$'\x1f' read -r model effort pct dir session_id limits <<<"$(
    jq -r --slurpfile uc "$uc" '
        def gauges:
            ($uc[0].usage.limits // [] | map(select(.percent != null))
                | map("\(.scope.model.display_name // .kind):\(.percent | floor)"))
            as $cached
            | if ($cached | length) > 0 then $cached
              else (.rate_limits // {} | to_entries
                  | map(select(.value.used_percentage != null))
                  | map("\(.key):\(.value.used_percentage | floor)"))
              end
            | join(";");
        [
            (.model.display_name // .model.id // "?"),
            (.effort.level // ""),
            (.context_window.used_percentage // 0 | floor),
            (.workspace.current_dir // .cwd // ""),
            (.session_id // ""),
            gauges
        ] | map(tostring) | join("\u001f")' <<<"$input" 2>/dev/null
)"
model=${model:-?} pct=${pct:-0}

R=$'\e[0m'
c() { printf '\e[38;5;%sm%s\e[0m' "$1" "$2"; } # c COLOR TEXT

MODEL_C=141 GREY=244 CLEAN=42 AHEAD=220 BEHIND=196 DIRTY=208 CONFLICT=196 STAGED=42

# Percentage of the fill's brightness used for the bar's trough.
TROUGH_PCT=25

# Colour ramp: cool while there is headroom, hot as a limit fills. 24-bit, so the trough can be
# an exact fraction of the fill rather than whichever 256-cube index happens to sit nearby --
# the cube bottoms out well before these hues get dark enough, and collides across bands.
ramp() { # prints "R G B" for PCT
    local p=${1:-0}
    if ((p < 25)); then
        printf '0 135 255' # blue
    elif ((p < 35)); then
        printf '0 215 255' # cyan
    elif ((p < 50)); then
        printf '0 215 135' # green
    elif ((p < 60)); then
        printf '255 215 0' # yellow
    elif ((p < 70)); then
        printf '255 175 0' # amber
    elif ((p < 80)); then
        printf '255 135 0' # orange
    elif ((p < 90)); then
        printf '255 95 0' # orange-red
    else
        printf '255 0 0' # red
    fi
}

# Eighth-of-a-cell partials, so a 6-wide bar still distinguishes 2% from 14% from 0%.
# An array, not string slicing: ${str:i:1} on multibyte glyphs needs a UTF-8 locale, and the
# status line does not control the environment Claude Code hands it.
PARTIAL=('▏' '▎' '▍' '▌' '▋' '▊' '▉')

# gauge LABEL PCT [WIDTH] [COLOR_PCT] -- label, bar and percent all in one ramp colour.
# COLOR_PCT lets a caller colour by a different scale than the fill (the STATE meters pass
# 100-p so a high score reads cool, not red). The number is printed only from NUM_MIN% up
# (default 50): below that the colour and fill say enough. Fill is clamped to WIDTH so an
# over-100% window still renders, while the number stays truthful.
gauge() {
    local label=$1 raw=${2//[!0-9]/} w=${3:-6} p e f r bar pad num=""
    raw=${raw:-0}
    p=$raw
    ((p > 100)) && p=100
    ((raw >= ${NUM_MIN:-50})) && num=" ${raw}%"
    e=$((p * w * 8 / 100)) # fill measured in eighths of a cell
    f=$((e / 8))
    r=$((e % 8))
    printf -v bar '%*s' "$f" ''
    bar=${bar// /█}
    if ((r)); then
        bar+=${PARTIAL[r - 1]}
        ((f++))
    fi
    printf -v pad '%*s' $((w - f)) ''
    # The whole bar sits on a trough background, and everything unfilled is a plain space on it.
    # A partial glyph paints only the left fraction of its cell, so its remainder has to match the
    # empty cells exactly -- shading them (with U+2591) instead makes that remainder a visibly
    # different colour from its neighbours.
    local cr cg cb
    read -r cr cg cb <<<"$(ramp "${4:-$p}")"
    printf '\e[38;2;%d;%d;%dm%s\e[48;2;%d;%d;%dm%s%s\e[0m' \
        "$cr" "$cg" "$cb" "${label:+$label }" \
        $((cr * TROUGH_PCT / 100)) $((cg * TROUGH_PCT / 100)) $((cb * TROUGH_PCT / 100)) \
        "$bar" "$pad"
    [ -n "$num" ] && printf '\e[38;2;%d;%d;%dm%s\e[0m' "$cr" "$cg" "$cb" "$num"
    return 0
}

# git_state DIR -- fills `git_plain` and `git_color` with " branch +staged *unstaged ?untracked
# !conflicts ^ahead vbehind", modelled on liquidprompt: green clean, yellow out of sync with the
# remote, orange dirty, red conflicted. One `git status` call supplies every count.
git_plain="" git_color=""
git_state() {
    local out line xy head="" oid="" upstream="" ab
    local ahead=0 behind=0 staged=0 unstaged=0 untracked=0 conflict=0 branch color
    out=$(git -C "$1" status --porcelain=v2 --branch 2>/dev/null) || return 1
    while IFS= read -r line; do
        case $line in
            '# branch.head '*) head=${line#\# branch.head } ;;
            '# branch.oid '*) oid=${line#\# branch.oid } ;;
            '# branch.upstream '*) upstream=${line#\# branch.upstream } ;;
            '# branch.ab '*)
                ab=${line#\# branch.ab }
                ahead=${ab%% *} ahead=${ahead#+}
                behind=${ab##* } behind=${behind#-}
                ;;
            '1 '* | '2 '*)
                xy=${line:2:2}
                [ "${xy:0:1}" != . ] && ((staged++))
                [ "${xy:1:1}" != . ] && ((unstaged++))
                ;;
            'u '*) ((conflict++)) ;;
            '?'*) ((untracked++)) ;;
        esac
    done <<<"$out"
    [ -n "$head" ] || return 1
    branch=$head
    [ "$branch" = '(detached)' ] && branch=${oid:0:8}

    if ((conflict)); then
        color=$CONFLICT
    elif ((staged || unstaged || untracked)); then
        color=$DIRTY
    elif ((behind)); then
        color=$BEHIND
    elif ((ahead)); then
        color=$AHEAD
    elif [ -z "$upstream" ]; then
        color=$GREY
    else
        color=$CLEAN
    fi

    git_plain=" $branch" git_color="$(c "$color" " $branch")"
    add() { # add COLOR MARK COUNT
        ((${3:-0})) || return 0
        git_plain+=" $2$3" git_color+=" $(c "$1" "$2$3")"
    }
    add "$STAGED" + "$staged"
    add "$DIRTY" '*' "$unstaged"
    add "$GREY" '?' "$untracked"
    add "$CONFLICT" '!' "$conflict"
    add "$AHEAD" '^' "$ahead"
    add "$BEHIND" v "$behind"
    return 0
}

# Line 1: cwd, then branch and git state. The path is truncated from the left, since the tail is
# the part that identifies where you are.
line1="" plain1=""
if [ -n "$dir" ]; then
    d=$dir
    [[ $d == "$HOME"* ]] && d="~${d#"$HOME"}"
    # ostree host: /home is a symlink to /var/home, and Claude Code hands out either form.
    # When the direct $HOME match missed, retry on realpath'd forms so ~ still folds.
    if [[ $d != '~'* ]]; then
        hr=$(realpath -m "$HOME" 2>/dev/null)
        dr=$(realpath -m "$dir" 2>/dev/null)
        [ -n "$hr" ] && [[ $dr == "$hr"* ]] && d="~${dr#"$hr"}"
    fi
    git_state "$dir" && { line1=" $git_color" plain1=" $git_plain"; }
    budget=$((WIDTH - ${#plain1}))
    ((${#d} > budget && budget > 3)) && d="…${d: -$((budget - 1))}"
    line1="$d$line1"
fi

# Plugin badges: every */hooks/*-statusline.sh under the installed marketplaces, so a newly
# installed plugin shows up without editing this script. Most print only while their mode flag is
# active. Deliberately narrower than *statusline.sh: sylvain-marketplace ships a whole competing
# statusline, plus a configure-statusline.sh that copies itself over ~/.claude/statusline.sh and
# rewrites settings.json -- neither is a badge and running them here would be destructive.
# Only the first line of a badge is kept, so a chatty one cannot break the row layout, and
# stdin is closed so one cannot hang the bar waiting for input.
badges=""
while IFS= read -r b; do
    out=$(bash "$b" </dev/null 2>/dev/null | head -n 1) && [ -n "$out" ] && badges+=" $out"
done < <(find "$cfg/plugins/marketplaces" -type f -path '*/hooks/*' -name '*-statusline.sh' \
    2>/dev/null | sort)

# Line 2: model, effort, context gauge, one gauge per usage limit, then badges
model=${model#Claude } model=${model%% (*} # "Claude Opus 5 (1M context)" -> "Opus 5"
line2="$(c "$MODEL_C" "$model")"
[ -n "$effort" ] && line2+=" $(c "$GREY" "$effort")"
line2+="  $(gauge ctx "$pct")"
if [ -n "$limits" ]; then
    IFS=';' read -ra windows <<<"$limits"
    for wnd in "${windows[@]}"; do
        key=${wnd%%:*}
        case $key in
            session | five_hour) lbl=5h ;;
            weekly_all | seven_day) lbl=7d ;;
            weekly_scoped) lbl=weekly ;;
            spend_limit) lbl=spend ;;
            *) # model-scoped window: "Fable" -> "F", seven_day_opus -> "O"
                lbl=${key#seven_day_}
                lbl=${lbl^}
                lbl=${lbl:0:1}
                ;;
        esac
        line2+="  $(gauge "$lbl" "${wnd##*:}")"
    done
fi
printf '%s\n%s%s\n' "$line1" "$line2" "$badges"

# ═════════════════════════════════════════════════════════════════════════════
# LifeOS section — everything below renders ONLY inside a LifeOS context.
# This is the sole intended divergence from the work dotfiles' statusline.
# ═════════════════════════════════════════════════════════════════════════════

LIFEOS_DIR=${LIFEOS_DIR:-$HOME/.claude/LIFEOS}

# LifeOS contexts: dir-prefix list (fast path) plus `.lifeos` marker-file walk (no-edit escape
# hatch). realpath -m normalizes /home <-> /var/home on this ostree host and folds the
# ~/Code/freiheit-wtf -> ~/Code/web/freiheit-wtf symlink.
SL_LIFEOS_DIRS=(
    "$HOME/Documents/freibrain"
    "$HOME/.claude"
    "$HOME/Code/personal-brief"
    "$HOME/Code/web/freiheit-wtf"
)
in_lifeos=0
if [ -n "$dir" ]; then
    cwd_r=$(realpath -m "$dir" 2>/dev/null || echo "$dir")
    for d in "${SL_LIFEOS_DIRS[@]}"; do
        dr=$(realpath -m "$d" 2>/dev/null || echo "$d")
        case $cwd_r/ in "$dr"/*) in_lifeos=1 && break ;; esac
    done
    if ((!in_lifeos)); then
        p=$cwd_r
        while [ -n "$p" ] && [ "$p" != / ]; do
            [ -f "$p/.lifeos" ] && { in_lifeos=1 && break; }
            p=${p%/*}
        done
    fi
fi
((in_lifeos)) || exit 0

NOW_EPOCH=$(date +%s)
SEP="$(c 240 '│')"

# ── Row 3: LifeOS │ 🇺🇸 CITY, ST  HH:MM  🌤 72°F │ SESSION [│ ascent] ─────────
# Location and weather are stale-while-revalidate: the render path only reads the caches
# (sub-millisecond); a detached, mkdir-locked subshell refreshes them when stale. settings.json
# .location is authoritative when set (VPN-correct, no third-party IP lookup); ip-api.com is the
# fallback. Weather comes from open-meteo via the cached lat/lon.
SL_CACHE=${XDG_CACHE_HOME:-$HOME/.cache}/lifeos-statusline
mkdir -p "$SL_CACHE" 2>/dev/null
LOC_CACHE=$SL_CACHE/location-cache.json
WX_CACHE=$SL_CACHE/weather-cache.json
LOC_TTL=3600 WX_TTL=900

eval "$(jq -r '
    "TEMP_UNIT=" + (.preferences.temperatureUnit // "fahrenheit" | @sh) + "\n" +
    "LOC_CITY=" + (.location.city? // "" | @sh) + "\n" +
    "LOC_REGION=" + (.location.regionName? // .location.region? // "" | @sh) + "\n" +
    "LOC_CC=" + (.location.countryCode? // "" | @sh) + "\n" +
    "LOC_LAT=" + (.location.lat? // "" | tostring | @sh) + "\n" +
    "LOC_LON=" + (.location.lon? // "" | tostring | @sh)
' "$cfg/settings.json" 2>/dev/null)"
[ "${TEMP_UNIT:-}" != celsius ] && TEMP_UNIT=fahrenheit

age() { # seconds since FILE's mtime, huge when missing
    local m
    m=$(stat -c %Y "$1" 2>/dev/null) || { echo 999999; return; }
    echo $((NOW_EPOCH - m))
}

if [ "$(age "$LOC_CACHE")" -gt $LOC_TTL ] || [ "$(age "$WX_CACHE")" -gt $WX_TTL ]; then
    (
        lock=$SL_CACHE/refresh.lock
        mkdir "$lock" 2>/dev/null || {
            # Held -- steal only if stale (>60s: a refresh takes seconds).
            [ "$(age "$lock")" -gt 60 ] && rmdir "$lock" 2>/dev/null && mkdir "$lock" 2>/dev/null || exit 0
        }
        trap 'rmdir "$lock" 2>/dev/null' EXIT
        if [ -n "$LOC_CITY" ]; then
            jq -n --arg city "$LOC_CITY" --arg region "$LOC_REGION" --arg cc "$LOC_CC" \
                --arg lat "$LOC_LAT" --arg lon "$LOC_LON" \
                '{city:$city, regionName:$region, countryCode:$cc,
                  lat:($lat | if . == "" then null else tonumber end),
                  lon:($lon | if . == "" then null else tonumber end)}' >"$LOC_CACHE" 2>/dev/null
        elif [ "$(age "$LOC_CACHE")" -gt $LOC_TTL ]; then
            loc=$(curl -s --max-time 3 'http://ip-api.com/json/?fields=city,regionName,countryCode,lat,lon' 2>/dev/null)
            [ -n "$loc" ] && jq -e .city <<<"$loc" >/dev/null 2>&1 && printf '%s' "$loc" >"$LOC_CACHE"
        fi
        if [ "$(age "$WX_CACHE")" -gt $WX_TTL ] && [ -f "$LOC_CACHE" ]; then
            eval "$(jq -r '"lat=\(.lat // empty)\nlon=\(.lon // empty)"' "$LOC_CACHE" 2>/dev/null)"
            if [ -n "${lat:-}" ] && [ -n "${lon:-}" ]; then
                wx=$(curl -s --max-time 4 "https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}&current=temperature_2m,weather_code,is_day&temperature_unit=${TEMP_UNIT}" 2>/dev/null)
                if [ -n "$wx" ] && jq -e .current <<<"$wx" >/dev/null 2>&1; then
                    eval "$(jq -r '.current | "t=\(.temperature_2m)\nwc=\(.weather_code)\nid=\(.is_day)"' <<<"$wx" 2>/dev/null)"
                    case $wc in # open-meteo WMO weather_code -> emoji
                        0) icon=$([ "$id" = 1 ] && echo ☀️ || echo 🌙) ;;
                        1 | 2) icon=$([ "$id" = 1 ] && echo 🌤️ || echo ☁️) ;;
                        3) icon=☁️ ;;
                        45 | 48) icon=🌫️ ;;
                        51 | 53 | 55 | 56 | 57 | 61 | 63 | 65 | 66 | 67 | 80 | 81 | 82) icon=🌧️ ;;
                        71 | 73 | 75 | 77 | 85 | 86) icon=🌨️ ;;
                        95 | 96 | 99) icon=⛈️ ;;
                        *) icon=🌡️ ;;
                    esac
                    u=$([ "$TEMP_UNIT" = celsius ] && echo °C || echo °F)
                    echo "$icon ${t%%.*}$u" >"$WX_CACHE"
                fi
            fi
        fi
    ) </dev/null >/dev/null 2>&1 &
    disown 2>/dev/null || true
fi

loc_str="" flag=""
if [ -f "$LOC_CACHE" ]; then
    eval "$(jq -r '
        "city=" + (.city // "" | ascii_upcase | @sh) + "\n" +
        "region=" + (.regionName // .region // "" | ascii_upcase | @sh) + "\n" +
        "cc=" + (.countryCode // "" | ascii_upcase | @sh)
    ' "$LOC_CACHE" 2>/dev/null)"
    # Country code -> flag emoji: each regional indicator is U+1F1E6 + (letter - 'A'),
    # UTF-8 F0 9F 87 A6..BF, built from raw bytes so bash 3 would cope too.
    if [ ${#cc} -eq 2 ]; then
        c1=$(printf '%d' "'${cc:0:1}") c2=$(printf '%d' "'${cc:1:1}")
        if ((c1 >= 65 && c1 <= 90 && c2 >= 65 && c2 <= 90)); then
            flag=$(printf '%b' "\xf0\x9f\x87\x$(printf '%02x' $((0xA6 + c1 - 65)))\xf0\x9f\x87\x$(printf '%02x' $((0xA6 + c2 - 65)))")
        fi
    fi
    [ -n "$city" ] && loc_str="$(c 117 "$city")"
    [ -n "$city" ] && [ -n "$region" ] && loc_str+="$(c 240 ',') $(c 110 "$region")"
fi
wx_str=$(cat "$WX_CACHE" 2>/dev/null)

# Session label: /rename's customTitle in Claude Code's sessions-index wins, then LifeOS's
# auto-generated session-names.json. Both lookups are cheap enough at refreshInterval=5.
session_label=""
if [ -n "$session_id" ]; then
    idx="$cfg/projects/${dir//[\/.]/-}/sessions-index.json"
    if [ -f "$idx" ]; then
        session_label=$(grep -A10 "\"sessionId\": \"$session_id\"" "$idx" 2>/dev/null |
            grep '"customTitle"' | head -1 | sed 's/.*"customTitle": "//; s/".*//')
    fi
    [ -z "$session_label" ] && [ -f "$LIFEOS_DIR/MEMORY/STATE/session-names.json" ] &&
        session_label=$(jq -r --arg sid "$session_id" '.[$sid] // empty' \
            "$LIFEOS_DIR/MEMORY/STATE/session-names.json" 2>/dev/null)
fi

# Ascent chip: icon/label/color are resolved at write time by the LifeOS hooks and stored on
# the work.json row, so this stays a pure read and cannot drift from the Pulse board.
ascent=""
work_json=$LIFEOS_DIR/MEMORY/STATE/work.json
if [ -n "$session_id" ] && [ -f "$work_json" ]; then
    eval "$(jq -r --arg sid "$session_id" '
        [ .sessions[]? | select(.sessionUUID == $sid and ((.ascent | type) == "object")) ]
        | sort_by(.updatedAt // "") | last
        | if . == null then empty else
            "a_icon=" + (.ascent.icon // "" | @sh) + "\n" +
            "a_label=" + (.ascent.label // "" | @sh) + "\n" +
            "a_color=" + (.ascent.color // "" | @sh)
          end' "$work_json" 2>/dev/null)"
    if [ -n "${a_label:-}" ]; then
        a_fg=$(c 246 '')
        case ${a_color:-} in
            \#[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F])
                h=${a_color#\#}
                a_fg=$(printf '\e[38;2;%d;%d;%dm' "$((16#${h:0:2}))" "$((16#${h:2:2}))" "$((16#${h:4:2}))")
                ;;
        esac
        ascent=" $SEP ${a_fg}${a_icon} ${a_label}${R}"
    fi
fi

hdr="$(c 141 LifeOS) $SEP ${flag:+$flag }${loc_str:-$(c 240 '—')}  $(c 250 "$(date +%H:%M)")"
[ -n "$wx_str" ] && hdr+="  $wx_str"
[ -n "$session_label" ] && hdr+=" $SEP $(c 180 "${session_label^^}")"
hdr+=$ascent
printf '%s\n' "$hdr"

# ── Row 4: STATE meters, rendered with the same gauge() as row 2 ─────────────
# LIFEOS_STATE.json is written by ComputeGap.ts on a schedule. The ramp is inverted
# (COLOR_PCT = 100-p) because a high STATE score is good news, and NUM_MIN=0 because the
# score IS the point. "finances" falls back to the legacy .dimensions.money key.
# Columns chosen by the principal 2026-08-30: RHYTHMS replaces CREATIVITY.
dims=(health rhythms relationships finances freedom)
labels=(HEALTH RHYTHMS RELS FIN FREEDOM)
state_json=$LIFEOS_DIR/USER/TELOS/LIFEOS_STATE.json
if [ -f "$state_json" ]; then
    IFS=$'\t' read -r -a vals <<<"$(
        # --args must come AFTER the input file, or jq swallows the filename as a positional.
        jq -r '[ $ARGS.positional[] as $d
            | (.dimensions[$d].pct
               // (if $d == "finances" then .dimensions.money.pct else null end)
               // "N/A" | tostring) ] | @tsv' "$state_json" --args "${dims[@]}" 2>/dev/null
    )"
    srow="$(c 240 STATE)"
    for i in "${!dims[@]}"; do
        v=${vals[$i]:-N/A} v=${v%%.*}
        case $v in
            '' | *[!0-9]*) srow+="  $(c 240 "${labels[$i]} —")" ;;
            *) srow+="  $(NUM_MIN=0 gauge "${labels[$i]}" "$v" 4 $((100 - v)))" ;;
        esac
    done
    printf '%s\n' "$srow"
fi

# ── Row 5: 🧠 memory-loop health, one plain-English sentence ──────────────────
# Straight port of the LifeOS statusline's 2026-06-10 redesign, minus its BSD-date branch
# (this host is Linux). Sage for healthy states; red/amber only for problems.
review_state=$LIFEOS_DIR/MEMORY/OBSERVABILITY/review-state.json
if [ -f "$review_state" ]; then
    m_turns=$(jq -r '.turn_count_since_last_review // 0' "$review_state" 2>/dev/null)
    m_pending=$(jq -r '.pending_review // false' "$review_state" 2>/dev/null)
    m_last=$(jq -r '.last_review_at // ""' "$review_state" 2>/dev/null)
    m_thresh=$(jq -r '.turn_threshold // 8' "$LIFEOS_DIR/USER/CONFIG/memory-review.json" 2>/dev/null)
    { [ -z "$m_thresh" ] || [ "$m_thresh" = null ]; } && m_thresh=8

    m_age=never m_age_sec=999999999
    if [ -n "$m_last" ] && [ "$m_last" != null ]; then
        then_epoch=$(date -u -d "$m_last" +%s 2>/dev/null || echo "$NOW_EPOCH")
        m_age_sec=$((NOW_EPOCH - then_epoch))
        ((m_age_sec < 0)) && m_age_sec=0
        m=$((m_age_sec / 60)) h=$((m_age_sec / 3600)) dy=$((m_age_sec / 86400))
        if ((dy >= 1)); then m_age=${dy}d; elif ((h >= 1)); then m_age=${h}h; else m_age=${m}m; fi
    fi

    m_health=ok m_detail=""
    hrow=$(tail -1 "$LIFEOS_DIR/MEMORY/OBSERVABILITY/memory-health.jsonl" 2>/dev/null)
    if [ -n "$hrow" ]; then
        m_health=$(jq -r '.overall // "ok"' <<<"$hrow" 2>/dev/null)
        m_detail=$(jq -r '.findings[0].message // ""' <<<"$hrow" 2>/dev/null)
    fi

    m_dispatched=0
    rrow=$(tail -1 "$LIFEOS_DIR/MEMORY/OBSERVABILITY/reviewer-runs.jsonl" 2>/dev/null)
    [ -n "$rrow" ] && [ "$(jq -r '.ok // false' <<<"$rrow" 2>/dev/null)" = true ] &&
        m_dispatched=$(jq -r '.dispatch_summary.succeeded // 0' <<<"$rrow" 2>/dev/null)

    # Hot-layer fill across both _MEMORY.md files (body chars past the frontmatter, /24576).
    m_pct=0
    pm=$LIFEOS_DIR/USER/PRINCIPAL/PRINCIPAL_MEMORY.md
    dm=$LIFEOS_DIR/USER/DIGITAL_ASSISTANT/DA_MEMORY.md
    if [ -f "$pm" ] && [ -f "$dm" ]; then
        # FNR==1 resets the frontmatter counter per file; one awk pass over both.
        used=$(awk 'FNR==1{ic=0} /^---$/{ic++; next} ic==2 && NF>0 && !/^<!--/ && !/^-->/' "$pm" "$dm" 2>/dev/null | wc -c)
        m_pct=$((used * 100 / 24576))
    fi

    m_color=$'\e[38;2;167;184;148m' # sage
    if [ "$m_health" = critical ]; then
        m_color=$'\e[38;2;239;68;68m'
        m_line="PROBLEM · ${m_detail:-RUN MEMORYHEALTHCHECK}"
    elif [ "$m_health" = warn ]; then
        m_color=$'\e[38;2;251;191;36m'
        m_line="NEEDS ATTENTION · ${m_detail:-RUN MEMORYHEALTHCHECK}"
    elif [ "$m_age" != never ] && ((m_age_sec <= 30 && m_dispatched > 0)); then
        m_line="SAVED $m_dispatched NEW MEMORIES JUST NOW · ${m_pct}% FULL"
    elif [ "$m_pending" = true ]; then
        m_line="REVIEW QUEUED, RUNS AT NEXT PAUSE · LAST REVIEW $m_age AGO"
    elif ((m_turns >= m_thresh)); then
        m_line="REVIEW DUE, WAITING FOR A QUIET MOMENT · LAST $m_age AGO"
    elif [ "$m_age" = never ]; then
        m_line="NO REVIEWS YET · FIRST ONE AFTER $m_thresh TURNS"
    else
        m_line="OK · REVIEWED $m_age AGO · NEXT IN $((m_thresh - m_turns)) TURNS · ${m_pct}% FULL"
    fi
    m_line=$(tr '[:lower:]' '[:upper:]' <<<"$m_line")
    [ ${#m_line} -gt 68 ] && m_line="${m_line:0:67}…"
    # %s carries the text so a literal "%" (e.g. "26% FULL") isn't eaten by printf.
    printf '🧠  %s%s%s\n' "$m_color" "$m_line" "$R"
fi
exit 0
