(impl-trait 'SP3FBR2AGK5H9QBDH3EEN6DF8EK8JY7RX8QJ5SVTE.xcall-manager-trait.xcall-manager-trait)
;; title: xcall-manager
;; version:
;; summary: XCall Manager contract for managing cross-chain communication protocols
;; description: Manages the configuration of cross-chain communication using XCall.

;; traits
(define-trait xcall-manager-trait
  (
    (get-protocols () (response (tuple (sources (list 100 (string-ascii 200))) (destinations (list 100 (string-ascii 200)))) uint))
    (verify-protocols ((protocols (list 100 (string-ascii 200)))) (response bool uint))
  )
)
(use-trait xcall-manager-trait .xcall-manager-trait.xcall-manager-trait)
(use-trait rlp-encode-trait .rlp-encode.rlp-encode-trait)
(use-trait rlp-decode-trait .rlp-decode.rlp-decode-trait)
;;

;; token definitions
;;

;; constants
(define-constant ERR_ONLY_ADMIN (err u100))
(define-constant ERR_ONLY_CALL_SERVICE (err u101))
(define-constant ERR_UNKNOWN_MESSAGE_TYPE (err u102))
(define-constant ERR_PROTOCOL_MISMATCH (err u103))
(define-constant ERR_NO_PROPOSAL (err u104))
(define-constant ERR_EXECUTION_FAILED (err u105))
;;

;; data vars
(define-data-var xcall principal tx-sender)
(define-data-var admin principal tx-sender)
(define-data-var icon-governance (string-ascii 256) "")
(define-data-var proposed-protocol-to-remove (string-ascii 256) "")
(define-data-var sources (list 100 (string-ascii 256)) (list))
(define-data-var destinations (list 100 (string-ascii 256)) (list))
;;

;; data maps
;;

;; public functions
(define-public (initialize (xcall principal) (icon-governance-address (string-ascii 256)) (admin-address principal) (initial-sources (list 100 (string-ascii 256))) (initial-destinations (list 100 (string-ascii 256))))
  (begin
    (var-set xcall xcall)
    (var-set icon-governance icon-governance-address)
    (var-set admin admin-address)
    (var-set sources initial-sources)
    (var-set destinations initial-destinations)
    (ok true)
  )
)

(define-public (propose-removal (protocol (string-ascii 256)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) ERR_ONLY_ADMIN)
    (var-set proposed-protocol-to-remove protocol)
    (ok true)
  )
)

(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) ERR_ONLY_ADMIN)
    (var-set admin new-admin)
    (ok true)
  )
)

(define-public (set-protocols (new-sources (list 100 (string-ascii 256))) (new-destinations (list 100 (string-ascii 256))))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) ERR_ONLY_ADMIN)
    (var-set sources new-sources)
    (var-set destinations new-destinations)
    (ok true)
  )
)

(define-public (handle-call-message (from (string-ascii 256)) (data (buff 1024)) (protocols (list 100 (string-ascii 256))))
  (begin
    (asserts! (is-eq contract-caller (var-get xcall)) ERR_ONLY_CALL_SERVICE)
    (asserts! (is-eq from (var-get icon-governance)) ERR_PROTOCOL_MISMATCH)

    (let ((method (get-method data)))
      (if (and (not (verify-protocols-unordered protocols (var-get sources))) (is-eq method "ConfigureProtocols"))
          (begin
            (verify-protocol-recovery protocols)
            (if (is-eq method "Execute")
                (execute-message (decode-execute data))
                (if (is-eq method "ConfigureProtocols")
                    (configure-protocols (decode-configure-protocols data))
                    ERR_UNKNOWN_MESSAGE_TYPE
                )
            )
          )
          (ok true)
      )
    )
  )
)
;;

;; read only functions
(define-read-only (get-protocols)
  (ok {sources: (var-get sources), destinations: (var-get destinations)})
)

(define-read-only (verify-protocols (protocols (list 100 (string-ascii 256))))
  (ok (verify-protocols-unordered protocols (var-get sources)))
)
;;

;; private functions
(define-private (get-method (data (buff 1024)))
  (get method (decode-message data))
)

(define-private (decode-message (data (buff 1024)))
  (let ((decoded (decode-rlp data)))
    (ok (tuple (method (get 0 decoded))))
  )
)

(define-private (decode-execute (data (buff 1024)))
  (let ((decoded (decode-rlp data)))
    (ok (tuple
          (contract-address (get 1 decoded))
          (data (get 2 decoded))
        ))
  )
)

(define-private (decode-configure-protocols (data (buff 1024)))
  (let ((decoded (decode-rlp data)))
    (ok (tuple
          (sources (get 1 decoded))
          (destinations (get 2 decoded))
        ))
  )
)

(define-private (execute-message (message (tuple (contract-address principal) (data (buff 1024)))))
  (let ((result (contract-call? (get contract-address message) (get data message))))
    (unwrap! result ERR_EXECUTION_FAILED)
  )
)

(define-private (configure-protocols (message (tuple (sources (list 100 (string-ascii 256))) (destinations (list 100 (string-ascii 256))))))
  (begin
    (var-set sources (get sources message))
    (var-set destinations (get destinations message))
    (ok true)
  )
)

(define-private (verify-protocol-recovery (protocols (list 100 (string-ascii 256))))
  (let ((modified-sources (get-modified-protocols)))
    (asserts! (verify-protocols-unordered modified-sources protocols) ERR_PROTOCOL_MISMATCH)
    (ok true)
  )
)

(define-private (get-modified-protocols)
  (let ((protocol-to-remove (var-get proposed-protocol-to-remove)))
    (asserts! (> (len protocol-to-remove) u0) ERR_NO_PROPOSAL)
    (filter (var-get sources) (lambda (protocol) (not (is-eq protocol protocol-to-remove))))
  )
)

(define-private (verify-protocols-unordered (array1 (list 100 (string-ascii 256))) (array2 (list 100 (string-ascii 256))))
  (and (is-eq (len array1) (len array2))
       (fold (lambda (protocol1 acc1)
               (fold (lambda (protocol2 acc2)
                       (or (is-eq protocol1 protocol2) acc2))
                     array2
                     acc1))
             array1
             true))
)
;;
