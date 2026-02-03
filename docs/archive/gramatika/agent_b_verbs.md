# Agent B: Serbian Verb Inflector

## Objective

Implement `Ohmyword.Linguistics.Verbs` module that generates all conjugated forms of Serbian verbs.

---

## File to Create

```
lib/ohmyword/linguistics/verbs.ex
test/ohmyword/linguistics/verbs_test.exs
```

---

## Behaviour Implementation

```elixir
defmodule Ohmyword.Linguistics.Verbs do
  @behaviour Ohmyword.Linguistics.Inflector
  
  @impl true
  def applicable?(word), do: word.part_of_speech == :verb
  
  @impl true
  def generate_forms(word) do
    # Return list of {term, form_tag} tuples
  end
end
```

---

## Serbian Verb Conjugation Overview

Serbian verbs conjugate across:
- **Tenses**: Present, Past (L-participle), Imperative, Infinitive
- **Person**: 1st, 2nd, 3rd
- **Number**: Singular, Plural
- **Gender** (past tense only): Masculine, Feminine, Neuter

**Note on Compound Tenses**: Future and perfect tenses are formed analytically with auxiliaries (ću, sam, etc.). We store only the synthetic forms — the participles and present tense that combine with auxiliaries.

---

## Form Tags to Generate

### Infinitive
```
inf
```

### Present Tense (6 forms)
```
pres_1sg, pres_2sg, pres_3sg, pres_1pl, pres_2pl, pres_3pl
```

### Past Participle / L-Participle (6 forms)
Used to form past, future, conditional. Agrees in gender/number with subject.
```
past_m_sg, past_f_sg, past_n_sg, past_m_pl, past_f_pl, past_n_pl
```

### Imperative (3 forms)
```
imp_2sg, imp_1pl, imp_2pl
```

### Optional: Passive Participle (if transitive)
```
pass_part_m_sg, pass_part_f_sg, pass_part_n_sg
pass_part_m_pl, pass_part_f_pl, pass_part_n_pl
```

### Optional: Present Adverbial Participle
```
pres_adv_part
```

### Optional: Past Adverbial Participle
```
past_adv_part
```

**Minimum forms per verb**: 16 (inf + 6 present + 6 past + 3 imperative)

---

## Verb Conjugation Classes

### Class 1: A-Verbs (conjugation_class: "a-verb")

Infinitive ends in `-ati`, present stem = infinitive stem.

**Example: čitati (to read)**

| Form | Conjugation |
|------|-------------|
| inf | čitati |
| pres_1sg | čita-m |
| pres_2sg | čita-š |
| pres_3sg | čita |
| pres_1pl | čita-mo |
| pres_2pl | čita-te |
| pres_3pl | čitaju |
| imp_2sg | čitaj |
| imp_1pl | čitajmo |
| imp_2pl | čitajte |
| past_m_sg | čitao |
| past_f_sg | čitala |
| past_n_sg | čitalo |
| past_m_pl | čitali |
| past_f_pl | čitale |
| past_n_pl | čitala |

**Present endings (a-verb)**:
| Person | Singular | Plural |
|--------|----------|--------|
| 1st | -m | -mo |
| 2nd | -š | -te |
| 3rd | — | -ju |

**Stem**: Remove `-ti` from infinitive → `čita-`

### Class 2: I-Verbs (conjugation_class: "i-verb")

Infinitive ends in `-iti` or `-eti` (with i-type conjugation), present uses `-im` etc.

**Example: govoriti (to speak)**

| Form | Conjugation |
|------|-------------|
| inf | govoriti |
| pres_1sg | govor-im |
| pres_2sg | govor-iš |
| pres_3sg | govor-i |
| pres_1pl | govor-imo |
| pres_2pl | govor-ite |
| pres_3pl | govor-e |
| imp_2sg | govori |
| imp_1pl | govorimo |
| imp_2pl | govorite |
| past_m_sg | govorio |
| past_f_sg | govorila |
| past_n_sg | govorilo |
| past_m_pl | govorili |
| past_f_pl | govorile |
| past_n_pl | govorila |

**Present endings (i-verb)**:
| Person | Singular | Plural |
|--------|----------|--------|
| 1st | -im | -imo |
| 2nd | -iš | -ite |
| 3rd | -i | -e |

**Stem**: Remove `-iti` or `-eti` → `govor-`

### Class 3: E-Verbs (conjugation_class: "e-verb")

Infinitive ends in `-ati`, `-eti`, or consonant + `-ti`, but present stem differs and uses `-em` etc.

**Example: pisati (to write)**

Infinitive stem: `pisa-`
Present stem: `piš-` (from grammar_metadata.present_stem)

| Form | Conjugation |
|------|-------------|
| inf | pisati |
| pres_1sg | piš-em |
| pres_2sg | piš-eš |
| pres_3sg | piš-e |
| pres_1pl | piš-emo |
| pres_2pl | piš-ete |
| pres_3pl | piš-u |
| imp_2sg | piši |
| imp_1pl | pišimo |
| imp_2pl | pišite |
| past_m_sg | pisao |
| past_f_sg | pisala |
| past_n_sg | pisalo |
| past_m_pl | pisali |
| past_f_pl | pisale |
| past_n_pl | pisala |

**Present endings (e-verb)**:
| Person | Singular | Plural |
|--------|----------|--------|
| 1st | -em | -emo |
| 2nd | -eš | -ete |
| 3rd | -e | -u |

### Class 4: JE-Verbs

Present stem ends in a consonant, present tense inserts `-je-`.

**Example: piti (to drink)**

Present stem: `pij-`

| Form | Conjugation |
|------|-------------|
| inf | piti |
| pres_1sg | pij-em |
| pres_2sg | pij-eš |
| pres_3sg | pij-e |
| pres_1pl | pij-emo |
| pres_2pl | pij-ete |
| pres_3pl | pij-u |

---

## Grammar Metadata Keys

Read these from `word.grammar_metadata`:

| Key | Type | Effect |
|-----|------|--------|
| `present_stem` | string | Stem for present tense (when different from infinitive stem) |
| `aorist_stem` | string | Stem for aorist (if generating aorist) |
| `irregular_forms` | map | Override specific forms, e.g., `%{"pres_1sg" => "hoću"}` |
| `defective` | boolean | Missing some standard forms |
| `impersonal` | boolean | Only 3rd person forms (weather verbs) |
| `auxiliary` | boolean | Marks auxiliary verbs (biti, hteti) — highly irregular |

---

## Reflexive Verbs

If `word.reflexive == true`:
- The `word.term` includes "se" (e.g., "smejati se")
- The base verb is everything before " se"
- Conjugated forms also include "se"

**Example: smejati se (to laugh)**

| Form | Conjugation |
|------|-------------|
| inf | smejati se |
| pres_1sg | smejem se |
| pres_2sg | smeješ se |
| pres_3sg | smeje se |
| past_m_sg | smejao se |

**Note**: Store the full form including "se" in the output.

---

## Handling the Two Stems

Most verbs have two stems:
1. **Infinitive stem**: Used for past participle, infinitive
2. **Present stem**: Used for present tense, imperative

**Deriving stems**:

For most verbs, if `grammar_metadata.present_stem` is not provided:
- a-verbs: present stem = infinitive stem
- i-verbs: present stem = infinitive stem (remove -iti)
- e-verbs: MUST have `present_stem` in metadata (unpredictable)

---

## Past Participle (L-Participle) Formation

From infinitive stem + endings:

| Gender/Number | Ending |
|---------------|--------|
| m_sg | -o (but stem vowel may change: -ao, -io, -eo) |
| f_sg | -la |
| n_sg | -lo |
| m_pl | -li |
| f_pl | -le |
| n_pl | -la |

**Special case**: If infinitive stem ends in consonant, add `-ao` for m_sg:
- `pisati` → stem `pisa-` → `pisao`
- `govoriti` → stem `govori-` → `govorio` (stem ends in `i`, so just `-o`)

---

## Imperative Formation

From present stem:

| Person | Ending |
|--------|--------|
| 2sg | -i / -j |
| 1pl | -imo / -jmo |
| 2pl | -ite / -jte |

**Rules**:
- If present stem ends in vowel: add `-j`, `-jmo`, `-jte`
- If present stem ends in consonant: add `-i`, `-imo`, `-ite`

**Examples**:
- `čita-` (vowel) → čitaj, čitajmo, čitajte
- `piš-` (consonant) → piši, pišimo, pišite

---

## Highly Irregular Verbs

### biti (to be)

```elixir
%{
  "pres_1sg" => "sam",      # or "jesam" (emphatic)
  "pres_2sg" => "si",       # or "jesi"
  "pres_3sg" => "je",       # or "jest/jeste"
  "pres_1pl" => "smo",      # or "jesmo"
  "pres_2pl" => "ste",      # or "jeste"
  "pres_3pl" => "su",       # or "jesu"
  "past_m_sg" => "bio",
  "past_f_sg" => "bila",
  "past_n_sg" => "bilo",
  "past_m_pl" => "bili",
  "past_f_pl" => "bile",
  "past_n_pl" => "bila",
  "imp_2sg" => "budi",
  "imp_1pl" => "budimo",
  "imp_2pl" => "budite"
}
```

Handle via `grammar_metadata.irregular_forms` or hardcode detection for "biti".

### hteti (to want)

```elixir
%{
  "pres_1sg" => "hoću",     # or "ću" (clitic)
  "pres_2sg" => "hoćeš",    # or "ćeš"
  "pres_3sg" => "hoće",     # or "će"
  "pres_1pl" => "hoćemo",   # or "ćemo"
  "pres_2pl" => "hoćete",   # or "ćete"
  "pres_3pl" => "hoće",     # or "će"
}
```

### moći (can)

```elixir
%{
  "pres_1sg" => "mogu",
  "pres_2sg" => "možeš",
  "pres_3sg" => "može",
  "pres_1pl" => "možemo",
  "pres_2pl" => "možete",
  "pres_3pl" => "mogu"
}
```

---

## Algorithm Outline

```
1. Check for fully irregular verb (biti, hteti) — use hardcoded or metadata
2. Extract infinitive stem: remove "-ti" (or "-ći" for some verbs)
3. Get present stem: use grammar_metadata.present_stem or derive from infinitive stem
4. Check word.reflexive and extract base if needed
5. Generate forms:
   a. Infinitive: word.term
   b. Present: present_stem + present_endings (based on conjugation_class)
   c. Past participle: infinitive_stem + participle_endings
   d. Imperative: present_stem + imperative_endings
6. Apply irregular_forms overrides
7. If reflexive, append " se" to all forms
8. Return list of {lowercase_form, form_tag}
```

---

## Test Cases

### Test 1: A-Verb (čitati)

```elixir
word = %Word{
  term: "čitati",
  part_of_speech: :verb,
  verb_aspect: :imperfective,
  conjugation_class: "a-verb"
}

# Expected 16 forms
# pres_1sg: "čitam"
# past_m_sg: "čitao"
```

### Test 2: I-Verb (govoriti)

```elixir
word = %Word{
  term: "govoriti",
  part_of_speech: :verb,
  verb_aspect: :imperfective,
  conjugation_class: "i-verb"
}

# pres_1sg: "govorim"
# pres_3pl: "govore"
```

### Test 3: E-Verb with Present Stem (pisati)

```elixir
word = %Word{
  term: "pisati",
  part_of_speech: :verb,
  verb_aspect: :imperfective,
  conjugation_class: "e-verb",
  grammar_metadata: %{"present_stem" => "piš"}
}

# pres_1sg: "pišem"
# past_m_sg: "pisao"
# imp_2sg: "piši"
```

### Test 4: Reflexive Verb (smejati se)

```elixir
word = %Word{
  term: "smejati se",
  part_of_speech: :verb,
  verb_aspect: :imperfective,
  conjugation_class: "e-verb",
  reflexive: true,
  grammar_metadata: %{"present_stem" => "smej"}
}

# inf: "smejati se"
# pres_1sg: "smejem se"
# past_m_sg: "smejao se"
```

### Test 5: Highly Irregular (biti)

```elixir
word = %Word{
  term: "biti",
  part_of_speech: :verb,
  verb_aspect: :imperfective,
  grammar_metadata: %{
    "auxiliary" => true,
    "irregular_forms" => %{
      "pres_1sg" => "sam",
      "pres_2sg" => "si",
      "pres_3sg" => "je",
      "pres_1pl" => "smo",
      "pres_2pl" => "ste",
      "pres_3pl" => "su"
    }
  }
}

# Uses overrides for present
# Regular formation for past: bio, bila, bilo, etc.
```

### Test 6: Impersonal Verb

```elixir
word = %Word{
  term: "trebati",
  part_of_speech: :verb,
  verb_aspect: :imperfective,
  conjugation_class: "a-verb",
  grammar_metadata: %{"impersonal" => true}
}

# May only generate 3rd person forms (design decision)
# Or generate all forms anyway
```

### Test 7: Perfective Verb (napisati)

```elixir
word = %Word{
  term: "napisati",
  part_of_speech: :verb,
  verb_aspect: :perfective,
  conjugation_class: "e-verb",
  grammar_metadata: %{"present_stem" => "napiš"}
}

# Same conjugation pattern, aspect doesn't change endings
```

---

## Stem Extraction Helper

```elixir
def infinitive_stem(term) do
  cond do
    String.ends_with?(term, "ći") -> String.trim_trailing(term, "ći")
    String.ends_with?(term, "ti") -> String.trim_trailing(term, "ti")
    true -> term
  end
end

# For reflexive verbs, first strip " se":
def strip_reflexive(term) do
  String.trim_trailing(term, " se")
end
```

---

## Conjugation Endings Reference

### Present Tense

| Class | 1sg | 2sg | 3sg | 1pl | 2pl | 3pl |
|-------|-----|-----|-----|-----|-----|-----|
| a-verb | -m | -š | — | -mo | -te | -ju |
| i-verb | -im | -iš | -i | -imo | -ite | -e |
| e-verb | -em | -eš | -e | -emo | -ete | -u |

### Past Participle

| Gender | Singular | Plural |
|--------|----------|--------|
| m | -o (after vowel) / -ao (after consonant) | -li |
| f | -la | -le |
| n | -lo | -la |

### Imperative

| Class | 2sg | 1pl | 2pl |
|-------|-----|-----|-----|
| a-verb (stem ends vowel) | -j | -jmo | -jte |
| i-verb | -i | -imo | -ite |
| e-verb | -i | -imo | -ite |

---

## Output Format

```elixir
[
  {"čitati", "inf"},
  {"čitam", "pres_1sg"},
  {"čitaš", "pres_2sg"},
  {"čita", "pres_3sg"},
  {"čitamo", "pres_1pl"},
  {"čitate", "pres_2pl"},
  {"čitaju", "pres_3pl"},
  {"čitao", "past_m_sg"},
  {"čitala", "past_f_sg"},
  {"čitalo", "past_n_sg"},
  {"čitali", "past_m_pl"},
  {"čitale", "past_f_pl"},
  {"čitala", "past_n_pl"},
  {"čitaj", "imp_2sg"},
  {"čitajmo", "imp_1pl"},
  {"čitajte", "imp_2pl"}
]
```

---

## Do NOT

- Handle other parts of speech
- Modify schemas
- Generate compound tenses (future, perfect) — only the component parts
- Insert into database (CacheManager does that)

---

## Acceptance Criteria

1. `applicable?/1` returns true only for verbs
2. `generate_forms/1` returns minimum 16 forms for regular verbs
3. All three conjugation classes work correctly
4. Reflexive verbs include "se" in all forms
5. Present stem override works
6. Irregular form overrides are applied
7. Past participle gender/number agreement correct
8. All test cases pass
