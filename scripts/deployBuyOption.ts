import { TestSystem } from '@lyrafinance/protocol';

async function main() {
  const provider = new ethers.providers.JsonRpcProvider('http://127.0.0.1:8545/');
  const privateKey = '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80';
  provider.getGasPrice = async () => {
    return ethers.BigNumber.from('0');
  };
  provider.estimateGas = async () => {
    return ethers.BigNumber.from(15000000);
  };
  const deployer = new ethers.Wallet(privateKey, provider);

  let linkTracer = false;
  let exportAddresses = true;
  let localTestSystem = await TestSystem.deploy(deployer, linkTracer, exportAddresses);
  await TestSystem.seed(deployer, localTestSystem);

  let boardIds = await localTestSystem.optionMarket.getLiveBoards();
  let strikeIds = await localTestSystem.optionMarket.getBoardStrikes(boardIds[0]);
  await localTestSystem.optionMarket.openPosition({
    strikeId: strikeIds[0],
    positionId: 0,
    optionType: TestSystem.OptionType.LONG_CALL,
    amount: 1,
    setCollateralTo: 0,
    iterations: 1,
    minTotalCost: 0,
    maxTotalCost: 500,
    referrer: '0x0000000000000000000000000000000000000000',
  });
  console.log('successfully bought an option');
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
