# Agent D: Serbian Pronoun Inflector

## Objective

Implement `Ohmyword.Linguistics.Pronouns` module that generates all forms of Serbian pronouns.

---

## File to Create

```
lib/ohmyword/linguistics/pronouns.ex
test/ohmyword/linguistics/pronouns_test.exs
```

---

## Behaviour Implementation

```elixir
defmodule Ohmyword.Linguistics.Pronouns do
  @behaviour Ohmyword.Linguistics.Inflector
  
  @impl true
  def applicable?(word), do: word.part_of_speech == :pronoun
  
  @impl true
  def generate_forms(word) do
    # Return list of {term, form_tag} tuples
  end
end
```

---

## Serbian Pronoun Overview

Pronouns are highly irregular in Serbian. Most must be stored as complete paradigms rather than derived from rules.

### Pronoun Types

| Type | Examples | Declension Pattern |
|------|----------|-------------------|
| Personal | ja, ti, on/ona/ono, mi, vi, oni | Highly irregular, clitics |
| Reflexive | sebe | Single paradigm |
| Possessive | moj, tvoj, njegov, naš | Adjective-like declension |
| Demonstrative | ovaj, taj, onaj | Adjective-like |
| Interrogative | ko, šta, koji, čiji | Mixed patterns |
| Relative | koji, čiji, kakav | Adjective-like |
| Indefinite | neko, nešto, neki | Based on interrogatives |
| Negative | niko, ništa | Based on interrogatives |

---

## Strategy: Manual Forms

Because pronouns are irregular, the recommended approach is:

1. Check `grammar_metadata.manual_forms_only`
2. If true: return forms from `grammar_metadata.forms` directly
3. If false: attempt rule-based generation for adjective-like pronouns

Most personal pronouns should have `manual_forms_only: true` with complete paradigms in the seed data.

---

## Personal Pronouns

### Ja (I) - 1st Person Singular

| Case | Full Form | Clitic |
|------|-----------|--------|
| nom | ja | — |
| gen | mene | me |
| dat | meni | mi |
| acc | mene | me |
| voc | — | — |
| ins | mnom(e) | — |
| loc | meni | — |

### Ti (you) - 2nd Person Singular

| Case | Full Form | Clitic |
|------|-----------|--------|
| nom | ti | — |
| gen | tebe | te |
| dat | tebi | ti |
| acc | tebe | te |
| voc | ti | — |
| ins | tobom | — |
| loc | tebi | — |

### On (he) - 3rd Person Singular Masculine

| Case | Full Form | Clitic |
|------|-----------|--------|
| nom | on | — |
| gen | njega | ga |
| dat | njemu | mu |
| acc | njega | ga |
| voc | — | — |
| ins | njim(e) | — |
| loc | njemu | — |

### Ona (she) - 3rd Person Singular Feminine

| Case | Full Form | Clitic |
|------|-----------|--------|
| nom | ona | — |
| gen | nje | je |
| dat | njoj | joj |
| acc | nju | je/ju |
| voc | — | — |
| ins | njom(e) | — |
| loc | njoj | — |

### Ono (it) - 3rd Person Singular Neuter

| Case | Full Form | Clitic |
|------|-----------|--------|
| nom | ono | — |
| gen | njega | ga |
| dat | njemu | mu |
| acc | njega | ga |
| voc | — | — |
| ins | njim(e) | — |
| loc | njemu | — |

### Mi (we) - 1st Person Plural

| Case | Full Form | Clitic |
|------|-----------|--------|
| nom | mi | — |
| gen | nas | nas |
| dat | nama | nam |
| acc | nas | nas |
| voc | — | — |
| ins | nama | — |
| loc | nama | — |

### Vi (you pl./formal) - 2nd Person Plural

| Case | Full Form | Clitic |
|------|-----------|--------|
| nom | vi | — |
| gen | vas | vas |
| dat | vama | vam |
| acc | vas | vas |
| voc | vi | — |
| ins | vama | — |
| loc | vama | — |

### Oni/One/Ona (they) - 3rd Person Plural

| Case | M | F | N | Clitic |
|------|---|---|---|--------|
| nom | oni | one | ona | — |
| gen | njih | njih | njih | ih |
| dat | njima | njima | njima | im |
| acc | njih | njih | njih | ih |
| voc | — | — | — | — |
| ins | njima | njima | njima | — |
| loc | njima | njima | njima | — |

---

## Reflexive Pronoun: Sebe

No nominative form. Same for all persons.

| Case | Full Form | Clitic |
|------|-----------|--------|
| nom | — | — |
| gen | sebe | se (rare) |
| dat | sebi | si |
| acc | sebe | se |
| voc | — | — |
| ins | sobom | — |
| loc | sebi | — |

---

## Form Tags for Personal Pronouns

For personal pronouns, use these tags:

```
nom, gen, dat, acc, ins, loc           # Full forms
gen_clitic, dat_clitic, acc_clitic     # Clitic forms
```

Or for 3rd person with gender:
```
nom_m, nom_f, nom_n
gen_m, gen_f, gen_n  # (these are usually the same)
...
```

---

## Possessive Pronouns

Decline like adjectives. Can use adjective-like generation.

### Moj (my)

| Case | M.Sg | F.Sg | N.Sg | M.Pl | F.Pl | N.Pl |
|------|------|------|------|------|------|------|
| nom | moj | moja | moje | moji | moje | moja |
| gen | mog(a) | moje | mog(a) | mojih | mojih | mojih |
| dat | mom(e/u) | mojoj | mom(e/u) | mojim(a) | mojim(a) | mojim(a) |
| acc | moj/mog | moju | moje | moje | moje | moja |
| voc | moj | moja | moje | moji | moje | moja |
| ins | mojim | mojom | mojim | mojim(a) | mojim(a) | mojim(a) |
| loc | mom(e/u) | mojoj | mom(e/u) | mojim(a) | mojim(a) | mojim(a) |

Other possessives (tvoj, svoj, naš, vaš) follow similar patterns.

### Njegov (his), Njen (her), Njihov (their)

Follow standard adjective declension.

---

## Demonstrative Pronouns

### Ovaj (this), Taj (that), Onaj (that over there)

Follow adjective-like declension with some irregularities:

| Case | M.Sg | F.Sg | N.Sg |
|------|------|------|------|
| nom | ovaj | ova | ovo |
| gen | ovog(a) | ove | ovog(a) |
| dat | ovom(e/u) | ovoj | ovom(e/u) |
| acc | ovaj/ovog | ovu | ovo |
| voc | — | — | — |
| ins | ovim | ovom | ovim |
| loc | ovom(e/u) | ovoj | ovom(e/u) |

---

## Interrogative Pronouns

### Ko (who)

| Case | Form |
|------|------|
| nom | ko |
| gen | koga |
| dat | kome/komu |
| acc | koga |
| voc | — |
| ins | kim(e) |
| loc | kome/komu |

### Šta (what)

| Case | Form |
|------|------|
| nom | šta |
| gen | čega |
| dat | čemu |
| acc | šta |
| voc | — |
| ins | čim(e) |
| loc | čemu |

### Koji (which) - Adjective-like

Declines like an adjective across gender, number, case.

---

## Grammar Metadata Keys

| Key | Type | Effect |
|-----|------|--------|
| `manual_forms_only` | boolean | Use forms from seed, don't generate |
| `pronoun_type` | string | personal, reflexive, possessive, demonstrative, interrogative, relative, indefinite, negative |
| `clitic_forms` | map | Map of case → clitic form |
| `person` | integer | 1, 2, 3 for personal pronouns |
| `number` | string | "singular", "plural" |

---

## Algorithm Outline

```
1. Check grammar_metadata.manual_forms_only
   - If true: lookup word in hardcoded paradigms or return empty
2. Check pronoun_type
3. If possessive/demonstrative/interrogative(koji): 
   - Delegate to adjective-like declension
4. If personal:
   - Use hardcoded paradigms
5. Apply clitic_forms if present
6. Return {form, tag} list
```

---

## Hardcoded Paradigms Approach

For personal and reflexive pronouns, maintain a lookup table:

```elixir
@personal_pronouns %{
  "ja" => [
    {"ja", "nom"},
    {"mene", "gen"},
    {"me", "gen_clitic"},
    {"meni", "dat"},
    {"mi", "dat_clitic"},
    {"mene", "acc"},
    {"me", "acc_clitic"},
    {"mnom", "ins"},
    {"mnome", "ins_alt"},
    {"meni", "loc"}
  ],
  "ti" => [...],
  "on" => [...],
  # etc.
}
```

When `generate_forms/1` is called:
1. Look up `word.term` in the paradigm table
2. Return the stored forms
3. If not found, return empty or attempt inference

---

## Test Cases

### Test 1: Personal Pronoun with Manual Forms

```elixir
word = %Word{
  term: "ja",
  part_of_speech: :pronoun,
  gender: nil,
  grammar_metadata: %{
    "pronoun_type" => "personal",
    "manual_forms_only" => true,
    "person" => 1,
    "number" => "singular"
  }
}

# Expected: 10 forms (6 cases + 3 clitics + alt)
# nom: "ja"
# gen: "mene"
# gen_clitic: "me"
# etc.
```

### Test 2: Reflexive Pronoun

```elixir
word = %Word{
  term: "sebe",
  part_of_speech: :pronoun,
  grammar_metadata: %{
    "pronoun_type" => "reflexive",
    "manual_forms_only" => true
  }
}

# No nominative
# gen: "sebe"
# acc_clitic: "se"
```

### Test 3: Possessive Pronoun (Adjective-like)

```elixir
word = %Word{
  term: "moj",
  part_of_speech: :pronoun,
  gender: :masculine,
  grammar_metadata: %{
    "pronoun_type" => "possessive"
  }
}

# Declines like adjective
# nom_sg_m: "moj"
# nom_sg_f: "moja"
# nom_sg_n: "moje"
# ...
```

### Test 4: Demonstrative Pronoun

```elixir
word = %Word{
  term: "ovaj",
  part_of_speech: :pronoun,
  gender: :masculine,
  grammar_metadata: %{
    "pronoun_type" => "demonstrative"
  }
}

# nom_sg_m: "ovaj"
# nom_sg_f: "ova"
# nom_sg_n: "ovo"
```

### Test 5: Interrogative Ko

```elixir
word = %Word{
  term: "ko",
  part_of_speech: :pronoun,
  grammar_metadata: %{
    "pronoun_type" => "interrogative",
    "manual_forms_only" => true
  }
}

# nom: "ko"
# gen: "koga"
# dat: "kome" / "komu"
# acc: "koga"
# ins: "kim" / "kime"
# loc: "kome" / "komu"
```

### Test 6: 3rd Person Plural with Genders

```elixir
word = %Word{
  term: "oni",
  part_of_speech: :pronoun,
  gender: :masculine,  # for "oni"
  grammar_metadata: %{
    "pronoun_type" => "personal",
    "person" => 3,
    "number" => "plural"
  }
}

# nom_m: "oni"
# nom_f: "one"
# nom_n: "ona"
# gen: "njih"
# gen_clitic: "ih"
```

---

## Clitic Form Tags

When generating clitic forms, use these tags:

```
gen_clitic
dat_clitic
acc_clitic
```

Or for reflexive:
```
acc_clitic  # "se"
dat_clitic  # "si"
```

---

## Possessive Pronoun Declension

For possessive pronouns, reuse adjective logic or implement simplified version:

| Possessive | Pattern Notes |
|------------|---------------|
| moj, tvoj, svoj | Soft-ish stem, "moj-" |
| naš, vaš | Hard stem, "naš-" |
| njegov, njezin, njihov | Standard adjective |

---

## Output Format

```elixir
# For "ja"
[
  {"ja", "nom"},
  {"mene", "gen"},
  {"me", "gen_clitic"},
  {"meni", "dat"},
  {"mi", "dat_clitic"},
  {"mene", "acc"},
  {"me", "acc_clitic"},
  {"mnom", "ins"},
  {"meni", "loc"}
]

# For possessive "moj"
[
  {"moj", "nom_sg_m"},
  {"moja", "nom_sg_f"},
  {"moje", "nom_sg_n"},
  {"moga", "gen_sg_m"},
  {"moje", "gen_sg_f"},
  # ... etc
]
```

---

## Simplification for MVP

If full pronoun coverage is too complex:

**Option A**: Only handle personal + reflexive pronouns (hardcoded)
- ja, ti, on, ona, ono, mi, vi, oni, sebe
- ~100 forms total

**Option B**: Mark all pronouns as `manual_forms_only` and rely on seed data
- Inflector just returns what's in the seed
- No rule-based generation

**Recommended**: Option A for common pronouns + Option B as fallback.

---

## Do NOT

- Handle other parts of speech
- Modify schemas
- Generate forms for unlisted pronouns (return empty)
- Insert into database

---

## Acceptance Criteria

1. `applicable?/1` returns true only for pronouns
2. Personal pronouns return correct paradigms
3. Clitic forms are included
4. Possessive pronouns decline like adjectives
5. `manual_forms_only` flag is respected
6. Unknown pronouns return empty list or base form
7. All test cases pass
