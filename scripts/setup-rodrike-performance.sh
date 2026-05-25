#!/bin/bash

set -e

echo "======================================"
echo " Rodrike Performance"
echo "======================================"
echo

sudo pacman -S --needed power-profiles-daemon
sudo systemctl enable --now power-profiles-daemon

sudo tee /usr/local/bin/rodrike-performance >/dev/null <<'EOF'
#!/usr/bin/env bash

if [ "$#" -eq 0 ]; then
    echo "Uso: rodrike-performance <comando>"
    exit 1
fi

if ! command -v powerprofilesctl >/dev/null 2>&1; then
    exec "$@"
fi

if ! powerprofilesctl list | grep -q "performance:"; then
    exec "$@"
fi

old_profile="$(powerprofilesctl get 2>/dev/null || true)"

powerprofilesctl set performance 2>/dev/null || true

"$@"
exit_code=$?

if [ -n "$old_profile" ]; then
    powerprofilesctl set "$old_profile" 2>/dev/null || true
fi

exit "$exit_code"
EOF

sudo chmod +x /usr/local/bin/rodrike-performance

echo
echo "Rodrike Performance instalado."
echo "Uso en Steam:"
echo "  rodrike-performance %command%"

