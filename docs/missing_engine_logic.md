# Inflection Engine Improvement Prompt

This document outlines the gaps between the inflection engine and the hand-curated seed data. Use this as a roadmap to improve the inflectors.

## Running Validation Tests

```bash
# Run inflector validation tests (excluded by default)
mix test --include inflector_validation test/ohmyword/linguistics/inflector_validation_test.exs

# Run all tests including validation
mix test --include inflector_validation
```

The tests compare engine output against `priv/repo/vocabulary_seed.json` which contains hand-verified forms.

---

## 1. NOUNS - Priority Issues

**File**: `lib/ohmyword/linguistics/nouns.ex`

### 1.1 Fleeting Vowel "A" - Edge Cases

**Current**: `remove_fleeting_a/3` (lines 275-315) handles basic cases.

**Problem**: Engine produces wrong forms for some consonant clusters.

| Word | Case | Expected | Engine Produces |
|------|------|----------|-----------------|
| pas | acc_pl | pse | pasa |

**Root Cause**: The accusative plural for animate masculine nouns should use the stem without fleeting-a + ending, not genitive plural form.

**Fix Location**: `generate_accusative/5` (lines 222-245) - the animate plural logic needs adjustment.

### 1.2 O-Stem Consonant Cluster Handling

**Problem**: "sto" (table) forms are completely wrong.

| Word | Case | Expected | Engine Produces |
|------|------|----------|-----------------|
| sto | gen_sg | stola | sta |
| sto | dat_sg | stolu | stu |
| sto | nom_pl | stolovi | sta |

**Root Cause**: The engine doesn't recognize that "sto" has an extended stem "stol-" for oblique cases. This is similar to e-stem extended stems but for o-stem nouns.

**Fix**: Add `extended_stem` support for o-stem nouns, or add metadata `"extended_stem" => "stol"` handling.

### 1.3 Palatalization in Vocative

**Problem**: "junak" vocative and plural forms have palatalization issues.

| Word | Case | Expected | Engine Produces |
|------|------|----------|-----------------|
| junak | voc_sg | junace | junače |
| junak | nom_pl | junaci | junakovi |

**Root Cause**:
1. Vocative uses wrong palatalization (č instead of c) - should be sibilarization k→c before -e
2. Plural incorrectly adds -ov- insert for words ending in -k with palatalization

**Fix Location**:
- `apply_vocative_palatalization/2` (lines 337-348) - needs sibilarization, not palatalization
- `get_plural_insert/2` (lines 322-335) - should return "" for palatalized stems

### 1.4 Irregular Plurals with Stem Changes

**Problem**: Words with `irregular_plural` metadata don't apply endings correctly.

| Word | Irregular Plural | Case | Expected | Engine Produces |
|------|------------------|------|----------|-----------------|
| čovek | ljudi | nom_pl | ljudi | ljudii |
| čovek | ljudi | gen_pl | ljudi | ljudia |
| dete | deca | nom_pl | deca | deta |

**Root Cause**: The irregular plural stem is used but regular endings are still applied. For suppletive plurals, the stem IS the complete form.

**Fix**: Add metadata flag `"irregular_plural_complete" => true` or detect when irregular_plural already contains the ending.

### 1.5 E-Stem Extended Stems

**Problem**: "dete" extended stem forms are wrong.

| Word | Case | Expected | Engine Produces |
|------|------|----------|-----------------|
| dete | gen_sg | deteta | deta |
| dete | ins_sg | detetom | detem |

**Root Cause**: Extended stem "et" should produce "detet-" not "det-".

**Fix Location**: `apply_extended_stem/3` (lines 161-179) - the stem building logic.

### 1.6 I-Stem Instrumental Singular

**Problem**: "ljubav" instrumental singular is wrong.

| Word | Case | Expected | Engine Produces |
|------|------|----------|-----------------|
| ljubav | ins_sg | ljubavlju | ljubavi |

**Root Cause**: I-stem feminine nouns ending in consonant + "v" have special instrumental: -vlju not -vi.

**Fix**: Add rule for -av/-ev endings in i-stem to use -lju instrumental.

---

## 2. VERBS - Priority Issues

**File**: `lib/ohmyword/linguistics/verbs.ex`

### 2.1 Present Stem Derivation

**Problem**: Many verbs derive wrong present stems.

| Verb | Class | Expected Stem | Engine Derives |
|------|-------|---------------|----------------|
| ići | irregular | id- | ič- |
| smejati se | a-verb | smej- | smeja- |

**Root Cause**:
- `derive_present_stem/2` doesn't handle -ći verbs
- A-verb derivation doesn't account for -jati verbs needing -j- stem

**Fix Location**: Lines 125-171 - add rules for:
1. -ći verbs: map to their present stems (ići→id, moći→mož, etc.)
2. -jati verbs: present stem keeps the -j- (smejati→smej, not smeja)

### 2.2 Irregular Verb: "biti" (to be)

**Problem**: Imperative forms are wrong.

| Form Tag | Expected | Engine Produces |
|----------|----------|-----------------|
| imp_2sg | budi | bii |
| imp_1pl | budimo | biimo |
| imp_2pl | budite | biite |

**Root Cause**: "biti" needs complete `irregular_forms` override for imperatives since the stem changes to "bud-".

**Fix**: The seed data should include these overrides, OR add special handling for auxiliary verbs.

### 2.3 Irregular Verb: "ići" (to go)

**Problem**: Almost all forms are wrong.

| Form Tag | Expected | Engine Produces |
|----------|----------|-----------------|
| pres_1sg | idem | idm |
| past_m_sg | išao | icio |

**Root Cause**:
- Present stem should be "ide-" (with vowel), not "id-"
- Past stem should be "iš-" (iotated), not "ici-"

**Fix**: Add to `grammar_metadata`:
```elixir
"present_stem" => "ide",
"past_stem" => "iš"
```
And implement `past_stem` support in `get_l_participle_stem/2`.

### 2.4 Reflexive Verb Stem Issues

**Problem**: "smejati se" conjugates as regular a-verb instead of je-verb pattern.

| Form Tag | Expected | Engine Produces |
|----------|----------|-----------------|
| pres_1sg | smejem se | smejam se |
| pres_3pl | smeju se | smejaju se |

**Root Cause**: The conjugation class is set to "a-verb" but the verb follows je-verb conjugation pattern.

**Fix**: Either:
1. Change `conjugation_class` to "je-verb" in seed data
2. Or detect -jati verbs and auto-switch to je-verb endings

### 2.5 Diacritic Handling in Forms

**Problem**: Engine produces forms with diacritics that seed data has without.

| Form Tag | Expected | Engine Produces |
|----------|----------|-----------------|
| pres_2sg (pisati) | pises | piseš |
| pres_2sg (govoriti) | govoris | govoriš |

**Root Cause**: Seed data uses ASCII-only (š→s, č→c, etc.) but engine applies proper Serbian orthography.

**Fix**: Either:
1. Normalize engine output to strip diacritics
2. Or update seed data to use proper diacritics

**Decision needed**: Which is the canonical form? Recommend using diacritics (engine is correct).

---

## 3. ADJECTIVES - Priority Issues

**File**: `lib/ohmyword/linguistics/adjectives.ex`

### 3.1 Comparative/Superlative Forms Missing

**Problem**: Engine doesn't generate comparative/superlative for adjectives without explicit stems.

| Word | Form Tag | Expected | Engine Status |
|------|----------|----------|---------------|
| lep | comp_nom_sg_m | lepši | MISSING |
| lep | super_nom_sg_m | najlepši | MISSING |

**Root Cause**: `maybe_generate_comparative_forms/3` requires `metadata["comparative_stem"]` to be set.

**Fix Options**:
1. Add `"comparative_stem" => "lepš"` to seed data
2. Or implement automatic comparative stem derivation rules:
   - Regular: stem + "ij" (star → starij → stariji)
   - Consonant mutation: p→pš, t→ć, k→č, etc. (lep → lepš → lepši)

### 3.2 Form Tag Mismatch with Seed

**Problem**: Seed uses simplified tags, engine uses full tags.

| Seed Tag | Engine Tag |
|----------|------------|
| indef_nom_sg_m | indef_nom_sg_m |
| def_nom_sg_m | def_nom_sg_m |
| comp_nom_sg_m | comp_nom_sg_m |

**Status**: Tags match! The issue is missing forms, not tag format.

### 3.3 Indeclinable Adjectives

**Problem**: "bez" (beige) should return single invariable form.

| Word | Expected Tag | Engine Produces |
|------|--------------|-----------------|
| bez | invariable | base |

**Root Cause**: Engine returns `"base"` tag, seed expects `"invariable"`.

**Fix**: In `Invariables.generate_forms/1`, return `"invariable"` tag for adjectives with `metadata["indeclinable"] == true`.

---

## 4. PRONOUNS - Priority Issues

**File**: `lib/ohmyword/linguistics/pronouns.ex`

### 4.1 Form Tag Suffix Mismatch

**Problem**: Personal pronouns use different tag format than seed expects.

| Word | Seed Tag | Engine Tag |
|------|----------|------------|
| ja | nom_sg | nom |
| ja | gen_sg | gen |
| ja | gen_sg_clitic | gen_clitic |

**Root Cause**: Engine uses simple case names (`nom`, `gen`) while seed uses `_sg` suffix (`nom_sg`, `gen_sg`).

**Fix Location**: `@personal_pronouns` map (lines 24-152) - add `_sg` suffix to all form tags.

```elixir
# Current
"ja" => [{"ja", "nom"}, {"mene", "gen"}, ...]
# Should be
"ja" => [{"ja", "nom_sg"}, {"mene", "gen_sg"}, ...]
```

### 4.2 Demonstrative Pronouns Incomplete

**Problem**: "ovaj" only generates 6 forms, seed has more.

| Seed has | Engine missing |
|----------|----------------|
| nom_sg_m, nom_sg_f, nom_sg_n | (has these) |
| gen_sg_m, gen_sg_f, gen_sg_n | (has these) |
| dat_sg_m, dat_sg_f, ... | MISSING |

**Root Cause**: Seed only includes partial forms, engine generates full paradigm. This may be intentional in seed.

**Fix**: Verify seed data completeness or adjust test to allow extras.

---

## 5. NUMERALS & OTHER - Priority Issues

**File**: `lib/ohmyword/linguistics/numerals.ex`

### 5.1 "dva" Form Tags

**Problem**: Tag format mismatch.

| Seed Tag | Engine Tag |
|----------|------------|
| nom_m | nom_m |
| nom_f | nom_f |
| gen | gen_m (and gen_f) |

**Root Cause**: Seed uses single `gen` tag, engine generates separate `gen_m` and `gen_f`.

**Fix**: Either simplify engine tags or expand seed data.

---

## Summary: Quick Wins vs. Larger Efforts

### Quick Wins (metadata/config changes):
1. Add `present_stem` to irregular verbs in seed
2. Add `comparative_stem` to adjectives in seed
3. Standardize diacritics (pick one approach)
4. Add `_sg` suffix to personal pronoun tags

### Medium Effort (code changes):
1. Fix accusative plural for animate nouns with fleeting-a
2. Fix vocative palatalization (use sibilarization)
3. Add -jati verb detection for je-verb conjugation
4. Fix i-stem instrumental -vlju rule

### Larger Effort (new features):
1. Implement extended stem for o-stem nouns (sto→stol-)
2. Implement automatic comparative stem derivation
3. Add `past_stem` support for verbs
4. Handle suppletive irregular plurals (ljudi, deca)

---

## Test-Driven Development Approach

1. Pick one issue from above
2. Run: `mix test --include inflector_validation`
3. Find the specific failing assertion
4. Implement the fix
5. Re-run tests to verify
6. Repeat

The validation tests will show exactly which forms are wrong, making it easy to verify fixes incrementally.
