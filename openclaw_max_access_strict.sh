#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

echo ""
echo "OpenClaw max practical access setup (strict, non-root)"
echo "============================================================"
echo ""

log_ok() { echo "[OK] $1"; }
log_warn() { echo "[WARN] $1"; }
die() { echo "[ERROR] $1"; exit 1; }

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
command -v shizuku >/dev/null 2>&1 || die "shizuku command not found. Configure Shizuku terminal integration first."
command -v rish >/dev/null 2>&1 || die "rish command not found. Export Shizuku terminal files and rerun."

shizuku
rish -c whoami >/dev/null 2>&1 || die "rish bridge is not active. Start Shizuku in the app and rerun."
log_ok "rish bridge is working"

echo ""
echo "Step 3/6: Improve background reliability for Termux"
rish -c "dumpsys deviceidle whitelist +com.termux"
rish -c "cmd appops set com.termux RUN_IN_BACKGROUND allow"
rish -c "cmd appops set com.termux RUN_ANY_IN_BACKGROUND allow"
rish -c "cmd appops set com.termux WAKE_LOCK allow"

echo ""
echo "Step 4/6: Grant media/storage permissions to Termux"
rish -c "pm grant com.termux android.permission.READ_EXTERNAL_STORAGE" || log_warn "READ_EXTERNAL_STORAGE grant failed"
rish -c "pm grant com.termux android.permission.WRITE_EXTERNAL_STORAGE" || log_warn "WRITE_EXTERNAL_STORAGE grant failed"
rish -c "pm grant com.termux android.permission.READ_MEDIA_IMAGES" || log_warn "READ_MEDIA_IMAGES grant failed"
rish -c "pm grant com.termux android.permission.READ_MEDIA_VIDEO" || log_warn "READ_MEDIA_VIDEO grant failed"
rish -c "pm grant com.termux android.permission.READ_MEDIA_AUDIO" || log_warn "READ_MEDIA_AUDIO grant failed"

echo ""
echo "Step 5/6: OpenClaw setup reminders"
echo "Run these after installing OpenClaw:"
echo "openclaw onboard"
echo "openclaw auth add google --key YOUR_GEMINI_KEY"
echo "openclaw gateway"

echo ""
echo "Step 6/6: Verification"
command -v openclaw >/dev/null 2>&1 && log_ok "openclaw command found" || log_warn "openclaw command not found"
rish -c id
rish -c "settings get global adb_wifi_enabled"

echo ""
echo "============================================================"
echo "Done"
echo "============================================================"
echo ""
echo "Notes:"
echo "- True full device control requires root."
echo "- This strict script fails fast if shizuku/rish are missing or inactive."
echo "- Some permission grants may still fail on certain Android versions."
