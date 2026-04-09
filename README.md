# Openclaw-Termux-NoRoot-fixed

Safer and guided Termux plus Shizuku setup assets for OpenClaw-style Android automation.

This repository focuses on reviewable scripts that avoid direct remote code execution and avoid overwriting OpenClaw agent identity files automatically.

## Included Files

- `auto_setup_safe.sh`: trimmed setup script that keeps dependency and Shizuku setup while skipping remote installer execution and AI override writes.
- `auto_setup_safe_guided.sh`: safe setup plus explicit manual OpenClaw installation guidance.
- `auto_setup_compare.html`: side-by-side comparison of the safe and guided setup variants.
- `openclaw_max_access.sh`: one-command best-effort non-root access setup for Termux plus Shizuku.
- `openclaw_max_access_strict.sh`: strict fail-fast access setup script that exits if Shizuku or rish are not ready.
- `openclaw_max_access_steps.txt`: manual checklist for maximum practical non-root access.
- `openclaw_max_access_run_guide.txt`: quick run instructions for Termux.

## Safety Model

- No `curl | bash` execution path is included.
- No automatic rewrite of OpenClaw workspace identity, tools, or agent instruction files is included.
- Scripts are intended to be inspected before use on-device.
- True full device control still requires root.

## Recommended Starting Point

If you want the safer guided setup:

```bash
chmod +x auto_setup_safe_guided.sh
bash auto_setup_safe_guided.sh
```

If you want the stricter Shizuku verification path:

```bash
chmod +x openclaw_max_access_strict.sh
bash openclaw_max_access_strict.sh
```

## Requirements

- Android device with Termux installed
- Shizuku installed and running
- Shizuku terminal integration exported so `rish` and `shizuku` are available in Termux

## Notes

- Some permission grants are Android-version dependent and may fail harmlessly.
- When permission grants fail, `rish -c` can still be used for many privileged shell actions.

## License

MIT