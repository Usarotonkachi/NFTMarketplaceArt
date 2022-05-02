const hre = require("hardhat");
const ethers = hre.ethers;

async function main() {
  const MyNFT = await ethers.getContractFactory("myNFT");
  const myNFT = await MyNFT.deploy();

  await myNFT.deployed();
  
  console.log("PancakeSniper deployed to address: ", myNFT.address);
  console.log("PancakeSniper deployed to block: ", await hre.ethers.provider.getBlockNumber());
  console.log("PancakeSniper owner is: ", await (myNFT.provider.getSigner() ).getAddress() );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });