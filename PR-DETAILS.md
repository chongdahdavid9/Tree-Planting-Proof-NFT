Tree-Planting-Proof-NFT + Independent Leaderboard

Overview
This PR introduces a complete Clarinet project with:
- Tree-Planting-Proof-NFT contract (Clarity v2) for on-chain tree certificates (NFT-like), verifications, adoption/payments, carbon offsets, and planter reputation.
- Planter-Leaderboard contract (independent; no cross-contract calls or traits) tracking top planters by planted, verified, and carbon across all-time and daily/weekly/monthly periods.

Technical Implementation
- Contracts:
  - contracts/tree-planting-proof-nft.clar
    - Storage: token-owner, trees metadata map, verifier registry, species coefficients, planter stats, admin/treasury/fee config
    - Entrypoints: initialize, set-verifier, mint, verify, list/cancel adoption, adopt, transfer
    - Carbon: estimate and update based on species coefficient and block-height-derived age
  - contracts/planter-leaderboard.clar
    - Storage: score maps and fixed-size TOPN leaderboards per metric and period
    - Entrypoints: inc-planted/inc-verified/inc-carbon, top-N queries and ranks, period helpers
- Config: Clarinet.toml with clarity_version=2
- Tests: Clarinet-based tests covering mint/verify/adopt/transfer/carbon; leaderboard updates and queries
- CI: GitHub Actions workflow running Clarinet syntax check

Testing & Validation
•  ✅ Contract structure and syntax implemented
•  ✅ Comprehensive test suite with 15+ test scenarios
•  ✅ CI/CD pipeline configured (syntax check via Clarinet Docker)
•  ✅ Independent leaderboard feature with no external dependencies
