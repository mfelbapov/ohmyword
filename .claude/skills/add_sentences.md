# Skill: Add Sentences to the Sentence Bank

## Overview

This skill adds new sentences to `priv/repo/sentences_seed.json` for use in the fill-in-the-blank practice exercises at `/write`. Sentences are also displayed as examples in the dictionary, word detail, and flashcard views.

## Seed File

**Path:** `priv/repo/sentences_seed.json`

The file is a JSON array of sentence objects. Each sentence has:

```json
{
  "text_rs": "Vidim velikog psa u parku.",
  "text_en": "I see a big dog in the park.",
  "words": [
    {
      "word": "Vidim",
      "word_term": "videti",
      "form_tag": "pres_1sg"
    },
    {
      "word": "velikog",
      "word_term": "velik",
      "form_tag": "def_acc_sg_m"
    },
    {
      "word": "psa",
      "word_term": "pas",
      "form_tag": "acc_sg"
    },
    {
      "word": "u",
      "word_term": "u",
      "form_tag": "invariable"
    },
    {
      "word": "parku",
      "word_term": "park",
      "form_tag": "loc_sg"
    }
  ]
}
```

## Field Definitions

### `text_rs` (string, required)
The full Serbian sentence in **Latin script** with proper diacritics (č, ć, š, ž, đ). Must include punctuation (period, question mark, exclamation mark). Capitalization follows standard Serbian rules (sentence-initial cap only, proper nouns excluded from vocabulary).

### `text_en` (string, required)
The English translation. Should be natural English, not a word-for-word gloss. Must include terminal punctuation.

### `words` (array, required)
Array of word annotation objects. **Not every word in the sentence needs to be annotated** — only words that exist in the vocabulary seed (`priv/repo/vocabulary_seed.json`) should be annotated. Function words, proper nouns, and words not in the vocabulary are left unannotated. Unannotated words cannot become blanks in exercises (except at difficulty 3, where all positions become blanks and unannotated words are checked via exact token match).

Each word annotation object has three fields:

#### `word` (string, required)
The **exact inflected form** as it appears in `text_rs`, preserving capitalization and diacritics. This is used to find the token position in the sentence via case-insensitive matching against the tokenized sentence.

**Tokenization rule:** The sentence is tokenized with the regex `[\p{L}]+` (Unicode letter sequences). All punctuation is stripped. So "Vidim velikog psa u parku." becomes `["Vidim", "velikog", "psa", "u", "parku"]`. The `word` field must exactly match one of these tokens (case-insensitive).

**Duplicate words:** If the same word form appears twice in a sentence, list both annotations separately. The seed loader uses a consumed-positions set to match them in order of appearance.

#### `word_term` (string, required)
The **dictionary base form** (lemma) of the word. Must exactly match the `term` field of a word in `priv/repo/vocabulary_seed.json`. This is used to look up the word in the database via `Repo.get_by(Word, term: word_term)`.

**Critical:** If a word_term does not exist in the vocabulary seed, the annotation will be silently skipped during seeding (logged as "SKIPPED word: 'X' not found in vocabulary"). Always verify the term exists before adding.

#### `form_tag` (string, required)
The grammatical form tag identifying which inflected form this is. Must match a form_tag that the inflection engine produces for this word, because answer checking looks up `search_terms` rows by `(word_id, form_tag)` to find acceptable answers.

## Complete Form Tag Reference

### Nouns (14 forms)
7 cases × 2 numbers:
| Singular | Plural |
|----------|--------|
| `nom_sg` | `nom_pl` |
| `gen_sg` | `gen_pl` |
| `dat_sg` | `dat_pl` |
| `acc_sg` | `acc_pl` |
| `voc_sg` | `voc_pl` |
| `ins_sg` | `ins_pl` |
| `loc_sg` | `loc_pl` |

### Verbs (18–24 forms)
| Group | Form Tags |
|-------|-----------|
| Infinitive | `inf` |
| Present | `pres_1sg`, `pres_2sg`, `pres_3sg`, `pres_1pl`, `pres_2pl`, `pres_3pl` |
| L-participle (past) | `past_m_sg`, `past_f_sg`, `past_n_sg`, `past_m_pl`, `past_f_pl`, `past_n_pl` |
| Imperative | `imp_2sg`, `imp_1pl`, `imp_2pl` |
| Passive participle | `pass_part_m_sg`, `pass_part_f_sg`, `pass_part_n_sg`, `pass_part_m_pl`, `pass_part_f_pl`, `pass_part_n_pl` |
| Adverbial participles | `pres_adv_part`, `past_adv_part` |

Note: Verbs with `no_passive_participle` metadata produce only 18 forms (no passive participle group).

### Adjectives (up to 168 forms)
Pattern: `{definiteness}_{case}_{number}_{gender}`

- **Definiteness prefixes:** `indef_`, `def_`, `comp_` (comparative), `super_` (superlative)
- **Cases:** `nom`, `gen`, `dat`, `acc`, `voc`, `ins`, `loc`
- **Numbers:** `sg`, `pl`
- **Genders:** `m`, `f`, `n`

Examples: `indef_nom_sg_m`, `def_acc_sg_f`, `comp_gen_pl_n`, `super_ins_sg_m`

Not all adjectives have comparative/superlative forms. Indeclinable adjectives use `invariable`.

### Pronouns (variable)
Personal/reflexive pronouns have case-based tags with clitic variants:
- `nom_sg`, `gen_sg`, `gen_sg_clitic`, `dat_sg`, `dat_sg_clitic`, `acc_sg`, `acc_sg_clitic`, `ins_sg`, `loc_sg`
- Plural equivalents: `nom_pl`, `gen_pl`, `gen_pl_clitic`, etc.

Possessive/demonstrative pronouns use gendered tags:
- Pattern: `{case}_{number}_{gender}` (e.g., `nom_sg_m`, `gen_sg_f`, `acc_pl_n`)
- Some have `_anim` variants: `acc_sg_m_anim`
- Some have `_alt` variants: `gen_sg_m_alt`, `dat_sg_m_alt`

### Numerals (variable)
- Cardinal "jedan": `nom_sg_m`, `nom_sg_f`, `nom_sg_n`, `gen_sg_m`, etc. (gendered singular)
- Cardinals 2-4: `nom_m`, `nom_f`, `gen`, `dat`, `acc_m`, `acc_f`, `ins`, `loc` (partially gendered)
- Cardinals 5+: `base` (invariable)
- Ordinals: same pattern as adjectives (`nom_sg_m`, `gen_sg_f`, etc.)
- Collectives: `nom`, `gen`, `dat`, `acc`, `ins`, `loc`

### Invariables (1–3 forms)
- Prepositions, conjunctions, particles, interjections: `invariable`
- Adverbs without comparison: `invariable`
- Adverbs with comparison: `base`, `comparative`, `superlative`

## How Sentences Are Used in the App

### Fill-in-the-Blank Practice (`/write` — WriteSentenceLive)

Two direction modes:

**EN→SR (default):** English sentence shown as plain text. Serbian sentence shown with blanks where annotated words are removed. User types the Serbian inflected form.

**SR→EN:** Serbian sentence shown as plain text. English sentence shown with blanks. User types the English words.

Three difficulty levels:

| Level | Blanks | Hints |
|-------|--------|-------|
| 1 (Easy) | 1 random annotated word | YES — form_tag badge + "term = translation" label |
| 2 (Medium) | 1 random annotated word | NO |
| 3 (Hard) | ALL token positions (not just annotated) | NO |

At difficulty 3 in EN→SR mode, the user types the entire Serbian sentence. Unannotated positions are checked via exact token match (after normalization). Annotated positions are checked against the `search_terms` table.

**Answer checking normalization pipeline:** `trim → to_latin (Cyrillic→Latin) → strip_diacritics → downcase`. This means users can type in Cyrillic or Latin, with or without diacritics, in any case.

### Dictionary / Word Detail / Flashcards
Sentences also appear as example sentences:
- **Dictionary search results:** One sentence per word (batch loaded)
- **Word detail page:** Up to 3 sentences per word
- **Flashcards:** One sentence per word, used as context on card face

## Language Rules — Serbian Ekavski Standard

**Every sentence MUST be pure Serbian ekavski.** This is the single most important quality requirement. A grammatically perfect sentence is worthless if it uses Croatian vocabulary or ijekavski forms.

### Ekavski jat reflex (e, never ije/je)

The jat vowel is always **e** in ekavski. This applies to all word categories and all inflected forms:

| Category | Correct (ekavski) | Wrong (ijekavski) |
|----------|-------------------|-------------------|
| Nouns | mleko, reka, dete, vreme, mesto, pesma, svet, telo, vera, cvet | mlijeko, rijeka, dijete, vrijeme, mjesto, pjesma, svijet, tijelo, vjera, cvijet |
| Verbs | videti, voleti, hteti, smeti, razumeti, sedeti, leteti, trpeti | vidjeti, voljeti, htjeti, smjeti, razumjeti, sjediti, letjeti, trpjeti |
| L-participle | video, voleo, hteo, razumeo, sedeo | vidio, volio, htio, razumio, sjedio |
| Adjectives | lep, beo, ceo, slep, levo | lijep, bijel, cijel, slijep, lijevo |
| Adverbs | lepo, ovde, gde, negde | lijepo, ovdje, gdje, negdje |
| Prefixed | prevod, pregled, predlog, prenos | prijevod, pregled, prijedlog, prijenos |

**Watch for subtle jat words** that are easy to miss: "deo" (not "dio"), "sneg" (not "snijeg"), "beg" (not "bijeg"), "smer" (not "smjer"), "svet" (not "svijet"), "stena" (not "stijena").

### Serbian lexicon (not Croatian, Bosnian, or Montenegrin)

Use standard Serbian vocabulary. Many words differ from Croatian even when the jat reflex is the same:

| Serbian | Croatian/Other | Meaning |
|---------|---------------|---------|
| hleb | kruh | bread |
| voz | vlak | train |
| vazduh | zrak | air |
| so | sol | salt |
| sto | stol | table |
| hiljada | tisuća | thousand |
| pozorište | kazalište | theater |
| fudbal | nogomet | football |
| hemija | kemija | chemistry |
| istorija | povijest | history |
| geografija | zemljopis | geography |
| avion | zrakoplov | airplane |
| univerzitet | sveučilište | university |
| uslov | uvjet | condition |
| saobračaj | promet | traffic |
| železnica | željeznica | railway |
| opština | općina | municipality |
| tačka | točka | point/period |
| tačno | točno | exactly |
| potrebno | potrebito | necessary |

### Serbian grammar patterns

Serbian has distinct grammatical preferences that differ from Croatian:

- **"Da + present" construction:** Serbian strongly prefers "da + present" over bare infinitive in many contexts. "Moram da idem" (not "moram ići"), "Hoću da čitam" (not "hoću čitati"), "Počeo je da radi" (not "počeo je raditi"). The infinitive is fine in isolation or with modal verbs where both are standard, but when in doubt prefer "da + present".
- **"Da li" for yes/no questions:** Serbian uses "da li" (e.g., "Da li si gladan?") or verb-first inversion. Avoid the Croatian "je li" as a general question particle (though "je li" is acceptable specifically for "je" → "je li on tu?").
- **"Trebati" conjugation:** Serbian conjugates "trebati" impersonally: "Treba mi pomoć" (I need help), "Treba da učiš" (You should study). Avoid the Croatian personal conjugation "Trebam pomoć".
- **Future tense:** Both "Ja ću da čitam" and "Ja ću čitati" are acceptable in Serbian. The short form "čitaću" (clitic fusion) is also standard Serbian.
- **Reflexive "se" placement:** In Serbian, "se" can come before the verb in emphasis: "Ja se nadam" is natural.

### Modern standard Serbian vocabulary

- Stick to standard modern Serbian. Avoid archaic or dialectal forms unless the vocabulary seed specifically includes them.
- Use standard Serbian word formation: "-nje" for verbal nouns (čitanje, pisanje), "-ost" for abstract nouns (lepota uses -ota, but radost, mladost use -ost), "-lac"/"-telj" for agent nouns.
- For international/technical terms, use the Serbian standard form: "kompjuter" (not "računalo"), "telefon", "internet".

## Validation Checklist

Before adding each sentence, verify:

1. **`text_rs` is valid Serbian** — correct grammar, ekavski, proper diacritics, natural phrasing
2. **`text_en` is natural English** — not a mechanical word-for-word translation
3. **Every `word_term` exists in the vocabulary seed** — search `priv/repo/vocabulary_seed.json` for the exact `term` value
4. **Every `word` matches a token in `text_rs`** — after tokenizing with `[\p{L}]+`, the word must appear (case-insensitive)
5. **Every `form_tag` is valid for the word's POS** — refer to the form tag reference above; the tag must be one that the inflection engine actually produces for this word
6. **The `word` is the correct inflected form** for the given `form_tag` — e.g., if `form_tag` is `acc_sg` for noun "kuća", the word must be "kuću" (not "kuća" which is nom_sg)
7. **No duplicate sentences** — check that a very similar sentence doesn't already exist in the seed
8. **Reasonable annotation density** — annotate 1–5 words per sentence. Not every word needs annotation, but each sentence should have at least 1 annotated word to be useful in exercises
9. **Varied form_tags** — prefer exercising different cases/tenses/forms across sentences rather than repeating nom_sg over and over
10. **Sentence length** — aim for 4–10 words. Short enough to fit in the UI, long enough to provide grammatical context

## Step-by-Step Process

1. **Read the vocabulary seed** to find available words: `priv/repo/vocabulary_seed.json`
2. **Read existing sentences** to avoid duplicates and understand coverage: `priv/repo/sentences_seed.json`
3. **Compose sentences** that are grammatically correct, natural Serbian ekavski
4. **Annotate words** — for each annotated word:
   a. Confirm `word_term` exists in vocabulary seed (exact match on `term` field)
   b. Determine the correct `form_tag` for the inflected form
   c. Verify the `word` field matches the actual inflected form for that tag
5. **Add entries** to the JSON array in `priv/repo/sentences_seed.json`
6. **Run `mix ecto.reset`** to reseed the database and verify no SKIPPED/WARN messages appear for the new sentences
7. **Run `mix precommit`** to ensure everything compiles and tests pass

## Common Mistakes to Avoid

- **Wrong form_tag for the form:** Using `nom_sg` when the word is in accusative. Check the grammatical role in the sentence.
- **Adjective definiteness mismatch:** Serbian adjectives have indefinite and definite forms. Use `def_` tags when the adjective is in definite (long) form, `indef_` when indefinite (short). Definite is used after demonstratives, possessives, or when the noun is specific.
- **Missing diacritics in `word` or `text_rs`:** Always include č, ć, š, ž, đ where required.
- **word_term not in vocabulary:** The seed loader silently skips these — always verify.
- **Tokenization mismatch:** Punctuation attached to words gets stripped by `[\p{L}]+`. So in "parku." the token is "parku", and `word` should be "parku" (without period). But "parku." would also work since matching is case-insensitive against the token.
- **Verb form confusion:** L-participle (`past_*`) forms are NOT the same as present tense forms. "čitao" is `past_m_sg` (he read), "čita" is `pres_3sg` (he reads).
- **Using Croatian/ijekavski forms:** Always use ekavski. "video" not "vidio", "hteo" not "htio", "lepo" not "lijepo", "ovde" not "ovdje". This applies to ALL inflected forms too — "videla" not "vidjela", "lepog" not "lijepog".
- **Using Croatian vocabulary:** "hleb" not "kruh", "voz" not "vlak", "tačno" not "točno". See the full vocabulary table in the Language Rules section above.
- **Croatian grammar patterns:** Using bare infinitive where Serbian prefers "da + present" ("moram da idem" not "moram ići"), using personal "trebam" instead of impersonal "treba mi", using "je li" as a general question word instead of "da li".
