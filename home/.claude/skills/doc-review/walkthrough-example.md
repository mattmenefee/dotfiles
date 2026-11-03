# Document Review: A Worked Walkthrough

A worked example of the walkthrough in SKILL.md, from phase 1 to the proposed order, using the
finding set from the Pre-Merge Checklist example in `review-file.md`:

<!-- Keep in sync with the Pre-Merge Checklist example and the Consolidated Summary example table,
     whose finding set this reuses, and with the F8 example under Tracking Finding Status -->

```text
Question 1 of 1 — F5 ⚖️ Whether the Quick Start covers the Docker path (Quick Start)
The Quick Start documents the native install only and links to Installation, which presents Docker
as an equal path. The choice is how much of that the Quick Start carries.
  (b) Native only, linking to Installation for Docker (Recommended) — stays short; Docker users
      leave the Quick Start at its first step
  (a) Document both paths — complete for every reader; roughly doubles the section
  Defer to a follow-up / Leave open for now
Recommended: (b), because the Quick Start exists to be short and Installation covers Docker.
User: (b) — keep it short.

Not recommended 2 of 2 — F8 🟢 Low: Split the reference page (Reference)
The reference page covers both the command-line flags and the configuration file.
Reviewer: Defer — the sibling page is not in this branch. Mine: Defer, for the same reason.
  Defer (Recommended) / Implement / Ignore / Leave open for now
User: Implement — the sibling page can link to it later.
F8 opens G4: no group touches the reference page.

Proposed order
G2 — Correct the installation steps: the only 🔴 Critical; now first, since F5 is ruled
G1 — Settle the Quick Start's scope: 🟡 Medium, now behind G2 since F5 is settled; F5 kept
     the Quick Start native-only, so F7 drops the Docker prerequisites and F9 states the scope
G4 — Split the reference page: opened for F8; lowest severity and touches nothing else
Which group first?
```

F5 is the only question in phase 1: no reviewer split and no check was handed back. F6 was put the
same way as F8 and ruled Ignore, so it is checked 🚫 where it stands, while F8 moves to G4 with a
**Ruling** line, in the form Tracking Finding Status shows. F1, F7 and F9 are recommended Implement
and never asked about; F2, F3 and F4 were already ruled and G3 is complete, so none of them appears.
F5 goes straight to ✅ (kept native only) in phase 1's batch, since the link is already there and
keeping it needs no edit, and G1 drops behind G2 because the decision that put it first is settled.
Had the user answered F5 "Leave open for now" or "skip for now", F5 would stay ❓ with no **Ruling**
line, F7 and F9 would wait on it, G1 would stay first in the proposal with F7 and F9 marked waiting
on F5, and "all" would take G2 and G4.
