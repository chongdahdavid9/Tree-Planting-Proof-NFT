;; Planter Leaderboard Contract
;; Independent leaderboard tracking top planters

;; Error constants  
(define-constant err-zero (err u201))

;; Constants
(define-constant TOPN u10)
(define-constant BPD u144)

;; Storage maps for scores
(define-map all-time {who: principal} {planted: uint, verified: uint, carbon: uint})

;; Leaderboard lists  
(define-data-var all-time-planted (list 10 {who: principal, score: uint}) (list))

;; Private helper functions
(define-private (get-all-time-helper (who principal))
  (default-to {planted: u0, verified: u0, carbon: u0}
    (map-get? all-time {who: who})
  )
)

;; Period calculation functions
(define-read-only (current-day)
  (/ block-height BPD)
)

;; Public functions
(define-public (inc-planted (who principal) (by uint))
  (begin
    (asserts! (> by u0) err-zero)
    (let ((current-all-time (get-all-time-helper who)))
      (map-set all-time {who: who}
        (merge current-all-time {planted: (+ (get planted current-all-time) by)})
      )
      (ok true)
    )
  )
)

;; Read-only query functions
(define-read-only (get-all-time (who principal))
  (get-all-time-helper who)
)

(define-read-only (get-top-all-time-planted)
  (var-get all-time-planted)
)
