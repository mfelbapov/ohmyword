# Agent E: Serbian Numeral Inflector

## Objective

Implement `Ohmyword.Linguistics.Numerals` module that generates all forms of Serbian numerals.

---

## File to Create

```
lib/ohmyword/linguistics/numerals.ex
test/ohmyword/linguistics/numerals_test.exs
```

---

## Behaviour Implementation

```elixir
defmodule Ohmyword.Linguistics.Numerals do
  @behaviour Ohmyword.Linguistics.Inflector
  
  @impl true
  def applicable?(word), do: word.part_of_speech == :numeral
  
  @impl true
  def generate_forms(word) do
    # Return list of {term, form_tag} tuples
  end
end
```

---

## Serbian Numeral Overview

Serbian numerals are complex because:
- **1** declines for gender and case (like adjective)
- **2, 3, 4** have gender forms and decline (special pattern)
- **5-20, 30, 40...** don't decline (mostly)
- **Ordinals** decline like adjectives
- **Collectives** have special forms

---

## Numeral Types

Stored in `grammar_metadata.numeral_type`:

| Type | Examples | Behavior |
|------|----------|----------|
| cardinal | jedan, dva, pet | Varies by number |
| ordinal | prvi, drugi, peti | Adjective declension |
| collective | dvoje, troje, petoro | Special declension |

---

## Cardinal Numerals

### Jedan (1) - Declines like Adjective

Full adjectival declension with gender:

| Case | M | F | N |
|------|---|---|---|
| nom | jedan | jedna | jedno |
| gen | jednog(a) | jedne | jednog(a) |
| dat | jednom(e/u) | jednoj | jednom(e/u) |
| acc | jedan/jednog | jednu | jedno |
| voc | — | — | — |
| ins | jednim | jednom | jednim |
| loc | jednom(e/u) | jednoj | jednom(e/u) |

### Dva (2) - Gender Forms + Partial Declension

| Case | M/N | F |
|------|-----|---|
| nom | dva | dve/dvije |
| gen | dvaju | dveju/dviju |
| dat | dvama | dvema/dvjema |
| acc | dva | dve/dvije |
| ins | dvama | dvema/dvjema |
| loc | dvama | dvema/dvjema |

### Tri (3) - Partial Declension

| Case | All Genders |
|------|-------------|
| nom | tri |
| gen | triju |
| dat | trima |
| acc | tri |
| ins | trima |
| loc | trima |

### Četiri (4) - Partial Declension

| Case | All Genders |
|------|-------------|
| nom | četiri |
| gen | četiriju |
| dat | četirima |
| acc | četiri |
| ins | četirima |
| loc | četirima |

### Pet (5) and Higher - Generally Invariable

Numbers 5-20 and tens (30, 40, ...) typically don't decline in modern usage:

| Numeral | Form |
|---------|------|
| pet | pet (all cases) |
| šest | šest |
| sedam | sedam |
| osam | osam |
| devet | devet |
| deset | deset |
| jedanaest | jedanaest |
| ... | ... |
| dvadeset | dvadeset |
| trideset | trideset |

Some speakers use genitive/dative forms for 5-10, but these are becoming archaic.

### Compound Cardinals

- 21 = dvadeset jedan (declines "jedan" part)
- 22 = dvadeset dva (declines "dva" part)
- 100 = sto (declines: sto, sta/stotine, ...)
- 200 = dvesta (or "dve stotine")

---

## Ordinal Numerals

Ordinals decline exactly like adjectives:

| Ordinal | M | F | N |
|---------|---|---|---|
| 1st | prvi | prva | prvo |
| 2nd | drugi | druga | drugo |
| 3rd | treći | treća | treće |
| 4th | četvrti | četvrta | četvrto |
| 5th | peti | peta | peto |

**Generate forms**: Delegate to adjective-like declension (42+ forms each).

---

## Collective Numerals

Used with pluralia tantum nouns and mixed-gender groups:

| Cardinal | Collective |
|----------|------------|
| 2 | dvoje |
| 3 | troje |
| 4 | četvoro |
| 5 | petoro |
| 6 | šestoro |

**Declension of dvoje**:

| Case | Form |
|------|------|
| nom | dvoje |
| gen | dvoga |
| dat | dvoma |
| acc | dvoje |
| ins | dvoma |
| loc | dvoma |

---

## Grammar Metadata Keys

| Key | Type | Effect |
|-----|------|--------|
| `numeral_type` | string | "cardinal", "ordinal", "collective" |
| `numeral_value` | integer | The numeric value (1, 2, 3...) |
| `gender_forms` | boolean | Has different gender forms (true for 1, 2) |
| `declines` | boolean | Whether it declines at all |
| `governs` | string | Case governed by this numeral |
| `irregular_forms` | map | Override specific forms |

---

## Algorithm Outline

```
1. Get numeral_type from grammar_metadata
2. If ordinal:
   - Delegate to adjective-like declension
3. If cardinal:
   a. Check numeral_value or infer from term
   b. If 1: full adjective declension
   c. If 2: gender forms + special declension
   d. If 3-4: partial declension
   e. If 5+: return base form only (invariable)
4. If collective:
   - Use collective paradigm
5. Apply irregular_forms overrides
6. Return {form, tag} list
```

---

## Form Tags

### For "jedan" (adjective-like)

```
nom_sg_m, nom_sg_f, nom_sg_n
gen_sg_m, gen_sg_f, gen_sg_n
dat_sg_m, dat_sg_f, dat_sg_n
acc_sg_m, acc_sg_f, acc_sg_n
ins_sg_m, ins_sg_f, ins_sg_n
loc_sg_m, loc_sg_f, loc_sg_n
```

### For "dva" (gender + case)

```
nom_m, nom_f    # (or nom_mn, nom_f for masc/neut vs fem)
gen_m, gen_f
dat_m, dat_f
acc_m, acc_f
ins_m, ins_f
loc_m, loc_f
```

### For "tri", "četiri" (case only)

```
nom, gen, dat, acc, ins, loc
```

### For invariable (5+)

```
base
```

### For ordinals (adjective-like)

```
nom_sg_m, nom_sg_f, nom_sg_n
nom_pl_m, nom_pl_f, nom_pl_n
gen_sg_m, gen_sg_f, gen_sg_n
... (42 forms)
```

---

## Test Cases

### Test 1: Jedan (1) - Full Declension

```elixir
word = %Word{
  term: "jedan",
  part_of_speech: :numeral,
  gender: :masculine,
  grammar_metadata: %{
    "numeral_type" => "cardinal",
    "numeral_value" => 1,
    "gender_forms" => true,
    "declines" => true
  }
}

# Expected: ~21 forms (7 cases × 3 genders)
# nom_sg_m: "jedan"
# nom_sg_f: "jedna"
# nom_sg_n: "jedno"
# gen_sg_m: "jednog"
```

### Test 2: Dva (2) - Gender + Partial Declension

```elixir
word = %Word{
  term: "dva",
  part_of_speech: :numeral,
  gender: :masculine,
  grammar_metadata: %{
    "numeral_type" => "cardinal",
    "numeral_value" => 2,
    "gender_forms" => true,
    "declines" => true
  }
}

# nom_m: "dva"
# nom_f: "dve"
# gen_m: "dvaju"
# gen_f: "dveju"
```

### Test 3: Tri (3) - No Gender, Partial Declension

```elixir
word = %Word{
  term: "tri",
  part_of_speech: :numeral,
  grammar_metadata: %{
    "numeral_type" => "cardinal",
    "numeral_value" => 3,
    "gender_forms" => false,
    "declines" => true
  }
}

# nom: "tri"
# gen: "triju"
# dat: "trima"
```

### Test 4: Pet (5) - Invariable

```elixir
word = %Word{
  term: "pet",
  part_of_speech: :numeral,
  grammar_metadata: %{
    "numeral_type" => "cardinal",
    "numeral_value" => 5,
    "declines" => false
  }
}

# Returns only: {"pet", "base"}
```

### Test 5: Ordinal - Prvi (1st)

```elixir
word = %Word{
  term: "prvi",
  part_of_speech: :numeral,
  gender: :masculine,
  grammar_metadata: %{
    "numeral_type" => "ordinal",
    "numeral_value" => 1
  }
}

# Declines like adjective
# nom_sg_m: "prvi"
# nom_sg_f: "prva"
# nom_sg_n: "prvo"
# gen_sg_m: "prvog"
```

### Test 6: Collective - Dvoje

```elixir
word = %Word{
  term: "dvoje",
  part_of_speech: :numeral,
  grammar_metadata: %{
    "numeral_type" => "collective",
    "numeral_value" => 2,
    "declines" => true
  }
}

# nom: "dvoje"
# gen: "dvoga"
# dat: "dvoma"
```

### Test 7: Ordinal - Treći (3rd) with Soft Stem

```elixir
word = %Word{
  term: "treći",
  part_of_speech: :numeral,
  gender: :masculine,
  grammar_metadata: %{
    "numeral_type" => "ordinal",
    "numeral_value" => 3,
    "soft_stem" => true
  }
}

# nom_sg_n: "treće" (soft stem: -e not -o)
```

---

## Hardcoded Paradigms

For cardinals 1-4 and collectives, use hardcoded paradigms:

```elixir
@cardinal_paradigms %{
  "jedan" => %{
    "nom_sg_m" => "jedan",
    "nom_sg_f" => "jedna",
    "nom_sg_n" => "jedno",
    "gen_sg_m" => "jednog",
    "gen_sg_f" => "jedne",
    "gen_sg_n" => "jednog",
    # ...
  },
  "dva" => %{
    "nom_m" => "dva",
    "nom_f" => "dve",
    "gen_m" => "dvaju",
    "gen_f" => "dveju",
    # ...
  },
  "tri" => %{
    "nom" => "tri",
    "gen" => "triju",
    "dat" => "trima",
    "acc" => "tri",
    "ins" => "trima",
    "loc" => "trima"
  },
  "četiri" => %{
    "nom" => "četiri",
    "gen" => "četiriju",
    "dat" => "četirima",
    "acc" => "četiri",
    "ins" => "četirima",
    "loc" => "četirima"
  }
}

@collective_paradigms %{
  "dvoje" => %{...},
  "troje" => %{...},
  # ...
}
```

---

## Ordinal Declension

Ordinals follow standard adjective patterns. You can:

1. **Reuse adjective logic** - Call into adjective declension
2. **Implement simplified version** - Same endings as adjectives

Most ordinals have hard stems. Exception: `treći` (3rd) has soft stem.

---

## Output Format

```elixir
# For "jedan"
[
  {"jedan", "nom_sg_m"},
  {"jedna", "nom_sg_f"},
  {"jedno", "nom_sg_n"},
  {"jednog", "gen_sg_m"},
  {"jedne", "gen_sg_f"},
  {"jednog", "gen_sg_n"},
  # ...
]

# For "dva"
[
  {"dva", "nom_m"},
  {"dve", "nom_f"},
  {"dvaju", "gen_m"},
  {"dveju", "gen_f"},
  # ...
]

# For "pet"
[
  {"pet", "base"}
]

# For ordinal "prvi"
[
  {"prvi", "nom_sg_m"},
  {"prva", "nom_sg_f"},
  {"prvo", "nom_sg_n"},
  # ... (42 forms)
]
```

---

## Simplification for MVP

If full numeral coverage is complex:

**Option A**: Only handle 1-4 + ordinals
- These are the most common
- 5+ are invariable anyway

**Option B**: Cardinals only, skip ordinals/collectives
- Add later

**Recommended**: Option A - cardinals 1-10 + common ordinals.

---

## Special Cases

### Oba/Obe (both)

Declines similarly to "dva":

| Case | M/N | F |
|------|-----|---|
| nom | oba | obe |
| gen | obaju | obeju |
| dat | obama/oboma | obema |
| acc | oba | obe |
| ins | obama/oboma | obema |
| loc | obama/oboma | obema |

### Stotina (hundred), Hiljada (thousand)

These are actually **nouns** that take noun declension. May be tagged as numerals but decline as nouns.

---

## Do NOT

- Handle other parts of speech
- Generate forms for very large numbers (100+)
- Modify schemas
- Insert into database

---

## Acceptance Criteria

1. `applicable?/1` returns true only for numerals
2. "jedan" has full gender × case declension
3. "dva" has gender forms and partial declension
4. "tri", "četiri" have partial declension (no gender)
5. "pet" and higher return only base form
6. Ordinals decline like adjectives
7. `numeral_type` is respected
8. All test cases pass
