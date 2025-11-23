;; Tree Planting Proof NFT Contract
;; NFT-like tokens for tree planting proofs with metadata, verification, adoption system, and carbon tracking

;; Error constants
(define-constant err-not-admin (err u100))
(define-constant err-unauthorized (err u101))
(define-constant err-token-not-found (err u102))
(define-constant err-not-owner (err u103))
(define-constant err-already-verified (err u104))
(define-constant err-not-verified (err u105))
(define-constant err-invalid-species (err u106))
(define-constant err-already-adopted (err u107))
(define-constant err-bad-price (err u108))
(define-constant err-stx-transfer (err u109))
(define-constant err-not-listed (err u110))
(define-constant err-overflow (err u111))

;; Constants
(define-constant BLOCKS_PER_DAY u144)
(define-constant BLOCKS_PER_YEAR u52560)

;; Data variables
(define-data-var owner (optional principal) none)
(define-data-var platform-treasury principal (as-contract tx-sender))
(define-data-var platform-fee-bps uint u250) ;; 2.5%
(define-data-var next-id uint u1)

;; Storage maps
(define-map token-owner {id: uint} principal)

(define-map token-approval {id: uint} principal)

(define-map trees 
  {id: uint} 
  {
    species: (string-ascii 32),
    location: (string-ascii 64),
    uri: (optional (string-utf8 256)),
    planting-height: uint,
    verified: bool,
    verification-height: (optional uint),
    planter: principal,
    adopter: (optional principal),
    adoption-price: (optional uint),
    carbon-kg: uint
  }
)

(define-map planter-stats 
  {who: principal} 
  {
    planted: uint,
    verified: uint,
    adopted: uint,
    carbon-kg: uint,
    reputation: int
  }
)

(define-map verifiers {who: principal} bool)

(define-map species-coef {name: (string-ascii 32)} {kg-per-year: uint})

;; Private functions
(define-private (is-admin (p principal))
  (match (var-get owner)
    admin (is-eq p admin)
    false
  )
)

(define-private (get-planter-stats-helper (who principal))
  (default-to 
    {planted: u0, verified: u0, adopted: u0, carbon-kg: u0, reputation: 0}
    (map-get? planter-stats {who: who})
  )
)

(define-private (update-planter-stats (who principal) (planted-inc uint) (verified-inc uint) (adopted-inc uint) (carbon-inc uint) (reputation-inc int))
  (let ((current (get-planter-stats-helper who)))
    (map-set planter-stats {who: who}
      {
        planted: (+ (get planted current) planted-inc),
        verified: (+ (get verified current) verified-inc),
        adopted: (+ (get adopted current) adopted-inc),
        carbon-kg: (+ (get carbon-kg current) carbon-inc),
        reputation: (+ (get reputation current) reputation-inc)
      }
    )
  )
)

(define-private (seed-species-coefficients)
  (begin
    (map-set species-coef {name: "mango"} {kg-per-year: u70})
    (map-set species-coef {name: "oak"} {kg-per-year: u48})
    (map-set species-coef {name: "pine"} {kg-per-year: u30})
    (map-set species-coef {name: "maple"} {kg-per-year: u42})
    (map-set species-coef {name: "birch"} {kg-per-year: u25})
    (map-set species-coef {name: "cedar"} {kg-per-year: u38})
    (map-set species-coef {name: "willow"} {kg-per-year: u20})
    (map-set species-coef {name: "other"} {kg-per-year: u35})
  )
)

;; Public functions
(define-public (initialize (admin principal) (treasury principal))
  (begin
    (asserts! (is-none (var-get owner)) err-unauthorized)
    (var-set owner (some admin))
    (var-set platform-treasury treasury)
    (seed-species-coefficients)
    (ok true)
  )
)

(define-public (set-platform-fee (bps uint))
  (begin
    (asserts! (is-admin tx-sender) err-not-admin)
    (asserts! (<= bps u10000) err-bad-price)
    (var-set platform-fee-bps bps)
    (ok true)
  )
)

(define-public (set-treasury (t principal))
  (begin
    (asserts! (is-admin tx-sender) err-not-admin)
    (var-set platform-treasury t)
    (ok true)
  )
)

(define-public (set-verifier (who principal) (allowed bool))
  (begin
    (asserts! (is-admin tx-sender) err-not-admin)
    (map-set verifiers {who: who} allowed)
    (ok true)
  )
)

(define-public (set-species-coef (name (string-ascii 32)) (kg-per-year uint))
  (begin
    (asserts! (is-admin tx-sender) err-not-admin)
    (map-set species-coef {name: name} {kg-per-year: kg-per-year})
    (ok true)
  )
)

(define-public (mint-tree (species (string-ascii 32)) (location (string-ascii 64)) (uri (optional (string-utf8 256))))
  (let ((id (var-get next-id)))
    (asserts! (is-some (map-get? species-coef {name: species})) err-invalid-species)
    (map-set token-owner {id: id} tx-sender)
    (map-set trees {id: id}
      {
        species: species,
        location: location,
        uri: uri,
        planting-height: block-height,
        verified: false,
        verification-height: none,
        planter: tx-sender,
        adopter: none,
        adoption-price: none,
        carbon-kg: u0
      }
    )
    (update-planter-stats tx-sender u1 u0 u0 u0 1)
    (var-set next-id (+ id u1))
    (ok id)
  )
)

(define-public (transfer (id uint) (to principal))
  (let ((current-owner (unwrap! (map-get? token-owner {id: id}) err-token-not-found)))
    (asserts! (is-eq tx-sender current-owner) err-not-owner)
    (map-set token-owner {id: id} to)
    (map-delete token-approval {id: id})
    (ok true)
  )
)

(define-public (approve (id uint) (to principal))
  (let ((current-owner (unwrap! (map-get? token-owner {id: id}) err-token-not-found)))
    (asserts! (is-eq tx-sender current-owner) err-not-owner)
    (map-set token-approval {id: id} to)
    (ok true)
  )
)

(define-public (revoke-approval (id uint))
  (let ((current-owner (unwrap! (map-get? token-owner {id: id}) err-token-not-found)))
    (asserts! (is-eq tx-sender current-owner) err-not-owner)
    (map-delete token-approval {id: id})
    (ok true)
  )
)

(define-public (transfer-from (id uint) (from principal) (to principal))
  (let ((current-owner (unwrap! (map-get? token-owner {id: id}) err-token-not-found)))
    (asserts! (is-eq from current-owner) err-not-owner)
    (let (
      (is-owner (is-eq tx-sender current-owner))
      (approved? (match (map-get? token-approval {id: id}) approver (is-eq approver tx-sender) false))
    )
      (asserts! (or is-owner approved?) err-unauthorized)
      (map-set token-owner {id: id} to)
      (map-delete token-approval {id: id})
      (ok true)
    )
  )
)

(define-read-only (get-approved (id uint))
  (map-get? token-approval {id: id})
)

(define-public (verify-tree (id uint))
  (let ((tree (unwrap! (map-get? trees {id: id}) err-token-not-found)))
    (asserts! (default-to false (map-get? verifiers {who: tx-sender})) err-unauthorized)
    (asserts! (not (get verified tree)) err-already-verified)
    (map-set trees {id: id}
      (merge tree {
        verified: true,
        verification-height: (some block-height)
      })
    )
    (update-planter-stats (get planter tree) u0 u1 u0 u0 2)
    (ok true)
  )
)

(define-public (list-for-adoption (id uint) (price uint))
  (let ((current-owner (unwrap! (map-get? token-owner {id: id}) err-token-not-found))
        (tree (unwrap! (map-get? trees {id: id}) err-token-not-found)))
    (asserts! (is-eq tx-sender current-owner) err-not-owner)
    (asserts! (> price u0) err-bad-price)
    (map-set trees {id: id}
      (merge tree {adoption-price: (some price)})
    )
    (ok true)
  )
)

(define-public (cancel-adoption (id uint))
  (let ((current-owner (unwrap! (map-get? token-owner {id: id}) err-token-not-found))
        (tree (unwrap! (map-get? trees {id: id}) err-token-not-found)))
    (asserts! (is-eq tx-sender current-owner) err-not-owner)
    (map-set trees {id: id}
      (merge tree {adoption-price: none})
    )
    (ok true)
  )
)

(define-public (adopt-tree (id uint))
  (let ((tree (unwrap! (map-get? trees {id: id}) err-token-not-found))
        (price (unwrap! (get adoption-price tree) err-not-listed))
        (current-owner (unwrap! (map-get? token-owner {id: id}) err-token-not-found))
        (fee (/ (* price (var-get platform-fee-bps)) u10000))
        (payout (- price fee)))
    (asserts! (get verified tree) err-not-verified)
    (asserts! (is-none (get adopter tree)) err-already-adopted)
    (try! (stx-transfer? fee tx-sender (var-get platform-treasury)))
    (try! (stx-transfer? payout tx-sender current-owner))
    (map-set trees {id: id}
      (merge tree {
        adopter: (some tx-sender),
        adoption-price: none
      })
    )
    (update-planter-stats (get planter tree) u0 u0 u1 u0 3)
    (ok id)
  )
)

(define-public (update-carbon (id uint))
  (let ((tree (unwrap! (map-get? trees {id: id}) err-token-not-found))
        (species-data (unwrap! (map-get? species-coef {name: (get species tree)}) err-invalid-species))
        (age-years (/ (- block-height (get planting-height tree)) BLOCKS_PER_YEAR))
        (new-carbon (* (get kg-per-year species-data) age-years))
        (carbon-diff (- new-carbon (get carbon-kg tree))))
    (map-set trees {id: id}
      (merge tree {carbon-kg: new-carbon})
    )
    (update-planter-stats (get planter tree) u0 u0 u0 carbon-diff 0)
    (ok new-carbon)
  )
)

;; Read-only functions
(define-read-only (owner-of (id uint))
  (ok (map-get? token-owner {id: id}))
)

(define-read-only (get-tree (id uint))
  (ok (map-get? trees {id: id}))
)

(define-read-only (get-planter-stats (who principal))
  (get-planter-stats-helper who)
)

(define-read-only (is-verifier (who principal))
  (default-to false (map-get? verifiers {who: who}))
)

(define-read-only (get-species-coef (species (string-ascii 32)))
  (map-get? species-coef {name: species})
)

(define-read-only (get-age-years (id uint))
  (match (map-get? trees {id: id})
    tree (ok (/ (- block-height (get planting-height tree)) BLOCKS_PER_YEAR))
    err-token-not-found
  )
)

(define-read-only (estimate-carbon (id uint))
  (match (map-get? trees {id: id})
    tree (match (map-get? species-coef {name: (get species tree)})
      species-data (let ((age-years (/ (- block-height (get planting-height tree)) BLOCKS_PER_YEAR)))
        (ok (* (get kg-per-year species-data) age-years))
      )
      err-invalid-species
    )
    err-token-not-found
  )
)

(define-read-only (get-next-id)
  (var-get next-id)
)

(define-read-only (get-platform-fee-bps)
  (var-get platform-fee-bps)
)

(define-read-only (get-platform-treasury)
  (var-get platform-treasury)
)
