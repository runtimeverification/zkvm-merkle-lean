# Current status

Creating first pipeline Rust → hax → Lean → specification → proof

## Choosing right candicate for first verification

Source: [Risk0 merkle.rs](https://github.com/risc0/risc0/blob/2e73cb82cadfbad9190b2b34f124481c9b57d371/risc0/zkvm/src/receipt/merkle.rs)

Best starting candidate: Merkle proof verification / Merkle root recomputation

```rust
impl MerkleProof {
    /// Verify the Merkle inclusion proof against the given leaf and root.
    pub fn verify(
        &self,
        leaf: &Digest,
        root: &Digest,
        hashfn: &dyn HashFn<BabyBear>,
    ) -> Result<()> {
        ensure!(
            self.root(leaf, hashfn) == *root,
            "merkle proof verify failed"
        );
        Ok(())
    }

    /// Calculate the root of this branch by iteratively hashing, starting from the leaf.
    pub fn root(&self, leaf: &Digest, hashfn: &dyn HashFn<BabyBear>) -> Digest {
        let mut cur = *leaf;
        let mut cur_index = self.index;
        for sibling in &self.digests {
            cur = if cur_index & 1 == 0 {
                *hashfn.hash_pair(&cur, sibling)
            } else {
                *hashfn.hash_pair(sibling, &cur)
            };
            cur_index >>= 1;
        }
        cur
    }
}

```

### Why this is the best first piece

- Actually used in both RISC0 and Jolt (commitments to memory/trace pages)
- Elementary specification: "root = fold over path"
- Possible to prove the logic's correctness without cryptographic assumptions about the hash
- Convenient to link with the "Oracle" concept from ArkLib: hash compression can be an oracle

## Adapt the Rust code for extraction

The simplification is acceptable and well-justified for formal verification purposes: what we did

- Removed Trait Dependencies
- Eliminated Result Type and Error Handling
- Flattened Struct into Function Parameters
- Removed Generic Type Parameters
- Added Toy Hash for Testing

**How it can be united with ArkLib:**

In ArkLib, the hash_pair can be modeled as a cryptographic oracle. This transforms Merkle root computation into an oracle computation that makes exactly len(digests) queries to the hash oracle, naturally fitting ArkLib's verification framework where algorithms interact with oracle abstractions.

```rust

// This is a "representative zkVM code": the algorithm is identical, 
// the interface has been adapted for verification/extraction. 

#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub struct Digest(pub [u32; 8]);

pub fn merkle_root_from_path(
    leaf: Digest,
    index: u32,
    digests: &[Digest],
    hash_pair: fn(&Digest, &Digest) -> Digest,
) -> Digest {
    let mut cur = leaf;
    let mut cur_index = index;
    for sibling in digests {
        cur = if cur_index & 1 == 0 {
            hash_pair(&cur, sibling)
        } else {
            hash_pair(sibling, &cur)
        };
        cur_index >>= 1;
    }
    cur
}

pub fn merkle_verify_from_path(
    leaf: Digest,
    index: u32,
    digests: &[Digest],
    expected_root: Digest,
    hash_pair: fn(&Digest, &Digest) -> Digest,
) -> bool {
    merkle_root_from_path(leaf, index, digests, hash_pair) == expected_root
}

// For `сargo test` to pass and provide a basic sanity check, we implement a 'toy hash' function:

#[cfg(test)]
mod tests {
    use super::*;

    fn toy_hash_pair(a: &Digest, b: &Digest) -> Digest {
        let mut out = [0u32; 8];
        for i in 0..8 {
            out[i] = a.0[i].wrapping_add(b.0[i]) ^ 0x9e3779b9;
        }
        Digest(out)
    }

    #[test]
    fn root_and_verify_agree() {
        let leaf = Digest([1,2,3,4,5,6,7,8]);
        let sib1 = Digest([9,10,11,12,13,14,15,16]);
        let sib2 = Digest([17,18,19,20,21,22,23,24]);
        let path = vec![sib1, sib2];

        let root = merkle_root_from_path(leaf, 3, &path, toy_hash_pair);
        assert!(merkle_verify_from_path(leaf, 3, &path, root, toy_hash_pair));
    }
}

```

We extracted the essence of the Merkle proof algorithm while removing RISC0-specific implementation details.

## Extract code to lean and write/prove first theorems

### Theorem 1: `merkle_verify_is_pure_eq`

Proves that the verification function `merkle_verify_from_path` is purely syntactic unfolding. This property is trivial but important — it shows that the verification code does nothing beyond comparing the computed and expected roots.

### Theorem 2: `merkle_verify_of_computed_root_is_true`

Proves basic soundness of the algorithm:
- If we compute a root `r` via `merkle_root_from_path`
- And then verify the same root `r` via `merkle_verify_from_path`
- The result will always be `true`

```lean
import MerkleRootLean.Extracted.Merkle_root_rs
-- Two theorems below are not about crypto-security, but it is already machine-checked for the Rust-extracted code.

-- merkle_verify_is_pure_eq theorem proves that extracted verify — is the same as “calculate root and compare to expected”.
-- "verify = pure (root == expected_root)" (almost rfl/simp)
theorem merkle_verify_is_pure_eq
  (leaf : Merkle_root_rs.Digest)
  (index : u32)
  (digests : RustSlice Merkle_root_rs.Digest)
  (expected_root : Merkle_root_rs.Digest)
  (hash_pair :
    Merkle_root_rs.Digest → Merkle_root_rs.Digest → RustM Merkle_root_rs.Digest) :
  Merkle_root_rs.merkle_verify_from_path leaf index digests expected_root hash_pair
    =
  (do
    let r ← Merkle_root_rs.merkle_root_from_path leaf index digests hash_pair
    pure (Core.Cmp.PartialEq.eq Merkle_root_rs.Digest Merkle_root_rs.Digest r expected_root)) := by
  -- should work:
  simp [Merkle_root_rs.merkle_verify_from_path]

-- merkle_verify_of_computed_root_is_true proves the basic soundness property of verify:
-- "if expected_root = compute_root(data), then verify(data, expected_root) = true."
-- "if expected_root = computed_root, verify should return true"
theorem merkle_verify_of_computed_root_is_true
  (leaf : Merkle_root_rs.Digest)
  (index : u32)
  (digests : RustSlice Merkle_root_rs.Digest)
  (hash_pair :
    Merkle_root_rs.Digest → Merkle_root_rs.Digest → RustM Merkle_root_rs.Digest) :
  (do
    let r ← Merkle_root_rs.merkle_root_from_path leaf index digests hash_pair
    Merkle_root_rs.merkle_verify_from_path leaf index digests r hash_pair)
    =
  pure true := by
  -- Unfold verify, and just eq r r left
  simp [Merkle_root_rs.merkle_verify_from_path]

```

## Current work summary

Stage 1 / Recon:

We set up a PoC end-to-end pipeline (Rust → cargo hax into lean → Lean project/CI) on a simplified zkVM-representative component: Merkle-path root recomputation (adapted from RISC0, with an extraction-friendly interface). CI is green with hax/Lean steps currently marked non-blocking.

Current blocker: the Lean backend extraction succeeds, but the generated Lean module does not typecheck against the current Lean prelude because it references missing/incomplete core models (Core.Cmp, Core.Iter, and generated AssociatedTypes for traits like PartialEq/Eq/Debug, plus iterator/fold APIs).

We asked the hax maintainers Source: [Zulip](https://hacspec.zulipchat.com/#narrow/channel/269544-general/topic/hax.20.2B.20lean.20example/with/561950534)

  
They confirmed this is expected right now. Preferred workaround is to 
(a) define missing Core.* locally or 
(b) patch the extracted Lean. They also noted they are switching methodology: core library models will be written in Rust and then extracted to Lean with hax; hand-written Lean core models will soon be replaced.

Next steps:

- Build a minimal Rust “core-model” crate for the missing traits/APIs (PartialEq/Eq/Iter) and extract it to Lean (instead of maintaining hand-written Lean stubs).
- Document the encountered gaps/heuristics and raise issues/PRs where appropriate.
- Once the extracted Merkle module typechecks, finish at least basic proofs (e.g., verify is “compute root then compare”, plus a trivial acceptance lemma).



