;; CoreTap Contract
;; Fitness and wellness tracking platform

;; Constants 
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-trainer (err u101))
(define-constant err-invalid-program (err u102))
(define-constant err-program-exists (err u103))
(define-constant err-achievement-exists (err u104))
(define-constant err-invalid-achievement (err u105))
(define-constant err-inactive-program (err u106))

;; [Previous code remains unchanged until check-achievements function]

;; Check and award achievements
(define-private (check-achievements (user principal) (program-id uint))
    (let 
        ((progress (unwrap-panic (map-get? user-progress { user: user, program-id: program-id })))
         (program (unwrap-panic (map-get? programs program-id))))
        (asserts! (get active program) err-inactive-program)
        (ok (fold check-single-achievement 
            (get-achievements-for-program program-id)
            (ok true)))
    )
)

;; Check single achievement
(define-private (check-single-achievement (achievement-id uint) (prior (response bool bool)))
    (let 
        ((achievement (unwrap-panic (map-get? achievements achievement-id)))
         (user-progress (unwrap-panic (map-get? user-progress 
             { user: tx-sender, program-id: (get program-id achievement) }))))
        (if (and
                (is-ok prior)
                (>= (get completed-workouts user-progress) (get required-workouts achievement))
            )
            (award-achievement tx-sender achievement-id)
            prior
        )
    )
)

;; Helper function to get achievement IDs
(define-read-only (get-achievement-ids)
    (ok (map uint-to-buff (list u0 u1 u2 u3 u4 u5 u6 u7 u8 u9)))
)

;; Helper function to filter achievements by program
(define-read-only (get-achievement-for-program (achievement-id uint))
    (match (map-get? achievements achievement-id)
        achievement (is-eq (get program-id achievement) program-id)
        false
    )
)

;; [Rest of the contract remains unchanged]
