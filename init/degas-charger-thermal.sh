#!/vendor/bin/sh
# SPDX-License-Identifier: Apache-2.0
# Select factory profiles; mi_thermald continues to own all thermal limits.

THERMAL_MESSAGE=/sys/class/thermal/thermal_message
USB_ONLINE=/sys/class/power_supply/usb/online

choose_thermal_scenario() {
    case "$1:$2" in
        0:*) echo 6 ;;     # Keep the existing battery-powered CPU profile.
        1:0) echo 27 ;;    # Factory charge profile, panel off (including AOD).
        *) echo 0 ;;       # Factory normal profile for screen on or unknown input.
    esac
}

apply_thermal_scenario() {
    charging=$(cat "$USB_ONLINE" 2>/dev/null) || charging=unknown
    screen=$(cat "$THERMAL_MESSAGE/screen_state" 2>/dev/null) || screen=unknown
    scenario=$(choose_thermal_scenario "$charging" "$screen")
    current=$(cat "$THERMAL_MESSAGE/sconfig" 2>/dev/null) || current=unknown
    if [ "$current" != "$scenario" ] || [ "$1" = 1 ]; then
        if echo "$scenario" > "$THERMAL_MESSAGE/sconfig"; then
            echo "degas-charger-thermal: usb=$charging screen=$screen scenario=$scenario"
        else
            echo "degas-charger-thermal: cannot write sconfig" >&2
            return 1
        fi
    fi
}

run_thermal_policy() {
    # The daemon installs its inotify watch after loading sensors/devices.
    # Reassert during startup, including mi_thermald restarts. A sysfs value
    # alone cannot prove that the daemon has received the profile event.
    startup_polls=12
    while true; do
        sleep 5
        force=0
        if [ "$startup_polls" -gt 0 ]; then
            force=1
            startup_polls=$((startup_polls - 1))
        fi
        apply_thermal_scenario "$force"
    done
}

# Used only by offline tests to source the actual policy functions.
if [ "${DEGAS_CHARGER_THERMAL_LIBRARY:-0}" != 1 ]; then
    run_thermal_policy
fi
