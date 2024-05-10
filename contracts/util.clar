(define-constant HEX "0123456789abcdef")
(define-constant C32 "0123456789ABCDEFGHJKMNPQRSTVWXYZ")
(define-constant LOWERCASE "abcdefghijklmnopqrstuvwxyz")
(define-constant UPPERCASE "ABCDEFGHIJKLMNOPQRSTUVWXYZ")

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
    (address-buff (unwrap-panic (to-consensus-buff? address)))
    (address-sliced-buff (unwrap-panic (slice? address-buff u5 (len address-buff))))
    (has-period (is-some (index-of address ".")))
  )
    (if has-period
      (let (
        (parts (unwrap-panic (slice? address (unwrap-panic (index-of? address ".")) (len address))))
        (address-part (unwrap-panic (element-at parts u0)))
        (contract-name-part (unwrap-panic (element-at parts u1)))
        (address-hash160 (hash160 (unwrap-panic (to-consensus-buff? address-part))))
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
        (address-sliced-buff-hash (hash160 address-sliced-buff))
        (address-principal-buff (concat 0x051a address-sliced-buff-hash))
        (address-normal-principal (unwrap-panic (from-consensus-buff? principal address-principal-buff)))
      )
        address-normal-principal
      )
    )
  )
)


(define-private (from-c32-aux (char (string-ascii 1)) (result uint))
  (let (
    (c32-symbols "0123456789ABCDEFGHJKMNPQRSTVWXYZ")
    (symbol-index (index-of c32-symbols char))
  )
    (if (is-none symbol-index)
      u0 ;; Return 0 if the character is not found
      (+ (* result u32) (unwrap-panic symbol-index))
    )
  )
)

(define-read-only (from-c32 (c32-string (string-ascii 128)))
  (let (
    (result u0)
  )
    (fold from-c32-aux c32-string result) ;; TODO: Replace with bit shifting because multiplying by 32 causes overflow
  )
)

(define-read-only (c32-decode (c32-string (string-ascii 128)))
  (let (
    (c32-length (len c32-string))
    (decoded-length (- c32-length u1))
    (decoded-string (unwrap! (slice? c32-string u0 decoded-length) (err false)))
    (checksum-string (unwrap! (slice? c32-string decoded-length c32-length) (err false)))
    (decoded-result (from-c32 decoded-string))
  )
    (let (
      (checksum (from-c32 checksum-string))
      (version (mod checksum u31))
      (bytes-len (/ (- decoded-result (* version (pow u2 u20))) u256))
      (data-bytes (mod decoded-result (pow u2 (- (* u8 bytes-len) u5))))
      (computed-checksum (mod (/ decoded-result (pow u2 (- (* u8 bytes-len) u5))) u31))
    )
      (if (is-eq checksum computed-checksum)
        (ok {version: version, data: data-bytes, checksum: checksum})
        (err false)
      )
    )
  )
)


(define-private (to-upper-char (char (string-ascii 1)) (result (string-ascii 128)))
  (let ((index (index-of LOWERCASE char)))
    (if (is-some index)
      (unwrap-panic (as-max-len? (concat result (unwrap-panic (element-at UPPERCASE (unwrap-panic index)))) u128))
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