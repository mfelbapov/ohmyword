
Feature: Bi-Directional Scaffolded Sentence Construction
Scenario 1: Session Setup (Direction & Scaffolding)
Given a pair of matched sentences, one in English and one in Serbian,
And a selected "Source" language and "Target" language,
And a selected difficulty level (e.g., Easy/Partial vs. Hard/Full),
When the challenge loads,
Then the Source sentence is displayed fully visible,
And the Target sentence is displayed with text either partially replaced by placeholders (Easy) or entirely hidden (Hard).

Scenario 2: Successful Verification
Given the user is viewing the masked Target sentence prompt,
When the user types a response into the input field and submits,
Then the system compares the input against a pre-defined list of valid accepted answers for that specific sentence,
And if the input matches any valid variation (ignoring capitalization or punctuation), the system marks the answer as correct.

Scenario 3: Failed Verification & Feedback
Given the user has submitted an attempt,
When the input does not match any string in the list of valid accepted answers,
Then the system marks the answer as incorrect,
And displays the closest valid answer alongside the user's input to visually indicate the discrepancy.

toggle trigers english to serbian and cyrilic to latin already exist reuse them
follow test driven development practices
