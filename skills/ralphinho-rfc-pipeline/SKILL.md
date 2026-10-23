---
name: ralphinho-rfc-pipeline
description: Chia một RFC thành DAG thực thi đa agent — phân rã thành các đơn vị công việc có dependency và acceptance test, chạy nghiên cứu, lập kế hoạch, triển khai, test và review cho từng đơn vị, rồi merge qua một hàng đợi với các branch đã rebase và xác minh toàn hệ thống cuối cùng. Dùng khi một tính năng quá lớn cho một lượt agent đơn lẻ, khi điều phối thực thi đa agent dựa trên RFC, hoặc khi quản lý merge queue giữa các đơn vị do agent xây dựng.
metadata:
  origin: ECC
---

# Ralphinho RFC Pipeline

Inspired by [humanplane](https://github.com/humanplane) style RFC decomposition patterns and multi-unit orchestration workflows.

Use this skill when a feature is too large for a single agent pass and must be split into independently verifiable work units.

## Pipeline Stages

1. RFC intake
2. DAG decomposition
3. Unit assignment
4. Unit implementation
5. Unit validation
6. Merge queue and integration
7. Final system verification

## Unit Spec Template

Each work unit should include:
- `id`
- `depends_on`
- `scope`
- `acceptance_tests`
- `risk_level`
- `rollback_plan`

## Complexity Tiers

- Tier 1: isolated file edits, deterministic tests
- Tier 2: multi-file behavior changes, moderate integration risk
- Tier 3: schema/auth/perf/security changes

## Quality Pipeline per Unit

1. research
2. implementation plan
3. implementation
4. tests
5. review
6. merge-ready report

## Merge Queue Rules

- Never merge a unit with unresolved dependency failures.
- Always rebase unit branches on latest integration branch.
- Re-run integration tests after each queued merge.

## Recovery

If a unit stalls:
- evict from active queue
- snapshot findings
- regenerate narrowed unit scope
- retry with updated constraints

## Outputs

- RFC execution log
- unit scorecards
- dependency graph snapshot
- integration risk summary
