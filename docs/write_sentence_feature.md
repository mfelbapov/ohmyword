# Write Sentence Feature

## Description
Fill-in-the-blank exercise where users complete Serbian sentences by typing the correct inflected form of a vocabulary word.

## User Flow
1. User sees a sentence with a blank: "Vidim _____."
2. User sees hints: word ("pas"), translation ("dog"), expected form ("accusative singular")
3. User types answer: "psa"
4. System validates (diacritic-insensitive) and shows feedback
5. User proceeds to next sentence

## Technical Approach

### New Schema: `Sentence`
- `text` - sentence with `{blank}` placeholder
- `translation` - English translation
- `blank_form_tag` - expected grammatical form (e.g., "acc_sg")
- `hint` - optional user-facing hint
- `word_id` - FK to vocabulary word

### New Context: `Ohmyword.Exercises`
- CRUD for sentences
- `get_random_sentence/1` with optional POS filter
- `check_answer/2` - validates user input against expected inflected form

### Answer Validation
- Uses existing `Utils.Transliteration.strip_diacritics/1` for normalization
- Accepts answer if normalized input matches normalized expected form
- Returns both correctness and the properly diacritical form for display

### New LiveView: `WriteSentenceLive`
- Pattern follows existing `FlashcardLive` structure
- State: current_sentence, user_answer, result, history, script_mode, pos_filter
- Events: submit_answer, next, previous, toggle_script, filter_pos
- Reuses: script_toggle, pos_filter, display_term, humanize_form_tag components

### Route
```elixir
live "/write", WriteSentenceLive, :index
```

## Files to Create
- `priv/repo/migrations/*_create_sentences.exs`
- `lib/ohmyword/exercises/sentence.ex`
- `lib/ohmyword/exercises/exercises.ex`
- `lib/ohmyword_web/live/write_sentence_live.ex`
- `priv/repo/sentences_seed.json`
- `test/ohmyword/exercises_test.exs`
- `test/ohmyword_web/live/write_sentence_live_test.exs`

## Files to Modify
- `lib/ohmyword_web/router.ex`
- `priv/repo/seeds.exs`
