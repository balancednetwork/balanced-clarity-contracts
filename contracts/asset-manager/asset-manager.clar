;; title: asset-manager
;; version:
;; summary:
;; description:

;; traits
(use-trait ft-trait .sip-010-trait.sip-010-trait)
(impl-trait .call-service-receiver-trait.call-service-receiver-trait)
;;

;; token definitions
;;

;; constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ICON_ASSET_MANAGER "0x1.icon/cxabea09a8c5f3efa54d0a0370b14715e6f2270591")
(define-constant X_CALL_NETWORK_ADDRESS "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.x-call")
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_INVALID_AMOUNT (err u101))
(define-constant ERR_EXCEED_WITHDRAW_LIMIT (err u102))
(define-constant ERR_INVALID_TOKEN (err u103))
(define-constant ERR_INVALID_MESSAGE (err u104))
(define-constant ERR_INVALID_MESSAGE_WITHDRAW_TO_NATIVE_UNSUPPORTED (err u105))
(define-constant POINTS u10000)
(define-constant NATIVE_TOKEN 'ST000000000000000000002AMW42H.nativetoken)
(define-constant SBTC_TOKEN 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtc)
;;

;; data vars
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

(define-public (handle-call-message (from (string-ascii 150)) (data (buff 1024)) (protocols (list 50 (string-ascii 150))))
  (let (
    (method-result (contract-call? .asset-manager-messages get-method data))
    (deposit-name (contract-call? .asset-manager-messages get-deposit-name))
    (deposit-revert-name (contract-call? .asset-manager-messages get-deposit-revert-name))
    (withdraw-to-name (contract-call? .asset-manager-messages get-withdraw-to-name))
    (withdraw-native-to-name (contract-call? .asset-manager-messages get-withdraw-native-to-name))
  )
    (asserts! (is-ok method-result) ERR_INVALID_MESSAGE)
    (let ((method (unwrap-panic method-result)))
      (if (is-eq method withdraw-to-name)
        (let ((message-result (contract-call? .asset-manager-messages decode-withdraw-to data)))
          (asserts! (is-ok message-result) ERR_INVALID_MESSAGE)
          (let ((message (unwrap-panic message-result)))
            (asserts! (is-eq from ICON_ASSET_MANAGER) ERR_UNAUTHORIZED)
            (let (
              (token-address-string (get token-address message))
              (to-address-string (get to message))
              (to-address-principal (address-string-to-principal (unwrap-panic (as-max-len? to-address-string u128))))
              (amount (get amount message))
            )
              (if (is-eq token-address-string "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.sbtc")
                  (withdraw .sbtc amount (unwrap-panic to-address-principal))
                  ;; (if (is-eq token-address "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.bnusd")
                  ;;     (withdraw 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.bnusd amount to-principal)
                  ;;     ERR_INVALID_TOKEN
                  ;; )
                  ERR_INVALID_TOKEN
              )
            )
          )
        )
        (if (is-eq method withdraw-native-to-name)
          ERR_INVALID_MESSAGE_WITHDRAW_TO_NATIVE_UNSUPPORTED
          (if (is-eq method deposit-revert-name)
            (let ((message-result (contract-call? .asset-manager-messages decode-deposit-revert data)))
              (asserts! (is-ok message-result) ERR_INVALID_MESSAGE)
              (let ((message (unwrap-panic message-result)))
                (asserts! (is-eq from X_CALL_NETWORK_ADDRESS) ERR_UNAUTHORIZED)
                (let (
                  (token-address (get token-address message))
                  (token-principal (unwrap-panic (principal-of? (unwrap-panic (as-max-len? (unwrap-panic (to-consensus-buff? token-address)) u33)))))
                  (to-address (get to message))
                  (to-principal (unwrap-panic (principal-of? (unwrap-panic (as-max-len? (unwrap-panic (to-consensus-buff? to-address)) u33)))))
                  (amount (get amount message))
                )
                  (withdraw .sbtc amount to-principal)
                )
              )
            )
            ERR_INVALID_MESSAGE
          )
        )
      )
    )
  )
)

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




;;;;;;;;; util.clar placed here because it isnt importing

(define-constant C32SET "0123456789ABCDEFGHJKMNPQRSTVWXYZ")

(define-constant ERR_INVALID_ADDRESS (err u1000))
(define-constant ERR_INVALID_CONTRACT_NAME (err u1001))

(define-data-var result-var (buff 400) 0x)
(define-data-var addr-var (buff 400) 0x)

(define-public (address-string-to-principal (address (string-ascii 128)))
  (let (
    (period-index (index-of address "."))
  )
    (if (is-some period-index)
      (let (
        (address-part (unwrap-panic (slice? address u0 (unwrap-panic period-index))))
        (contract-name-part (unwrap-panic (slice? address u42 (len address))))
      )
        (begin
          (asserts! (is-eq (unwrap-panic period-index) u41) ERR_INVALID_ADDRESS)
          (asserts! (is-valid-c32 address-part) ERR_INVALID_ADDRESS)
          (ok (unwrap-panic (c32-decode address-part (as-max-len? contract-name-part u40))))
        )
      )
      (begin
        (asserts! (is-eq (len address) u41) ERR_INVALID_ADDRESS)
        (asserts! (is-valid-c32 address) ERR_INVALID_ADDRESS)
        (ok (unwrap-panic (c32-decode address none)))
      )
    )
  )
)

(define-private (c32-decode-aux (input (string-ascii 1)) (res {bit-buff: uint, bits-remaining: uint}))
  (let ((index (unwrap-panic (index-of? C32SET input)))
        (bit-buff (bit-or (bit-shift-left (get bit-buff res) u5) index))
        (bits-remaining (+ (get bits-remaining res) u5)))
    (if (>= bits-remaining u8)
        (let ((char (to-buff (bit-and (bit-shift-right bit-buff (- bits-remaining u8)) u255)))
              (bits-remaining1 (- bits-remaining u8))
              (bit-buff1 (bit-and bit-buff (- (bit-shift-left u1 bits-remaining1) u1))))
          (set (unwrap-panic (as-max-len? (var-get addr-var) u399)) char)
          (tuple (bit-buff bit-buff1) (bits-remaining bits-remaining1)))
        (tuple (bit-buff bit-buff) (bits-remaining bits-remaining)))))

(define-private (c32-decode (address (string-ascii 128)) (contract-name (optional (string-ascii 40))))
  (begin
    (var-set addr-var 0x)
    (fold c32-decode-aux (unwrap-panic (slice? address u1 (- (len address) u5))) (tuple (bit-buff u0) (bits-remaining u0)))
    (let ((version (to-buff (unwrap-panic (index-of? C32SET (unwrap-panic (element-at? address u1))))))
          (pub-key-hash (unwrap-panic (slice? (var-get addr-var) u1 u21))))
      (if (is-some contract-name)
        (principal-construct? version (unwrap-panic (as-max-len? pub-key-hash u20)) (unwrap-panic contract-name))
        (principal-construct? version (unwrap-panic (as-max-len? pub-key-hash u20)))
      )
    )
  )
)

(define-private (set (address (buff 399)) (char (buff 1)))
  (var-set addr-var (concat address char)))

(define-private (to-buff (data uint))
  (begin
    (let ((encoded (unwrap-panic (to-consensus-buff? data))))
      (unwrap-panic (element-at? encoded (- (len encoded) u1))))))


(define-private (is-valid-c32 (address (string-ascii 128)))
  (fold is-c32-char address true))

(define-private (is-c32-char (char (string-ascii 1)) (valid bool))
  (and valid (is-some (index-of C32SET char))))