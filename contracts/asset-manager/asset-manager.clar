;; title: asset-manager
;; version:
;; summary:
;; description:

;; traits
(use-trait ft-trait .sip-010-trait.sip-010-trait)
;;

;; token definitions
;;

;; constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_INVALID_AMOUNT (err u101))
(define-constant ERR_EXCEED_WITHDRAW_LIMIT (err u102))
(define-constant POINTS u10000)
;;

;; data vars
(define-data-var x-call principal 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
(define-data-var icon-asset-manager (string-ascii 40) "")
(define-data-var x-call-manager principal 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
;;

;; data maps
(define-map period { token: principal } { period: uint })
(define-map percentage { token: principal } { percentage: uint })
(define-map last-update { token: principal } { last-update: uint })
(define-map current-limit { token: principal } { current-limit: uint })
;;

;; public functions
(define-public (configure-rate-limit (token <ft-trait>) (new-period uint) (new-percentage uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (<= new-percentage POINTS) ERR_INVALID_AMOUNT)
    (map-set period { token: (contract-of token) } { period: new-period })
    (map-set percentage { token: (contract-of token) } { percentage: new-percentage })
    (map-set last-update { token: (contract-of token) } { last-update: block-height })
    (let ((balance (unwrap! (get-balance token) ERR_INVALID_AMOUNT)))
      (map-set current-limit { token: (contract-of token) } { current-limit: (/ (* balance new-percentage) POINTS) }))
    (ok true)
  )
)

(define-public (reset-limit (token <ft-trait>))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (let ((balance (unwrap-panic (get-balance token))))
      (map-set current-limit { token: (contract-of token) } { current-limit: (/ (* balance (get-percentage token )) POINTS) }))
    (ok true)
  )
)

(define-public (deposit (token <ft-trait>) (amount uint))
  (begin
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (try! (contract-call? token transfer amount tx-sender (as-contract tx-sender) none))
    ;; TODO: Send deposit message to ICON network
    (ok true)
  )
)

(define-public (withdraw (token <ft-trait>) (amount uint) (recipient principal))
  (begin
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (let ((result (verify-withdraw token amount)))
      (if (is-ok result)
          (begin
            (try! (contract-call? token transfer amount (as-contract tx-sender) recipient none))
            (ok true)
          )
          (unwrap-err! result ERR_EXCEED_WITHDRAW_LIMIT) ;; is this throwing the right error?
      )
    )
  )
)
;;

;; read only functions
(define-read-only (get-current-limit (token <ft-trait>))
  (get current-limit (unwrap-panic (map-get? current-limit { token: (contract-of token) })))
)

(define-read-only (get-period (token <ft-trait>))
  (let ((period-tuple (map-get? period { token: (contract-of token) })))
    (if (is-some period-tuple)
        (get period (unwrap-panic period-tuple))
        u0
    )
  )
)

(define-read-only (get-percentage (token <ft-trait>))
  (let ((percentage-tuple (map-get? percentage { token: (contract-of token) })))
    (if (is-some percentage-tuple)
        (get percentage (unwrap-panic percentage-tuple))
        u0
    )
  )
)
;;

;; private functions
(define-private (get-balance (token <ft-trait>))
  (if (is-eq (contract-of token) 'ST000000000000000000002AMW42H.nativetoken)
      (ok (stx-get-balance (as-contract tx-sender)))
      (ok (unwrap! (contract-call? token get-balance (as-contract tx-sender)) ERR_INVALID_AMOUNT))
  )
)

(define-private (verify-withdraw (token <ft-trait>) (amount uint))
  (let ((balance (unwrap-panic (get-balance token))))
    (let ((limit (calculate-limit balance token)))
      (if (>= (- balance amount) limit)
          (begin
            (map-set current-limit { token: (contract-of token) } { current-limit: limit })
            (map-set last-update { token: (contract-of token) } { last-update: block-height })
            (ok true)
          )
          (err ERR_EXCEED_WITHDRAW_LIMIT)
      )
    )
  )
)

(define-private (calculate-limit (balance uint) (token <ft-trait>))
  (let ((token-period (get-period token)))
    (let ((token-percentage (get-percentage token)))
      (let ((max-limit (/ (* balance token-percentage) POINTS)))
        (let ((max-withdraw (- balance max-limit)))
              (let ((time-diff (- block-height (get last-update (unwrap-panic (map-get? last-update { token: (contract-of token) }))))))
                (let ((capped-time-diff (if (< time-diff token-period) time-diff token-period)))
                  (let ((added-allowed-withdrawal (/ (* max-withdraw capped-time-diff) token-period)))
                    (let ((limit (+ (get current-limit (unwrap-panic (map-get? current-limit { token: (contract-of token) }))) added-allowed-withdrawal)))
                      (let ((capped-limit (if (< balance limit) balance limit)))
                        (if (> capped-limit max-limit) max-limit capped-limit)
                      )
                    )
                  )
                )
              )
            )
          )
      )
    )
  )
;;