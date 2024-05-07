;; title: asset-manager
;; version:
;; summary:
;; description:

;; traits
(use-trait ft-trait .sip-010-trait.sip-010-trait)
;; (impl-trait .call-service-receiver-trait.call-service-receiver-trait)
;;

;; token definitions
;;

;; constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_INVALID_AMOUNT (err u101))
(define-constant ERR_EXCEED_WITHDRAW_LIMIT (err u102))
(define-constant POINTS u10000)
(define-constant NATIVE_TOKEN 'ST000000000000000000002AMW42H.nativetoken)
;;

;; data vars
(define-data-var x-call principal 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
(define-data-var icon-asset-manager (string-ascii 40) "")
(define-data-var x-call-manager principal 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
;;

;; data maps
(define-map limit-map principal {
  period: uint,
  percentage: uint,
  last-update: uint,
  current-limit: uint
})
;;

;; public functions
(define-public (configure-rate-limit (token <ft-trait>) (new-period uint) (new-percentage uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (<= new-percentage POINTS) ERR_INVALID_AMOUNT)
    (let ((balance (unwrap! (get-balance token) ERR_INVALID_AMOUNT)))
      (map-set limit-map (contract-of token) {
        period: new-period,
        percentage: new-percentage,
        last-update: block-height,
        current-limit: (/ (* balance new-percentage) POINTS)
      })
    )
    (ok true)
  )
)

(define-public (reset-limit (token <ft-trait>))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (let ((balance (unwrap-panic (get-balance token))))
      (let ((period-tuple (unwrap-panic (map-get? limit-map (contract-of token)))))
        (map-set limit-map (contract-of token) (merge period-tuple {
          current-limit: (/ (* balance (get percentage period-tuple)) POINTS)
        }))
      )
    )
    (ok true)
  )
)

(define-public (deposit-native (amount uint) )
  (begin
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    ;; TODO: Send deposit message to ICON network
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

;; (define-public (handle-call-message (from (string-ascii 150)) (data (buff 1024)) (protocols (list 50 (string-ascii 150))))
;;   (let ((method (contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.asset-manager-messages get-method data)))
;;     (if (is-eq method "withdraw-to")
;;         (let ((message (contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.asset-manager-messages decode-withdraw-to data)))
;;           (if (is-eq from ICON_ASSET_MANAGER)
;;               (let ((token (get token-address message))
;;                     (to (get to message))
;;                     (amount (get amount message)))
;;                 (withdraw token to amount)
;;               )
;;               (err ERR_UNAUTHORIZED)
;;           )
;;         )
;;         (if (is-eq method "withdraw-native-to")
;;             (err "Withdraw to native is currently not supported")
;;             (if (is-eq method "deposit-revert")
;;                 (let ((message (contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.asset-manager-messages decode-deposit-revert data)))
;;                   (if (is-eq from X_CALL_NETWORK_ADDRESS)
;;                       (let ((token (get token-address message))
;;                             (to (get to message))
;;                             (amount (get amount message)))
;;                         (withdraw token to amount)
;;                       )
;;                       (err ERR_UNAUTHORIZED)
;;                   )
;;                 )
;;                 (err "Unknown message type")
;;             )
;;         )
;;     )
;;   )
;; )

;;

;; read only functions
(define-read-only (get-current-limit (token <ft-trait>))
  (let ((period-tuple (unwrap-panic (map-get? limit-map (contract-of token)))))
    (get current-limit period-tuple)
  )
)

(define-read-only (get-period (token <ft-trait>))
  (let ((period-tuple (unwrap-panic (map-get? limit-map (contract-of token)))))
    (get period period-tuple)
  )
)

(define-read-only (get-percentage (token <ft-trait>))
  (let ((period-tuple (unwrap-panic (map-get? limit-map (contract-of token)))))
    (get percentage period-tuple)
  )
)
;;

;; private functions
(define-private (get-balance (token <ft-trait>))
  (if (is-eq (contract-of token) NATIVE_TOKEN)
      (ok (stx-get-balance (as-contract tx-sender)))
      (ok (unwrap! (contract-call? token get-balance (as-contract tx-sender)) ERR_INVALID_AMOUNT))
  )
)

(define-private (verify-withdraw (token <ft-trait>) (amount uint))
  (let ((balance (unwrap-panic (get-balance token))))
    (let ((limit (calculate-limit balance token)))
      (if (< amount limit)
          (begin
            (let ((period-tuple (unwrap-panic (map-get? limit-map (contract-of token)))))
              (map-set limit-map (contract-of token) (merge period-tuple {
                current-limit: (- limit amount),
                last-update: block-height
              }))
            )
            (ok true)
          )
          (err ERR_EXCEED_WITHDRAW_LIMIT)
      )
    )
  )
)

(define-private (calculate-limit (balance uint) (token <ft-trait>))
  (let ((period-tuple (unwrap-panic (map-get? limit-map (contract-of token)))))
    (let ((token-period (get period period-tuple)))
      (let ((token-percentage (get percentage period-tuple)))
        (let ((max-limit (/ (* balance token-percentage) POINTS)))
          (let ((max-withdraw (- balance max-limit)))
            (let ((time-diff (- block-height (get last-update period-tuple))))
              (let ((capped-time-diff (if (< time-diff token-period) time-diff token-period)))
                (let ((added-allowed-withdrawal (/ (* max-withdraw capped-time-diff) token-period)))
                  (let ((limit (+ (get current-limit period-tuple) added-allowed-withdrawal)))
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
)
;;