# Agent A: Serbian Noun Inflector

## Objective

Implement `Ohmyword.Linguistics.Nouns` module that generates all declined forms of Serbian nouns.

---

## File to Create

```
lib/ohmyword/linguistics/nouns.ex
test/ohmyword/linguistics/nouns_test.exs
```

---

## Behaviour Implementation

Implement the `Ohmyword.Linguistics.Inflector` behaviour:

```elixir
defmodule Ohmyword.Linguistics.Nouns do
  @behaviour Ohmyword.Linguistics.Inflector
  
  @impl true
  def applicable?(word), do: word.part_of_speech == :noun
  
  @impl true
  def generate_forms(word) do
    # Return list of {term, form_tag} tuples
  end
end
```

---

## Serbian Noun Declension Overview

Serbian nouns decline across:
- **7 cases**: nominative, genitive, dative, accusative, vocative, instrumental, locative
- **2 numbers**: singular, plural

This produces **14 forms** per noun (some may be identical).

### The Cases

| Case | Abbreviation | Question | Usage |
|------|--------------|----------|-------|
| Nominative | nom | ko? šta? (who? what?) | Subject |
| Genitive | gen | koga? čega? (of whom? of what?) | Possession, partitive, after certain prepositions |
| Dative | dat | kome? čemu? (to whom? to what?) | Indirect object |
| Accusative | acc | koga? šta? (whom? what?) | Direct object |
| Vocative | voc | (direct address) | Calling someone |
| Instrumental | ins | kim? čim? (with whom? with what?) | Means, accompaniment |
| Locative | loc | o kome? o čemu? (about whom?) | Location (always with preposition) |

---

## Form Tags to Generate

```
nom_sg, gen_sg, dat_sg, acc_sg, voc_sg, ins_sg, loc_sg
nom_pl, gen_pl, dat_pl, acc_pl, voc_pl, ins_pl, loc_pl
```

---

## Declension Classes

### 1. Masculine Consonant Stems (declension_class: "consonant")

Base pattern for masculine nouns ending in a consonant.

**Example: grad (city)**

| Case | Singular | Plural |
|------|----------|--------|
| nom | grad | grad-ov-i |
| gen | grad-a | grad-ov-a |
| dat | grad-u | grad-ov-ima |
| acc | grad (inanimate) | grad-ov-e |
| voc | grad-e | grad-ov-i |
| ins | grad-om | grad-ov-ima |
| loc | grad-u | grad-ov-ima |

**Endings (consonant stem masculine)**:

| Case | Singular | Plural |
|------|----------|--------|
| nom | — | -ovi / -evi / -i |
| gen | -a | -ova / -eva / -a |
| dat | -u | -ovima / -evima / -ima |
| acc | — (inan) / -a (anim) | -ove / -eve / -e |
| voc | -e / -u | -ovi / -evi / -i |
| ins | -om / -em | -ovima / -evima / -ima |
| loc | -u | -ovima / -evima / -ima |

**Plural stem selection**:
- Most consonant stems: add `-ov-` before plural endings (grad → gradovi)
- Stems ending in palatals (č, ć, š, ž, đ, dž, j, lj, nj): add `-ev-` (muž → muževi)
- Some short stems: no insert, just endings (zub → zubi)

### 2. Masculine with Fleeting A (grammar_metadata.fleeting_a: true)

The vowel "a" in the final syllable disappears when endings are added.

**Example: pas (dog)**

| Case | Singular | Plural |
|------|----------|--------|
| nom | pas | ps-i |
| gen | ps-a | pas-a |
| dat | ps-u | ps-ima |
| acc | ps-a (animate) | ps-e |
| voc | ps-e | ps-i |
| ins | ps-om | ps-ima |
| loc | ps-u | ps-ima |

**Pattern**: Remove the "a" before the final consonant when adding endings.
- pas → ps- (stem for most forms)
- But gen_pl keeps the "a": pasa

**Common fleeting-a nouns**: pas, san (dream), dan (day → but irregular), vrabac (sparrow)

### 3. A-Stem Feminine (declension_class: "a-stem")

Feminine nouns ending in -a.

**Example: žena (woman)**

| Case | Singular | Plural |
|------|----------|--------|
| nom | žen-a | žen-e |
| gen | žen-e | žen-a |
| dat | žen-i | žen-ama |
| acc | žen-u | žen-e |
| voc | žen-o | žen-e |
| ins | žen-om | žen-ama |
| loc | žen-i | žen-ama |

**Endings**:

| Case | Singular | Plural |
|------|----------|--------|
| nom | -a | -e |
| gen | -e | -a |
| dat | -i | -ama |
| acc | -u | -e |
| voc | -o | -e |
| ins | -om | -ama |
| loc | -i | -ama |

### 4. A-Stem Masculine (declension_class: "a-stem", gender: masculine)

Some masculine nouns end in -a (typically names, professions).

**Example: tata (dad)**

| Case | Singular | Plural |
|------|----------|--------|
| nom | tat-a | tat-e |
| gen | tat-e | tat-a |
| dat | tat-i | tat-ama |
| acc | tat-u | tat-e |
| voc | tat-o | tat-e |
| ins | tat-om | tat-ama |
| loc | tat-i | tat-ama |

Same endings as feminine a-stem, but noun is grammatically masculine (adjective agreement is masculine).

### 5. O-Stem Neuter (declension_class: "o-stem")

Neuter nouns ending in -o.

**Example: selo (village)**

| Case | Singular | Plural |
|------|----------|--------|
| nom | sel-o | sel-a |
| gen | sel-a | sel-a |
| dat | sel-u | sel-ima |
| acc | sel-o | sel-a |
| voc | sel-o | sel-a |
| ins | sel-om | sel-ima |
| loc | sel-u | sel-ima |

**Endings**:

| Case | Singular | Plural |
|------|----------|--------|
| nom | -o | -a |
| gen | -a | -a |
| dat | -u | -ima |
| acc | -o | -a |
| voc | -o | -a |
| ins | -om | -ima |
| loc | -u | -ima |

### 6. E-Stem Neuter (declension_class: "e-stem")

Neuter nouns ending in -e.

**Example: polje (field)**

| Case | Singular | Plural |
|------|----------|--------|
| nom | polj-e | polj-a |
| gen | polj-a | polj-a |
| dat | polj-u | polj-ima |
| acc | polj-e | polj-a |
| voc | polj-e | polj-a |
| ins | polj-em | polj-ima |
| loc | polj-u | polj-ima |

Same as o-stem except:
- ins_sg: -em (not -om)

### 7. I-Stem Feminine (declension_class: "i-stem")

Feminine nouns ending in a consonant.

**Example: stvar (thing)**

| Case | Singular | Plural |
|------|----------|--------|
| nom | stvar | stvar-i |
| gen | stvar-i | stvar-i |
| dat | stvar-i | stvar-ima |
| acc | stvar | stvar-i |
| voc | stvar-i | stvar-i |
| ins | stvar-i / stvarju | stvar-ima |
| loc | stvar-i | stvar-ima |

**Endings**:

| Case | Singular | Plural |
|------|----------|--------|
| nom | — | -i |
| gen | -i | -i |
| dat | -i | -ima |
| acc | — | -i |
| voc | -i | -i |
| ins | -i / -ju | -ima |
| loc | -i | -ima |

---

## Grammar Metadata Keys

Read these from `word.grammar_metadata`:

| Key | Type | Effect |
|-----|------|--------|
| `fleeting_a` | boolean | Remove "a" from stem when adding endings |
| `palatalization` | boolean | Consonant changes in vocative (k→č, g→ž, h→š) |
| `irregular_plural` | string | Override entire plural stem (e.g., "ljudi" for čovek) |
| `irregular_forms` | map | Override specific forms (e.g., `%{"gen_pl" => "očiju"}`) |
| `singularia_tantum` | boolean | No plural forms exist |
| `pluralia_tantum` | boolean | No singular forms exist (term is plural) |

---

## Animacy Rule (Critical)

For **masculine nouns only**:
- `word.animate == true`: Accusative = Genitive form
- `word.animate == false`: Accusative = Nominative form

This applies to both singular and plural.

**Examples**:
- "Vidim psa" (I see the dog) — animate, acc = gen
- "Vidim grad" (I see the city) — inanimate, acc = nom

---

## Palatalization (Vocative)

When `grammar_metadata.palatalization == true`, apply consonant changes in vocative singular:

| Original | Becomes | Example |
|----------|---------|---------|
| k | č | junak → junače |
| g | ž | bog → bože |
| h | š | duh → duše |
| c | č | otac → oče |
| z | ž | knez → kneže |

---

## Algorithm Outline

```
1. Extract stem from word.term based on declension_class
2. Check for irregular_forms overrides
3. Check for singularia_tantum / pluralia_tantum
4. For each case × number:
   a. If override exists, use it
   b. Otherwise, apply regular ending
   c. Apply fleeting_a if needed
   d. Apply palatalization for vocative if needed
   e. Handle animacy for accusative
5. Return list of {lowercase_form, form_tag}
```

---

## Stem Extraction

| Declension Class | Term Example | Stem |
|------------------|--------------|------|
| consonant | grad | grad |
| a-stem | žena | žen (remove -a) |
| o-stem | selo | sel (remove -o) |
| e-stem | polje | polj (remove -e) |
| i-stem | stvar | stvar |
| consonant + fleeting_a | pas | ps (remove fleeting a) |

---

## Test Cases

### Test 1: Basic Masculine Inanimate (grad)

```elixir
word = %Word{
  term: "grad",
  part_of_speech: :noun,
  gender: :masculine,
  animate: false,
  declension_class: "consonant"
}

# Expected: 14 forms
# acc_sg should equal nom_sg ("grad")
```

### Test 2: Masculine Animate with Fleeting A (pas)

```elixir
word = %Word{
  term: "pas",
  part_of_speech: :noun,
  gender: :masculine,
  animate: true,
  declension_class: "consonant",
  grammar_metadata: %{"fleeting_a" => true}
}

# Expected:
# nom_sg: "pas"
# gen_sg: "psa"
# acc_sg: "psa" (animate = genitive)
# gen_pl: "pasa" (fleeting a returns)
```

### Test 3: Feminine A-Stem (žena)

```elixir
word = %Word{
  term: "žena",
  part_of_speech: :noun,
  gender: :feminine,
  declension_class: "a-stem"
}

# Expected 14 forms following a-stem pattern
```

### Test 4: Neuter O-Stem (selo)

```elixir
word = %Word{
  term: "selo",
  part_of_speech: :noun,
  gender: :neuter,
  declension_class: "o-stem"
}
```

### Test 5: Irregular Plural (čovek → ljudi)

```elixir
word = %Word{
  term: "čovek",
  part_of_speech: :noun,
  gender: :masculine,
  animate: true,
  declension_class: "consonant",
  grammar_metadata: %{"irregular_plural" => "ljudi"}
}

# nom_pl, voc_pl: "ljudi"
# gen_pl: "ljudi"
# dat_pl, ins_pl, loc_pl: "ljudima"
# acc_pl: "ljude"
```

### Test 6: Palatalization in Vocative (junak)

```elixir
word = %Word{
  term: "junak",
  part_of_speech: :noun,
  gender: :masculine,
  animate: true,
  declension_class: "consonant",
  grammar_metadata: %{"palatalization" => true}
}

# voc_sg: "junače" (k → č)
```

### Test 7: Specific Form Override (oko → očiju)

```elixir
word = %Word{
  term: "oko",
  part_of_speech: :noun,
  gender: :neuter,
  declension_class: "o-stem",
  grammar_metadata: %{
    "irregular_forms" => %{"gen_pl" => "očiju"}
  }
}

# gen_pl: "očiju" (override)
# other forms: regular
```

### Test 8: Singularia Tantum (mleko - milk)

```elixir
word = %Word{
  term: "mleko",
  part_of_speech: :noun,
  gender: :neuter,
  declension_class: "o-stem",
  grammar_metadata: %{"singularia_tantum" => true}
}

# Only 7 singular forms, no plural
```

### Test 9: Feminine I-Stem (stvar)

```elixir
word = %Word{
  term: "stvar",
  part_of_speech: :noun,
  gender: :feminine,
  declension_class: "i-stem"
}

# 14 forms following i-stem pattern
```

---

## Edge Cases to Handle

1. **Empty or nil declension_class**: Infer from gender + term ending
2. **Missing animacy for masculine**: Default to inanimate or raise error
3. **Term already lowercase**: Ensure output is always lowercase
4. **Duplicate forms**: Multiple cases may produce same surface form (that's OK)

---

## Inference Rules (if declension_class is nil)

| Gender | Term Ends In | Inferred Class |
|--------|--------------|----------------|
| masculine | consonant | consonant |
| masculine | -a | a-stem |
| masculine | -o | o-stem |
| feminine | -a | a-stem |
| feminine | consonant | i-stem |
| neuter | -o | o-stem |
| neuter | -e | e-stem |

---

## Output Format

Return a list of tuples, all terms lowercase:

```elixir
[
  {"grad", "nom_sg"},
  {"grada", "gen_sg"},
  {"gradu", "dat_sg"},
  {"grad", "acc_sg"},
  {"grade", "voc_sg"},
  {"gradom", "ins_sg"},
  {"gradu", "loc_sg"},
  {"gradovi", "nom_pl"},
  {"gradova", "gen_pl"},
  {"gradovima", "dat_pl"},
  {"gradove", "acc_pl"},
  {"gradovi", "voc_pl"},
  {"gradovima", "ins_pl"},
  {"gradovima", "loc_pl"}
]
```

---

## Do NOT

- Handle other parts of speech (verbs, adjectives, etc.)
- Modify the Word schema
- Create database migrations
- Handle search_terms insertion (CacheManager does that)

---

## Acceptance Criteria

1. `applicable?/1` returns true only for nouns
2. `generate_forms/1` returns 14 forms for regular nouns
3. Fleeting-a is correctly applied
4. Animacy determines accusative form
5. Palatalization works in vocative
6. Irregular overrides are respected
7. Singularia/pluralia tantum handled
8. All test cases pass
