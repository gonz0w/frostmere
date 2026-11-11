# Frostmere project policy

## Purpose and authority

Frostmere is an original, single-player fantasy action RPG: a handcrafted Nordic
home world, detailed block-built characters and scenery, exploration, factions,
crafting and monstrous combat. Space, crystal-sky and infernal chapters connect
through its main timeline. Multiplayer, voxel terrain editing and a building
sandbox are outside the current product contract.

Owner and policy decision maker: **gonz0w**. Owner decisions in GitHub or the
working conversation become durable through a reviewed policy change. Routine
implementation choices inside a selected issue are delegated. Unresolved policy
conflicts stop only the work that depends on them.

Agent Temper pin: `bc4ae7f68ee346b9970f07c7c4bff020120f0278`. See
[provenance](.agent-temper/SOURCE.md). Only the
[GitHub profile](.agent-temper/profiles/github.md) is selected. No strict-TDD,
model-routing or other copied profile is implicitly selected. Local policy stays
outside the immutable bundle. Source changes require an explicit reviewed update.

## Artifact retention

Follow the adopted [artifact lifecycle](.agent-temper/docs/reference/artifact-lifecycle.md).
Use the isolated paths and seven-day CI diagnostic retention documented in
[CONTRIBUTING.md](CONTRIBUTING.md). Keep engine downloads, packages and normal
player data out of source. Before substantial output, record its location,
storage bound and retention trigger in the owning issue. Preserve diagnostics,
active work and recovery assets under existing authority.

## Technology and product contracts

- Godot **4.7.2**, typed GDScript, shaders, JSON content. Python 3.11+ standard
  library for repository checks. Audio regeneration additionally uses NumPy;
  playing the committed WAV assets does not require it.
- Current native evidence: Apple Silicon macOS, M5 Max. M1 / 32 GB remains the
  baseline to qualify. Target outcome: macOS, Windows and Linux; x86_64 Windows
  and Linux are initial portability candidates, not verified support promises.
- Keep the existing Mobile renderer, camera modes, fixed world, resource IDs,
  serialized formats and safe profile isolation. Do not rename the Godot
  application/user-data identity without a tested save migration.
- [Repository map](docs/REPOSITORY_MAP.md), [save contract](docs/SAVE_RESUME.md),
  [crafting](docs/CRAFTING.md), [adventure](docs/ADVENTURE.md), and
  [scope history](docs/SCOPE.md) describe product behavior and context.
- No mandatory network account, telemetry or external service is introduced by
  publication. New runtime dependencies, languages, services or major architecture
  changes require an issue explaining the benefit and owner approval.
- Original code, content, generated audio and game artwork use BSD-3-Clause,
  copyright gonz0w. Retain [third-party notices](THIRD_PARTY_NOTICES.md).
  Contributions must permit distribution under the same license; no CLA or
  signed-off-by requirement is selected. Do not import unlicensed assets.

## Work, selection and completion

[GitHub Issues](https://github.com/gonz0w/frostmere/issues) is the sole live
tracker. Milestones define capabilities and exit conditions, not release dates.
Historic scope, validation and art notes are dated evidence and cannot assign work.
The GitHub profile's six `status:*` labels apply unchanged; each open executable
issue has exactly one. Closed issues have no active status label. Dependencies
use explicit `Blocked by #N` references. Use assignees for people; identify agent
ownership in issue comments. `priority:P0` blocks delivery, P1 is planned, P2 is
follow-up. An owner-selected ready issue is authorized; backlog is not.

The owner selects milestone order and consequential scope changes. Agents may
triage, create bounded findings, map dependencies and propose priorities. On a
continuation, resume the active batch or select the highest-priority ready issue
within the owner's selected milestone. One active batch per integration lead;
record its outcome, included issues, exclusions and acceptance in the owning
issue. Do not silently add discoveries. Required review counts as unfinished work.

Specify acceptance before implementation. Prefer test-first behavior changes;
reproduce defects first, or record why reproduction is unavailable and the
alternative check. Prose and asset changes use source/link/visual checks, without
contrived unit tests. [CONTRIBUTING.md](CONTRIBUTING.md) owns executable commands
and check applicability. Native visuals, input, audio and timing require suitable
real hardware; headless results do not qualify those behaviors or other platforms.

Bound investigations to three repair attempts per failed check and one selected
batch. At exhaustion, record evidence and ask the owner to replan; do not waive
acceptance. Stop early when required evidence is sufficient. Costly hardware,
network services and paid runners require explicit approval. Routine local checks
and public GitHub source-check Actions are authorized by this adoption.

Completion requires observable acceptance, applicable checks, updated reader
instructions, separate review and accepted integration. Record passed, failed,
unavailable and historical evidence distinctly. New findings are reviewed at
milestone selection; an actual security exposure or data-loss blocker pauses
related delivery and is reported to the owner. No emergency release authority.

## Integration and delivery

Agents may implement selected work, commit, push and open PRs targeting `main`.
Agents may merge after applicable checks and a separate review with findings
resolved. A reviewer subagent may supply that review; record that it is agent
review, not independent human assurance. No required signature policy is selected.

Initial source publication has no parent branch: issue #1 records the review
and acceptance of the root commit. This bootstrap integration rule expires after
that push. Later changes use PRs. Agent Temper takes effect with the accepted
publication commit; it does not retroactively invalidate historic work.

Releases/tags, published packages, deployment, permission changes, spending,
secret access and messages to outside people require explicit owner authorization.
The current request authorizes a public repository, README/screenshots and GitHub
issues/milestones; it does not authorize social-media posts or a new binary release.
Destructive history rewrites and removal of user data require approval.

No current release is declared supported by this source publication. Maintain
source setup and issue triage; release support, artifact recovery and native
qualification must be settled in their milestone before the next release.
Use clear reader-focused Markdown; keep facts at their canonical home and avoid
parallel local progress logs. Recheck navigation when public interfaces, setup,
policy or support scope change.

## Exceptions

None. The one-time root-commit integration above fills the project's integration
choice; it does not remove checks or separate review.
