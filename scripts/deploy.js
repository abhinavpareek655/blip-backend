// scripts/deploy.js

const hre = require("hardhat");

async function main() {
  // Deploy BlipAuth
  const Auth = await hre.ethers.getContractFactory("BlipAuth");
  const auth = await Auth.deploy();
  await auth.waitForDeployment();
  const authAddress = await auth.getAddress();
  console.log("✅ BlipAuth deployed to:", authAddress);

  // Deploy BlipPosts
  const Posts = await hre.ethers.getContractFactory("BlipPosts");
  const posts = await Posts.deploy();
  await posts.waitForDeployment();
  const postsAddress = await posts.getAddress();
  console.log("✅ BlipPosts deployed to:", postsAddress);

  // Deploy BlipProfile
  const Profile = await hre.ethers.getContractFactory("BlipProfile");
  const profile = await Profile.deploy();
  await profile.waitForDeployment();
  const profileAddress = await profile.getAddress();
  console.log("✅ BlipProfile deployed to:", profileAddress)
}

main().catch((error) => {
  console.error("❌ Deployment failed:", error);
  process.exitCode = 1;
});
