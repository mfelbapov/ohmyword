# Existing Words to Check

Discrepancies between seed forms and engine output.

## Validation Run Summary

**525 words with forms processed. 0 engine discrepancies found.**

### False Positives: Adjective `acc_sg_m` (27 words)

The validation script reported 27 adjective mismatches on `indef_acc_sg_m` and/or `def_acc_sg_m` forms. These are **all false positives** caused by the engine generating both animate and inanimate accusative forms under the same form tag, and the script's `Map.new` picking the alternate (last) form instead of the primary one.

Affected words: bled, brz, debeo, divlji, drag, hladan, jeftin, kiseo, lak, okrugao, otvoren, prav, pun, ružan, skup, slab, suv, svež, tanak, tih, topao, tvrd, veseo, visok, zatvoren, zdrav, širok.

**No action needed** — the engine produces correct forms for all of these.

**Recommendation:** Update the validation script to handle duplicate form tags (use a multimap or check if seed form matches *any* engine form for that tag) to avoid future false positives.

---

## Ekavski / Serbian Lexicon Compliance Issues

5 words in the seed fail the Serbian ekavski standard check:

### sol (noun) — Non-Serbian lexeme

**Current:** sol (translation: salt)
**Correct ekavski/Serbian:** so
**Reason:** "sol" is Croatian/Bosnian. Serbian uses "so" (i-stem feminine noun).

### poslije (preposition) — Ijekavski form

**Current:** poslije (translation: after)
**Correct ekavski:** posle
**Reason:** "poslije" is ijekavski jat reflex. Ekavski is "posle".

### prije (preposition) — Ijekavski form

**Current:** prije (translation: before)
**Correct ekavski:** pre
**Reason:** "prije" is ijekavski jat reflex. Ekavski is "pre".

### tijekom (preposition) — Croatian form

**Current:** tijekom (translation: during)
**Correct Serbian:** tokom
**Reason:** "tijekom" is a Croatian instrumental form of "tijek". Serbian uses "tokom" (instrumental of "tok").

### uslijed (preposition) — Ijekavski form

**Current:** uslijed (translation: due to)
**Correct ekavski:** usled
**Reason:** "uslijed" is ijekavski jat reflex. Ekavski is "usled".
