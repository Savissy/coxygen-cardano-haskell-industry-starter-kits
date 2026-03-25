

# 🧾 Detailed Tutorial: Understanding and Using `Invoice Financing Validator`

This tutorial explains the `Invoice Financing` smart contract, covering its purpose, structure, validator logic, and how it powers a tokenized invoice financing dApp on Cardano.

---

## 📚 Table of Contents

1. [📦 Imports Overview](#1-imports-overview)
2. [🗃️ Data Structures](#2-data-structures)
3. [🧠 Core Validator Logic](#3-core-validator-logic)
4. [⚙️ Validator Script Compilation](#4-validator-script-compilation)
5. [🔧 Helper Functions](#5-helper-functions)
6. [🧪 Practical Usage Example](#6-practical-usage-example)
7. [🧷 Testing Strategy](#7-testing-strategy)
8. [✅ Best Practices](#8-best-practices)
9. [📘 Glossary of Terms](#9-glossary-of-terms)

---

## 1. 📦 Imports Overview

### Plutus API Modules

* **Plutus.V2.Ledger.Api**

  * Provides core blockchain types:

    * `ScriptContext`
    * `TxInfo`
    * `PubKeyHash`
    * `Validator`

* **Plutus.V2.Ledger.Contexts**

  * Functions like:

    * `txInfoSignatories`
    * `valuePaidTo`
    * `getContinuingOutputs`

* **Plutus.V1.Ledger.Value**

  * Used for working with tokens:

    * `AssetClass`
    * `assetClassValueOf`
    * `valueOf`
    * `adaSymbol`, `adaToken`

---

### Utility Modules

* **PlutusTx**

  * Compiles Haskell into Plutus Core

* **PlutusTx.Prelude**

  * On-chain safe functions

* **Cardano.Api**

  * Used for generating script addresses

* **Codec.Serialise / ByteString**

  * Used for CBOR serialization

---

## 2. 🗃️ Data Structures

### `Investor`

Represents a single investor:

```haskell
data Investor = Investor
    { invPkh    :: PubKeyHash
    , invAmount :: Integer
    }
```

* `invPkh`: Investor wallet
* `invAmount`: Amount funded

---

### `InvoiceDatum`

Core state of the contract:

```haskell
data InvoiceDatum = InvoiceDatum
    { idIssuer     :: PubKeyHash
    , idInvoiceNFT :: AssetClass
    , idFaceValue  :: Integer
    , idRepayment  :: Integer
    , idInvestors  :: [Investor]
    , isRepaid     :: Bool
    }
```

#### Fields explained:

| Field          | Description                       |
| -------------- | --------------------------------- |
| `idIssuer`     | Invoice creator                   |
| `idInvoiceNFT` | NFT representing invoice          |
| `idFaceValue`  | Amount investor pays              |
| `idRepayment`  | Amount issuer must repay          |
| `idInvestors`  | List of investors (max 1)         |
| `isRepaid`     | Whether invoice is already repaid |

---

### `InvoiceAction`

Defines user actions:

```haskell
data InvoiceAction
    = FundInvoice
    | RepayInvoice
```

---

## 3. 🧠 Core Validator Logic

### `mkInvoiceValidator`

This is the **heart of the smart contract**.

---

## 🟢 Fund Invoice Logic

```haskell
FundInvoice ->
```

### Conditions:

1. **Invoice must not be funded**

```haskell
notFunded dat
```

2. **Invoice must not be repaid**

```haskell
not $ isRepaid dat
```

3. **Issuer must receive payment**

```haskell
paidAda info (idIssuer dat) >= idFaceValue dat
```

4. **NFT must remain locked**

```haskell
nftPreserved dat ctx
```

5. **Investor must sign transaction**

```haskell
investorSigned
```

---

## 🔵 Repay Invoice Logic

```haskell
RepayInvoice ->
```

### Conditions:

1. **Invoice must not be repaid already**

```haskell
not $ isRepaid dat
```

2. **Must have exactly one investor**

```haskell
hasInvestor
```

3. **Enough ADA must be present**

```haskell
>= idRepayment dat
```

4. **Investor must be paid (principal + profit)**

```haskell
invAmount + profit
```

Where:

```haskell
profit = idRepayment - idFaceValue
```

---

## 🧠 Key Insight

This contract enforces:

👉 **Trustless invoice financing**

* Investor funds invoice → issuer gets liquidity
* Issuer repays → investor gets profit

---

## 4. ⚙️ Validator Script Compilation

### `validator`

```haskell
validator =
    mkValidatorScript
        $$(PlutusTx.compile [|| mkValidatorUntyped ||])
```

* Converts Haskell → Plutus Core
* Ready for deployment

---

## 5. 🔧 Helper Functions

### `paidAda`

```haskell
paidAda info pkh =
    valueOf (valuePaidTo info pkh) adaSymbol adaToken
```

➡️ Checks how much ADA was paid to a wallet

---

### `notFunded`

```haskell
notFunded dat =
    case idInvestors dat of
        [] -> True
        _  -> False
```

➡️ Ensures invoice has no investor yet

---

### `nftPreserved`

```haskell
nftPreserved dat ctx =
```

➡️ Ensures:

* NFT stays in script
* Prevents theft during funding

---

### `toBech32ScriptAddress`

Generates readable address:

```haskell
toBech32ScriptAddress network validator
```

---

### `writeCBOR`

Exports validator:

```haskell
writeCBOR "invoice_financing.cbor"
```

---

## 6. 🧪 Practical Usage Example

```haskell
-- Compile validator
main

-- Output:
-- invoice_financing.cbor
-- Script address

-- Example flow:
-- 1. Mint invoice NFT
-- 2. Lock in script with datum
-- 3. Investor funds
-- 4. Issuer repays
```

---

## 7. 🧷 Testing Strategy

Test these scenarios:

### ✅ Funding

* Investor pays correct amount → PASS
* No signature → FAIL
* Already funded → FAIL

### ✅ Repayment

* Full repayment → PASS
* Underpayment → FAIL
* No investor → FAIL
* Double repayment → FAIL

---

## 8. ✅ Best Practices

* Always enforce **state transitions**
* Use flags like `isRepaid`
* Validate **exact token ownership**
* Restrict investor count
* Add clear `traceIfFalse` messages

---

## 9. 📘 Glossary of Terms

| Term              | Meaning                       |
| ----------------- | ----------------------------- |
| **Invoice NFT**   | Token representing an invoice |
| **Datum**         | On-chain state                |
| **Validator**     | Smart contract rules          |
| **Funding**       | Investor pays issuer          |
| **Repayment**     | Issuer pays investor          |
| **AssetClass**    | Token identifier              |
| **PubKeyHash**    | Wallet identity               |
| **ScriptContext** | Transaction info              |
| **UTxO**          | Unspent transaction output    |
| **Bech32**        | Address format                |

---

# 🚀 Final Understanding

This contract implements:

👉 **A complete on-chain invoice financing system**

Flow:

1. Issuer creates invoice NFT
2. Investor funds → issuer gets liquidity
3. Issuer repays → investor earns profit
4. Contract enforces everything

---

