---
name: prediction-market-oracle-research
description: Nghiên cứu prediction market như nguồn dữ liệu hoặc tín hiệu oracle cho sản phẩm, agent, dashboard và thông tin hỗ trợ ra quyết định của doanh nghiệp. Dùng cho phân tích có căn cứ nguồn về xác suất hàm ý từ thị trường, các lưu ý và pattern tích hợp mà không đưa ra lời khuyên đầu tư. Dùng khi đánh giá prediction market làm nguồn dữ liệu hoặc tín hiệu oracle cho một sản phẩm, agent hoặc dashboard.
metadata:
  origin: ECC
---

# Prediction Market Oracle Research

Use this skill when prediction markets are being considered as a data source,
forecasting input, oracle-like signal, or decision-intelligence layer.

## Guardrails

- Do not treat market prices as objective truth.
- Do not provide investment advice or trading recommendations.
- Separate venue mechanics, liquidity, incentives, and resolution rules from the
  implied signal.
- Call out manipulation, thin liquidity, stale markets, and ambiguous outcomes.
- For on-chain or execution-linked systems, run `llm-trading-agent-security`
  before granting any write authority.

## Research Workflow

1. Define the decision the signal is meant to inform.
2. Find relevant markets, events, tags, and venues.
3. Record market-implied probabilities with timestamps and source links.
4. Evaluate signal quality:
   - liquidity
   - spread
   - market age
   - trader/incentive concentration if known
   - resolution authority
   - geography or account restrictions
5. Compare against non-market sources such as filings, news, polls, research,
   customer data, or internal KPIs.
6. Recommend whether the signal is usable, weak, or unsuitable for the stated
   decision.

## Integration Patterns

- Research assistant: source-grounded context for a human analyst.
- Dashboard signal: market-implied probability alongside internal metrics.
- Agent memory input: a time-stamped signal that can be retrieved later.
- Alerting input: notify when probabilities, spreads, or liquidity cross a
  threshold.
- Scenario planning: compare multiple event outcomes without automating trades.

## Output Contract

Use:

1. decision context
2. market sources
3. signal quality
4. comparison sources
5. integration recommendation
6. caveats

End with:

```text
Prediction-market signals are informational inputs, not investment advice.
```
