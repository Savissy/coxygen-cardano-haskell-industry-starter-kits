# 🧾 Detailed Tutorial: Understanding and Using `Invoice Document Minting Policy`

This tutorial explains the `Invoice Document Minting Policy` smart contract, covering its purpose, imports, minting rules, policy compilation, and practical usage in a tokenized invoice financing system on Cardano.

---

## 📚 Table of Contents

1. [📦 Imports Overview](#1-imports-overview)
2. [🗃️ Core Configuration](#2-core-configuration)
3. [🧠 Core Minting Policy Logic](#3-core-minting-policy-logic)
4. [⚙️ Policy Script Compilation](#4-policy-script-compilation)
5. [🔧 Helper Logic Inside the Policy](#5-helper-logic-inside-the-policy)
6. [🧪 Practical Usage Example](#6-practical-usage-example)
7. [🧷 Testing Strategy](#7-testing-strategy)
8. [✅ Best Practices](#8-best-practices)
9. [📘 Glossary of Terms](#9-glossary-of-terms)

---

## 1. 📦 Imports Overview

### Plutus API Modules

* **Plutus.V2.Ledger.Api**

  * Provides essential on-chain types such as:

    * `ScriptContext`
    * `TxInfo`
    * `CurrencySymbol`
    * `TokenName`
    * `MintingPolicy`
    * `Address`
    * `ValidatorHash`

* **Plutus.V2.Ledger.Contexts**

  * Supplies context-related helpers such as:

    * `ownCurrencySymbol`

### Value Utilities

* **Plutus.V1.Ledger.Value**

  * Used for token accounting and inspection:

    * `flattenValue`
    * `AssetClass`
    * `assetClassValueOf`

### Compilation and Prelude

* **PlutusTx**

  * Compiles Haskell code into Plutus Core.

* **PlutusTx.Prelude**

  * Safe on-chain functions such as:

    * `traceIfFalse`
    * `any`
    * `error`

### Serialization Utilities

* **Codec.Serialise**

  * Serializes the minting policy script.

* **ByteString / Base16**

  * Used for writing the CBOR hex representation of the policy to file.

---

## 2. 🗃️ Core Configuration

### `financingValidatorHash`

This value hardcodes the validator hash of the financing contract:

```haskell
financingValidatorHash :: ValidatorHash
```

### Purpose

The minting policy uses this hash to ensure that the newly minted invoice NFT is not sent anywhere arbitrarily. Instead, it must be locked at the invoice financing validator.

This creates a strong relationship between:

* the **minting policy**
* the **financing validator**
* the **invoice NFT**

### Why this matters

Without this check, someone could mint an invoice NFT and send it to their own wallet instead of the financing contract. That would break the intended workflow.

---

## 3. 🧠 Core Minting Policy Logic

### `mkDocPolicy`

This is the main minting policy function:

```haskell
mkDocPolicy :: ScriptContext -> Bool
```

It enforces three rules:

---

### 1. Exactly one invoice NFT must be minted

```haskell
traceIfFalse "must mint exactly one invoice NFT" singleMint
```

#### Meaning

The transaction must mint:

* exactly one token
* under this policy
* with quantity `1`

#### Why this matters

The invoice NFT is meant to represent a unique invoice document.
This prevents:

* minting multiple NFTs in one transaction
* minting fungible-style quantities
* accidental or malicious over-minting

---

### 2. The issuer must sign the transaction

```haskell
traceIfFalse "issuer must sign transaction" issuerSigned
```

#### Meaning

The transaction must contain exactly one signer.

```haskell
case txInfoSignatories info of
    [_] -> True
    _   -> False
```

#### Why this matters

This ensures an explicit signer authorized the minting transaction.

### Important note

This check enforces **exactly one signer**, not just “at least one signer.”
So if the transaction contains two or more signers, the policy will fail.

---

### 3. The NFT must be locked at the financing contract

```haskell
traceIfFalse "NFT not locked at financing contract" nftLocked
```

#### Meaning

Among the transaction outputs, there must be an output that:

* goes to the financing validator address
* contains the freshly minted NFT

This is checked by:

```haskell
outputHasNFT :: TxOut -> Bool
```

The output must satisfy:

* address uses `ScriptCredential`
* validator hash equals `financingValidatorHash`
* output contains exactly 1 of the newly minted NFT

#### Why this matters

This prevents minting the invoice NFT and sending it:

* to a normal wallet address
* to the wrong script
* to an unrelated marketplace or user

The NFT is therefore born directly into the invoice financing workflow.

---

## 4. ⚙️ Policy Script Compilation

### `mkPolicy`

This is the untyped wrapper:

```haskell
mkPolicy :: BuiltinData -> BuiltinData -> ()
```

It ignores the redeemer and only uses the `ScriptContext`:

```haskell
mkPolicy _ ctx =
    if mkDocPolicy (unsafeFromBuiltinData ctx)
    then ()
    else error ()
```

### Why this wrapper exists

Plutus minting policies operate on raw `BuiltinData`, so the strongly typed function must be wrapped for on-chain execution.

---

### `policy`

This compiles the minting policy into an on-chain script:

```haskell
policy :: MintingPolicy
policy =
    mkMintingPolicyScript
        $$(PlutusTx.compile [|| mkPolicy ||])
```

This compiled script is what gets serialized and used off-chain for NFT minting.

---

## 5. 🔧 Helper Logic Inside the Policy

### `info`

```haskell
info :: TxInfo
info = scriptContextTxInfo ctx
```

Extracts transaction-level information from the script context.

---

### `ownCS`

```haskell
ownCS :: CurrencySymbol
ownCS = ownCurrencySymbol ctx
```

Gets the currency symbol of the policy currently executing.

### Why it matters

This allows the policy to verify that the minted token belongs to **this exact policy**.

---

### `minted`

```haskell
minted :: [(CurrencySymbol, TokenName, Integer)]
minted = flattenValue (txInfoMint info)
```

Flattens the minted value into a list of:

* currency symbol
* token name
* amount

This makes it easier to inspect what was minted.

---

### `singleMint`

```haskell
singleMint :: Bool
singleMint =
    case minted of
        [(cs, _, amt)] -> cs == ownCS && amt == 1
        _              -> False
```

Checks that:

* only one asset entry exists in the mint field
* it belongs to this policy
* the minted amount is exactly 1

---

### `issuerSigned`

```haskell
issuerSigned :: Bool
issuerSigned =
    case txInfoSignatories info of
        [_] -> True
        _   -> False
```

Checks that there is exactly one signer.

---

### `nftLocked`

```haskell
nftLocked :: Bool
nftLocked =
    any outputHasNFT (txInfoOutputs info)
```

Scans outputs to confirm that the NFT was placed in the financing validator output.

---

### `outputHasNFT`

This helper performs the actual output validation.

It checks:

1. Output address is a script address
2. Script hash matches `financingValidatorHash`
3. Output contains exactly one copy of the minted token

---

### `mintedTokenName`

```haskell
mintedTokenName :: TokenName
```

Extracts the token name from the minted value.

This is needed because the policy must verify the exact asset locked in the financing contract output.

---

## 6. 🧪 Practical Usage Example

### Example workflow

1. Prepare the invoice document off-chain
2. Derive a token name, often from the invoice file hash
3. Build a mint transaction using this policy
4. Create an output to the financing validator
5. Place exactly one minted NFT in that script output
6. Sign and submit the transaction

---

### Example high-level flow

```haskell
-- Compile the policy to CBOR
main

-- Off-chain:
-- 1. Load the policy
-- 2. Mint exactly one invoice NFT
-- 3. Send it to the financing validator output
-- 4. Attach invoice datum at the financing validator
```

---

## 7. 🧷 Testing Strategy

A good testing strategy should include the following cases.

### ✅ Successful mint

* exactly one NFT minted
* exactly one signer
* NFT locked at financing validator

Expected result: **PASS**

---

### ❌ Multiple tokens minted

* minting more than one invoice NFT
* minting multiple assets under the same policy

Expected result: **FAIL**

---

### ❌ No signer or too many signers

* zero signers
* two or more signers

Expected result: **FAIL**

---

### ❌ NFT sent to wrong address

* minted NFT sent to wallet address
* minted NFT sent to another script
* minted NFT not included in financing validator output

Expected result: **FAIL**

---

### ❌ Wrong asset locked

* output contains a different token
* output does not contain the freshly minted token name

Expected result: **FAIL**

---

## 8. ✅ Best Practices

* Keep the minting policy narrowly scoped:

  * one invoice NFT per transaction
  * one signer
  * one destination validator

* Tie the minting policy to the financing validator:

  * prevents detached or free-floating invoice NFTs

* Prefer deterministic token names:

  * e.g. file hash, invoice reference hash, or unique document digest

* Test all edge cases:

  * especially wrong output destinations and malformed mint values

* Keep validator hash references synchronized:

  * if the financing validator changes, update `financingValidatorHash`

---

## 9. 📘 Glossary of Terms

| Term                  | Definition                                                                    |
| --------------------- | ----------------------------------------------------------------------------- |
| **Minting Policy**    | A smart contract that controls whether tokens may be minted or burned         |
| **CurrencySymbol**    | Identifier of the minting policy under which a token exists                   |
| **TokenName**         | Name of a token under a given policy                                          |
| **NFT**               | Non-fungible token; a token intended to be unique                             |
| **ScriptContext**     | The on-chain context containing the current transaction information           |
| **TxInfo**            | Transaction details available to the script                                   |
| **ValidatorHash**     | Hash of a validator script, used to identify a script address                 |
| **AssetClass**        | Pair of `CurrencySymbol` and `TokenName` identifying a token                  |
| **flattenValue**      | Converts a value into a list of `(CurrencySymbol, TokenName, Amount)` entries |
| **ownCurrencySymbol** | Returns the current minting policy’s currency symbol                          |
| **ScriptCredential**  | Credential showing an address is controlled by a script                       |
| **CBOR**              | Serialized binary format used to export scripts                               |

---

# 🚀 Final Understanding

This minting policy ensures that an invoice NFT is not just minted arbitrarily.
Instead, it guarantees:

* exactly one invoice NFT is created
* an issuer explicitly authorizes the mint
* the NFT is immediately locked into the financing contract

That makes this policy a strong companion to the invoice financing validator.

Together, they form a two-part system:

1. **Minting Policy**

   * controls creation of the invoice NFT

2. **Financing Validator**

   * controls funding and repayment of the invoice lifecycle
