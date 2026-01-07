# zkvm-merkle-lean-verified

A small end-to-end prototype pipeline for verifying zkVM-related Rust code in Lean 4:

**Rust → hax extraction → Lean 4 specs/proofs (WIP)**

This repo is an early-stage experiment aimed at establishing a practical workflow to
verify real-world Rust components used in zkVM / zkEVM stacks.

## Scope (Phase 1)

We extracted a simplified, representative Merkle-path root computation derived from
RISC Zero's `merkle.rs` (receipt Merkle inclusion logic).

Instead of extracting the full RISC0 codebase, we created a small Rust crate with an
*extract-friendly interface*:

- Avoids `dyn Trait` (`&dyn HashFn`) by passing `hash_pair` as a function argument
- Avoids `anyhow::Result` by providing a boolean-style verifier
- Keeps the algorithm identical to the original Merkle-path accumulation logic

## Repository layout

- `rust/merkle_root_rs/`  
  Minimal Rust crate containing:
  - `merkle_root_from_path`
  - `merkle_verify_from_path`
  plus Rust unit tests.

- `scripts/extract.sh`  
  Runs: `cargo hax into lean` and copies the generated Lean output into the Lean project.

- `lean/`  
  Lean 4 project (Lake).
  - `lean/MerkleRootLean/Extracted/` contains the hax-generated Lean code.
  - `lean/HaxLib/` contains the vendored hax Lean prelude (required by the extracted code).

## Current status

- ✅ Rust code builds and tests pass.
- ✅ hax extraction runs and produces Lean code.
- ⚠️ Lean compilation of the extracted code is currently **WIP**:
  the extracted Lean code references `Core.*` identifiers (e.g. `Core.Cmp.PartialEq`)
  that are not resolved in the current Lean environment.
- ⚠️ There are version-compatibility constraints between the hax Lean prelude and the Lean toolchain.
  The toolchain has been adjusted locally, but additional alignment work is required for CI.

## Next steps (Phase 2 / TODO)

1. **Fix Lean compilation of extracted code**
   - Provide/enable the missing `Core.*` namespaces expected by hax output
   - Or adjust hax backend configuration to emit Lean code targeting available libraries

2. **Add a Lean specification for Merkle root**
   - A pure functional spec (e.g. fold over the authentication path)
   - Prove equivalence between the extracted implementation and the spec

3. **Re-introduce ArkLib (optional)**
   - Use ArkLib as a reference spec library for crypto primitives/protocol structure
   - Model `hash_pair` as an abstract oracle function (later: oracle computations)

4. **Scale up toward real-world components**
   - Identify a practical path toward verifying extracted code from zkVMs (Jolt, RISC Zero).

## How to run locally

### Rust
```bash
cd rust/merkle_root_rs
cargo test

