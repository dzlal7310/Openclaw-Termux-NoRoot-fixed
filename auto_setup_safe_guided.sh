#!/data/data/com.termux/files/usr/bin/bash
# ========================================================================
# CloudBot + Shizuku safer installer (guided)
# ========================================================================
# This variant intentionally avoids:
# 1) Piping or executing remote scripts
# 2) Overwriting OpenClaw workspace identity/tool/agent files
# 3) Auto-injecting broad phone control wrappers
#
# Review this file before running.
# ========================================================================

export DEBIAN_FRONTEND=noninteractive
export DPKG_FORCE=confold
export APT_LISTCHANGES_FRONTEND=none
export LANG=C
export LC_ALL=C

echo ""
echo "CloudBot safer setup (guided)"
echo "============================================================"
echo ""

# ========================================================================
# Step 1/4: Update packages and install dependencies
# ========================================================================
echo "[1/4] Updating packages and installing dependencies..."

pkg update -y -o Dpkg::Options::="--force-confold" -o Dpkg::Options::="--force-confdef" </dev/null 2>&1 || {
    echo "WARN: pkg update had warnings; continuing."
}

pkg install -y curl nodejs git cmake make clang binutils nmap openssl android-tools which </dev/null 2>&1 || {
    echo "WARN: Some packages may have failed; checking essentials."
}

MISSING=""
for cmd in curl node git nmap adb; do
    if ! command -v "$cmd" </dev/null >/dev/null 2>&1; then
        MISSING="$MISSING $cmd"
    fi
done

if [ -n "$MISSING" ]; then
    echo "ERROR: Missing critical commands:$MISSING"
    echo "Try: pkg install -y curl nodejs git nmap android-tools"
    exit 1
fi

echo "OK: dependencies installed"

# ========================================================================
# Step 2/4: Setup Shizuku terminal helper scripts (rish, shizuku)
# ========================================================================
echo ""
echo "[2/4] Linking Shizuku to Termux..."

if [ ! -d "$HOME/storage" ]; then
    echo "Termux storage permission may prompt now; tap Allow."
    echo "y" | termux-setup-storage >/dev/null 2>&1 || true
    sleep 3
else
    echo "Storage access already configured."
fi

SHIZUKU_DIR="$HOME/storage/shared/Shizuku"
mkdir -p "$SHIZUKU_DIR" 2>/dev/null || true

cat > "$SHIZUKU_DIR/copy.sh" << 'SHIZUKU_EOF'
#!/data/data/com.termux/files/usr/bin/bash

BASEDIR=$( dirname "${0}" )
BIN=/data/data/com.termux/files/usr/bin
HOME=/data/data/com.termux/files/home
DEX="${BASEDIR}/rish_shizuku.dex"

if [ ! -f "${DEX}" ]; then
  echo "Cannot find ${DEX}"
  exit 1
fi

ARCH=$(getprop ro.product.cpu.abi 2>/dev/null || echo "arm64-v8a")
case "$ARCH" in
  arm64*) LIB_ARCH="arm64" ;;
  armeabi*) LIB_ARCH="arm" ;;
  x86_64*) LIB_ARCH="x86_64" ;;
  x86*) LIB_ARCH="x86" ;;
  *) LIB_ARCH="arm64" ;;
esac

tee "${BIN}/shizuku" > /dev/null << EOF
#!/data/data/com.termux/files/usr/bin/bash

ports=\$( nmap -sT -p30000-50000 --open localhost 2>/dev/null | grep "open" | cut -f1 -d/ )

for port in \${ports}; do
  result=\$( adb connect "localhost:\${port}" 2>/dev/null )
  if [[ "\$result" =~ "connected" || "\$result" =~ "already" ]]; then
    echo "\${result}"
    adb shell "\$( adb shell pm path moe.shizuku.privileged.api | sed 's/^package://;s/base\\\\.apk/lib\\\\/${LIB_ARCH}\\\\/libshizuku\\\\.so/' )"
    adb shell settings put global adb_wifi_enabled 0
    exit 0
  fi
done

echo "ERROR: No port found. Is wireless debugging enabled?"
exit 1
EOF

dex="${HOME}/rish_shizuku.dex"

tee "${BIN}/rish" > /dev/null << EOF
#!/data/data/com.termux/files/usr/bin/bash

[ -z "\$RISH_APPLICATION_ID" ] && export RISH_APPLICATION_ID="com.termux"
/system/bin/app_process -Djava.class.path="${dex}" /system/bin --nice-name=rish rikka.shizuku.shell.ShizukuShellLoader "\${@}"
EOF

chmod +x "${BIN}/shizuku" "${BIN}/rish"
cp -f "${DEX}" "${dex}"
chmod -w "${dex}"
SHIZUKU_EOF

chmod +x "$SHIZUKU_DIR/copy.sh"

if [ ! -f "$SHIZUKU_DIR/rish_shizuku.dex" ]; then
    echo "ERROR: rish_shizuku.dex not found in $SHIZUKU_DIR"
    echo ""
    echo "Fix steps:"
    echo "1) Open Shizuku app"
    echo "2) Tap 'Use Shizuku in terminal apps'"
    echo "3) Tap 'Export files'"
    echo "4) Select Internal Storage/Shizuku"
    echo "5) Run this script again"
    exit 1
fi

bash "$SHIZUKU_DIR/copy.sh" </dev/null && {
    echo "OK: rish and shizuku commands installed"
} || {
    echo "WARN: copy.sh had issues; scripts may still be present"
}

# ========================================================================
# Step 3/4: Apply Node.js IPv4 DNS fix for Termux
# ========================================================================
echo ""
echo "[3/4] Applying Node.js IPv4 DNS fix..."

if ! grep -q "NODE_OPTIONS=--dns-result-order=ipv4first" ~/.bashrc 2>/dev/null; then
    echo "export NODE_OPTIONS=--dns-result-order=ipv4first" >> ~/.bashrc
fi

export NODE_OPTIONS=--dns-result-order=ipv4first
echo "OK: IPv4 DNS fix applied"

# ========================================================================
# Step 4/4: Guided manual OpenClaw install (no auto execution)
# ========================================================================
echo ""
echo "[4/4] OpenClaw install guidance (manual, no remote execution)"
echo ""
echo "To keep this installer safe, OpenClaw is NOT auto-installed."
echo "Use trusted docs and run only commands you verify first."
echo ""
echo "Suggested checks before install:"
echo "1) Confirm command source and domain authenticity"
echo "2) Download script to file first, inspect it, then run from file"
echo "3) Avoid piping network output directly to bash"
echo ""
echo "After manual OpenClaw install, recommended setup:"
echo "1) openclaw onboard"
echo "2) openclaw auth add google --key YOUR_GEMINI_KEY"
echo "3) openclaw gateway"

echo ""
echo "============================================================"
echo "GUIDED SAFE SETUP COMPLETE"
echo "============================================================"
echo ""
echo "What was intentionally skipped:"
echo "- Remote OpenClaw install command from external domain"
echo "- OpenClaw workspace identity/tools/agents file overrides"
echo "- Phone automation wrapper script injection"
echo ""
echo "Manual next steps (optional):"
echo "1) Verify Shizuku: shizuku"
echo "2) Verify shell bridge: rish -c whoami"
echo "3) If needed, install OpenClaw manually from trusted instructions"
echo ""
