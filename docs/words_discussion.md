# Seed vs Engine Discrepancy Analysis

This document explains why the `validate_existing_words` audit flagged certain words. The audit compared seed forms (hand-authored in `vocabulary_seed.json`) against engine-generated forms and flagged every mismatch.

## Categories of Discrepancies

### 1. Verbs: Engine generates 24 forms, seed had 16 (~30 verbs)

Every verb was flagged because the seed originally only included 16 forms (inf + 6 present + 6 L-participle + 3 imperative). The engine was later expanded to also generate passive participles (6 forms) and adverbial participles (2 forms).

**Status:** Expected. The seed simply had fewer forms. No action needed beyond optionally backfilling the seed.

### 2. Adjectives: Seed has 4-10 forms, engine has 84-168 (~10 adjectives)

Adjectives like `crn`, `dobar`, `jak`, `lep`, `mlad`, `nov`, `star`, `velik`, `dug`, `beo`, `loš`, `mali`, `sam`, `sretan`.

The seed stored only citation forms (a few nominatives). The engine generates the full paradigm: 7 cases x 3 genders x 2 numbers x 2 definiteness = 84 positive forms, plus 42 comparative + 42 superlative = up to 168 total.

**Status:** Expected. The engine is doing its job.

### 3. Ordinal numerals: Seed has 5 forms, engine has 42 (~15 numerals)

All ordinals (prvi through devetnaesti) show the same pattern. Ordinals decline like adjectives, so the engine generates the full declension. The seed had citation forms only.

**Status:** Expected.

### 4. Pronouns: Seed has 6-9 forms, engine has 7-62

- Personal pronouns (ja, ti, on, ona, mi): engine adds alt instrumental forms, clitic forms, vocative
- Possessive (moj): 7 seed -> 62 engine (full declension across genders/numbers/cases + alt forms)
- Demonstrative (ovaj, taj): 6 seed -> 42 engine
- Interrogative (ko, sta): engine adds alt forms

**Status:** Expected. The engine generates complete paradigms including alternative/clitic forms.

### 5. Nouns: Seed missing plural forms (kosa, ljubav)

- `kosa`: seed has 6 (singular only), engine adds 8 plural forms
- `ljubav`: seed has 7 (singular only), engine adds 7 plural forms

**Status:** Minor. These nouns do have plurals; the seed was authored as if they were singularia tantum.

### 6. Tag mismatch (ajde)

Initially reported as a mismatch, but on investigation the engine correctly generates "invariable" for interjections, matching the seed. No actual bug.

**Status:** False alarm. No fix needed.

## Actual Bugs Found and Fixed

While the mismatches themselves were mostly harmless, the audit revealed real bugs in the forms the engine generated:

### Bug 1: I-verb passive participles lacked iotation (FIXED)

The engine was using the full infinitive stem (e.g., `govori` from `govoriti`) for iotation, but the trailing vowel meant iotation had no effect, producing wrong forms like `govorien` instead of `govoren`.

**Root cause:** `get_infinitive_stem` removes `-ti` but not the preceding vowel (`-i` from `-iti`, `-e` from `-eti`). The passive participle code needed to strip this vowel before applying iotation.

**Fix:** Strip trailing vowel from infinitive stem, then apply iotation with cluster support.

Examples of corrected forms:
- govoriti: govorien → govoren
- nositi: nosien → nošen
- baciti: bacien → bačen (also required adding c→č to iotation rules)
- raditi: radien → rađen
- videti: videen → viđen
- misliti: mislien → mišljen (cluster sl→šlj)
- pustiti: pustien → pušten (cluster st→št)

### Bug 2: E-verb passive participles (same root cause as Bug 1)

Verbs like videti, voleti, zeleti, ziveti are classified as i-verbs despite ending in `-eti`. They had the same trailing vowel issue. Fixed by the same change.

### Bug 3: Passive participles for intransitive/modal verbs (FIXED)

Verbs like biti, ici, moci, hteti, morati, bojati se, spavati, trcati generated nonsensical passive participles (e.g., biti -> `bin`, ici -> `in`).

**Fix:** Added `no_passive_participle` metadata flag. When set, passive participle generation is skipped (18 forms instead of 24). Applied to 14 verbs in the seed.

### Bug 4: Wrong adverbial participles for irregular verbs (FIXED)

- biti: `biući` → budući (via irregular_forms)
- dati: `daući` → dajući (via irregular_forms)
- hteti: `hteući` → hoteći (via irregular_forms)

**Fix:** Added correct adverbial participle forms as irregular_forms overrides in the seed for 12 irregular verbs.

### Bug 5: hteti imperative forms (FIXED)

The seed only had present tense overrides for hteti. Without imperative overrides, the engine generated wrong forms (`htei`, `hteimo`, `hteite`).

**Fix:** Added imperative overrides to hteti's irregular_forms: htej, htejmo, htejte.

### Bug 6: lep comparative missing iotation (FIXED)

The seed had `comparative_stem: "leps"` (ASCII) instead of `"lepš"` (with diacritics). This produced `lepsi` instead of the correct `lepši`.

**Fix:** Updated comparative_stem to `"lepš"` and corrected all comparative/superlative seed forms.

### Additional seed fixes

- doći past forms: ASCII `dosao` → diacritical `došao` (and all other past forms)
- ići past forms: ASCII `isao` → diacritical `išao` (and all other past forms)
- moći pres_1sg: dialectal `možem` → standard `mogu`
- reći imperatives: `reči` → `reci` (correct standard form)
