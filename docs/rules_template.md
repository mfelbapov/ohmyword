Let me think through this carefully — the prompt needs to give Claude Code enough context about the engine architecture, the composable template concept, and concrete examples across different parts of speech so it can reason about the full rule set.

This is an exploratory discussion, not an implementation task. Do not write code or create files.
Context
Ohmyword is a Serbian language learning app with a linguistic engine (Linguistics.Dispatcher and its modules) that generates inflected forms for Serbian ekavski words. The engine takes a base word (lemma) with its grammatical properties and produces all inflected forms by applying transformation rules in sequence.
I want to add a composable rule explanation system. The idea is that each discrete transformation rule in the engine carries a human-readable template string. When the engine generates a form, it also assembles the relevant templates into a step-by-step explanation of how the base word became that form. One template per rule, reused across every word that triggers that rule.
The Goal
Help me identify and catalog every rule in the engine, then write a clear, learner-friendly template string for each one. Templates should be written for an English speaker learning Serbian — no linguistic jargon unless it's a term the learner needs to know (like "case" or "gender"), and always with a concrete illustration.
How Rules Compose
A single inflected form is the result of multiple rules firing in sequence. The explanation chains their templates together. Here are examples across different parts of speech:
Example 1: Noun — "pas" (dog), accusative singular
Base word: pas (masculine, animate, consonant stem)
Rules that fire:

Animacy rule: Masculine animate nouns use the genitive form for the accusative case

Template: "For masculine animate nouns, the accusative borrows the genitive form — you're accusing a living thing, so Serbian marks it differently. Instead of looking up the accusative ending, we use the genitive."


Fleeting-a rule: The vowel "a" in the final syllable drops when an ending is added

Template: "The 'a' in '{base}' is a fleeting vowel — it disappears when endings are added. The stem becomes '{modified_stem}'."
Rendered: "The 'a' in 'pas' is a fleeting vowel — it disappears when endings are added. The stem becomes 'ps-'."


Case ending rule: Genitive singular consonant-stem ending is "-a"

Template: "The genitive singular ending for consonant-stem masculine nouns is '-a'."



Result shown to learner: pas → ps- → psa

Step 1: Accusative of an animate masculine noun? Use the genitive form.
Step 2: The fleeting 'a' drops from the stem: pas → ps-
Step 3: Add the genitive singular ending -a: ps- → psa

Example 2: Noun — "žena" (woman), dative singular
Base word: žena (feminine, a-stem)
Rules that fire:

Stem extraction: a-stem nouns drop the -a to get the stem

Template: "For a-stem nouns, remove the final '-a' to get the stem: '{base}' → '{stem}'."
Rendered: "Remove the final '-a' to get the stem: 'žena' → 'žen-'."


Case ending rule: Dative singular a-stem ending is "-i"

Template: "The dative singular ending for a-stem feminine nouns is '-i'."


Palatalization rule (does NOT fire here, but would for some a-stem nouns):

Template: "Before the ending '-i', the consonant '{consonant}' softens to '{softened}' (palatalization)."
Example where it fires: "majka" → dative "majci" (k → c before i)



Result: žena → žen- → ženi
Example 3: Verb — "pisati" (to write), present tense first person singular
Base word: pisati (imperfective, e-conjugation)
Rules that fire:

Infinitive stem extraction: Remove -ti to get the infinitive stem

Template: "Remove '-ti' from the infinitive to get the stem: '{infinitive}' → '{stem}'."
Rendered: "Remove '-ti': 'pisati' → 'pisa-'."


Present stem derivation: For e-conjugation, the present stem may differ from the infinitive stem

Template: "This verb uses a different stem in the present tense: '{inf_stem}' → '{pres_stem}'."
Rendered: "'pisa-' becomes 'piš-' in the present tense."


Consonant alternation: s → š before certain vowels

Template: "The consonant '{original}' changes to '{alternated}' before the present tense vowel (consonant alternation)."


Person/number ending: First person singular present ending is "-em" for e-conjugation

Template: "The first person singular ending for e-conjugation verbs is '-em'."



Result: pisati → pisa- → piš- → pišem
Example 4: Adjective — "velik" (big), definite accusative singular masculine animate
Base word: velik (masculine form)
Rules that fire:

Definiteness: Serbian adjectives have indefinite and definite (long) forms

Template: "The definite (long) form of the adjective is used when referring to a specific known thing."


Animacy agreement: Adjective modifying a masculine animate noun uses genitive form for accusative

Template: "Just like the noun it describes, a masculine animate adjective in the accusative takes the genitive form."


Definite genitive ending: Definite genitive singular masculine ending is "-og" or "-eg"

Template: "The definite genitive singular masculine ending is '-og' (or '-eg' after soft consonants)."



Result: velik → velikog
Example 5: Noun — "Srbin" (a Serb), nominative plural
Base word: Srbin (masculine, animate, consonant stem)
Rules that fire:

Plural stem change: The suffix "-in" drops in the plural for nouns denoting nationality/group membership

Template: "Nouns ending in '-in' that denote nationality or group membership drop '-in' in all plural forms: '{base}' → '{plural_stem}'."
Rendered: "'Srbin' → 'Srb-' in the plural."


Case ending rule: Nominative plural consonant-stem masculine ending is "-i"

Template: "The nominative plural ending for consonant-stem masculine nouns is '-i'."



Result: Srbin → Srb- → Srbi
Example 6: Noun — "dete" (child), nominative plural
Base word: dete (neuter, e-stem, irregular plural)
Rules that fire:

Suppletive plural stem: Some neuter nouns use a completely different stem in the plural

Template: "This noun uses a special plural stem: '{singular_stem}' → '{plural_stem}'. This is an irregular form that must be memorized."
Rendered: "'dete' uses the plural stem 'dec-'."


Case ending rule: Nominative plural for this class uses "-a"

Template: "The nominative plural ending is '-a'."



Result: dete → dec- → deca
What I Need From This Discussion

Rule inventory: Go through the engine modules and identify every discrete transformation rule. Categorize them by type — stem extraction, case endings, consonant alternations, fleeting vowels, palatalization, animacy, definiteness, aspect-related rules, irregular overrides, etc.
Template drafts: For each rule, draft a learner-friendly template string. It should explain WHAT happens and WHY in one or two sentences. Use placeholders like {base}, {stem}, {ending}, {consonant}, {alternated} where the engine would insert specific values at runtime.
Composition logic: Think through how templates chain together. What's the ordering? Are there rules that suppress or modify other rules' explanations? For example, if a form is an irregular override from grammar_metadata, should the explanation just say "this is an irregular form" or should it still try to explain the pattern?
Edge cases: Where does the composable approach break down? Suppletion (completely irregular forms), forms where multiple valid explanations exist, cases where the "why" is purely historical and not helpful to a learner.
Coverage estimation: Roughly how many distinct rule templates would we need to cover the current 1,022 words and their forms? My guess is 40-60 but challenge that.

Do not write implementation code. Help me think through the full catalog of rules, the template language, and where this approach works well versus where it needs special handling.
