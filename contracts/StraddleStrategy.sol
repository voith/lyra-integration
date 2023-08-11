//SPDX-License-Identifier:ISC
pragma solidity 0.8.16;

import {OptionMarket} from "@lyrafinance/protocol/contracts/OptionMarket.sol";
import {BaseExchangeAdapter} from "@lyrafinance/protocol/contracts/BaseExchangeAdapter.sol";
import {OptionGreekCache} from "@lyrafinance/protocol/contracts/OptionGreekCache.sol";
import {IERC20Decimals} from "@lyrafinance/protocol/contracts/interfaces/IERC20Decimals.sol";

contract StraddleStrategy {
  OptionMarket internal optionMarket;
  BaseExchangeAdapter internal exchangeAdapter;
  OptionGreekCache internal optionGreekCache;
  IERC20Decimals internal quoteAsset;

  error ERC20TransferFailed(address from, address to, uint amount);

  constructor(address _optionMarket, address _exchangeAdapter, address _optionGreekCache) {
    optionMarket = OptionMarket(_optionMarket);
    exchangeAdapter = BaseExchangeAdapter(_exchangeAdapter);
    optionGreekCache = OptionGreekCache(_optionGreekCache);
    quoteAsset = IERC20Decimals(optionMarket.quoteAsset());
  }

  /**
   * @notice This function executes a long straddle strategy by opening equal sized long call
   *         and long put options. The collateral needed for executing this function can be fetched
   *         calling the `getMinCollateral` function.
   *
   * @dev `msg.sender` needs to approve the amount of collateral that is needed to open the
   *       positions to this contract.
   *
   * @param strikeId id of strike against which the option will be opened
   * @param size size of the option
   */
  function buyStraddle(uint256 strikeId, uint256 size) external {
    (uint256 callCollateral, uint256 putCollateral) = getMinCollateral(strikeId, size);
    uint256 totalCollateral = callCollateral + putCollateral;

    if (!quoteAsset.transferFrom(msg.sender, address(this), totalCollateral)) {
      revert ERC20TransferFailed(msg.sender, address(this), totalCollateral);
    }
    quoteAsset.approve(address(optionMarket), totalCollateral);

    OptionMarket.TradeInputParameters memory params = OptionMarket.TradeInputParameters({
      strikeId: strikeId,
      positionId: 0,
      optionType: OptionMarket.OptionType.LONG_CALL,
      amount: 1,
      setCollateralTo: callCollateral,
      iterations: 1,
      minTotalCost: 0,
      maxTotalCost: type(uint256).max,
      referrer: address(0)
    });
    // Open long call option
    OptionMarket.Result memory callResult = optionMarket.openPosition(params);
    params.optionType = OptionMarket.OptionType.LONG_PUT;
    params.setCollateralTo = putCollateral;
    // Open long put option
    OptionMarket.Result memory putResult = optionMarket.openPosition(params);

    // Transfer back unused collateral
    if (totalCollateral > (callResult.totalCost + putResult.totalCost)) {
      uint256 amountToReturn = totalCollateral - (callResult.totalCost + putResult.totalCost);
      if (!quoteAsset.transfer(msg.sender, amountToReturn)) {
        revert ERC20TransferFailed(address(this), msg.sender, amountToReturn);
      }
    }
  }

  /**
   * @notice This function calculates the minimum collateral needed to execute `buyStraddle`.
   *
   * @param strikeId id of strike against which the option will be opened
   * @param size size of the option
   */
  function getMinCollateral(
    uint256 strikeId,
    uint256 size
  ) public view returns (uint256 callCollateral, uint256 putCollateral) {
    (uint256 strikePrice, uint256 expiry) = optionMarket.getStrikeAndExpiry(strikeId);
    uint256 spotPrice = exchangeAdapter.getSpotPriceForMarket(
      address(optionMarket),
      BaseExchangeAdapter.PriceType.REFERENCE
    );
    callCollateral = optionGreekCache.getMinCollateral(
      OptionMarket.OptionType.LONG_CALL,
      strikePrice,
      expiry,
      spotPrice,
      size
    );
    putCollateral = optionGreekCache.getMinCollateral(
      OptionMarket.OptionType.LONG_PUT,
      strikePrice,
      expiry,
      spotPrice,
      size
    );
  }
}
