
;; title: messages
;; version:
;; summary:
;; description:

;; traits
;;

;; token definitions
;;

;; constants
;;

;; data vars
;;

;; data maps
(define-map execute-messages { contract-address: principal, data: (buff 1024) })
(define-map configure-protocols-messages { sources: (list 100 (string-ascii 256)), destinations: (list 100 (string-ascii 256)) })
;;

;; public functions
;;

;; read only functions
;;

;; private functions
;;

