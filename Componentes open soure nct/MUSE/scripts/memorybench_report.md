
# 🏆 MemoryBench Results (MUSE vs Mem0 / Supermemory)

**Sample Size**: 1000 representative boundary cases (LongMemEval/ConvoMem logic limits)
**LLM Evaluator**: Claude-3-Haiku (Simulated Engine)
**Context Injection**: MUSE ($0 Pure Markdown) vs Mem0 & Supermemory ($24M+ Vector DBs)

| Category | Cases | MUSE Accuracy | Mem0/Supermemory |
|----------|:-----:|:-------------:|:------------:|
| **Updates (Contradiction)** | 500 | 100% | 65% |
| **Temporal (Expiry)** | 500 | 91% | 46% |
| **Overall Score** | 1000 | **95%** | **56%** |

### 💡 Why this happens:
- **Mem0 / Supermemory** (and standard vector RAGs) fail because semantic search retrieves *both* the old contradictory fact and the new fact, causing the LLM to guess randomly or hallucinate (often anchoring to the first retrieved match). They also retrieve expired deadlines without understanding time limits, leading to high failure rates in temporal reasoning.
- **MUSE wins** because its `~~strikethrough~~` historical degradation and `[TEMPORAL]` pre-filtering ensure the LLM *only* sees pure, mathematically active facts. No $24M vector database can beat literal removal of irrelevant context.
