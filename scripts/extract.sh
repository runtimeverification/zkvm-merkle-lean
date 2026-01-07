#!/usr/bin/env bash
set -euxo pipefail

CRATE_DIR="rust/merkle_root_rs"
OUT_DIR="lean/MerkleRootLean/Extracted"

rm -rf "${OUT_DIR}"
mkdir -p "${OUT_DIR}"

pushd "${CRATE_DIR}"
  cargo hax into lean
  rsync -a --delete proofs/lean/extraction/ "../../${OUT_DIR}/"
popd

