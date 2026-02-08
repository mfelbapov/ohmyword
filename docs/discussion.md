# Agentic Word Creation for Serbian Inflection Engine

## Context

The Ohmyword app has a Serbian inflection engine that generates all grammatical forms for words. Currently, the vocabulary seed contains 521 words with hand-verified forms. The question: can Sonnet reliably generate new word entries with correct forms, and what's the best approach for an agentic workflow?

---

## Can Sonnet Generate Serbian Forms with Minimal Errors?

### Short Answer: Not for Direct Form Generation

LLMs (including Sonnet) are not reliable for generating complete inflection tables for morphologically rich languages like Serbian. The error rate would be too high for production use.

**Why LLMs struggle with Serbian inflection:**
1. **84 adjective forms, 24 verb forms, 14 noun forms** - many opportunities for errors
2. **Subtle phonological rules** - fleeting A, palatalization (k→č, g→ž), iotation
3. **Soft-stem detection** - affects ending selection (-eg vs -og in genitive)
4. **Diacritics** - consistent handling of č, ć, š, ž, đ
5. **Exception handling** - when to apply irregular_forms vs rely on rules

Even with careful prompting, expect 5-15% error rate on forms, which compounds across many words.

### What Sonnet CAN Do Well

1. **Classify word properties** - determine POS, gender, declension_class, conjugation_class
2. **Identify metadata flags** - fleeting_a, palatalization, soft_stem, animate
3. **Provide present_stem/past_stem** for verbs that need overrides
4. **Flag words as irregular** - recognize when a word doesn't follow patterns

---

## Recommended Architecture: LLM as Metadata Provider, Engine as Form Generator

```
┌─────────────────────────────────────────────────────────────────┐
│                        AGENTIC WORKFLOW                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   [User/Agent] ──▶ "Add word: kuća (house)"                    │
│                                                                 │
│   [Classifier Agent (Sonnet)]                                  │
│        │                                                        │
│        ├── Determines: noun, feminine, a-stem                  │
│        ├── Identifies: no special flags needed                 │
│        └── Outputs metadata JSON (NO forms)                    │
│                                                                 │
│   [Engine] ──▶ generate_forms(word_with_metadata)              │
│        │                                                        │
│        └── Returns 14 noun forms using a-stem rules            │
│                                                                 │
│   [Validator Agent (Sonnet)]                                   │
│        │                                                        │
│        ├── Reviews generated forms for obvious errors          │
│        ├── Flags uncertain cases for human review              │
│        └── Returns confidence score                            │
│                                                                 │
│   [Human Review Queue] ──▶ Low-confidence words flagged        │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Agent Roles

### 1. Classifier Agent (Primary)

**Input:** Word + translation + optional context
**Output:** Complete metadata JSON (no forms)

```json
{
  "term": "kuća",
  "translation": "house",
  "part_of_speech": "noun",
  "gender": "feminine",
  "declension_class": "a-stem",
  "animate": false,
  "proficiency_level": 1,
  "grammar_metadata": {}
}
```

**What this agent must determine by POS:**

| POS | Required Fields | Metadata Flags |
|-----|-----------------|----------------|
| Noun | gender, declension_class, animate | fleeting_a, palatalization, extended_stem, drops_in_plural, ins_ju, singularia/pluralia_tantum |
| Verb | conjugation_class, verb_aspect, reflexive | present_stem, past_stem, present_conjugation_class, auxiliary |
| Adjective | gender | fleeting_a, soft_stem, comparative_stem, superlative_stem, indeclinable, no_short_form |
| Pronoun | gender | pronoun_type |
| Numeral | gender | numeral_type, numeral_value |
| Others | - | comparative, superlative (for adverbs) |

**Prompting strategy:**
- Provide examples of each declension class/conjugation class
- Include decision tree for metadata flags
- Ask for reasoning before final answer

### 2. Validator Agent (Quality Control)

**Input:** Word metadata + engine-generated forms
**Output:** Validation result + confidence score

```json
{
  "valid": true,
  "confidence": 0.95,
  "issues": [],
  "needs_human_review": false
}
```

**Checks:**
- Forms look phonologically plausible
- No obvious typos or diacritic errors
- Endings match expected patterns for the class
- Special cases handled (vocative palatalization, etc.)

### 3. Irregular Handler Agent (Edge Cases)

**Input:** Word that classifier marked as irregular
**Output:** Complete irregular_forms map

This is the only agent that outputs actual forms. Used sparingly for:
- Suppletive forms (dobar → bolji)
- Historical irregulars (čovek → ljudi)
- Borrowed words with non-standard declension

---

## Alternative Approaches

### A. Human-in-the-Loop Batch Processing

1. Agent generates metadata for batch of words
2. Engine generates forms
3. Human reviews ALL forms in spreadsheet format
4. Corrections imported back

**Pros:** Highest accuracy
**Cons:** Slow, doesn't scale

### B. Confidence-Based Routing

1. Classifier assigns confidence to its metadata
2. High-confidence: auto-commit to seed
3. Medium-confidence: validator reviews
4. Low-confidence: human queue

**Thresholds:**
- \>0.9: Auto-approve
- 0.7-0.9: Validator review
- <0.7: Human review

### C. Test-Driven Validation

1. Require 3-5 sample forms with new word request
2. Agent generates full metadata
3. Engine generates all forms
4. Compare sample forms with engine output
5. Mismatches trigger investigation

```json
{
  "term": "pas",
  "translation": "dog",
  "sample_forms": {
    "gen_sg": "psa",
    "nom_pl": "psi",
    "voc_sg": "pse"
  }
}
```

If engine produces different forms → either metadata wrong or irregular_forms needed.

---

## Implementation Considerations

### Schema for Agent Output

Create a strict JSON schema that agents must follow:

```elixir
# lib/ohmyword/linguistics/schemas/word_metadata_schema.ex
defmodule Ohmyword.Linguistics.Schemas.WordMetadata do
  # Validate agent output before sending to engine
end
```

### Audit Trail

Track provenance of each word:

```elixir
%Word{
  source: :agent_generated,
  source_metadata: %{
    classifier_model: "claude-sonnet-4-20250514",
    classifier_confidence: 0.92,
    validator_model: "claude-sonnet-4-20250514",
    validator_confidence: 0.95,
    human_reviewed: false,
    created_at: ~U[2025-02-08 12:00:00Z]
  }
}
```

### Feedback Loop

When human corrects an agent's work:
1. Log the correction
2. Build regression test from correction
3. Periodically retrain/reprompt with failure cases

---

## Recommended Approach

**Phase 1: Semi-automated with high human oversight**
1. Classifier agent provides metadata
2. Engine generates forms
3. Human reviews ALL new words

**Phase 2: Confidence-based automation**
1. Add validator agent
2. Auto-approve high-confidence common patterns
3. Human reviews flagged items only

**Phase 3: Full automation for common cases**
1. Build regression test suite from Phase 1-2 corrections
2. Only route truly unusual words to humans
3. Periodic random audits

---

## Key Insight

The existing inflection engine is the core asset. It encodes correct Serbian grammar rules. The role of the LLM should be **classification and metadata extraction**, not form generation. This plays to LLM strengths (understanding context, identifying patterns) while avoiding weaknesses (precise rule application, consistency across many forms).

---

## Questions to Consider

1. What's the acceptable error rate for new words?
2. Who will perform human review? Native speaker required?
3. Should irregular words require human input always?
4. What volume of new words do you anticipate?
5. Should there be a "staging" table before words go live?

---

## Follow-up: App Feature vs Engine Development

**User Question:**
> So basically this would be useful if I wanted to implement AI in the app but not really useful in creating the engine.

**Answer:**

Correct. This agentic workflow is designed for **runtime word addition as an app feature** (users or admins adding new vocabulary through an AI-assisted interface), not for **developing or improving the inflection engine itself**.

For engine development, the workflow is fundamentally different:

| Aspect | App Feature (AI Word Addition) | Engine Development |
|--------|--------------------------------|-------------------|
| **Goal** | Add new words using existing rules | Create/fix the rules themselves |
| **LLM Role** | Classify words, provide metadata | Analyze patterns, suggest rule changes |
| **Validation** | Compare engine output to expectations | Compare engine output to linguistic references |
| **Error handling** | Flag word as irregular, add to irregular_forms | Fix the engine code |
| **Scale** | Many words, same rules | Few rule changes, affects many words |

**For engine development, better approaches:**

1. **Linguistic reference first** - Start with grammar books, not LLM output
2. **Test-driven development** - Write expected forms, then implement rules to match
3. **Pattern extraction** - Use existing seed data to identify missing patterns
4. **Edge case collection** - Gather irregular words, implement as patterns or irregular_forms

The engine's value is that it's deterministic and correct. LLMs can help you *understand* Serbian grammar or *identify* what pattern a word follows, but the engine rules should come from linguistic knowledge, not LLM generation.

---

## 2026-02-08

**Q:** That is a fair assessment. I am aware of hallucinations, but I am ready for this tradeoff.

**A:** Understood. Accepting the hallucination tradeoff is reasonable given the architecture we outlined — the key mitigations are already baked into the design:

1. **The engine is the safety net.** Even if the LLM misclassifies a word (wrong declension class, missing a fleeting_a flag), the engine will still produce *structurally valid* forms for whatever metadata it receives. The failure mode is "wrong but grammatically consistent" rather than random garbage.

2. **Errors are correctable.** A misclassified word can be fixed by updating its metadata in the seed file — you don't need to retrain anything. Fix the `declension_class` or add a `grammar_metadata` flag, and the engine regenerates all forms correctly.

3. **The blast radius is small.** Each word is independent. A hallucination on one word doesn't affect any other word's forms. Compare this to an engine rule bug, which could break dozens of words at once.

4. **You already have a validation baseline.** The 521 seed words with verified forms serve as a regression suite. Any new classifier prompt can be tested against known words first to gauge accuracy before being used on unknowns.

**Practical next step:** Start with a simple Classifier Agent prompt that takes a word + translation and outputs the seed JSON format. Test it against 20-30 known words from the seed to measure your actual error rate. If it's tolerable (and for metadata classification, it likely will be far better than for raw form generation), you have a working pipeline.

---

## 2026-02-08

**Q:** The argument is quite circular from my side, this is not a critical app and there will be human involved in all stages.

**A:** Fair point — and it cuts through a lot of the over-engineering in the earlier discussion. When you have:

- **A non-critical app** (language learning, not medical/financial)
- **A human in the loop at every stage** (you reviewing all output)

...then most of the validator agent, confidence scoring, staging tables, and audit trail machinery is unnecessary overhead. The simplest viable workflow is just:

1. **Ask the LLM** to generate the seed JSON entry for a word
2. **You review it** — does the metadata look right? Do the generated forms look right?
3. **Add it to the seed** if it passes your eye test
4. **Run the validation test** (`mix test --include inflector_validation`) as a final sanity check

That's it. No multi-agent pipeline, no confidence thresholds. You're the validator. The discussion above is useful as a reference for *what to look for* when reviewing (declension class, metadata flags, etc.), but the actual process can be as simple as a conversation with Claude.

The earlier architecture makes sense if you're building a self-service feature where *users* add words without your involvement. But for *you* growing the vocabulary — just use the LLM as an assistant and trust your own review.

---
