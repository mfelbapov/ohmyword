# Agent F: Serbian Invariables Inflector

## Objective

Implement `Ohmyword.Linguistics.Invariables` module that handles all non-declining parts of speech: adverbs, prepositions, conjunctions, interjections, and particles.

---

## File to Create

```
lib/ohmyword/linguistics/invariables.ex
test/ohmyword/linguistics/invariables_test.exs
```

---

## Behaviour Implementation

```elixir
defmodule Ohmyword.Linguistics.Invariables do
  @behaviour Ohmyword.Linguistics.Inflector
  
  @invariable_pos [:adverb, :preposition, :conjunction, :interjection, :particle]
  
  @impl true
  def applicable?(word), do: word.part_of_speech in @invariable_pos
  
  @impl true
  def generate_forms(word) do
    # Return list of {term, form_tag} tuples
  end
end
```

---

## Parts of Speech Covered

| POS | Examples | Notes |
|-----|----------|-------|
| adverb | brzo, polako, ovde, tamo | Some have comparison |
| preposition | u, na, za, iz, kod, preko | Invariable, govern cases |
| conjunction | i, ili, ali, jer, ako, da | Invariable |
| interjection | ej, oj, jao, bravo | Invariable |
| particle | li, ne, da, zar, čak | Invariable |

---

## Basic Strategy

For most invariables:
1. Return just the base form with tag `"base"` or `"invariable"`
2. For adverbs with comparison, also return comparative and superlative

---

## Adverbs

### Invariable Adverbs (Most Common)

Most adverbs don't change form:

| Adverb | Meaning |
|--------|---------|
| ovde | here |
| tamo | there |
| sada | now |
| onda | then |
| uvek | always |
| nikad | never |
| možda | maybe |
| već | already |
| još | still, yet |
| vrlo | very |

For these: return `[{term, "base"}]`

### Adverbs with Comparison

Some adverbs (usually derived from adjectives) have comparative and superlative:

| Positive | Comparative | Superlative |
|----------|-------------|-------------|
| brzo (quickly) | brže | najbrže |
| polako (slowly) | sporije | najsporije |
| dobro (well) | bolje | najbolje |
| loše (badly) | gore | najgore |
| daleko (far) | dalje | najdalje |
| blizu (near) | bliže | najbliže |

---

## Grammar Metadata Keys for Adverbs

| Key | Type | Effect |
|-----|------|--------|
| `comparative` | string | Comparative form (e.g., "brže") |
| `superlative` | string | Superlative form (e.g., "najbrže") |
| `derived_from` | string | Source adjective (for documentation) |
| `no_comparison` | boolean | Explicitly mark as not comparable |

---

## Adverb Algorithm

```
1. Add base form: {word.term, "base"}
2. Check grammar_metadata.comparative
   - If present: add {comparative, "comp"}
3. Check grammar_metadata.superlative
   - If present: add {superlative, "super"}
4. Return list
```

---

## Prepositions

All prepositions are invariable. Just return the base form.

| Preposition | Meaning | Governs |
|-------------|---------|---------|
| u | in, into | acc (motion), loc (static) |
| na | on, onto | acc (motion), loc (static) |
| za | for, behind | acc, ins |
| iz | from, out of | gen |
| od | from | gen |
| do | to, until | gen |
| kod | at, by | gen |
| sa/s | with | ins (or gen for "from") |
| bez | without | gen |
| preko | over, across | gen |
| ispod | under | gen |
| iznad | above | gen |
| između | between | gen |
| prema | towards | dat |
| ka | towards | dat |
| po | by, around | loc |
| pri | at, during | loc |
| o | about | loc |

**Output**: `[{term, "base"}]`

The case governance info is stored in `grammar_metadata.governs` but doesn't affect the form — it's just metadata for the learning app.

---

## Conjunctions

All conjunctions are invariable.

### Coordinating Conjunctions

| Conjunction | Meaning |
|-------------|---------|
| i | and |
| pa | and, so |
| ni | nor |
| ili | or |
| ali | but |
| a | and/but (contrast) |
| nego | but, than |
| već | but (after negative) |

### Subordinating Conjunctions

| Conjunction | Meaning |
|-------------|---------|
| da | that, to |
| jer | because |
| ako | if |
| kada/kad | when |
| dok | while |
| pošto | since, after |
| iako | although |
| mada | although |
| čim | as soon as |
| pre nego što | before |

**Output**: `[{term, "base"}]`

---

## Interjections

All interjections are invariable.

| Interjection | Usage |
|--------------|-------|
| ej | hey |
| oj | hey, oh |
| jao | oh no, ouch |
| bravo | bravo |
| aha | aha |
| oh | oh |
| ah | ah |
| hej | hey |
| uf | ugh |
| joj | oh dear |

**Output**: `[{term, "base"}]`

---

## Particles

All particles are invariable.

| Particle | Usage |
|----------|-------|
| li | question marker |
| ne | negation |
| da | yes, affirmation |
| zar | rhetorical question |
| čak | even |
| baš | just, exactly |
| tek | only, just |
| već | already |
| još | still, more |
| samo | only |
| možda | maybe |

**Output**: `[{term, "base"}]`

---

## Form Tags

| Tag | Usage |
|-----|-------|
| `base` | The invariable form (most common) |
| `comp` | Comparative adverb |
| `super` | Superlative adverb |
| `invariable` | Alternative to "base" |

Use `base` for simplicity. `invariable` is acceptable synonym.

---

## Test Cases

### Test 1: Simple Adverb (ovde)

```elixir
word = %Word{
  term: "ovde",
  part_of_speech: :adverb
}

# Expected: [{"ovde", "base"}]
```

### Test 2: Adverb with Comparison (brzo)

```elixir
word = %Word{
  term: "brzo",
  part_of_speech: :adverb,
  grammar_metadata: %{
    "comparative" => "brže",
    "superlative" => "najbrže",
    "derived_from" => "brz"
  }
}

# Expected:
# [
#   {"brzo", "base"},
#   {"brže", "comp"},
#   {"najbrže", "super"}
# ]
```

### Test 3: Irregular Adverb Comparison (dobro)

```elixir
word = %Word{
  term: "dobro",
  part_of_speech: :adverb,
  grammar_metadata: %{
    "comparative" => "bolje",
    "superlative" => "najbolje"
  }
}

# Expected:
# [
#   {"dobro", "base"},
#   {"bolje", "comp"},
#   {"najbolje", "super"}
# ]
```

### Test 4: Preposition (u)

```elixir
word = %Word{
  term: "u",
  part_of_speech: :preposition,
  grammar_metadata: %{
    "governs" => ["accusative", "locative"]
  }
}

# Expected: [{"u", "base"}]
```

### Test 5: Conjunction (i)

```elixir
word = %Word{
  term: "i",
  part_of_speech: :conjunction
}

# Expected: [{"i", "base"}]
```

### Test 6: Interjection (jao)

```elixir
word = %Word{
  term: "jao",
  part_of_speech: :interjection
}

# Expected: [{"jao", "base"}]
```

### Test 7: Particle (li)

```elixir
word = %Word{
  term: "li",
  part_of_speech: :particle
}

# Expected: [{"li", "base"}]
```

### Test 8: Multi-word Preposition (bez obzira na)

```elixir
word = %Word{
  term: "bez obzira na",
  part_of_speech: :preposition,
  grammar_metadata: %{
    "governs" => "accusative"
  }
}

# Expected: [{"bez obzira na", "base"}]
```

---

## Full Implementation

This module is simple enough to show the complete implementation:

```elixir
defmodule Ohmyword.Linguistics.Invariables do
  @behaviour Ohmyword.Linguistics.Inflector

  @invariable_pos [:adverb, :preposition, :conjunction, :interjection, :particle]

  @impl true
  def applicable?(%{part_of_speech: pos}), do: pos in @invariable_pos
  def applicable?(_), do: false

  @impl true
  def generate_forms(%{part_of_speech: :adverb} = word) do
    base = [{String.downcase(word.term), "base"}]
    
    comparative = 
      case get_in(word.grammar_metadata, ["comparative"]) do
        nil -> []
        comp -> [{String.downcase(comp), "comp"}]
      end
    
    superlative =
      case get_in(word.grammar_metadata, ["superlative"]) do
        nil -> []
        super -> [{String.downcase(super), "super"}]
      end
    
    base ++ comparative ++ superlative
  end

  def generate_forms(word) do
    # All other invariables: just base form
    [{String.downcase(word.term), "base"}]
  end
end
```

---

## Edge Cases

### 1. Adverb without Comparison Metadata

If `comparative` or `superlative` not in metadata, just return base form.

### 2. Empty or Nil Term

Return empty list `[]`.

### 3. Multi-word Expressions

Some invariables are multi-word (e.g., "bez obzira na"). Store and return as-is.

### 4. Case Sensitivity

Always lowercase the output term.

---

## Output Format

```elixir
# Invariable
[{"i", "base"}]

# Adverb with comparison
[
  {"brzo", "base"},
  {"brže", "comp"},
  {"najbrže", "super"}
]
```

---

## Do NOT

- Handle nouns, verbs, adjectives, pronouns, numerals
- Generate declined forms (these don't decline!)
- Modify schemas
- Insert into database

---

## Acceptance Criteria

1. `applicable?/1` returns true for adverb, preposition, conjunction, interjection, particle
2. `applicable?/1` returns false for noun, verb, adjective, pronoun, numeral
3. Basic invariables return `[{term, "base"}]`
4. Adverbs with comparison metadata return base + comp + super
5. All terms are lowercased
6. All test cases pass

---

## Notes

This is the simplest inflector module. It serves as:
- A catch-all for non-declining words
- A template for how inflectors work
- Quick wins for vocabulary coverage

Most vocabulary apps will have many invariables (common words like "i", "u", "na", "ali" are among the most frequent).
