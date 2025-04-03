require("@nomicfoundation/hardhat-toolbox");

const ALCHEMY_API_KEY = "https://eth-mainnet.g.alchemy.com/v2/G-7IkBYtVPx5HcxNIG-6QjXQQhNTC5WV";
const TESTNET_PRIVATE_KEY = process.env.TESTNET_PRIVATE_KEY;

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.28",
};
