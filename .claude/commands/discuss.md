---
name: discuss
description: Answer a question and save the Q&A to a specified file in the docs/ folder
allowed-tools: Read, Bash
disable-model-invocation: true
---

The user provided the following input:

$ARGUMENTS

## Instructions

1. Parse the input: the **first word** is the filename, everything after is the question
   - Example input: `discussion.md Why did we choose PostgreSQL?`
   - Filename: `docs/discussion.md`
   - Question: `Why did we choose PostgreSQL?`

2. Answer the question thoroughly

3. Append the Q&A to `docs/<filename>`. If the file doesn't exist, create it with:
   # <Filename without extension, title-cased>

4. Append using this format:

---
## [Current Date]

**Q:** [The original question]

**A:** [Your concise answer]

---

5. Always append, never overwrite
6. Confirm the save with the filepath
```

**Usage:**
```
/docs discussion.md Why did we choose PostgreSQL over MongoDB?
/docs architecture.md What's our caching strategy?
/docs decisions.md Why are we using feature flags?
```

Each one saves to a different file under `docs/`. You end up with a nice knowledge base:
```
docs/
├── discussion.md
├── architecture.md
└── decisions.md
