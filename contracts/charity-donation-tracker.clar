;; Simple Charity Donation Tracker Contract

(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_NOT_FOUND (err u101))

(define-map donations {id: uint} {donor: principal, amount: uint, charity: (string-ascii 64)})
(define-data-var next-id uint u1)

(define-public (make-donation (amount uint) (charity (string-ascii 64)))
  (let ((id (var-get next-id)))
    (map-set donations {id: id} {donor: tx-sender, amount: amount, charity: charity})
    (var-set next-id (+ id u1))
    (ok id)
  )
)

(define-read-only (get-donation (id uint))
  (map-get? donations {id: id})
)

(define-read-only (get-next-id)
  (var-get next-id)
)
