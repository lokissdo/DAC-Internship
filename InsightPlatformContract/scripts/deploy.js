// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");
async function main() {
  const [deployer] = await hre.ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  const CourseOpeningNFT = await hre.ethers.getContractFactory("CourseOpeningNFT");
  const nftDeployed1  = await CourseOpeningNFT.deploy("CourseOpeningNFT", "CONFT","localhost:3001/metadata/conft/");

  console.log("CourseOpeningNFT Contract :", nftDeployed1 );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });


  //0x26363C3D534dED99c9cad2f9163FF21D9c7CF773