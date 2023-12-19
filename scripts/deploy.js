const { ethers } = require("hardhat");

async function main() {
  // Deploy StudyCafeStorage
  const _StudyCafeStorage = await ethers.getContractFactory("StudyCafeStorage");
  StudyCafeStorage = await _StudyCafeStorage.deploy();
  await StudyCafeStorage.deployed();
  console.log("StudyCafeStorage deployed to:", StudyCafeStorage.address);

  // Deploy StudyCafeLogic
  const _StudyCafeLogic = await ethers.getContractFactory("StudyCafeLogic");
  StudyCafeLogic = await _StudyCafeLogic.deploy(
    ethers.utils.parseEther("1"),
    ethers.utils.parseEther("0.05"),
    10
  );
  await StudyCafeLogic.deployed();
  console.log("StudyCafeLogic deployed to:", StudyCafeLogic.address);

  // Deploy StudyCafeProxy
  const _StudyCafeProxy = await ethers.getContractFactory("StudyCafeProxy");
  StudyCafeProxy = await _StudyCafeProxy.deploy(
    StudyCafeLogic.address,
    StudyCafeStorage.address
  );
  await StudyCafeProxy.deployed();
  console.log("StudyCafeProxy deployed to:", StudyCafeProxy.address);
}

main()
  .then(() => {
    console.log("Deployment complete!");
    process.exit(0);
  })
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
