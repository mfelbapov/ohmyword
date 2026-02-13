# MASTER PROMPT: Serbian Language Learning App (Ohmyword)

> [!IMPORTANT]
> **Portfolio Note**: This document serves as the primary specification for the "Ohmyword" application. It demonstrates the ability to translate complex linguistic requirements into actionable technical specifications for AI-assisted development.

---

## 1. Project Context & Goals

**Objective**: Build a vocabulary learning application for English speakers learning Serbian, specifically addressing the grammatical complexities (cases, genders, aspects) that generic apps miss.

**Target Audience**: My son (primary), and other English speakers learning Serbian.

**Core Philosophy**: "Fake it till you automate it." Use a two-layer data architecture to separate linguistic correctness ("Source of Truth") from search performance ("Search Cache").

---

## 2. Architecture Strategy

### The "Two-Table" Approach

We separate the linguistic model from the access model.

1.  **`vocabulary_words` (Source of Truth)**
    *   Stores the "dictionary entry" or lemma.
    *   Contains deep linguistic metadata (gender, aspect pairs, etc.).
    *   Normalized.

2.  **`search_terms` (Search Cache)**
    *   Stores *every possible form* of a word (e.g., all 7 cases x 2 numbers = 14 forms for a noun).
    *   Dual-form storage: `term` (ASCII-stripped, for matching) + `display_form` (with diacritics, for display).
    *   Maps directly to the `word_id` (FK to vocabulary_words).
    *   Optimized for fast lookup via B-tree index.
    *   **Generation**: Seed forms are loaded from `vocabulary_seed.json` as locked entries; a rule engine (`Linguistics.Dispatcher`) generates remaining forms via `CacheManager.regenerate_word/1`.

### Script Handling (Latin vs. Cyrillic)
*   **Database**: Store EVERYTHING in **Latin** script.
*   **UI**: Dynamically render Cyrillic using a robust transliteration utility.
*   **Input**: Allow users to type in either script; normalize to Latin for search.

---

## 3. Database Schema Specification

### Enums (Postgres)
Define these native enums for data integrity.

```sql
CREATE TYPE part_of_speech AS ENUM ('noun', 'verb', 'adjective', 'adverb', 'pronoun', 'preposition', 'conjunction', 'interjection', 'particle', 'numeral');
CREATE TYPE grammatical_gender AS ENUM ('masculine', 'feminine', 'neuter');
CREATE TYPE verb_aspect AS ENUM ('perfective', 'imperfective', 'biaspectual');
CREATE TYPE search_term_source AS ENUM ('seed', 'manual', 'engine');
```

### Table: `vocabulary_words`

| Column | Type | Nullable | Notes |
| :--- | :--- | :--- | :--- |
| `id` | Integer | PK | Auto-increment |
| `term` | String | No | The headword (nominative singular or infinitive) |
| `translation` | String | No | Primary English translation |
| `translations` | Array[String] | No | defaults to `[]` |
| `part_of_speech` | part_of_speech | No | |
| `gender` | gender | Yes | Required for Nouns |
| `animate` | Boolean | Yes | Required for Masc. Nouns (affects Accusative) |
| `verb_aspect` | verb_aspect | Yes | Required for Verbs |
| `aspect_pair_id` | Integer | Yes | FK to `vocabulary_words` (self-ref) |
| `declension_class`| String | Yes | e.g., "consonant", "a_stem", "o_stem", "e_stem", "i_stem" |
| `usage_notes` | Text | Yes | Markdown supported |
| `categories` | Array[String] | No | defaults to `[]` |
| `proficiency_level`| Integer | No | 1-9 scale, defaults to 1 |
| `example_sentence_rs` | Text | Yes | Example sentence in Serbian |
| `example_sentence_en` | Text | Yes | Example sentence translated |
| `audio_url` | String | Yes | URL to pronunciation audio |
| `image_url` | String | Yes | URL to associated image |
| `conjugation_class` | String | Yes | For verbs only |
| `reflexive` | Boolean | Yes | For verbs only |
| `transitive` | Boolean | Yes | For verbs only |
| `grammar_metadata` | Map | No | defaults to `{}`, flexible grammar info |

### Table: `search_terms`

| Column | Type | Nullable | Notes |
| :--- | :--- | :--- | :--- |
| `id` | Integer | PK | Auto-increment |
| `term` | String | No | ASCII-stripped, lowercased form (for matching) |
| `display_form` | String | No | Original form with diacritics, lowercased (for display) |
| `word_id` | Integer | No | FK to `vocabulary_words` |
| `form_tag` | String | No | e.g., "gen_sg" (Genitive Singular) |
| `source` | search_term_source | No | defaults to 'seed' |
| `locked` | Boolean | Yes | defaults to false, prevents auto-updates |

**Note**: Diacritics are stripped at storage time (`term` column) via `Utils.Transliteration.strip_diacritics/1`. The `display_form` column preserves diacritics for rendering. Search queries are normalized to ASCII before matching against `term`.

---

## 4. Ecto Schema & Validation Rules

### `Ohmyword.Vocabulary.Word`
*   **Validations**:
    *   `term` and `translation` are required.
    *   If `part_of_speech` is `:noun`, `gender` is required.
    *   If `part_of_speech` is `:verb`, `verb_aspect` is required.
    *   `animate` defaults to `false`.
    *   `proficiency_level` must be an integer from 1-9.

### `Ohmyword.Search.SearchTerm`
*   **Indexes**:
    *   B-tree index on `search_terms.term` for efficient lookups.
    *   Unique constraint on `(term, word_id, form_tag)` to prevent duplicate entries.

---

## 5. Transliteration Utility (`Ohmyword.Utils.Transliteration`)

Implement a module with 1:1 mapping for Serbian Latin ↔ Cyrillic.

**Mapping Rules**:
*   A ↔ А
*   B ↔ Б
*   C ↔ Ц
*   Č ↔ Ч
*   Ć ↔ Ћ
*   Dž ↔ Џ (Digraph!)
*   Đ ↔ Ђ
*   E ↔ Е
*   F ↔ Ф
*   G ↔ Г
*   H ↔ Х
*   I ↔ И
*   J ↔ Ј
*   K ↔ К
*   L ↔ Л
*   Lj ↔ Љ (Digraph!)
*   M ↔ М
*   N ↔ Н
*   Nj ↔ Њ (Digraph!)
*   O ↔ О
*   P ↔ П
*   R ↔ Р
*   S ↔ С
*   Š ↔ Ш
*   T ↔ Т
*   U ↔ У
*   V ↔ В
*   Z ↔ З
*   Ž ↔ Ж

**Key Functions**:
*   `to_cyrillic(text)`: Converts Latin input to Cyrillic. *Handle digraphs (Lj, Nj, Dž) carefully—they must be converted before single letters.*
*   `to_latin(text)`: Converts Cyrillic input to Latin.
*   `strip_diacritics(text)`: Removes Serbian diacritics (č→c, ć→c, š→s, ž→z, đ→dj) for search normalization.

---

## 6. Seed Data Strategy

Vocabulary is stored in `priv/repo/vocabulary_seed.json` and loaded by `priv/repo/seeds.exs`.

**Current**: 521 words with full inflected forms across all parts of speech (nouns, verbs, adjectives, adverbs, pronouns, numerals, prepositions, conjunctions, interjections, particles).

Every word includes a `forms` array containing all inflected forms, validated against both LLM knowledge and the inflection engine. This enables automated bulk validation via `mix run validate_existing_words.exs`.

**Example Structure**:
```json
{
  "term": "pas",
  "translation": "dog",
  "part_of_speech": "noun",
  "gender": "masculine",
  "animate": true,
  "declension_class": "consonant",
  "proficiency_level": 1,
  "categories": ["animals"],
  "grammar_metadata": {},
  "forms": [
    {"form_tag": "nom_sg", "term": "pas"},
    {"form_tag": "gen_sg", "term": "psa"},
    {"form_tag": "dat_sg", "term": "psu"},
    ...
  ]
}
```

The seed script clears existing data, inserts each `Word`, loads its `forms` as locked `SearchTerm` entries (ASCII-stripped `term` + diacritical `display_form`), then runs `CacheManager.regenerate_word/1` to fill any engine-generated forms.

---
