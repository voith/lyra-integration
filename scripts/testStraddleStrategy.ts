import { TestSystem } from '@lyrafinance/protocol';

function assert(condition: boolean, message: string) {
  if (!condition) {
    throw new Error(message || 'Assertion failed');
  }
}

async function main() {
  const provider = new ethers.providers.JsonRpcProvider('http://localhost:8545');
  // picked this privateKey from ganache logs
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

  // deploy straddleStrategy
  const straddleStrategyFactory = (await ethers.getContractFactory('StraddleStrategy')).connect(deployer);
  const straddleStrategy = await straddleStrategyFactory.deploy(
    localTestSystem.optionMarket.address,
    localTestSystem.synthetixAdapter.address,
    localTestSystem.optionGreekCache.address,
  );

  // checks before executing buyStraddle
  let deployerInitialBalance = await localTestSystem.snx.quoteAsset.balanceOf(deployer.address);
  assert(
    (await localTestSystem.snx.quoteAsset.balanceOf(straddleStrategy.address)) == 0,
    'quoteAsset balance of straddleStrategy should be 0',
  );
  assert(
    (await localTestSystem.optionToken.balanceOf(straddleStrategy.address)) == 0,
    "straddleStrategy shouldn't have any open positions before executing buyStraddle",
  );

  // execute buyStraddle
  let boardIds = await localTestSystem.optionMarket.getLiveBoards();
  let strikeIds = await localTestSystem.optionMarket.getBoardStrikes(boardIds[0]);
  let strikeID = strikeIds[0];
  let { callCollateral, putCollateral } = await straddleStrategy.getMinCollateral(strikeID, 100);
  await localTestSystem.snx.quoteAsset.approve(straddleStrategy.address, callCollateral + putCollateral);
  await straddleStrategy.buyStraddle(strikeID, 100);

  // checks after executing buyStraddle
  let currentDeployerBalance = await localTestSystem.snx.quoteAsset.balanceOf(deployer.address);
  let [longCall, longPut] = await localTestSystem.optionToken.getOwnerPositions(straddleStrategy.address);
  assert(
    currentDeployerBalance.lt(deployerInitialBalance),
    'deployer balance should be less than initial balance after executing buyStraddle',
  );
  assert(
    (await localTestSystem.snx.quoteAsset.balanceOf(straddleStrategy.address)) == 0,
    'quoteAsset balance of straddleStrategy should be 0 after executing buyStraddle',
  );
  assert(
    (await localTestSystem.optionToken.balanceOf(straddleStrategy.address)) == 2,
    'straddleStrategy should have 2 open positions after executing buyStraddle',
  );
  assert(longCall.strikeId.eq(strikeID), 'strikeId of open position should match');
  assert(longPut.strikeId.eq(strikeID), 'strikeId of open position should match');
  assert(longCall.optionType == TestSystem.OptionType.LONG_CALL, 'option type should match');
  assert(longPut.optionType == TestSystem.OptionType.LONG_PUT, 'option type should match');

  console.log('execute buyStraddle and tested it successfully');
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
