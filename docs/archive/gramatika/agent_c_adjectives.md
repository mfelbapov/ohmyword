# Agent C: Serbian Adjective Inflector

## Objective

Implement `Ohmyword.Linguistics.Adjectives` module that generates all declined forms of Serbian adjectives.

---

## File to Create

```
lib/ohmyword/linguistics/adjectives.ex
test/ohmyword/linguistics/adjectives_test.exs
```

---

## Behaviour Implementation

```elixir
defmodule Ohmyword.Linguistics.Adjectives do
  @behaviour Ohmyword.Linguistics.Inflector
  
  @impl true
  def applicable?(word), do: word.part_of_speech == :adjective
  
  @impl true
  def generate_forms(word) do
    # Return list of {term, form_tag} tuples
  end
end
```

---

## Serbian Adjective Declension Overview

Serbian adjectives agree with nouns in:
- **Gender**: masculine, feminine, neuter
- **Number**: singular, plural
- **Case**: 7 cases

Additionally, adjectives have:
- **Definiteness**: indefinite (short) and definite (long) forms
- **Comparison**: positive, comparative, superlative

---

## Form Tags to Generate

### Indefinite (Short) Forms — Positive

```
indef_nom_sg_m, indef_nom_sg_f, indef_nom_sg_n
indef_gen_sg_m, indef_gen_sg_f, indef_gen_sg_n
indef_dat_sg_m, indef_dat_sg_f, indef_dat_sg_n
indef_acc_sg_m, indef_acc_sg_f, indef_acc_sg_n
indef_voc_sg_m, indef_voc_sg_f, indef_voc_sg_n
indef_ins_sg_m, indef_ins_sg_f, indef_ins_sg_n
indef_loc_sg_m, indef_loc_sg_f, indef_loc_sg_n

indef_nom_pl_m, indef_nom_pl_f, indef_nom_pl_n
indef_gen_pl_m, indef_gen_pl_f, indef_gen_pl_n
indef_dat_pl_m, indef_dat_pl_f, indef_dat_pl_n
indef_acc_pl_m, indef_acc_pl_f, indef_acc_pl_n
indef_voc_pl_m, indef_voc_pl_f, indef_voc_pl_n
indef_ins_pl_m, indef_ins_pl_f, indef_ins_pl_n
indef_loc_pl_m, indef_loc_pl_f, indef_loc_pl_n
```

### Definite (Long) Forms — Positive

```
def_nom_sg_m, def_nom_sg_f, def_nom_sg_n
def_gen_sg_m, def_gen_sg_f, def_gen_sg_n
... (same pattern as indefinite)
```

### Comparative Forms

```
comp_nom_sg_m, comp_nom_sg_f, comp_nom_sg_n
... (all 42 combinations)
```

### Superlative Forms

```
super_nom_sg_m, super_nom_sg_f, super_nom_sg_n
... (all 42 combinations)
```

**Total forms**: Up to 168 (42 × 4 degrees) for fully regular adjectives.

**Practical minimum**: For MVP, generate indefinite + definite positive forms = 84 forms. Comparative/superlative can be simplified.

---

## Indefinite vs Definite Forms

| Form | Use | Example |
|------|-----|---------|
| Indefinite | Predicate, first mention | "Čovek je star" (The man is old) |
| Definite | Attributive, known referent | "Stari čovek" (The old man) |

The difference is primarily in the masculine nominative singular:
- Indefinite: star (old)
- Definite: stari (the old one / old + known)

For other forms, definite often = indefinite + i/a/o lengthening.

---

## Adjective Declension Patterns

### Standard Adjective: "nov" (new)

**Dictionary form**: nov (masculine indefinite nominative singular)

#### Indefinite Forms

**Singular**:

| Case | Masculine | Feminine | Neuter |
|------|-----------|----------|--------|
| nom | nov | nov-a | nov-o |
| gen | nov-a | nov-e | nov-a |
| dat | nov-u | nov-oj | nov-u |
| acc | nov (inan) / nov-a (anim) | nov-u | nov-o |
| voc | nov | nov-a | nov-o |
| ins | nov-im | nov-om | nov-im |
| loc | nov-u / nov-om | nov-oj | nov-u / nov-om |

**Plural**:

| Case | Masculine | Feminine | Neuter |
|------|-----------|----------|--------|
| nom | nov-i | nov-e | nov-a |
| gen | nov-ih | nov-ih | nov-ih |
| dat | nov-im / nov-ima | nov-im / nov-ima | nov-im / nov-ima |
| acc | nov-e | nov-e | nov-a |
| voc | nov-i | nov-e | nov-a |
| ins | nov-im / nov-ima | nov-im / nov-ima | nov-im / nov-ima |
| loc | nov-im / nov-ima | nov-im / nov-ima | nov-im / nov-ima |

#### Definite Forms

**Singular**:

| Case | Masculine | Feminine | Neuter |
|------|-----------|----------|--------|
| nom | nov-i | nov-a | nov-o |
| gen | nov-og(a) | nov-e | nov-og(a) |
| dat | nov-om(u/e) | nov-oj | nov-om(u/e) |
| acc | nov-i (inan) / nov-og(a) (anim) | nov-u | nov-o |
| voc | nov-i | nov-a | nov-o |
| ins | nov-im | nov-om | nov-im |
| loc | nov-om(e/u) | nov-oj | nov-om(e/u) |

**Plural**: Same as indefinite for most forms.

---

## Soft Stem Adjectives

Adjectives whose stem ends in a soft consonant (č, ć, š, ž, đ, dž, j, lj, nj) have slight variations:

**Example: svež (fresh)**

| Form | Hard Stem (nov) | Soft Stem (svež) |
|------|-----------------|------------------|
| nom_sg_n | novo | sveže |
| nom_pl_n | nova | sveža |
| ins_sg_m | novim | svežim |

The difference is primarily using `-e-` instead of `-o-` in some endings.

---

## Comparison (Comparative & Superlative)

### Regular Comparative

Add `-iji` to the stem:

- nov → noviji (newer)
- star → stariji (older)

### Irregular Comparative

Some adjectives have suppletive or modified stems. Store in `grammar_metadata.comparative_stem`:

| Positive | Comparative | Note |
|----------|-------------|------|
| dobar | bolji | completely irregular |
| loš | gori | |
| velik | veći | |
| mali | manji | |
| lak | lakši | |

### Superlative

Add prefix `naj-` to comparative:

- noviji → najnoviji
- bolji → najbolji

---

## Grammar Metadata Keys

| Key | Type | Effect |
|-----|------|--------|
| `comparative_stem` | string | Base for comparative (e.g., "bolj" for dobar) |
| `superlative_stem` | string | Full superlative stem if irregular |
| `no_short_form` | boolean | Lacks indefinite forms (some participle-derived adjectives) |
| `indeclinable` | boolean | Foreign adjectives that don't decline (bež, fer) |
| `soft_stem` | boolean | Stem ends in soft consonant |
| `irregular_forms` | map | Override specific forms |

---

## Animacy in Masculine Accusative

Just like nouns, masculine adjectives in accusative singular depend on the animacy of the noun they modify:

- **Animate**: acc = gen form (novog čoveka)
- **Inanimate**: acc = nom form (nov grad)

**For the inflector**: Generate BOTH forms for accusative masculine singular:
- `indef_acc_sg_m_anim` → genitive form
- `indef_acc_sg_m_inan` → nominative form

Or: Generate one form with `acc_sg_m` and document that it could be either (simpler).

**Recommended approach**: Generate the inanimate form (= nominative) by default, note in comments that animate uses genitive. The search will find the genitive form anyway if user searches for it.

---

## Algorithm Outline

```
1. Check if indeclinable → return just base form
2. Extract stem from word.term
3. Determine if soft stem (check ending consonant or metadata)
4. Generate indefinite forms (42 forms)
5. Generate definite forms (42 forms)
6. If comparative_stem exists, generate comparative forms
7. If superlative, generate superlative forms
8. Apply irregular_forms overrides
9. Return list of {lowercase_form, form_tag}
```

---

## Stem Extraction

The dictionary form is masculine indefinite nominative singular.

| Term Ending | Stem |
|-------------|------|
| consonant | term itself (nov → nov) |
| -i | remove -i if it's definite form stored |

Most adjectives in dictionary form end in a consonant. The stem = the term.

---

## Endings Tables

### Indefinite Singular

| Case | M | F | N |
|------|---|---|---|
| nom | — | -a | -o/-e |
| gen | -a | -e | -a |
| dat | -u | -oj | -u |
| acc | —/-a | -u | -o/-e |
| voc | — | -a | -o/-e |
| ins | -im | -om | -im |
| loc | -u/-om | -oj | -u/-om |

### Indefinite Plural

| Case | M | F | N |
|------|---|---|---|
| nom | -i | -e | -a |
| gen | -ih | -ih | -ih |
| dat | -im(a) | -im(a) | -im(a) |
| acc | -e | -e | -a |
| voc | -i | -e | -a |
| ins | -im(a) | -im(a) | -im(a) |
| loc | -im(a) | -im(a) | -im(a) |

### Definite Singular

| Case | M | F | N |
|------|---|---|---|
| nom | -i | -a | -o/-e |
| gen | -og(a) | -e | -og(a) |
| dat | -om(u) | -oj | -om(u) |
| acc | -i/-og(a) | -u | -o/-e |
| voc | -i | -a | -o/-e |
| ins | -im | -om | -im |
| loc | -om(e) | -oj | -om(e) |

### Definite Plural

Same as indefinite plural.

---

## Test Cases

### Test 1: Regular Adjective (nov)

```elixir
word = %Word{
  term: "nov",
  part_of_speech: :adjective,
  gender: :masculine  # dictionary form gender
}

# Expected 84+ forms
# indef_nom_sg_m: "nov"
# indef_nom_sg_f: "nova"
# def_nom_sg_m: "novi"
```

### Test 2: Soft Stem (svež)

```elixir
word = %Word{
  term: "svež",
  part_of_speech: :adjective,
  gender: :masculine,
  grammar_metadata: %{"soft_stem" => true}
}

# indef_nom_sg_n: "sveže" (not "svežo")
```

### Test 3: Irregular Comparative (dobar)

```elixir
word = %Word{
  term: "dobar",
  part_of_speech: :adjective,
  gender: :masculine,
  grammar_metadata: %{
    "comparative_stem" => "bolj",
    "fleeting_a" => true  # dobar → dobr- when adding endings
  }
}

# indef_nom_sg_m: "dobar"
# indef_nom_sg_f: "dobra"
# comp_nom_sg_m: "bolji"
# super_nom_sg_m: "najbolji"
```

### Test 4: Indeclinable (bež)

```elixir
word = %Word{
  term: "bež",
  part_of_speech: :adjective,
  gender: :masculine,
  grammar_metadata: %{"indeclinable" => true}
}

# Returns only: {"bež", "base"} or {"bež", "invariable"}
```

### Test 5: Adjective from Participle (otvoren - opened)

```elixir
word = %Word{
  term: "otvoren",
  part_of_speech: :adjective,
  gender: :masculine
}

# Regular declension, definite: otvoreni
```

### Test 6: Velik (big) - Irregular Comparative

```elixir
word = %Word{
  term: "velik",
  part_of_speech: :adjective,
  gender: :masculine,
  grammar_metadata: %{
    "comparative_stem" => "već",
    "irregular_forms" => %{
      "comp_nom_sg_m" => "veći"
    }
  }
}

# comp_nom_sg_m: "veći"
# super_nom_sg_m: "najveći"
```

---

## Soft Stem Detection

If `grammar_metadata.soft_stem` is not set, detect automatically:

```elixir
@soft_consonants ~w(č ć š ž đ j)

def soft_stem?(term) do
  last_char = String.last(term)
  last_char in @soft_consonants
end
```

Note: "lj" and "nj" are digraphs, so check for those too.

---

## Fleeting A

Some adjectives have a fleeting "a" (like nouns):
- dobar → dobr-a (feminine)
- tanak → tank-a (feminine)

When `grammar_metadata.fleeting_a == true`, remove the "a" before adding endings.

```elixir
# dobar with fleeting_a
stem = "dobr"  # not "dobar"
feminine = stem <> "a" = "dobra"
```

---

## Output Format

```elixir
[
  {"nov", "indef_nom_sg_m"},
  {"nova", "indef_nom_sg_f"},
  {"novo", "indef_nom_sg_n"},
  {"nova", "indef_gen_sg_m"},
  {"nove", "indef_gen_sg_f"},
  {"nova", "indef_gen_sg_n"},
  # ... 42 indefinite forms
  {"novi", "def_nom_sg_m"},
  {"nova", "def_nom_sg_f"},
  {"novo", "def_nom_sg_n"},
  # ... 42 definite forms
  {"noviji", "comp_nom_sg_m"},
  # ... comparative forms
  {"najnoviji", "super_nom_sg_m"},
  # ... superlative forms
]
```

---

## Simplification Options

If full 168 forms is overwhelming for MVP:

**Option A**: Generate only positive forms (84 forms)
- Skip comparative and superlative
- Can add later

**Option B**: Generate fewer case combinations
- Nominative, genitive, accusative only (most common)
- Add remaining cases later

**Recommended**: Start with Option A (positive only), add comparison later.

---

## Do NOT

- Handle other parts of speech
- Generate noun forms
- Modify schemas
- Insert into database

---

## Acceptance Criteria

1. `applicable?/1` returns true only for adjectives
2. `generate_forms/1` returns indefinite + definite forms (minimum 84)
3. Soft stem uses correct endings (-e vs -o)
4. Fleeting A handled correctly
5. Indeclinable adjectives return only base form
6. Irregular comparative stems work
7. All test cases pass
