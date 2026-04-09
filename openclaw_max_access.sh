#!/data/data/com.termux/files/usr/bin/bash
set +e

echo ""
echo "OpenClaw max practical access setup (non-root)"
echo "============================================================"
echo ""

log_ok() { echo "[OK] $1"; }
log_warn() { echo "[WARN] $1"; }

run_step() {
  echo ""
  echo "-> $1"
  shift
  "$@"
  rc=$?
  if [ $rc -eq 0 ]; then
    log_ok "$1"
  else
    log_warn "$1 (exit $rc)"
  fi
}

echo "Step 1/6: Update package index and install dependencies"
pkg update -y
pkg install -y android-tools nmap termux-api curl which

if [ ! -d "$HOME/storage" ]; then
  echo ""
  echo "Termux storage permission prompt may appear now."
  echo "Please allow access if prompted."
  termux-setup-storage
fi

echo ""
echo "Step 2/6: Check Shizuku bridge"
if command -v shizuku >/dev/null 2>&1; then
  shizuku
else
  log_warn "shizuku command not found. Install or configure Shizuku terminal integration first."
fi

if command -v rish >/dev/null 2>&1; then
  rish -c whoami >/dev/null 2>&1
  if [ $? -eq 0 ]; then
    log_ok "rish bridge is working"
  else
    log_warn "rish bridge is not active yet"
  fi
else
  log_warn "rish command not found"
fi

echo ""
echo "Step 3/6: Improve background reliability for Termux (best effort)"
if command -v rish >/dev/null 2>&1; then
  rish -c "dumpsys deviceidle whitelist +com.termux"
  rish -c "cmd appops set com.termux RUN_IN_BACKGROUND allow"
  rish -c "cmd appops set com.termux RUN_ANY_IN_BACKGROUND allow"
  rish -c "cmd appops set com.termux WAKE_LOCK allow"
else
  log_warn "Skipping rish-only background tuning"
fi

echo ""
echo "Step 4/6: Grant media/storage permissions to Termux (best effort)"
if command -v rish >/dev/null 2>&1; then
  rish -c "pm grant com.termux android.permission.READ_EXTERNAL_STORAGE" || true
  rish -c "pm grant com.termux android.permission.WRITE_EXTERNAL_STORAGE" || true
  rish -c "pm grant com.termux android.permission.READ_MEDIA_IMAGES" || true
  rish -c "pm grant com.termux android.permission.READ_MEDIA_VIDEO" || true
  rish -c "pm grant com.termux android.permission.READ_MEDIA_AUDIO" || true
else
  log_warn "Skipping rish-only permission grants"
fi

echo ""
echo "Step 5/6: OpenClaw setup reminders"
echo "Run these after installing OpenClaw:"
echo "openclaw onboard"
echo "openclaw auth add google --key YOUR_GEMINI_KEY"
echo "openclaw gateway"

echo ""
echo "Step 6/6: Verification"
command -v openclaw >/dev/null 2>&1 && log_ok "openclaw command found" || log_warn "openclaw command not found"
if command -v rish >/dev/null 2>&1; then
  rish -c id || true
  rish -c "settings get global adb_wifi_enabled" || true
fi

echo ""
echo "============================================================"
echo "Done"
echo "============================================================"
echo ""
echo "Notes:"
echo "- True full device control requires root."
echo "- This script applies the maximum practical non-root setup."
echo "- If a grant fails, continue using rish -c for privileged shell actions."
