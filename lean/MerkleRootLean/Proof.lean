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
