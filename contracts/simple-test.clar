(define-constant ERR_TEST (err u100))

(define-map test-map {id: uint} {value: uint})

(define-public (test-function (id uint) (value uint))
  (begin
    (map-set test-map {id: id} {value: value})
    (ok true)
  )
)

(define-read-only (get-value (id uint))
  (map-get? test-map {id: id})
)
