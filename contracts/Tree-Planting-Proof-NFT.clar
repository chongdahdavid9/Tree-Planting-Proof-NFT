(define-non-fungible-token tree-planting-proof uint)

(define-data-var token-id-nonce uint u0)
(define-data-var contract-owner principal tx-sender)

(define-constant contract-admin tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-token-owner (err u101))
(define-constant err-invalid-token-id (err u102))
(define-constant err-already-verified (err u103))
(define-constant err-not-verified (err u104))
(define-constant err-invalid-coordinates (err u105))
(define-constant err-future-date (err u106))
(define-constant err-tree-already-registered (err u107))
(define-constant err-unauthorized-verifier (err u108))
(define-constant err-no-rewards (err u109))
(define-constant err-invalid-species (err u110))
(define-constant err-tree-not-verified (err u111))
(define-constant err-tree-already-adopted (err u112))
(define-constant err-insufficient-payment (err u113))
(define-constant err-self-adoption (err u114))
(define-constant err-adoption-expired (err u115))

(define-map tree-metadata
    uint
    {
        planter: principal,
        tree-species: (string-ascii 50),
        latitude: int,
        longitude: int,
        planted-date: uint,
        verified: bool,
        verifier: (optional principal),
        carbon-offset: uint,
        survival-status: (string-ascii 20),
    }
)

(define-map authorized-verifiers
    principal
    bool
)

(define-map planter-stats
    principal
    {
        trees-planted: uint,
        trees-verified: uint,
        total-carbon-offset: uint,
        reputation-score: uint,
    }
)

(define-map tree-location-registry
    {
        latitude: int,
        longitude: int,
    }
    uint
)

(define-map verification-rewards
    principal
    uint
)

(define-map species-carbon-rates
    (string-ascii 50)
    uint
)

(define-map tree-adoption
    uint
    {
        adopter: principal,
        adoption-fee: uint,
        adoption-date: uint,
        adoption-duration: uint,
        maintenance-fund: uint,
    }
)

(define-map adoption-pricing
    (string-ascii 50)
    uint
)

(define-map adopter-stats
    principal
    {
        trees-adopted: uint,
        total-contributed: uint,
        active-adoptions: uint,
    }
)

(define-read-only (get-last-token-id)
    (var-get token-id-nonce)
)

(define-read-only (get-token-uri (token-id uint))
    (ok (some "https://api.tree-nft.com/metadata/"))
)

(define-read-only (get-owner (token-id uint))
    (ok (nft-get-owner? tree-planting-proof token-id))
)

(define-read-only (get-tree-metadata (token-id uint))
    (map-get? tree-metadata token-id)
)

(define-read-only (get-planter-stats (planter principal))
    (default-to {
        trees-planted: u0,
        trees-verified: u0,
        total-carbon-offset: u0,
        reputation-score: u0,
    }
        (map-get? planter-stats planter)
    )
)

(define-read-only (is-authorized-verifier (verifier principal))
    (default-to false (map-get? authorized-verifiers verifier))
)

(define-read-only (get-verification-rewards (planter principal))
    (default-to u0 (map-get? verification-rewards planter))
)

(define-read-only (is-location-registered
        (latitude int)
        (longitude int)
    )
    (is-some (map-get? tree-location-registry {
        latitude: latitude,
        longitude: longitude,
    }))
)

(define-read-only (get-trees-by-location
        (latitude int)
        (longitude int)
    )
    (map-get? tree-location-registry {
        latitude: latitude,
        longitude: longitude,
    })
)

(define-read-only (get-species-carbon-rate (species (string-ascii 50)))
    (default-to u30 (map-get? species-carbon-rates species))
)

(define-read-only (get-tree-adoption (token-id uint))
    (map-get? tree-adoption token-id)
)

(define-read-only (get-adoption-price (species (string-ascii 50)))
    (default-to u1000000 (map-get? adoption-pricing species))
)

(define-read-only (get-adopter-stats (adopter principal))
    (default-to {
        trees-adopted: u0,
        total-contributed: u0,
        active-adoptions: u0,
    }
        (map-get? adopter-stats adopter)
    )
)

(define-read-only (is-tree-adopted (token-id uint))
    (is-some (get-tree-adoption token-id))
)

(define-read-only (is-adoption-active (token-id uint))
    (match (get-tree-adoption token-id)
        adoption-data (< burn-block-height
            (+ (get adoption-date adoption-data)
                (get adoption-duration adoption-data)
            ))
        false
    )
)

(define-private (is-valid-coordinates
        (latitude int)
        (longitude int)
    )
    (and
        (>= latitude -90000000)
        (<= latitude 90000000)
        (>= longitude -180000000)
        (<= longitude 180000000)
    )
)

(define-private (calculate-carbon-offset (tree-species (string-ascii 50)))
    (get-species-carbon-rate tree-species)
)

(define-private (update-planter-stats
        (planter principal)
        (carbon-offset uint)
        (verified bool)
    )
    (let ((current-stats (get-planter-stats planter)))
        (map-set planter-stats planter {
            trees-planted: (+ (get trees-planted current-stats) u1),
            trees-verified: (if verified
                (+ (get trees-verified current-stats) u1)
                (get trees-verified current-stats)
            ),
            total-carbon-offset: (+ (get total-carbon-offset current-stats) carbon-offset),
            reputation-score: (+ (get reputation-score current-stats)
                (if verified
                    u10
                    u5
                )),
        })
    )
)

(define-private (is-valid-species (species (string-ascii 50)))
    (or
        (is-eq species "oak")
        (or
            (is-eq species "pine")
            (or
                (is-eq species "maple")
                (or
                    (is-eq species "birch")
                    (or
                        (is-eq species "cedar")
                        (or
                            (is-eq species "willow")
                            (is-eq species "other")
                        )
                    )
                )
            )
        )
    )
)

(define-private (update-adopter-stats
        (adopter principal)
        (fee uint)
        (is-new-adoption bool)
    )
    (let ((current-stats (get-adopter-stats adopter)))
        (map-set adopter-stats adopter {
            trees-adopted: (if is-new-adoption
                (+ (get trees-adopted current-stats) u1)
                (get trees-adopted current-stats)
            ),
            total-contributed: (+ (get total-contributed current-stats) fee),
            active-adoptions: (if is-new-adoption
                (+ (get active-adoptions current-stats) u1)
                (get active-adoptions current-stats)
            ),
        })
    )
)

(define-public (initialize-species-rates)
    (begin
        (asserts! (is-eq tx-sender contract-admin) err-owner-only)
        (map-set species-carbon-rates "oak" u48)
        (map-set species-carbon-rates "pine" u35)
        (map-set species-carbon-rates "maple" u42)
        (map-set species-carbon-rates "birch" u25)
        (map-set species-carbon-rates "cedar" u38)
        (map-set species-carbon-rates "willow" u20)
        (map-set species-carbon-rates "other" u30)
        (ok true)
    )
)

(define-public (initialize-adoption-pricing)
    (begin
        (asserts! (is-eq tx-sender contract-admin) err-owner-only)
        (map-set adoption-pricing "oak" u2000000)
        (map-set adoption-pricing "pine" u1500000)
        (map-set adoption-pricing "maple" u1800000)
        (map-set adoption-pricing "birch" u1200000)
        (map-set adoption-pricing "cedar" u1600000)
        (map-set adoption-pricing "willow" u1000000)
        (map-set adoption-pricing "other" u1000000)
        (ok true)
    )
)

(define-public (plant-tree
        (tree-species (string-ascii 50))
        (latitude int)
        (longitude int)
        (planted-date uint)
    )
    (let (
            (token-id (+ (var-get token-id-nonce) u1))
            (carbon-offset (calculate-carbon-offset tree-species))
        )
        (asserts! (is-valid-coordinates latitude longitude)
            err-invalid-coordinates
        )
        (asserts! (is-valid-species tree-species) err-invalid-species)
        (asserts! (<= planted-date burn-block-height) err-future-date)
        (asserts! (not (is-location-registered latitude longitude))
            err-tree-already-registered
        )

        (try! (nft-mint? tree-planting-proof token-id tx-sender))

        (map-set tree-metadata token-id {
            planter: tx-sender,
            tree-species: tree-species,
            latitude: latitude,
            longitude: longitude,
            planted-date: planted-date,
            verified: false,
            verifier: none,
            carbon-offset: carbon-offset,
            survival-status: "planted",
        })

        (map-set tree-location-registry {
            latitude: latitude,
            longitude: longitude,
        }
            token-id
        )

        (update-planter-stats tx-sender carbon-offset false)
        (var-set token-id-nonce token-id)

        (ok token-id)
    )
)

(define-public (verify-tree (token-id uint))
    (let (
            (tree-data (unwrap! (get-tree-metadata token-id) err-invalid-token-id))
            (planter (get planter tree-data))
        )
        (asserts! (is-authorized-verifier tx-sender) err-unauthorized-verifier)
        (asserts! (not (get verified tree-data)) err-already-verified)

        (map-set tree-metadata token-id
            (merge tree-data {
                verified: true,
                verifier: (some tx-sender),
                survival-status: "verified",
            })
        )

        (update-planter-stats planter (get carbon-offset tree-data) true)

        (map-set verification-rewards planter
            (+ (get-verification-rewards planter) u10)
        )

        (ok true)
    )
)

(define-public (update-survival-status
        (token-id uint)
        (status (string-ascii 20))
    )
    (let ((tree-data (unwrap! (get-tree-metadata token-id) err-invalid-token-id)))
        (asserts! (is-authorized-verifier tx-sender) err-unauthorized-verifier)
        (asserts! (get verified tree-data) err-not-verified)

        (map-set tree-metadata token-id
            (merge tree-data { survival-status: status })
        )

        (ok true)
    )
)

(define-public (transfer
        (token-id uint)
        (sender principal)
        (recipient principal)
    )
    (begin
        (asserts! (is-eq tx-sender sender) err-not-token-owner)
        (try! (nft-transfer? tree-planting-proof token-id sender recipient))
        (ok true)
    )
)

(define-public (add-authorized-verifier (verifier principal))
    (begin
        (asserts! (is-eq tx-sender contract-admin) err-owner-only)
        (map-set authorized-verifiers verifier true)
        (ok true)
    )
)

(define-public (remove-authorized-verifier (verifier principal))
    (begin
        (asserts! (is-eq tx-sender contract-admin) err-owner-only)
        (map-delete authorized-verifiers verifier)
        (ok true)
    )
)

(define-public (update-species-carbon-rate
        (species (string-ascii 50))
        (rate uint)
    )
    (begin
        (asserts! (is-eq tx-sender contract-admin) err-owner-only)
        (map-set species-carbon-rates species rate)
        (ok true)
    )
)

(define-public (update-adoption-pricing
        (species (string-ascii 50))
        (price uint)
    )
    (begin
        (asserts! (is-eq tx-sender contract-admin) err-owner-only)
        (map-set adoption-pricing species price)
        (ok true)
    )
)

(define-public (claim-rewards)
    (let ((rewards (get-verification-rewards tx-sender)))
        (asserts! (> rewards u0) err-no-rewards)
        (map-delete verification-rewards tx-sender)
        (ok rewards)
    )
)

(define-public (adopt-tree
        (token-id uint)
        (duration uint)
    )
    (let (
            (tree-data (unwrap! (get-tree-metadata token-id) err-invalid-token-id))
            (adoption-fee (get-adoption-price (get tree-species tree-data)))
            (planter (get planter tree-data))
        )
        (asserts! (get verified tree-data) err-tree-not-verified)
        (asserts! (not (is-tree-adopted token-id)) err-tree-already-adopted)
        (asserts! (not (is-eq tx-sender planter)) err-self-adoption)
        (asserts! (> duration u0) err-invalid-token-id)

        (try! (stx-transfer? adoption-fee tx-sender planter))

        (map-set tree-adoption token-id {
            adopter: tx-sender,
            adoption-fee: adoption-fee,
            adoption-date: burn-block-height,
            adoption-duration: duration,
            maintenance-fund: (/ adoption-fee u2),
        })

        (update-adopter-stats tx-sender adoption-fee true)

        (ok token-id)
    )
)

(define-public (extend-adoption
        (token-id uint)
        (additional-duration uint)
    )
    (let (
            (adoption-data (unwrap! (get-tree-adoption token-id) err-invalid-token-id))
            (tree-data (unwrap! (get-tree-metadata token-id) err-invalid-token-id))
            (extension-fee (/ (get-adoption-price (get tree-species tree-data)) u2))
            (planter (get planter tree-data))
        )
        (asserts! (is-eq tx-sender (get adopter adoption-data))
            err-not-token-owner
        )
        (asserts! (is-adoption-active token-id) err-adoption-expired)
        (asserts! (> additional-duration u0) err-invalid-token-id)

        (try! (stx-transfer? extension-fee tx-sender planter))

        (map-set tree-adoption token-id
            (merge adoption-data {
                adoption-duration: (+ (get adoption-duration adoption-data) additional-duration),
                maintenance-fund: (+ (get maintenance-fund adoption-data) (/ extension-fee u2)),
            })
        )

        (update-adopter-stats tx-sender extension-fee false)

        (ok true)
    )
)

(define-public (bulk-verify-trees (token-ids (list 10 uint)))
    (begin
        (asserts! (is-authorized-verifier tx-sender) err-unauthorized-verifier)
        (ok (map verify-tree-helper token-ids))
    )
)

(define-private (verify-tree-helper (token-id uint))
    (match (get-tree-metadata token-id)
        tree-data (if (not (get verified tree-data))
            (begin
                (map-set tree-metadata token-id
                    (merge tree-data {
                        verified: true,
                        verifier: (some tx-sender),
                        survival-status: "verified",
                    })
                )
                (update-planter-stats (get planter tree-data)
                    (get carbon-offset tree-data) true
                )
                token-id
            )
            token-id
        )
        token-id
    )
)

(define-read-only (get-trees-planted-count)
    (var-get token-id-nonce)
)

(define-read-only (get-contract-stats)
    {
        total-trees: (var-get token-id-nonce),
        contract-owner: (var-get contract-owner),
    }
)

(define-read-only (get-trees-by-planter (planter principal))
    (get-planter-stats planter)
)

(define-read-only (calculate-environmental-impact (planter principal))
    (let ((stats (get-planter-stats planter)))
        {
            carbon-sequestered: (* (get total-carbon-offset stats) u365),
            oxygen-produced: (* (get total-carbon-offset stats) u730),
            air-purified: (* (get total-carbon-offset stats) u1000),
        }
    )
)

(initialize-species-rates)
(initialize-adoption-pricing)
