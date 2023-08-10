import { TestSystem } from '@lyrafinance/protocol';

async function main() {
  // 1. create local deployer and network
  const provider = new ethers.providers.JsonRpcProvider('http://localhost:8545');
  const privateKey = '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80';
  // 2. optional settings to prevent errors
  provider.getGasPrice = async () => { return ethers.BigNumber.from('0'); };
  provider.estimateGas = async () => { return ethers.BigNumber.from(15000000); }
  const deployer = new ethers.Wallet(privateKey, provider);

  // 3. deploy and seed Lyra market
  let linkTracer = false;
  let exportAddresses = true;
  let localTestSystem = await TestSystem.deploy(deployer, linkTracer, exportAddresses);
  await TestSystem.seed(deployer, localTestSystem, overrides={});

  // 4. call local contracts
  await localTestSystem.optionMarket.openPosition({
    strikeId: 1,
    positionId: 0,
    optionType: TestSystem.OptionType.LONG_CALL,
    amount: toBN("1"),
    setCollateralTo: toBN("0"),
    iterations: 3,
    minTotalCost: toBN("0"),
    maxTotalCost?: toBN("250"),
  });
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });