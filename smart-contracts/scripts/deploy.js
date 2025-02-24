async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);
  
    // Get the contract factory and deploy the contract
    const ProductContract = await ethers.getContractFactory("ProductContract");
    const productContract = await ProductContract.deploy();
    console.log("ProductContract deployed to:", productContract.target);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  