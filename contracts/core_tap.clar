;; CoreTap Contract
;; Fitness and wellness tracking platform

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-trainer (err u101))
(define-constant err-invalid-program (err u102))
(define-constant err-program-exists (err u103))

;; Data Variables
(define-data-var next-program-id uint u0)

;; Data Maps
(define-map trainers principal bool)
(define-map programs 
    uint 
    {
        trainer: principal,
        name: (string-ascii 50),
        description: (string-utf8 500),
        difficulty: uint,
        active: bool
    }
)

(define-map user-progress 
    { user: principal, program-id: uint }
    {
        completed-workouts: uint,
        last-workout: uint,
        achievements: (list 10 uint)
    }
)

;; Public Functions

;; Add a new trainer
(define-public (add-trainer (trainer-address principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (ok (map-set trainers trainer-address true))
    )
)

;; Create new program
(define-public (create-program 
    (name (string-ascii 50))
    (description (string-utf8 500))
    (difficulty uint))
    (let
        ((trainer-status (default-to false (map-get? trainers tx-sender)))
         (program-id (var-get next-program-id)))
        (asserts! trainer-status err-not-trainer)
        (asserts! (map-insert programs program-id {
            trainer: tx-sender,
            name: name,
            description: description,
            difficulty: difficulty,
            active: true
        }) err-program-exists)
        (var-set next-program-id (+ program-id u1))
        (ok program-id)
    )
)

;; Record workout completion
(define-public (record-workout (program-id uint))
    (let
        ((current-progress (default-to 
            { completed-workouts: u0, last-workout: u0, achievements: (list) }
            (map-get? user-progress { user: tx-sender, program-id: program-id }))))
        (ok (map-set user-progress 
            { user: tx-sender, program-id: program-id }
            {
                completed-workouts: (+ (get completed-workouts current-progress) u1),
                last-workout: block-height,
                achievements: (get achievements current-progress)
            }))
    )
)

;; Read-only functions

(define-read-only (get-program (program-id uint))
    (ok (map-get? programs program-id))
)

(define-read-only (get-user-progress (user principal) (program-id uint))
    (ok (map-get? user-progress { user: user, program-id: program-id }))
)

(define-read-only (is-trainer (address principal))
    (default-to false (map-get? trainers address))
)