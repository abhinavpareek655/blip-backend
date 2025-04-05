# BlipAuth Smart Contract & IPFS Setup Guide

This guide helps you deploy the BlipAuth smart contract using Hardhat, run it locally, connect it to your React Native app, and use a local IPFS node to store media and post data.

---

## ✅ Overview

1. Set up a Hardhat project  
2. Add the smart contract (`BlipAuth.sol`)  
3. Compile it  
4. Run a local blockchain  
5. Deploy the contract  
6. Copy the deployed address & ABI to your frontend  
7. Start a local IPFS node  
8. Upload files via IPFS in your React Native app  

---

## 🛠 Step-by-Step Guide

### ✅ 1. Initialize Hardhat

```bash
mkdir blip-contracts && cd blip-contracts
npm init -y
npm install --save-dev hardhat
npx hardhat
```

Choose: **“Create a basic sample project”**

---

### ✅ 2. Add Smart Contract

Create a file:

📄 `contracts/BlipAuth.sol`

Paste this contract:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract BlipAuth {
    struct User {
        address wallet;
        bytes32 passwordHash;
    }

    mapping(string => User) private users;

    function signup(string memory email, string memory password) public {
        require(users[email].wallet == address(0), "Email already registered");
        users[email] = User(msg.sender, keccak256(abi.encodePacked(password)));
    }

    function login(string memory email, string memory password) public view returns (bool) {
        User memory user = users[email];
        return user.wallet != address(0) && user.passwordHash == keccak256(abi.encodePacked(password));
    }
}
```

---

### ✅ 3. Compile the Contract

```bash
npx hardhat compile
```

ABI is generated in:

```
artifacts/contracts/BlipAuth.sol/BlipAuth.json
```

---

### ✅ 4. Start Local Blockchain

```bash
npx hardhat node --hostname 0.0.0.0
```

This runs a local network at `http://127.0.0.1:8545`.

---

### ✅ 5. Deploy the Contract

Create: `scripts/deploy.js`

```js
const hre = require("hardhat");

async function main() {
  const Auth = await hre.ethers.getContractFactory("BlipAuth");
  const auth = await Auth.deploy();
  await auth.waitForDeployment();
  console.log("BlipAuth deployed to:", await auth.getAddress());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
```

Deploy it:

```bash
npx hardhat run scripts/deploy.js --network localhost
```

Copy the deployed contract address.

---

### ✅ 6. Copy ABI to React Native App

- In your frontend, create `blockchain/BlipAuth.json`
- Copy only the `abi` array from `artifacts/.../BlipAuth.json`

```json
{
  "abi": [ /* ... your contract ABI ... */ ]
}
```

---

### ✅ 7. Connect in `authContract.ts`

```ts
import { JsonRpcProvider, Contract } from "ethers";
import AuthABI from "./BlipAuth.json";

const CONTRACT_ADDRESS = "PASTE_DEPLOYED_ADDRESS_HERE";
const provider = new JsonRpcProvider("http://127.0.0.1:8545");
const signer = await provider.getSigner();
const contract = new Contract(CONTRACT_ADDRESS, AuthABI.abi, signer);
```

---

## 🧠 BONUS: Local IPFS Setup for Media/Post Storage

### ✅ 1. Install IPFS CLI

From [https://docs.ipfs.tech/install/command-line/](https://docs.ipfs.tech/install/command-line/)

Or use:

```bash
# macOS
brew install ipfs

# Ubuntu
sudo apt install ipfs
```

---

### ✅ 2. Initialize IPFS Node

```bash
ipfs init
```

---

### ✅ 3. Start the IPFS Daemon

```bash
ipfs daemon
```

It will start at:

```
API:     http://127.0.0.1:5001
Gateway: http://127.0.0.1:8080
```

---

### ✅ 4. Upload a File (Test)

```bash
ipfs add hello.txt
```

Output:

```
added Qm... hello.txt
```

View it in browser:

```
http://127.0.0.1:8080/ipfs/Qm...
https://ipfs.io/ipfs/Qm...
```

---

### ✅ 5. List Local Files

```bash
ipfs pin ls
```

---

### ✅ 6. Use in React Native App

Configure `ipfs-http-client`:

```ts
import { create as ipfsHttpClient } from "ipfs-http-client";

const ipfs = ipfsHttpClient({
  host: "localhost",
  port: 5001,
  protocol: "http",
});
```

Upload:

```ts
const result = await ipfs.add(fileBlob);
console.log("CID:", result.path);
```

---

## 🎉 Done!

You're now fully connected to your:
- ✅ Local blockchain for auth and smart contract storage
- ✅ Local IPFS node for media and post data

---

### 🚀 Next Steps

- Save and fetch post CIDs from chain
- Create a decentralized feed UI

---