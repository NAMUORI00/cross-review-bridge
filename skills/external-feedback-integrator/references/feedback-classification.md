# Feedback Classification

## Apply

Use when the item is correct, supported by local evidence, within scope, and low enough risk to implement now.

Examples:

- missing null check confirmed in current code
- typo or wording fix that preserves meaning
- test gap for changed behavior
- figure/table/caption mismatch visible in provided artifacts

## Consider

Use when the item is plausible but not necessary now.

Examples:

- optional refactor
- broader test expansion
- alternative phrasing with no correctness impact
- performance work without evidence of a current bottleneck

## Reject

Use when the item is hallucinated, unsafe, unsupported, out of scope, or contradicted by local evidence.

Examples:

- references a file, API, figure, citation, or experiment that does not exist
- asks to remove important validation without reason
- overstates a claim or weakens privacy/security
- assumes a product direction the user did not request

## Needs User Decision

Use when the item is valid but changes direction, scope, risk, publication stance, product behavior, or research claims.

Examples:

- new experiment or evidence generation
- major architecture change
- shifting final recommendation or manuscript claim
- changing public UX or policy
