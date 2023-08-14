import { TestSystem, TestSystemContractsType } from '@lyrafinance/protocol';
import {
  Quoter,
  Quoter__factory,
  QuoterHelper,
  QuoterHelper__factory,
  StraddleStrategy__factory,
  StraddleStrategy,
} from '../typechain-types';

type SystemContracts = {
  quoter: Quoter;
  quoterHelper: QuoterHelper;
  straddleStrategy: StraddleStrategy;
};

async function deployAndSetupSystemContracts(
  deployer: ethers.Wallet,
  localTestSystem: TestSystemContractsType,
): Promise<SystemContracts> {
  // deploy QuoterHelper
  const quoterHelper = await new QuoterHelper__factory(deployer).deploy(localTestSystem.optionMarket.address);
  // Transfer some quoteAsset tokens to quoterHelper so that it can simulate opening an option
  // without the user having to approve and transfer tokens every single time.
  await localTestSystem.snx.quoteAsset.transfer(
    quoterHelper.address, ethers.utils.parseEther('10')
  );
  // deploy Quoter
  const quoter = await new Quoter__factory(deployer).deploy(quoterHelper.address);
  // deploy straddleStrategy
  const straddleStrategy = await new StraddleStrategy__factory(deployer).deploy(
    localTestSystem.optionMarket.address,
    quoter.address,
  );

  const systemContracts = {
    quoter: quoter,
    quoterHelper: quoterHelper,
    straddleStrategy: straddleStrategy,
  };
  return systemContracts as SystemContracts;
}

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

  const systemContracts = await deployAndSetupSystemContracts(deployer, localTestSystem);

  // checks before executing buyStraddle
  const straddleStrategy = systemContracts.straddleStrategy;
  const deployerInitialBalance = await localTestSystem.snx.quoteAsset.balanceOf(deployer.address);

  assert(
    (await localTestSystem.snx.quoteAsset.balanceOf(straddleStrategy.address)).eq(0),
    'quoteAsset balance of straddleStrategy should be 0 before executing buyStraddle',
  );
  assert(
    (await localTestSystem.optionToken.balanceOf(straddleStrategy.address)) == 0,
    "straddleStrategy shouldn't have any open positions before executing buyStraddle",
  );

  // execute buyStraddle
  const boardIds = await localTestSystem.optionMarket.getLiveBoards();
  const strikeIds = await localTestSystem.optionMarket.getBoardStrikes(boardIds[0]);
  const strikeID = strikeIds[1];
  const estimatedCost = (await straddleStrategy.callStatic.quoteBuyStraddle(strikeID, 100)).mul(2);
  await localTestSystem.snx.quoteAsset.approve(straddleStrategy.address, estimatedCost);
  await straddleStrategy.buyStraddle(strikeID, 100, estimatedCost);

  // checks after executing buyStraddle
  let currentDeployerBalance = await localTestSystem.snx.quoteAsset.balanceOf(deployer.address);
  let [longCall, longPut] = await localTestSystem.optionToken.getOwnerPositions(straddleStrategy.address);
  assert(
    currentDeployerBalance.lt(deployerInitialBalance),
    'deployer balance should be less than initial balance after executing buyStraddle',
  );
  assert(
    (await localTestSystem.snx.quoteAsset.balanceOf(straddleStrategy.address)).eq(0),
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

  console.log('executed buyStraddle and tested it successfully');
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
