# 🧾 Detailed Tutorial: Understanding and Using `InvoiceSpec.hs`

This tutorial explains the `InvoiceSpec.hs` test file, covering its imports, helper functions, test structure, and how it verifies the correctness of the `Invoice` smart contract’s datum, redeemer, validator hash, and address generation logic.

---

## 📚 Table of Contents

1. [📦 Imports Explanation](#1-imports-explanation)
2. [🔧 Key Functionalities Explained](#2-key-functionalities-explained)
3. [🧪 Test Structure](#3-test-structure)
4. [➕ Extending Tests](#4-extending-tests)
5. [✅ Best Practices](#5-best-practices)
6. [📘 Glossary of Terms](#6-glossary-of-terms)

---

## 1. 📦 Imports Explanation

### Testing Libraries

* **Test.Tasty**

  * Provides structured grouping of tests with `testGroup`.

* **Test.Tasty.HUnit**

  * Used for unit-style assertions with:

    * `testCase`
    * `assertFailure`
    * `@?=`
    * `assertBool`

---

### Contract Module

* **Invoice**

  * Imports the pieces being tested:

    * `Investor`
    * `InvoiceDatum`
    * `InvoiceAction`
    * `notFunded`
    * `validator`
    * `plutusValidatorHash`
    * `toBech32ScriptAddress`

This is the main smart contract module under test.

---

### Utility and Encoding Libraries

* **Data.ByteString.Base16**

  * Decodes hex strings into raw bytes.

* **Data.ByteString.Char8**

  * Handles byte strings as ASCII-style character data.

* **PlutusTx**

  * Used for `toBuiltinData` / `fromBuiltinData` round-trip checks.

* **PlutusTx.Builtins.Class**

  * Converts decoded byte arrays into Plutus-compatible built-in bytes.

---

### Ledger and Cardano Types

* **Plutus.V2.Ledger.Api**

  * Provides `PubKeyHash` and other on-chain types.

* **Plutus.V1.Ledger.Value**

  * Used for `CurrencySymbol`, `TokenName`, and `AssetClass`.

* **Cardano.Api**

  * Used for generating mainnet and testnet Bech32 script addresses.

---

## 2. 🔧 Key Functionalities Explained

### `decodeHexBS`

This helper converts a hex string into a Plutus-compatible `BuiltinByteString`.

**Purpose:**

* To construct realistic `PubKeyHash`, `CurrencySymbol`, and `TokenName` values for tests.

---

### `mkPkh`

Creates a `PubKeyHash` from a hex string.

```haskell
mkPkh :: String -> IO PlutusV2.PubKeyHash
```

**Why it matters:**
The validator uses `PubKeyHash` values for issuers and investors, so tests need a reliable way to construct them.

---

### `mkCurrencySymbol`, `mkTokenName`, `mkAssetClass`

These helpers create token identifiers used inside the `InvoiceDatum`.

**Why they matter:**
The contract stores an `AssetClass` in `idInvoiceNFT`, so tests must be able to build one correctly.

---

### `mkSampleInvoiceDatum`

Builds a funded invoice datum with:

* one issuer
* one investor
* a face value
* a repayment value
* `isRepaid = False`

This datum is useful for testing repayment-related behavior and serialization round trips.

---

### `mkUnfundedInvoiceDatum`

Builds an invoice datum with:

* no investors
* `isRepaid = False`

This datum is useful for testing funding-related logic such as `notFunded`.

---

### `assertInvestorEq`

Compares two `Investor` values field by field.

**Why it matters:**
Custom on-chain types are better compared explicitly instead of relying only on generic equality during debugging.

---

### `assertInvoiceDatumEq`

Compares two `InvoiceDatum` values field by field.

Checks:

* issuer
* invoice NFT
* face value
* repayment
* repayment status
* investors list

**Why it matters:**
This ensures serialization/deserialization did not corrupt any part of the datum.

---

## 3. 🧪 Test Structure

### Test Group Declaration

```haskell
tests :: TestTree
tests = testGroup "Invoice Validator Tests"
```

This groups all Invoice-related tests together into one suite.

---

### Test: `notFunded returns True for unfunded invoice`

**Purpose:**
Checks that the helper function:

```haskell
notFunded :: InvoiceDatum -> Bool
```

returns `True` when `idInvestors = []`.

**Why it matters:**
This is one of the core conditions used when validating `FundInvoice`.

---

### Test: `notFunded returns False for funded invoice`

**Purpose:**
Confirms that once an investor is present in `idInvestors`, the invoice is no longer considered unfunded.

**Why it matters:**
Prevents double-funding logic from being bypassed.

---

### Test: `InvoiceDatum BuiltinData round-trip test`

**Workflow:**

1. Build a valid `InvoiceDatum`
2. Convert it to `BuiltinData` using:

```haskell
PlutusTx.toBuiltinData
```

3. Decode it back using:

```haskell
PlutusTx.fromBuiltinData
```

4. Compare the result with the original

**Why it matters:**
This ensures the datum type is stable and serializes correctly for on-chain use.

---

### Test: `InvoiceAction FundInvoice round-trip test`

Checks that the redeemer constructor:

```haskell
FundInvoice
```

round-trips safely through `BuiltinData`.

---

### Test: `InvoiceAction RepayInvoice round-trip test`

Checks that:

```haskell
RepayInvoice
```

also round-trips correctly.

**Why it matters:**
Redeemers must serialize exactly as expected for the validator to decode them on-chain.

---

### Test: `Validator hash is deterministic`

Verifies that hashing the compiled validator twice gives the same result.

```haskell
let h1 = plutusValidatorHash validator
    h2 = plutusValidatorHash validator
in h1 @?= h2
```

**Why it matters:**
A validator hash must be stable and deterministic, otherwise the script address would not be reliable.

---

### Test: `Testnet script address is Bech32 addr_test...`

Generates the testnet script address and checks that it starts with the correct prefix.

**Why it matters:**
Confirms that the helper:

```haskell
toBech32ScriptAddress
```

produces a valid-looking testnet address.

---

### Test: `Mainnet script address is Bech32 addr1...`

Generates the mainnet version of the same script address and verifies the prefix.

**Why it matters:**
Shows the validator can be rendered correctly on both testnet and mainnet.

---

## 4. ➕ Extending Tests

Here are useful next tests to add for stronger coverage.

---

### Funding Logic Tests

You can add tests for:

* invoice already funded
* invoice already repaid
* missing issuer payment
* missing investor signature
* missing NFT continuation

These would require building mocked `ScriptContext` values.

---

### Repayment Logic Tests

You can extend coverage to:

* repaying with no investor
* repaying an already repaid invoice
* insufficient repayment amount
* investor not receiving full principal + profit

These are especially important for financial correctness.

---

### Datum State Machine Tests

Suggested state transition tests:

* `minted -> funded`
* `funded -> repaid`
* repaid invoice cannot return to minted/funded state

These help verify that the invoice lifecycle is consistent.

---

### Invalid Data Tests

Useful extra cases:

```haskell
testCase "Invalid InvoiceDatum decode fails" ...
```

Examples:

* malformed `PubKeyHash`
* missing investors field
* wrong redeemer shape

---

## 5. ✅ Best Practices

* Use explicit helper constructors for test data
* Compare fields one by one for custom data types
* Test both funded and unfunded states
* Test serialization round trips whenever datum/redeemer shapes change
* Add validator-context tests when business logic becomes more complex
* Keep test names descriptive and tied to specific contract rules

---

## 6. 📘 Glossary of Terms

| Term                         | Definition                                                                 |
| ---------------------------- | -------------------------------------------------------------------------- |
| **InvoiceDatum**             | The on-chain state of an invoice financing contract                        |
| **Investor**                 | The participant who funds the invoice                                      |
| **Redeemer**                 | The action supplied to the validator, e.g. `FundInvoice` or `RepayInvoice` |
| **BuiltinData**              | Raw serialized Plutus-compatible data                                      |
| **Round-trip Serialization** | Encoding and decoding data to confirm it remains unchanged                 |
| **Validator Hash**           | The cryptographic hash of the compiled validator script                    |
| **Bech32 Address**           | Human-readable Cardano address format                                      |
| **AssetClass**               | Pair of `CurrencySymbol` and `TokenName` identifying a token               |
| **PubKeyHash**               | Hash of a wallet public key used for authorization                         |
| **Testnet**                  | Cardano testing network                                                    |
| **Mainnet**                  | Live Cardano network                                                       |

---

## ✅ Final Understanding

`InvoiceSpec.hs` is a foundational test suite for the Invoice validator. It confirms that:

* datum helper logic works
* datum and redeemer serialization is correct
* validator hashing is deterministic
* script address generation is valid

This gives you confidence that the contract’s structure is sound before moving on to more advanced validator execution tests.
