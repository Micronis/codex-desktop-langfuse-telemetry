# Runbook: Safe PVC purge (desktop-local)

Telemetry data in `desktop-local` is disposable. Do **not** delete PVCs during normal Helm upgrades.

## When to purge

- Disk pressure from ClickHouse / Loki growth
- Explicit wipe after content-capture experiments
- Fresh start after failed Phase 1 install

## Steps

1. Stop ChatGPT desktop monitoring and drain exporters.
2. `helm uninstall` the affected release(s).
3. Confirm no pods still mounting the PVC: `kubectl get pod -A -o wide`.
4. Delete PVCs in the target namespace only.
5. Reinstall from `scripts/install-desktop-local.sh`.

## Weekly capacity check

See [weekly-capacity-check.md](weekly-capacity-check.md).
