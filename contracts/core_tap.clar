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

;; Check and award achievements
(define-private (check-achievements (user principal) (program-id uint))
    (let 
        ((progress (map-get? user-progress { user: user, program-id: program-id }))
         (program (map-get? programs program-id)))
        (match (tuple progress program)
            success (begin
                (asserts! (get active (get program success)) err-inactive-program)
                (ok (fold check-single-achievement 
                    (get-achievements-for-program program-id)
                    (ok true)))
            )
            failure err-invalid-program
        )
    )
)

;; Check single achievement
(define-private (check-single-achievement (achievement-id uint) (prior (response bool bool)))
    (let 
        ((achievement (map-get? achievements achievement-id))
         (user-progress (map-get? user-progress 
             { user: user, program-id: (get program-id achievement) })))
        (match (tuple achievement user-progress)
            success (if (and
                    (is-ok prior)
                    (>= (get completed-workouts (get user-progress success)) 
                        (get required-workouts (get achievement success)))
                )
                (award-achievement user achievement-id)
                prior
            )
            failure prior
        )
    )
)

;; Get achievements for specific program
(define-read-only (get-achievements-for-program (program-id uint))
    (filter get-achievement-for-program (get-achievement-ids))
)

;; Helper function to get achievement IDs
(define-read-only (get-achievement-ids)
    (map-get? achievement-index 'all-achievements)
)

;; Helper function to filter achievements by program
(define-read-only (get-achievement-for-program (achievement-id uint))
    (match (map-get? achievements achievement-id)
        achievement (is-eq (get program-id achievement) program-id)
        false
    )
)

;; Deactivate program
(define-public (deactivate-program (program-id uint))
    (let ((program (map-get? programs program-id)))
        (match program
            existing (begin
                (asserts! (or 
                    (is-eq tx-sender contract-owner)
                    (is-eq tx-sender (get trainer existing))
                ) err-owner-only)
                (ok (map-set programs program-id 
                    (merge existing { active: false })))
            )
            failure err-invalid-program
        )
    )
)
