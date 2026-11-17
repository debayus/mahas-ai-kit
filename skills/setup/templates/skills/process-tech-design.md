---
name: process-tech-design
description: Technical-design template and checklist for the Architect stage — approach, file-by-file changes, data migration, risks. Load when producing or evaluating a technical design for {{PROJECT_NAME}}.
---

# Technical design template — {{PROJECT_NAME}}

A design is good when the Developer **never has to make an architectural decision**.

## 1. Approach

The chosen solution in a paragraph, plus one line on why it beats the obvious alternative.

## 2. Plan gaps

Corrections to the plan. Empty is valid; silence is not — state "none".

## 3. File-by-file changes

Every file to create or modify, in implementation order, following this project's layering:

```
{{LAYER_FILE_MAP}}
```

{{DATA_SECTION}}

## Implementation notes & risks

Exact names, ordering constraints, gotchas, what could regress and how to probe it. Name the existing components to **reuse**.
