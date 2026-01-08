# CI Status Dashboard

We have a prototype repo zkvm-merkle-lean-verified implementing a Rust → hax → Lean pipeline (zkVM Merkle-path root computation).

## Current CI status:

Rust build/tests are stable and should remain a blocking check.
The hax and Lean steps are currently marked as WIP / non-blocking (allowed to fail), because we hit toolchain/version alignment issues.

## What we tried:

We installed cargo-hax and related binaries (hax-driver, hax-rust-engine, etc.) and attempted to run `cargo hax into lean` on CI.
hax requires rustc_private and a pinned nightly toolchain. We used the toolchain specified in our local hax checkout: nightly-2025-11-08 with components rustc-dev, rust-src, llvm-tools-preview.

## Why it currently fails in CI:

Installing hax from crates.io (cargo install cargo-hax --version 0.3.5) on the pinned nightly fails due to mismatches with rustc internals (e.g., missing/renamed types like CanonicalTyVarKind, DynKind, AssocItemContainer).
This suggests the crates.io release does not match the rustc internals for that nightly.
Lean build of the extracted output is also WIP

## What kind of help we need from DevOps:

Help pin and install a consistent hax toolchain in CI. Most likely we need to install hax from the same git revision as our local working checkout (not the crates.io 0.3.5 package), e.g. cargo install --git ... --rev <HAX_REV> cargo-hax and the companion binaries, using the pinned nightly nightly-2025-11-08.
Confirm CI network policy: whether we can fetch from GitHub directly or need a mirrored/internal repo.
(Optional) Add caching for ~/.cargo/{git,registry,bin} and a dedicated CARGO_TARGET_DIR to speed up tool installs.

Until this is resolved, we keep hax/Lean steps non-blocking so PRs are not blocked.
Thanks!
