async function main() {
    const [deployer] = await ethers.getSigners();
    const beginBalance = await deployer.getBalance();
  
    console.log("Deployer:", deployer.address);
    console.log("Balance:", ethers.utils.formatEther(beginBalance));

    const signer = "0x0";
    const inventory = "0x0";
    const saleStartTime = 1704693600;

    const telescopeContractFactory = await ethers.getContractFactory("Telescope");
    const telescopeContract = await telescopeContractFactory.deploy(saleStartTime, inventory, signer);
    console.log("Telescope contract: ", telescopeContract.address);

    // +++
    const endBalance = await deployer.getBalance();
    const gasSpend = beginBalance.sub(endBalance);

    console.log("\nLatest balance:", ethers.utils.formatEther(endBalance));
    console.log("Gas:", ethers.utils.formatEther(gasSpend));
  }

  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });