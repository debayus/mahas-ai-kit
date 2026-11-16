export const meta = {
  name: 'engineer-pipeline',
  description: 'Planner → Architect → Developer → Tester → Reviewer with fix loops until APPROVED',
  whenToUse: 'Full engineer pipeline for a {{PROJECT_NAME}} feature/bugfix. Pass the requirement as args (string), or {task, e2e, gate, skipReview, maxTestLoops, maxReviewLoops, cwd}. Invoked by /pipeline.',
  phases: [
    { title: 'Plan', detail: 'Planner: requirement → tasks, risks, acceptance criteria', model: '{{MODEL_PLANNER}}' },
    { title: 'Design', detail: 'Architect: plan → technical design', model: '{{MODEL_DESIGN}}' },
    { title: 'Implement', detail: 'Developer: apply the design; fix loops return here', model: '{{MODEL_BUILD}}' },
    { title: 'Test', detail: 'Tester: checks + tests until green, or red with diagnosis', model: '{{MODEL_BUILD}}' },
    { title: 'Review', detail: 'Reviewer: APPROVED or CHANGES_REQUIRED back to Developer', model: '{{MODEL_REVIEW}}' },
  ],
}

// ---------- input ----------
const input = typeof args === 'string' ? { task: args } : (args || {})
const task = input.task
if (!task) throw new Error('Missing task. Invoke with args: "<requirement>" or {task: "<requirement>"}')
// gate: 'analyze' (static checks only) | 'full' (checks + tests) | 'e2e'
const GATE = input.gate || (input.e2e ? 'e2e' : 'full')
const SKIP_REVIEW = !!input.skipReview
const MAX_TEST_LOOPS = input.maxTestLoops || 4
const MAX_REVIEW_LOOPS = input.maxReviewLoops || 3
// cwd: run the whole pipeline in another git worktree (parallel tickets).
const CWD = input.cwd || null
const WORKDIR_NOTE = CWD
  ? [
      `WORKING DIRECTORY (REQUIRED): ${CWD}`,
      'This repo is checked out as a separate git worktree for this ticket. ALL reads, edits, checks, tests and git status/diff must happen there:',
      `- Bash: start every command with \`cd ${CWD} &&\`.`,
      `- Read/Edit/Write/Grep/Glob: use ABSOLUTE paths under ${CWD}.`,
      'Do NOT read or change files in the session working directory — another ticket is in progress there. Relative paths in CLAUDE.md/skills are relative to the WORKING DIRECTORY above.',
    ].join('\n')
  : null
const withWorkdir = (parts) => (WORKDIR_NOTE ? [WORKDIR_NOTE, ...parts] : parts)
const NO_GIT = 'Never git commit/push/amend — leave all changes uncommitted in the working tree.'

// ---------- schemas ----------
const strs = { type: 'array', items: { type: 'string' } }
const PLAN_SCHEMA = {
  type: 'object',
  required: ['summary', 'tasks', 'acceptanceCriteria'],
  properties: {
    summary: { type: 'string', description: 'Requirement restated: business intent + technical implication' },
    tasks: {
      type: 'array',
      items: {
        type: 'object',
        required: ['id', 'title'],
        properties: { id: { type: 'string' }, title: { type: 'string' }, detail: { type: 'string' }, dependsOn: strs },
      },
    },
    risks: strs, edgeCases: strs, acceptanceCriteria: strs, assumptions: strs, openQuestions: strs,
  },
}
const DESIGN_SCHEMA = {
  type: 'object',
  required: ['approach', 'files'],
  properties: {
    approach: { type: 'string' },
    planGaps: { ...strs, description: 'Corrections to the plan; empty if none' },
    files: {
      type: 'array',
      items: { type: 'object', required: ['path', 'change'], properties: { path: { type: 'string' }, change: { type: 'string' } } },
    },
    dataMigration: { type: 'string', description: '"none" or the full migration spec' },
    integrationImpact: { type: 'string' },
    implementationNotes: strs, risks: strs,
  },
}
const DEV_SCHEMA = {
  type: 'object',
  required: ['summary', 'filesChanged'],
  properties: {
    summary: { type: 'string' },
    filesChanged: { ...strs, description: 'path — one-line what/why' },
    deviations: { ...strs, description: 'Departures from the design + reason' },
    blockers: strs,
  },
}
const TEST_SCHEMA = {
  type: 'object',
  required: ['status', 'summary'],
  properties: {
    status: { type: 'string', enum: ['green', 'red'] },
    summary: { type: 'string', description: 'Per-stage result incl. final passing/failing summary lines' },
    fixesApplied: strs,
    failures: { ...strs, description: 'When red: failing output + diagnosis for the Developer' },
  },
}
const REVIEW_SCHEMA = {
  type: 'object',
  required: ['verdict', 'summary'],
  properties: {
    verdict: { type: 'string', enum: ['APPROVED', 'CHANGES_REQUIRED'] },
    summary: { type: 'string' },
    criteriaMet: { type: 'number' }, criteriaTotal: { type: 'number' },
    unmetCriteria: strs,
    issues: {
      type: 'array',
      items: {
        type: 'object',
        required: ['severity', 'description'],
        properties: {
          severity: { type: 'string', enum: ['blocker', 'major', 'minor'] },
          file: { type: 'string' },
          description: { type: 'string', description: "What's wrong → what fixed looks like" },
        },
      },
    },
    notes: { ...strs, description: 'Non-blocking nits' },
  },
}

// ---------- prompt builders ----------
const j = (v) => JSON.stringify(v, null, 1)
const testerScope =
  GATE === 'analyze'
    ? 'Scope: `{{ANALYZE_CMD}}` + `{{FORMAT_CHECK_CMD}}` ONLY. Do NOT run the test suite. Green means no new errors and the format check passes. Format failures: format the reported files only.'
    : GATE === 'e2e'
      ? 'Scope: `{{ANALYZE_CMD}}` + `{{FORMAT_CHECK_CMD}}` + `{{TEST_CMD}}` + end-to-end (`{{E2E_CMD}}`).'
      : 'Scope: `{{ANALYZE_CMD}}` + `{{FORMAT_CHECK_CMD}}` + `{{TEST_CMD}}`. Skip end-to-end.'

function testerPrompt(round, context, plan) {
  return withWorkdir([
    `Engineer-pipeline TESTER stage, round ${round}. Follow your agent instructions.`,
    `Original requirement:\n${task}`,
    `Acceptance criteria to cover with tests:\n${j(plan.acceptanceCriteria)}`,
    `Context:\n${context}`,
    testerScope,
    `Fix compile/build/lint/test-infra failures yourself and re-run until green. If a failure is a product-logic defect versus the design, return status "red" with a precise diagnosis instead of fixing it. Never add features. ${NO_GIT}`,
  ]).join('\n\n')
}

// ---------- Phase 1: Plan ----------
phase('Plan')
const plan = await agent(
  withWorkdir([
    'Engineer-pipeline PLANNER stage. Follow your agent instructions (load the process-planning skill).',
    `Requirement from the user:\n${task}`,
    'Produce the full plan: restated requirement, ordered tasks with dependencies, risks, edge cases, testable acceptance criteria, assumptions/open questions. Never include a commit/push/tag task.',
  ]).join('\n\n'),
  { agentType: 'planner', label: 'planner', phase: 'Plan', schema: PLAN_SCHEMA }
)
if (!plan) throw new Error('Planner returned no result (skipped or failed)')
log(`Plan: ${plan.tasks.length} tasks, ${(plan.acceptanceCriteria || []).length} acceptance criteria`)

// ---------- Phase 2: Design ----------
phase('Design')
const design = await agent(
  withWorkdir([
    'Engineer-pipeline ARCHITECT stage. Follow your agent instructions (load the process-tech-design skill).',
    `Original requirement:\n${task}`,
    `Planner output:\n${j(plan)}`,
    'Critique the plan (record corrections in planGaps), then produce the technical design: approach, file-by-file changes in implementation order, data migration spec or "none", integration impact, implementation notes, risks. Prefer reusing existing components.',
  ]).join('\n\n'),
  { agentType: 'architect', label: 'architect', phase: 'Design', schema: DESIGN_SCHEMA }
)
if (!design) throw new Error('Architect returned no result (skipped or failed)')
log(`Design: ${design.files.length} files to change, migration: ${design.dataMigration || 'none'}`)

// ---------- Phase 3: Implement ----------
phase('Implement')
let dev = await agent(
  withWorkdir([
    'Engineer-pipeline DEVELOPER stage. Follow your agent instructions (load the stack skills they name).',
    `Original requirement:\n${task}`,
    `Acceptance criteria:\n${j(plan.acceptanceCriteria)}`,
    `Technical design to implement verbatim:\n${j(design)}`,
    `Implement exactly this design — no scope changes. Report deviations/blockers honestly. ${NO_GIT}`,
  ]).join('\n\n'),
  { agentType: 'developer', label: 'developer', phase: 'Implement', schema: DEV_SCHEMA }
)
if (!dev) throw new Error('Developer returned no result (skipped or failed)')

// ---------- Phase 4: Test loop (Developer ↔ Tester until green) ----------
let test = null
let testRound = 0

async function testUntilGreen(context) {
  for (let i = 1; i <= MAX_TEST_LOOPS; i++) {
    testRound++
    test = await agent(testerPrompt(testRound, context, plan), {
      agentType: 'tester', label: `tester-r${testRound}`, phase: 'Test', schema: TEST_SCHEMA,
    })
    if (test && test.status === 'green') {
      log(`Tester round ${testRound}: green`)
      return true
    }
    log(`Tester round ${testRound}: red — ${test ? test.summary : 'no result'}`)
    if (i === MAX_TEST_LOOPS) return false
    const fix = await agent(
      withWorkdir([
        `Engineer-pipeline DEVELOPER stage — fix the failures the Tester diagnosed. Fix root causes only; no scope changes. ${NO_GIT}`,
        `Original requirement:\n${task}`,
        `Technical design (still authoritative):\n${j(design)}`,
        `Tester diagnosis:\n${j(test)}`,
      ]).join('\n\n'),
      { agentType: 'developer', label: `dev-fix-r${testRound}`, phase: 'Implement', schema: DEV_SCHEMA }
    )
    if (fix) dev = fix
  }
  return false
}

const initialGreen = await testUntilGreen(`Developer just implemented the design. Report:\n${j(dev)}`)
if (!initialGreen) {
  log(`Stopped: tests still red after ${MAX_TEST_LOOPS} Developer↔Tester rounds`)
  return { verdict: 'BLOCKED_TESTS_RED', task, plan, design, dev, test, review: null }
}
if (SKIP_REVIEW) {
  log('Review skipped (skipReview) — implemented, pending a combined test gate + review')
  return { verdict: 'IMPLEMENTED_PENDING_REVIEW', task, plan, design, dev, test, review: null }
}

// ---------- Phase 5: Review loop ----------
let review = null
for (let r = 1; r <= MAX_REVIEW_LOOPS; r++) {
  review = await agent(
    withWorkdir([
      `Engineer-pipeline REVIEWER stage, round ${r}. Follow your agent instructions (load the process-code-review skill, including its noise rules).`,
      `Original requirement:\n${task}`,
      `Acceptance criteria (your checklist):\n${j(plan.acceptanceCriteria)}`,
      `Technical design:\n${j(design)}`,
      `Developer report:\n${j(dev)}`,
      `Tester report (green):\n${j(test)}`,
      r > 1 ? 'This is a re-review: verify the previously listed issues are resolved and check the new changes. Do not raise new minor issues on code you already reviewed.' : '',
      'Inspect the working tree with git status/diff and read the changed files. Return APPROVED only if every acceptance criterion is met and no blocker/major issue remains; otherwise CHANGES_REQUIRED with concrete, actionable issues.',
    ].filter(Boolean)).join('\n\n'),
    { agentType: 'reviewer', label: `reviewer-r${r}`, phase: 'Review', schema: REVIEW_SCHEMA }
  )
  if (!review) throw new Error('Reviewer returned no result (skipped or failed)')
  if (review.verdict === 'APPROVED') break
  log(`Review round ${r}: CHANGES_REQUIRED — ${(review.issues || []).length} issues`)
  if (r === MAX_REVIEW_LOOPS) break

  const fix = await agent(
    withWorkdir([
      `Engineer-pipeline DEVELOPER stage — resolve the Reviewer's issues. Fix exactly what is listed; no scope changes. ${NO_GIT}`,
      `Original requirement:\n${task}`,
      `Technical design (still authoritative):\n${j(design)}`,
      `Reviewer issues:\n${j(review.issues || [])}`,
      `Unmet acceptance criteria:\n${j(review.unmetCriteria || [])}`,
    ]).join('\n\n'),
    { agentType: 'developer', label: `dev-review-fix-r${r}`, phase: 'Implement', schema: DEV_SCHEMA }
  )
  if (fix) dev = fix

  const green = await testUntilGreen(`Developer just fixed review issues. Report:\n${j(dev)}`)
  if (!green) {
    log(`Stopped: tests red after review-fix, ${MAX_TEST_LOOPS} rounds exhausted`)
    return { verdict: 'BLOCKED_TESTS_RED', task, plan, design, dev, test, review }
  }
}

const approved = !!review && review.verdict === 'APPROVED'
log(approved ? 'APPROVED' : `Not approved after ${MAX_REVIEW_LOOPS} review rounds`)
return { verdict: approved ? 'APPROVED' : 'NOT_APPROVED', task, plan, design, dev, test, review }
