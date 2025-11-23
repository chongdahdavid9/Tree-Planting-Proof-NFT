(define-constant ERR_NOT_OWNER u100)
(define-constant ERR_NOT_FOUND u101)

(define-data-var owner principal tx-sender)

(define-map species
  { name: (string-ascii 32) }
  { kg-per-year: uint }
)

(define-data-var total-species uint u0)

(define-read-only (get-owner)
  (var-get owner)
)

(define-read-only (get-species (name (string-ascii 32)))
  (map-get? species { name: name })
)

(define-read-only (get-total-species)
  (var-get total-species)
)

(define-public (set-owner (new-owner principal))
  (if (is-eq tx-sender (var-get owner))
    (begin
      (var-set owner new-owner)
      (ok new-owner)
    )
    (err ERR_NOT_OWNER)
  )
)

(define-public (set-species
    (name (string-ascii 32))
    (kg-per-year uint)
  )
  (if (is-eq tx-sender (var-get owner))
    (let ((existing (map-get? species { name: name })))
      (match existing
        some-data (begin
          (map-set species { name: name } { kg-per-year: kg-per-year })
          (ok kg-per-year)
        )
        (begin
          (map-set species { name: name } { kg-per-year: kg-per-year })
          (var-set total-species (+ (var-get total-species) u1))
          (ok kg-per-year)
        )
      )
    )
    (err ERR_NOT_OWNER)
  )
)

(define-public (remove-species (name (string-ascii 32)))
  (if (is-eq tx-sender (var-get owner))
    (match (map-get? species { name: name })
      some-data (begin
        (map-delete species { name: name })
        (var-set total-species (- (var-get total-species) u1))
        (ok true)
      )
      (err ERR_NOT_FOUND)
    )
    (err ERR_NOT_OWNER)
  )
)
