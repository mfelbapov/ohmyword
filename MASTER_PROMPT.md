# MASTER PROMPT: Serbian Language Learning App (Ohmyword)

> **Portfolio Note**: This document serves as the primary specification for the "Ohmyword" application. It demonstrates the ability to translate complex linguistic requirements into actionable technical specifications for AI-assisted development.

---

## 1. Project Context & Goals

**Objective**: Build a vocabulary learning application for English speakers learning Serbian, specifically addressing the grammatical complexities (cases, genders, aspects) that generic apps miss.

**Target Audience**: My son (primary), and other English speakers learning Serbian.

**Core Philosophy**: "Fake it till you automate it." Use a two-layer data architecture to separate linguistic correctness ("Source of Truth") from search performance ("Search Cache").

**Language Standard**: Serbian ekavski exclusively. Never ijekavski (ije/je). Use standard Serbian vocabulary, not Croatian/Bosnian/Montenegrin variants.

---

## 2. Architecture Strategy

### The "Two-Table" Approach

We separate the linguistic model from the access model.

1. **`vocabulary_words` (Source of Truth)**
   - Stores the "dictionary entry" or lemma.
   - Contains deep linguistic metadata (gender, aspect pairs, declension class, etc.).
   - Flexible `grammar_metadata` JSON field for per-word flags and irregular forms.

2. **`search_terms` (Search Cache)**
   - Stores *every possible form* of a word (e.g., all 7 cases x 2 numbers = 14 forms for a noun).
   - Dual-form storage: `term` (ASCII-stripped, for matching) + `display_form` (with diacritics, for display).
   - Maps directly to the `word_id` (FK to vocabulary_words).
   - Optimized for fast lookup via B-tree index.
   - **Generation**: Seed forms are loaded from `vocabulary_seed.json` as locked entries; a rule engine (`Linguistics.Dispatcher`) generates remaining forms via `CacheManager.regenerate_word/1`.

3. **`sentences` + `sentence_words` (Sentence Bank)**
   - Unified sentence bank with Serbian text (`text_rs`) and English translation (`text_en`).
   - `sentence_words` join table maps positions in the tokenized sentence to vocabulary words and their form tags.
   - Supports multi-blank exercises at three difficulty levels.

### Script Handling (Latin vs. Cyrillic)
- **Database**: Store EVERYTHING in **Latin** script.
- **UI**: Dynamically render Cyrillic using a robust transliteration utility.
- **Input**: Allow users to type in either script; normalize to Latin for search.

---

## 3. Database Schema Specification

### Enums (Postgres)

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
| `gender` | gender | Yes | Required for Nouns, Adjectives, Pronouns |
| `animate` | Boolean | Yes | Required for Masc. Nouns (affects Accusative) |
| `verb_aspect` | verb_aspect | Yes | Required for Verbs |
| `aspect_pair_id` | Integer | Yes | FK to `vocabulary_words` (self-ref) |
| `declension_class` | String | Yes | e.g., "consonant", "a_stem", "o_stem", "e_stem", "i_stem" |
| `conjugation_class` | String | Yes | For verbs: "a", "i", "e", "je", "irregular" |
| `reflexive` | Boolean | Yes | For verbs only |
| `transitive` | Boolean | Yes | For verbs only |
| `usage_notes` | Text | Yes | Markdown supported |
| `categories` | Array[String] | No | defaults to `[]` |
| `proficiency_level` | Integer | No | 1-9 scale, defaults to 1 |
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

### Table: `sentences`

| Column | Type | Nullable | Notes |
| :--- | :--- | :--- | :--- |
| `id` | Integer | PK | Auto-increment |
| `text_rs` | Text | No | Serbian sentence text (Latin script with diacritics) |
| `text_en` | Text | No | English translation |

### Table: `sentence_words`

| Column | Type | Nullable | Notes |
| :--- | :--- | :--- | :--- |
| `id` | Integer | PK | Auto-increment |
| `position` | Integer | No | 0-based token position in tokenized sentence |
| `form_tag` | String | No | Grammatical form tag (e.g., "pres_1sg", "acc_sg") |
| `sentence_id` | Integer | No | FK to `sentences` |
| `word_id` | Integer | No | FK to `vocabulary_words` |

**Note**: Unique constraint on `(sentence_id, position)`. Tokenization uses `[\p{L}]+` regex (Unicode letter sequences).

---

## 4. Ecto Schema & Validation Rules

### `Ohmyword.Vocabulary.Word`
- `term` and `translation` are required.
- If `part_of_speech` is `:noun`, `gender` is required.
- If `part_of_speech` is `:noun` and `gender` is `:masculine`, `animate` is required.
- If `part_of_speech` is `:verb`, `verb_aspect` is required.
- `proficiency_level` must be an integer from 1-9.

### `Ohmyword.Search.SearchTerm`
- B-tree index on `search_terms.term` for efficient lookups.
- Unique constraint on `(term, word_id, form_tag)` to prevent duplicate entries.

### `Ohmyword.Exercises.SentenceWord`
- Unique constraint on `(sentence_id, position)`.

---

## 5. Transliteration Utility (`Ohmyword.Utils.Transliteration`)

1:1 mapping for Serbian Latin <-> Cyrillic with proper digraph handling.

**Key Functions**:
- `to_cyrillic(text)`: Converts Latin input to Cyrillic. Handles digraphs (Lj, Nj, Dz) before single letters.
- `to_latin(text)`: Converts Cyrillic input to Latin.
- `strip_diacritics(text)`: Removes Serbian diacritics (c->c, c->c, s->s, z->z, dj->dj) for search normalization.

---

## 6. Seed Data Strategy

### Vocabulary (`priv/repo/vocabulary_seed.json`)

**Current**: 1022 words with full inflected forms across all parts of speech (nouns, verbs, adjectives, adverbs, pronouns, numerals, prepositions, conjunctions, interjections, particles).

Every word includes a `forms` array containing all inflected forms, validated against both LLM knowledge and the inflection engine.

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

The seed script clears existing data, inserts each Word, loads its `forms` as locked SearchTerm entries (ASCII-stripped `term` + diacritical `display_form`), then runs `CacheManager.regenerate_word/1` to fill any engine-generated forms. A second pass links aspect pairs.

### Sentences (`priv/repo/sentences_seed.json`)

**Example Structure**:
```json
{
  "text_rs": "Vidim velikog psa u parku.",
  "text_en": "I see a big dog in the park.",
  "words": [
    {"word": "Vidim", "word_term": "videti", "form_tag": "pres_1sg"},
    {"word": "velikog", "word_term": "velik", "form_tag": "def_acc_sg_m"},
    {"word": "psa", "word_term": "pas", "form_tag": "acc_sg"},
    {"word": "u", "word_term": "u", "form_tag": "invariable"},
    {"word": "parku", "word_term": "park", "form_tag": "loc_sg"}
  ]
}
```

The seed script creates Sentences, tokenizes Serbian text, and creates SentenceWord records linking positions to vocabulary words.

---

## 7. Features

### Implemented
- Dictionary search (Serbian inflected forms + English translation fallback)
- Flashcard practice (flip mode + write mode, SR<->EN direction, POS/category filters)
- Word detail pages with full inflection tables
- Multi-blank sentence exercises (3 difficulty levels, SR<->EN direction)
- Latin <-> Cyrillic script toggle throughout the UI
- Grammatical badges (POS, gender, animacy, verb aspect)
- Serbian inflection engine covering nouns, verbs, adjectives, pronouns, numerals, invariables
- Example sentences from sentence bank displayed in dictionary and flashcards
- Admin dashboard (Kaffy)
- User authentication with email confirmation

### Planned
- Spaced repetition algorithm
- Audio pronunciation
- Progress tracking per user
