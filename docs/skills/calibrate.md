# calibrate

Tune the dedup similarity threshold by evaluating real memory pairs.

## When it runs

- **On demand:** `/xgh-calibrate`

## What it does

1. Samples memory pairs from lossless-claude
2. Presents pairs for evaluation (duplicate or not)
3. Computes F1 score across threshold values
4. Recommends optimal threshold

## Modes

- **Interactive** (default): Shows pairs, asks for your judgment
- **Headless**: Auto-evaluates using heuristics
- **Comparison**: Tests two thresholds side-by-side

## Configuration

- `calibration.sample_size`: Number of pairs to evaluate (default: 50)
- `calibration.auto_confidence_threshold`: Confidence level for headless mode (default: 0.9)
- Current threshold: `analyzer.dedup_threshold` in ingest.yaml (default: 0.85)
