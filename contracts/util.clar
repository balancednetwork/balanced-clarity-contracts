(define-constant HEXSET "0123456789abcdef")
(define-constant CHARSET "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")
(define-constant C32SET "0123456789ABCDEFGHJKMNPQRSTVWXYZ")
(define-constant LOWERCASESET "abcdefghijklmnopqrstuvwxyz")
(define-constant UPPERCASESET "ABCDEFGHIJKLMNOPQRSTUVWXYZ")

(define-read-only (address-string-to-principal (address (string-ascii 128)))
  ;; Convert the address from type string to type principal
  ;; according to the Clarity value representation specification:
  ;; https://github.com/stacksgov/sips/blob/main/sips/sip-005/sip-005-blocks-and-transactions.md#clarity-value-representation
  ;;
  ;; Each value representation is comprised of a 1-byte type ID and a variable-length serialized payload.
  ;; The type ID for an ASCII string is 0x0d, standard principal is 0x05, and contract principal is 0x06.
  ;;
  ;; The Clarity value encoding for a string is:
  ;; [type ID (1 byte - 0x0d)] [length (4 bytes)] [ASCII-encoded string]
  ;;
  ;; The Clarity value encoding for a standard principal is:
  ;; [type ID (1 byte - 0x05)] [version (1 byte - 0x1a)] [hash160 (20 bytes)]
  ;;
  ;; The Clarity value encoding for a contract principal is:
  ;; [type ID (1 byte - 0x06)] [version (1 byte - 0x1a)] [hash160 (20 bytes)] [contract name length (1 byte)] [contract name (up to 128 bytes)]
  ;;
  ;; To convert a string to a principal:
  ;; 1. Convert the string to a consensus buffer
  ;; 2. Slice the buffer to remove the length prefix
  ;; 3. Check if the input string contains a period (.)
  ;; 4. If the string contains a period (contract principal):
  ;;    - Split the string into the address part and the contract name part
  ;;    - c32decode the address part 
  ;;    - Compute the hash160 of the c32decode
  ;;    - Concatenate the principal type byte (0x06), version byte (0x1a), hash160, contract name length, and contract name
  ;; 5. If the string doesn't contain a period (standard principal):
  ;;    - c32decode the entire sliced buffer
  ;;    - Compute the hash160 of the c32decode
  ;;    - Concatenate the principal type byte (0x05), version byte (0x1a), and the hash160
  ;; 6. Convert the resulting buffer to a principal using from-consensus-buff?
  (let (
    (has-period (is-some (index-of address ".")))
  )
    (if has-period
      (let (
        (parts (unwrap-panic (slice? address (unwrap-panic (index-of? address ".")) (len address))))
        (address-part (unwrap-panic (element-at parts u0)))
        (contract-name-part (unwrap-panic (element-at parts u1)))
        (decoded-result (c32-decode address-part))
        (address-hash160 (hash160 (unwrap-panic (to-consensus-buff? (get data (unwrap-panic decoded-result))))))
        (contract-name-len (len contract-name-part))
        (contract-name (unwrap-panic (as-max-len? (unwrap-panic (to-consensus-buff? contract-name-part)) u128)))
        (address-principal-buff (concat 0x061a address-hash160))
        (address-principal-buff2 (concat address-principal-buff (unwrap-panic (slice? (unwrap-panic (to-consensus-buff? contract-name-len)) u3 u7))))
        (address-principal-buff3 (concat address-principal-buff2 contract-name))
        (address-contract-principal (unwrap-panic (from-consensus-buff? principal address-principal-buff3)))
      )
        address-contract-principal
      )
      (let (
        (decoded-result (decode-c32 address))
        (address-sliced-buff-hash (hash160 (unwrap-panic (to-consensus-buff? (get result (unwrap-panic decoded-result))))))
        (address-principal-buff (concat 0x051a address-sliced-buff-hash))
        (address-normal-principal (unwrap-panic (from-consensus-buff? principal address-principal-buff)))
      )
        address-normal-principal
      )
    )
  )
)

(define-private (from-c32-aux (char (string-ascii 1)) (res {result: uint, carry: uint, carry-bits: uint}))
  (let (
    (symbol-index (index-of C32SET char))
  )
    (if (is-none symbol-index)
      res
      (let (
        (carry (bit-or (bit-shift-left (get carry res) u5) (unwrap-panic symbol-index)))
        (carry-bits (+ (get carry-bits res) u5))
      )
        (if (>= carry-bits u8)
          (let (
            (new-carry-bits (- carry-bits u8))
            (new-carry (bit-and carry (- (bit-shift-left u1 new-carry-bits) u1)))
            (result (+ (get result res) (bit-shift-right carry (- carry-bits u8))))
          )
            {result: result, carry: new-carry, carry-bits: new-carry-bits}
          )
          (let (
            (result (+ (get result res) (bit-shift-left carry (- u8 carry-bits))))
          )
            {result: result, carry: carry, carry-bits: carry-bits}
          )
        )
      )
    )
  )
)

(define-private (from-c32 (c32-string (string-ascii 128)))
  (get result (fold from-c32-aux c32-string {result: u0, carry: u0, carry-bits: u0}))
)

(define-read-only (c32-decode (c32-string (string-ascii 128)))
  (let (
    (normalized-input (c32-normalize c32-string))
    (version-char (unwrap-panic (element-at normalized-input u0)))
    (version (unwrap-panic (index-of C32SET version-char)))
    (data-string (unwrap-panic (as-max-len? (unwrap-panic (slice? normalized-input u1 (- (len normalized-input) u1))) u128)))
    (decoded-data (from-c32 data-string))
    (checksum (unwrap-panic (index-of C32SET (unwrap-panic (element-at normalized-input (- (len normalized-input) u1))))))
  )
    (let (
      (version-hex (if (< version u16)
        version
        (bit-and version u255)
      ))
      (data-bytes decoded-data)
      (computed-checksum (unwrap-panic (index-of C32SET (unwrap-panic (element-at normalized-input (- (len normalized-input) u1))))))
    )
    ;;   (if (and (is-eq version (bit-and checksum u31)) (is-eq checksum computed-checksum))
        (ok {version: version, data: data-bytes, checksum: checksum})
        ;; (err false)
    ;;   )
    )
  )
)


(define-private (to-upper-char (char (string-ascii 1)) (result (string-ascii 128)))
  (let ((index (index-of LOWERCASESET char)))
    (if (is-some index)
      (unwrap-panic (as-max-len? (concat result (unwrap-panic (element-at UPPERCASESET (unwrap-panic index)))) u128))
      (unwrap-panic (as-max-len? (concat result char) u128))
    )
  )
)

(define-private (to-upper (input (string-ascii 128)))
  (fold to-upper-char input "")
)

(define-private (replace-char (char (string-ascii 1)) (result (string-ascii 128)) (old-char (string-ascii 1)) (new-char (string-ascii 1)))
  (if (is-eq char old-char)
    (unwrap-panic (as-max-len? (concat result new-char) u128))
    (unwrap-panic (as-max-len? (concat result char) u128))
  )
)

(define-private (replace-all-aux (char (string-ascii 1)) (result (string-ascii 128)))
  (let (
    (old-char "O")
    (new-char "0")
  )
    (replace-char char result old-char new-char)
  )
)

(define-private (replace-all (input (string-ascii 128)) (old-char (string-ascii 1)) (new-char (string-ascii 1)))
  (fold replace-all-aux input "")
)

(define-private (c32-normalize (input (string-ascii 128)))
  (let (
    (uppercase-input (to-upper input))
    (normalized-input (replace-all uppercase-input "O" "0"))
    (normalized-input2 (replace-all normalized-input "L" "1"))
    (normalized-input3 (replace-all normalized-input2 "I" "1"))
  )
    normalized-input3
  )
)


(define-private (folder (input (string-ascii 1)) (res {bit-buff: uint, bits-remaining: uint, result: (string-ascii 128)}))
  (let (
    (alphabet "0123456789ABCDEFGHJKMNPQRSTVWXYZ")
    (index (unwrap-panic (index-of? alphabet input)))
    (bit-buff (bit-or (bit-shift-left (get bit-buff res) u5) index))
    (bits-remaining (+ (get bits-remaining res) u5))
  )
    (if (>= bits-remaining u8)
      (let (
        (char (unwrap-panic (element-at alphabet (bit-and (bit-shift-right bit-buff (- bits-remaining u8)) u31))))
        (bits-remaining1 (- bits-remaining u8))
        (bit-buff1 (bit-and bit-buff (- (bit-shift-left u1 bits-remaining1) u1)))
        (result1 (unwrap-panic (as-max-len? (concat (get result res) char) u128)))
      )
        (tuple (bit-buff bit-buff1) (bits-remaining bits-remaining1) (result result1))
      )
      (tuple (bit-buff bit-buff) (bits-remaining bits-remaining) (result (get result res)))
    )
  )
)

(define-read-only (decode-c32 (c32-string (string-ascii 128)))
  (let (
    (folded (fold folder (unwrap-panic (as-max-len? (unwrap-panic (slice? c32-string u1 (- (len c32-string) u1))) u128)) (tuple (bit-buff u0) (bits-remaining u0) (result ""))))
    (version (unwrap-panic (index-of? "0123456789ABCDEFGHJKMNPQRSTVWXYZ" (unwrap-panic (element-at c32-string u0)))))
  )
    (ok (merge folded {version: version}))
  )
)
