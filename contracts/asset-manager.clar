;; title: asset-manager
;; version:
;; summary:
;; description:

;; traits
(define-trait asset-manager-trait
  (
    (deposit (principal uint) (response bool uint))
    (vote-withdraw (principal uint) (response bool uint))
    (withdraw (principal uint) (response bool uint))
    (get-balance (principal) (response uint uint))
    (get-vote (principal) (response bool uint))
    (get-votes-threshold () (response uint uint))
  )
)

(use-trait xtrait .xtrait.xtrait)
(use-trait xcall-manager-trait .xcall-manager-trait.xcall-manager-trait)
;;

;; token definitions
;;

;; constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_INVALID_AMOUNT (err u101))
(define-constant ERR_INSUFFICIENT_BALANCE (err u102))
(define-constant ERR_INVALID_VOTE (err u103))
(define-constant ERR_VOTE_THRESHOLD_NOT_REACHED (err u104))
;;

;; data vars
(define-data-var votes-threshold uint u1)
;;

;; data maps
(define-map balances principal uint)
(define-map votes principal bool)
;;

;; public functions
(define-public (initialize (xCall <xtrait>) (icon-asset-manager <string-ascii>) (xCallManager <xcall-manager-trait>))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (ok true)
  )
)

(define-public (deposit (token <ft-trait>) (amount uint))
  (begin
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (unwrap! (transfer-tokens token amount tx-sender (as-contract tx-sender)) ERR_INSUFFICIENT_BALANCE)
    (map-set balances tx-sender (+ (default-to u0 (map-get? balances tx-sender)) amount))
    (ok true)
  )
)

(define-public (vote-withdraw (amount uint))
  (begin
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (asserts! (<= amount (default-to u0 (map-get? balances tx-sender))) ERR_INSUFFICIENT_BALANCE)
    (map-set votes tx-sender true)
    (ok true)
  )
)

(define-public (withdraw (token <ft-trait>) (amount uint))
  (begin
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (asserts! (<= amount (default-to u0 (map-get? balances tx-sender))) ERR_INSUFFICIENT_BALANCE)
    (asserts! (>= (len (filter (map-get? votes) (lambda (vote bool) vote))) (var-get votes-threshold)) ERR_VOTE_THRESHOLD_NOT_REACHED)
    (map-set balances tx-sender (- (default-to u0 (map-get? balances tx-sender)) amount))
    (unwrap! (transfer-tokens token amount (as-contract tx-sender) tx-sender) ERR_INSUFFICIENT_BALANCE)
    (map-delete votes tx-sender)
    (ok true)
  )
)

(define-public (set-votes-threshold (new-threshold uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (var-set votes-threshold new-threshold)
    (ok true)
  )
)
;;

;; read only functions
(define-read-only (get-balance (who principal))
  (default-to u0 (map-get? balances who))
)

(define-read-only (get-vote (who principal))
  (default-to false (map-get? votes who))
)

(define-read-only (get-votes-threshold)
  (var-get votes-threshold)
)
;;

;; private functions
;;

