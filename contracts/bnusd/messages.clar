
;; title: bnusd-messages
;; version:
;; summary:
;; description:

;; traits
;;

;; token definitions
;;

;; constants
(define-constant CROSS_TRANSFER "xCrossTransfer")
(define-constant CROSS_TRANSFER_REVERT "xCrossTransferRevert")
;;

;; data vars
;;

;; data maps
;; Define the XCrossTransfer map
(define-map XCrossTransfer uint
  { from: (string-ascii 20),
    to: (string-ascii 20),
    value: uint,
    data: (buff 1024) }
)

;; Define the XCrossTransferRevert map
(define-map XCrossTransferRevert uint
  { to: (string-ascii 20),
    value: uint }
)
;;

;; public functions
;;

;; read only functions
;;

;; private functions
;;

