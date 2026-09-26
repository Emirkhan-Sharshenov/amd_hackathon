# FACTORY.md — DRAFT

> Draft written before the factory has run. Everything marked **TODO** must be replaced
> with what actually happened and what it cost. Judges read this file to decide whether
> another team could stand the factory up, so keep it honest and measured.

## In one paragraph

A four-seat band in Band Desktop that builds a service from a written specification, one
stage at a time, with no human input after the task is dispatched. Its core idea: **the
specification, not the shipped checks, is the source of truth.** The coordinator first
compiles the specification into a numbered **requirements ledger** with every normative
statement quoted verbatim. Then two seats work in parallel from that ledger and blind to
each other: the **builder** writes the product, the **tester** writes black-box acceptance
tests. The **reviewer** accepts a revision only after rebuilding it from scratch and
walking every ledger item. A test and an implementation written independently from the
same text have to agree, which is how the factory finds gaps no shipped check asks about.

## Seats

| Seat | Harness | Model | Owns | Never does |
|---|---|---|---|---|
| [coordinator](mandates/coordinator.md) | TODO | TODO | ledger, dispatch, routing, stage verdict, stage report | writes code or tests |
| [builder](mandates/builder.md) | TODO | TODO | product source, Dockerfile, run instructions | edits tests, accepts own work |
| [tester](mandates/tester.md) | TODO | TODO | acceptance tests derived from the ledger | reads product source, edits product |
| [reviewer](mandates/reviewer.md) | TODO | TODO | clean rebuild, all checks, ledger walk, verdict | fixes anything itself |

Ownership is exclusive by folder, so the builder and the tester can commit in parallel
without conflicts.

## Flow of one stage

```
            task (only human input)
                    │
                    ▼
             ┌─────────────┐   requirements ledger (R1…Rn, verbatim)
             │ coordinator │───────────────────────────┐
             └─────────────┘                           │
          full spec + ledger                 full spec + ledger
                    │                                  │
                    ▼                                  ▼
             ┌─────────────┐                    ┌─────────────┐
             │   builder   │  (in parallel,     │   tester    │
             │  product    │   blind to each    │ black-box   │
             │  revision   │   other)           │ test suite  │
             └──────┬──────┘                    └──────┬──────┘
                    └──────────────┬───────────────────┘
                                   ▼
                            ┌─────────────┐
                            │  reviewer   │ clean build → checks → ledger walk
                            └──────┬──────┘
                 REJECT (item, expected, actual, owner)     ACCEPT (revision)
                 ▲ back to builder or tester                   │
                                                               ▼
                                              coordinator: stage report, tag,
                                              next stage (copy folder forward)
```

## Artifacts per stage

| Artifact | Written by | Purpose |
|---|---|---|
| Requirements ledger | coordinator | Every normative statement, numbered, quoted verbatim, with its section |
| Acceptance tests | tester | Executable proof per ledger item; runs with one command against a running service |
| Product source, Dockerfile, run instructions | builder | The service |
| Verdicts in the room | reviewer | Revision, commands, results, findings with owner |
| Stage report | coordinator | Times, review rounds, each rejection and its fix, known gaps |

## Design choices and what they cost

| Choice | Why | Cost |
|---|---|---|
| Ledger before any code | Grading is literal and most checks are held back; every hidden check is in the spec text. Quoting verbatim removes paraphrase errors (wrong casing, wrong code). | One extra step per stage, TODO min |
| Tester separate from builder, blind to source | A test written from the implementation only confirms the implementation. Two readings of the same text must agree. | One extra seat, TODO spend |
| Parallel builder and tester | Keeps the extra seat off the critical path. | Merge discipline: exclusive folders |
| Reviewer rebuilds from scratch, trusts no report | A service that only works on the builder's machine fails a judge. | Slower review rounds, TODO min each |
| Reviewer never fixes | Keeps the review independent, and every fix comes back through the room so it is traceable. | Extra round trip per finding |
| Three strikes per ledger item, then re-scope, then record as a gap | Stops the band from burning time and money in a loop on one item. | Some items may ship as known gaps |
| Stage folder copied forward, never rewritten | Each stage must keep passing every earlier stage. | Duplication across folders (required by the event) |
| TODO: model assignment per seat | TODO: e.g. strongest reasoning model for coordinator and reviewer, fast coding model for builder, a different model family for tester to avoid shared blind spots | TODO |

## How the factory catches and recovers from bad work

1. **At the ledger:** ambiguities are resolved once, by the most literal reading, and
   written down, so every seat works from the same interpretation.
2. **At the tester:** tests come from the text, including invariants under concurrency,
   retries, malformed input and boundaries — the categories shipped checks cover least.
3. **At the reviewer:** clean build, isolated-mode checks, earlier stages re-run, overshoot
   check, item-by-item comparison, and a scan for code that branches on test inputs.
4. **Recovery:** every rejection names the ledger item, expected vs actual evidence and the
   owner; the owner fixes and hands off a new revision; nothing is amended.

### A bad result it caught

TODO: one concrete example from the submitted run — the ledger item, what the builder
shipped, how the reviewer or a tester test found it, the fix revision.

## What we tried that did not work

TODO: record as it happens (e.g. handoffs that referenced earlier messages, a reviewer
that trusted the builder's output, a tester that read the source).

## Measured time and spend

| Stage | Dispatch → accept | Review rounds | Rejections (real defects) | Model spend | Result on shipped checks |
|---|---|---|---|---|---|
| 1 | TODO | TODO | TODO | TODO | TODO |
| 2 | TODO | TODO | TODO | TODO | TODO |
| 3 | TODO | TODO | TODO | TODO | TODO |
| 4 | TODO | TODO | TODO | TODO | TODO |

Spend source: TODO (provider dashboard / API usage export), measured per seat.

## Stand it up yourself

1. Install Band Desktop, Docker, Git and Python 3.12+ (for the event harness only).
2. Create four seats named `coordinator`, `builder`, `tester`, `reviewer`, each with the
   harness and model from its mandate; paste the mandate as the seat's standing
   instructions. Configure a Git name and email per seat.
3. Create an empty result repository and give the band its **absolute** path.
4. Create one room, add all four seats, and confirm each can send and receive an
   `@handle` message.
5. Dispatch the task to `@coordinator` using the template below. Send nothing else until
   the coordinator's final report.

### Dispatch template

```text
@coordinator Build this service one stage at a time.

Result repository (absolute): <PATH>
Specification for this stage: <PASTE THE FULL SPEC, OR THE ABSOLUTE PATH TO IT>
Stage folder: <STAGE FOLDER>; carry forward from: <PREVIOUS STAGE FOLDER or none>
Check command: <THE COMMAND THAT RUNS THE PROVIDED CHECKS, IN ISOLATED MODE>
When this stage is accepted, continue with: <NEXT SPEC or stop>
```
