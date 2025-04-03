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
