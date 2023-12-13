const { ethers } = require("hardhat");

async function main() {
  // Deploy StudyCafeStorage
  const StudyCafeStorage = await ethers.getContractFactory("StudyCafeStorage");
  const storage = await StudyCafeStorage.deploy();
  await storage.deployed(); // 대기
  console.log("StudyCafeStorage deployed to:", storage.address);

  // Deploy StudyCafeLogic
  const StudyCafeLogic = await ethers.getContractFactory("StudyCafeLogic");
  const logic = await StudyCafeLogic.deploy(100);
  await logic.deployed(); // 대기
  console.log("StudyCafeLogic deployed to:", logic.address);

  // Deploy StudyCafeProxy
  const StudyCafeProxy = await ethers.getContractFactory("StudyCafeProxy");
  const proxy = await StudyCafeProxy.deploy(logic.address);
  await proxy.deployed(); // 대기
  console.log("StudyCafeProxy deployed to:", proxy.address);

  // Set the logic contract address in the proxy
  await proxy.setLogicContract(logic.address);
  console.log("Logic contract address set in StudyCafeProxy");

  console.log("Deployment complete!");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
