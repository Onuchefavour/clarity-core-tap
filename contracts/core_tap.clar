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

;; Data Variables
(define-data-var next-program-id uint u0)
(define-data-var next-achievement-id uint u0)

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

(define-map achievements
    uint
    {
        name: (string-ascii 50),
        description: (string-utf8 200),
        program-id: uint,
        required-workouts: uint,
        nft-uri: (optional (string-utf8 256))
    }
)

(define-map user-achievements
    { user: principal, achievement-id: uint }
    {
        earned: bool,
        earned-at: (optional uint),
        nft-id: (optional uint)
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

;; Create new achievement 
(define-public (create-achievement
    (name (string-ascii 50))
    (description (string-utf8 200))
    (program-id uint)
    (required-workouts uint)
    (nft-uri (optional (string-utf8 256))))
    (let 
        ((achievement-id (var-get next-achievement-id)))
        (asserts! (is-some (map-get? programs program-id)) err-invalid-program)
        (asserts! (map-insert achievements achievement-id {
            name: name,
            description: description,
            program-id: program-id,
            required-workouts: required-workouts,
            nft-uri: nft-uri
        }) err-achievement-exists)
        (var-set next-achievement-id (+ achievement-id u1))
        (ok achievement-id)
    )
)

;; Record workout completion and check achievements
(define-public (record-workout (program-id uint))
    (let
        ((current-progress (default-to 
            { completed-workouts: u0, last-workout: u0, achievements: (list) }
            (map-get? user-progress { user: tx-sender, program-id: program-id }))))
        
        ;; Update progress
        (map-set user-progress 
            { user: tx-sender, program-id: program-id }
            {
                completed-workouts: (+ (get completed-workouts current-progress) u1),
                last-workout: block-height,
                achievements: (get achievements current-progress)
            })
        
        ;; Check for new achievements
        (ok (try! (check-achievements tx-sender program-id)))
    )
)

;; Check and award achievements
(define-private (check-achievements (user principal) (program-id uint))
    (let ((user-workouts (get completed-workouts 
            (unwrap-panic (map-get? user-progress { user: user, program-id: program-id })))))
        (fold check-single-achievement (list) (get-achievements-for-program program-id))
    )
)

;; Check single achievement
(define-private (check-single-achievement (achievement-id uint) (prior (response bool bool)))
    (let ((achievement (unwrap-panic (map-get? achievements achievement-id))))
        (if (and
                (is-eq (get program-id achievement) program-id)
                (>= user-workouts (get required-workouts achievement))
            )
            (award-achievement tx-sender achievement-id)
            prior
        )
    )
)

;; Award achievement
(define-private (award-achievement (user principal) (achievement-id uint))
    (let ((current-status (default-to 
            { earned: false, earned-at: none, nft-id: none }
            (map-get? user-achievements { user: user, achievement-id: achievement-id }))))
        (if (get earned current-status)
            (ok true)
            (begin
                (map-set user-achievements
                    { user: user, achievement-id: achievement-id }
                    {
                        earned: true,
                        earned-at: (some block-height),
                        nft-id: none  ;; NFT minting to be implemented
                    }
                )
                (ok true)
            )
        )
    )
)

;; Read-only functions

(define-read-only (get-program (program-id uint))
    (ok (map-get? programs program-id))
)

(define-read-only (get-user-progress (user principal) (program-id uint))
    (ok (map-get? user-progress { user: user, program-id: program-id }))
)

(define-read-only (get-achievement (achievement-id uint))
    (ok (map-get? achievements achievement-id))
)

(define-read-only (get-user-achievement-status (user principal) (achievement-id uint))
    (ok (map-get? user-achievements { user: user, achievement-id: achievement-id }))
)

(define-read-only (get-achievements-for-program (program-id uint))
    (filter get-achievement-for-program (unwrap-panic (get-achievement-ids)))
)

(define-read-only (is-trainer (address principal))
    (default-to false (map-get? trainers address))
)
