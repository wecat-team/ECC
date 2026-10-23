---
name: enterprise-agent-ops
description: Các biện pháp kiểm soát vận hành cho hệ thống agent chạy lâu dài hoặc host trên cloud — vòng đời runtime (start, pause, stop, restart), observability (log, metric, trace), phạm vi an toàn theo least-privilege và kill switch, và quản lý thay đổi rollout/rollback với audit log cùng metric thành công/chi phí. Dùng khi chạy đội agent production trên PM2, systemd hoặc container cần monitoring, ứng phó sự cố hoặc deployment gate.
metadata:
  origin: ECC
---

# Enterprise Agent Ops

Use this skill for cloud-hosted or continuously running agent systems that need operational controls beyond single CLI sessions.

## Operational Domains

1. runtime lifecycle (start, pause, stop, restart)
2. observability (logs, metrics, traces)
3. safety controls (scopes, permissions, kill switches)
4. change management (rollout, rollback, audit)

## Baseline Controls

- immutable deployment artifacts
- least-privilege credentials
- environment-level secret injection
- hard timeout and retry budgets
- audit log for high-risk actions

## Metrics to Track

- success rate
- mean retries per task
- time to recovery
- cost per successful task
- failure class distribution

## Incident Pattern

When failure spikes:
1. freeze new rollout
2. capture representative traces
3. isolate failing route
4. patch with smallest safe change
5. run regression + security checks
6. resume gradually

## Deployment Integrations

This skill pairs with:
- PM2 workflows
- systemd services
- container orchestrators
- CI/CD gates
