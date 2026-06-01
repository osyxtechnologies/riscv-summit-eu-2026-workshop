#!/usr/bin/env bash
# Bring up the workshop debug flow: start OpenOCD against the Genesys 2 / CVA6
# target, wait for it to be ready, then attach GDB and load the workshop images
# defined in the supplied GDB script.
#
# Usage:
#   cva6/launch.sh                          # uses cva6/baseline.gdb
#   cva6/launch.sh cva6/milestone1.gdb      # use a different GDB script
#
# Environment overrides:
#   OPENOCD_CFG    OpenOCD config         (default: cva6/ariane.cfg)
#   GDB            GDB binary             (default: riscv32-unknown-elf-gdb)
#   OPENOCD_PORT   GDB-server port        (default: 3333)
#   OPENOCD_LOG    OpenOCD output stream  (default: /tmp/openocd.log)
#   CVA6_UART      Primary CVA6 UART tty (default: /dev/ttyUSB0)
#   CVA6_UART2     Secondary CVA6 UART tty (default: unset). When set and the
#                  device exists, opens a 2nd minicom pane. The Makefile sets
#                  it only for milestone2 (baremetal on UART1); m0/m1 run a
#                  single console on UART0.

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"

OPENOCD_CFG="${OPENOCD_CFG:-$script_dir/ariane.cfg}"
GDB="${GDB:-riscv32-unknown-elf-gdb}"
OPENOCD_PORT="${OPENOCD_PORT:-3333}"
OPENOCD_LOG="${OPENOCD_LOG:-/tmp/openocd.log}"
CVA6_UART="${CVA6_UART:-/dev/ttyUSB0}"
CVA6_UART2="${CVA6_UART2:-}"

gdb_script="${1:-$script_dir/baseline.gdb}"

[[ -r $OPENOCD_CFG ]] || { echo "OpenOCD config not found: $OPENOCD_CFG" >&2; exit 1; }
[[ -r $gdb_script  ]] || { echo "GDB script not found: $gdb_script"    >&2; exit 1; }

echo "OpenOCD : $OPENOCD_CFG"
echo "GDB     : $GDB -x $gdb_script"
echo "Log     : $OPENOCD_LOG"

# Run from the repo root so the relative paths inside the GDB script resolve.
cd "$repo_root"

launch_error_file="$repo_root/.launch-error"
: > "$launch_error_file"

# Verify every file referenced by a GDB 'load' command exists before we
# start OpenOCD or open any console panes.
while IFS= read -r artifact; do
    if [[ ! -r "$artifact" ]]; then
        printf 'Build artifact not found: %s\nRun: make build PLATFORM=cva6 CONFIG=<milestone>\n' \
            "$artifact" | tee "$launch_error_file" >&2
        exit 1
    fi
done < <(grep -E '^\s*load\s' "$gdb_script" | awk '{print $2}')

: >"$OPENOCD_LOG"
openocd -f "$OPENOCD_CFG" >"$OPENOCD_LOG" 2>&1 &
openocd_pid=$!

cleanup() {
    if kill -0 "$openocd_pid" 2>/dev/null; then
        kill "$openocd_pid" 2>/dev/null || true
        wait "$openocd_pid" 2>/dev/null || true
    fi
}
trap cleanup EXIT INT TERM

ready_msg="Listening on port $OPENOCD_PORT for gdb connections"
deadline=$((SECONDS + 30))
while (( SECONDS < deadline )); do
    if grep -qF "$ready_msg" "$OPENOCD_LOG"; then
        break
    fi
    if ! kill -0 "$openocd_pid" 2>/dev/null; then
        printf 'OpenOCD exited before becoming ready.\nSee %s for details.\nReset the FPGA and re-run.\n' \
            "$OPENOCD_LOG" | tee "$launch_error_file" >&2
        tail -n 10 "$OPENOCD_LOG" >&2
        exit 1
    fi
    sleep 0.3
done

if ! grep -qF "$ready_msg" "$OPENOCD_LOG"; then
    printf 'OpenOCD did not become ready within 30s.\nSee %s for details.\nReset the FPGA and re-run.\n' \
        "$OPENOCD_LOG" | tee "$launch_error_file" >&2
    tail -n 10 "$OPENOCD_LOG" >&2
    exit 1
fi

if [ -n "$TMUX" ]; then
    cleanup_done=0

    # GDB loads the firmware in batch mode. On failure: write the error,
    # kill all minicom panes, and close the window (the host bash -c then
    # prints the error from .launch-error).
    (
        "$GDB" --batch -x "$gdb_script" </dev/null >>/tmp/gdb.log 2>&1
        rc=$?
        if [[ $rc -ne 0 ]]; then
            printf 'GDB failed (rc=%d); see /tmp/gdb.log\nMake sure the config is built: make build PLATFORM=cva6 CONFIG=<milestone>\nThen reset the FPGA and re-run.\n' \
                "$rc" > "$launch_error_file"
            pkill -x minicom 2>/dev/null || true
            tmux kill-window 2>/dev/null || true
        fi
    ) &
    gdb_wrapper=$!

    # Watchdog: tear everything down if OpenOCD dies unexpectedly.
    (
        while kill -0 "$openocd_pid" 2>/dev/null; do sleep 0.5; done
        printf 'OpenOCD crashed; see %s\nPlease reset the FPGA and re-run.\n' \
            "$OPENOCD_LOG" > "$launch_error_file"
        pkill -x minicom 2>/dev/null || true
        tmux kill-window 2>/dev/null || true
    ) &
    openocd_watchdog=$!

    # Cleanup for signals / errors that fire BEFORE exec (or in the no-UART
    # path where exec never runs).
    cleanup() {
        [[ $cleanup_done -eq 1 ]] && return; cleanup_done=1
        pkill -x minicom 2>/dev/null || true
        sleep 0.3
        kill "$openocd_watchdog" 2>/dev/null || true
        kill "$gdb_wrapper" 2>/dev/null || true
        wait "$gdb_wrapper" 2>/dev/null || true
        if kill -0 "$openocd_pid" 2>/dev/null; then
            kill "$openocd_pid" 2>/dev/null || true
            wait "$openocd_pid" 2>/dev/null || true
        fi
        tmux kill-window 2>/dev/null || true
    }
    trap cleanup EXIT INT TERM

    if [ -e "$CVA6_UART" ]; then
        # UART1 - split to the RIGHT (no -b) so UART0 (OpenSBI + main guest)
        # stays on the left in the exec'd pane and UART1 (baremetal) is on the
        # right.
        if [ -n "$CVA6_UART2" ] && [ -e "$CVA6_UART2" ]; then
            tmux split-window -h \
                "clear; minicom -b 115200 -c on -o -D '$CVA6_UART2'; pkill -x minicom 2>/dev/null || true" || true
        fi

        # UART0 - exec into the main pane so minicom directly owns the PTY.
        # Running minicom as a background job sharing a PTY fails with
        # "No cursor motion capability"; exec avoids that by replacing bash.
        # After minicom exits: kill any remaining UART1 pane and close the window.
        clear
        exec bash -c "minicom -b 115200 -c on -o -D '$CVA6_UART'; pkill -x minicom 2>/dev/null || true; tmux kill-window 2>/dev/null || true"
    else
        # No UART device in the container - hold the session alive.
        printf 'Note: %s not found in container - no UART console.\n' "$CVA6_UART" \
            | tee "$launch_error_file" >&2
        printf 'Target is running. Press Ctrl-C to stop.\n'
        while kill -0 "$openocd_pid" 2>/dev/null; do sleep 1; done
    fi
else
    "$GDB" -x "$gdb_script"
fi
