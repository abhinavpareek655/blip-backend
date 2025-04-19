# BlipAuth Smart Contract & IPFS Setup Guide

This guide helps you deploy the BlipAuth smart contract using Hardhat, run it locally, connect it to your React Native app, and use a local IPFS node to store media and post data.

---

## ✅ Overview

1. Compile smart contract  
2. Run a local blockchain  
3. Deploy the contract  
4. Copy the deployed address & ABI to your frontend  
5. Deploy OTP server

---

## 🛠 Step-by-Step Guide


### ✅ 1. Compile the Contract

```bash
npx hardhat compile
```

ABI is generated in:

```
artifacts/contracts/BlipAuth.sol/BlipAuth.json
```

---

### ✅ 2. Start Local Blockchain

```bash
npx hardhat node --hostname 0.0.0.0
```

This runs a local network at `http://127.0.0.1:8545`.

---

### ✅ 3. Deploy the Contract

Create: `scripts/deploy.js`

Deploy it:

```bash
npx hardhat run scripts/deploy.js --network localhost
```

Copy the deployed contract address.

---

### ✅ 4. Copy ABI to React Native App

- In your frontend, create `blockchain/BlipAuth.json`
- Copy only the `abi` array from `artifacts/.../BlipAuth.json`

```json
{
  "abi": [ /* ... your contract ABI ... */ ]
}
```

---

### ✅ 4.2. Connect in `authContract.ts`

```ts
import { JsonRpcProvider, Contract } from "ethers";
import AuthABI from "./BlipAuth.json";

const CONTRACT_ADDRESS = "PASTE_DEPLOYED_ADDRESS_HERE";
const provider = new JsonRpcProvider("http://127.0.0.1:8545");
const signer = await provider.getSigner();
const contract = new Contract(CONTRACT_ADDRESS, AuthABI.abi, signer);
```

---

### ✅ 5. Deploy OTP server

```bash
node styled-otp-server.js
```

---