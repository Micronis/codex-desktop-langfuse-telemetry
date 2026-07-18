# Runbook: Weekly PVC growth check

```bash
kubectl get pvc -A
kubectl -n langfuse get pvc
kubectl -n agent-observability get pvc

# If metrics-server is available:
kubectl top nodes
kubectl top pods -n langfuse
kubectl top pods -n agent-observability
```

Retention targets: Loki **7 days**, Langfuse **14 days**. Reassess after measuring disk growth (SPEC §3).

If Docker Desktop disk is constrained, purge or shorten retention before enabling content capture.
