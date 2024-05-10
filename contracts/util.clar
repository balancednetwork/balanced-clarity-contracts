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
  ;; [type ID (1 byte - 0x05)] [version (1 byte)] [hash160 (20 bytes)]
  ;;
  ;; The Clarity value encoding for a contract principal is:
  ;; [type ID (1 byte - 0x06)] [version (1 byte)] [hash160 (20 bytes)] [contract name length (1 byte)] [contract name (up to 128 bytes)]
  ;;
  ;; To convert a string to a principal:
  ;; 1. Convert the string to a consensus buffer
  ;; 2. Slice the buffer to remove the length prefix
  ;; 3. Check if the input string contains a period (.)
  ;; 4. If the string contains a period (contract principal):
  ;;    - Split the string into the address part and the contract name part
  ;;    - Compute the hash160 of the address part
  ;;    - Concatenate the principal type byte (0x06), version byte (0x00), hash160, contract name length, and contract name
  ;; 5. If the string doesn't contain a period (standard principal):
  ;;    - Compute the hash160 of the entire sliced buffer
  ;;    - Concatenate the principal type byte (0x05), version byte (0x00), and the hash160
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
        (address-principal-buff (concat 0x0600 address-hash160))
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