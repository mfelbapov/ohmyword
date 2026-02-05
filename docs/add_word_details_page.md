# Word Detail Page

## User Story

As a user
Given I am on the search page
When the results are presented
Then I can click a "View all forms" link on any result card
And I am taken to the word detail page at `/dictionary/:id`

## Detail Page Content

### Header
- Word term (large, script-aware via Latin/Cyrillic toggle)
- Part of speech badge, gender badge, aspect badge, animate badge

### Translations
- Primary translation
- Additional translations (if any)

### Grammar Details
- Declension class (nouns) or conjugation class (verbs)
- Reflexive / transitive (verbs)

### Inflection Tables
Full inflection table appropriate to the word's part of speech:

**Nouns**: 7 cases x singular/plural table
**Verbs**: Present tense (6 persons), past participle (M/F/N x Sg/Pl), imperative (3 forms)
**Adjectives**: Indefinite and definite paradigms (7 cases x 3 genders x 2 numbers), comparative/superlative
**Pronouns/Numerals**: List of all forms
**Invariables**: Base form (+ comparative/superlative for adverbs)

### Example Sentence
- Serbian sentence (script-aware)
- English translation

### Usage Notes (if present)

### Categories (if any)

## Navigation
- Back link to `/dictionary`
- Script toggle (Latin/Cyrillic) on the detail page
