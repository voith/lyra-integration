//SPDX-License-Identifier:ISC
pragma solidity 0.8.16;

import {OptionMarket} from "@lyrafinance/protocol/contracts/OptionMarket.sol";
import {BaseExchangeAdapter} from "@lyrafinance/protocol/contracts/BaseExchangeAdapter.sol";
import {OptionGreekCache} from "@lyrafinance/protocol/contracts/OptionGreekCache.sol";
import {IERC20Decimals} from "@lyrafinance/protocol/contracts/interfaces/IERC20Decimals.sol";
import {Quoter} from "./Quoter.sol";

contract StraddleStrategy {
  OptionMarket internal optionMarket;
  IERC20Decimals internal quoteAsset;
  Quoter internal quoter;

  error ERC20TransferFailed(address from, address to, uint amount);

  constructor(address _optionMarket, address _quoter) {
    optionMarket = OptionMarket(_optionMarket);
    quoteAsset = IERC20Decimals(optionMarket.quoteAsset());
    quoter = Quoter(_quoter);
    quoteAsset.approve(address(optionMarket), type(uint256).max);
  }

  /**
   * @notice This function executes a long straddle strategy by opening equal sized long call
   *         and long put options. The cost for executing this function can be calculated by
   *         calling `quoteBuyStraddle`
   *
   * @dev `msg.sender` needs to approve `quoteAsset` tokens to this contract before calling this function.
   *
   * @param strikeId id of strike against which the option will be opened
   * @param size size of the option
   * @param maxCost the max amount `quoteAsset` tokens that a user is willing to pay
   */
  function buyStraddle(uint256 strikeId, uint256 size, uint256 maxCost) external returns (uint256 totalCost) {
    if (!quoteAsset.transferFrom(msg.sender, address(this), maxCost)) {
      revert ERC20TransferFailed(msg.sender, address(this), maxCost);
    }

    OptionMarket.TradeInputParameters memory params = OptionMarket.TradeInputParameters({
      strikeId: strikeId,
      positionId: 0,
      optionType: OptionMarket.OptionType.LONG_CALL,
      amount: size,
      setCollateralTo: 0,
      iterations: 1,
      minTotalCost: 0,
      maxTotalCost: type(uint256).max,
      referrer: address(0)
    });
    // Open long call option
    OptionMarket.Result memory callResult = optionMarket.openPosition(params);
    params.optionType = OptionMarket.OptionType.LONG_PUT;
    // Open long put option
    OptionMarket.Result memory putResult = optionMarket.openPosition(params);
    totalCost = callResult.totalCost + putResult.totalCost;
    if (maxCost > totalCost && !quoteAsset.transfer(msg.sender, maxCost - totalCost)) {
        revert ERC20TransferFailed(address(this), msg.sender, maxCost - totalCost);
    }
  }

  /**
   * @notice Calculates the cost for executing `buyStraddle`
   *
   * @dev This function is not gas efficient. This should be called with `callStatic` for off-chain purposes.
   *
   * @param strikeId id of strike against which the option will be opened
   * @param size size of the option
   */
  function quoteBuyStraddle(uint256 strikeId, uint256 size) public returns (uint256 totalCost) {
    OptionMarket.TradeInputParameters memory params = OptionMarket.TradeInputParameters({
      strikeId: strikeId,
      positionId: 0,
      optionType: OptionMarket.OptionType.LONG_CALL,
      amount: size,
      setCollateralTo: 0,
      iterations: 1,
      minTotalCost: 0,
      maxTotalCost: type(uint256).max,
      referrer: address(0)
    });
    totalCost = quoter.quoteOpenPosition(params);
    params.optionType = OptionMarket.OptionType.LONG_PUT;
    totalCost += quoter.quoteOpenPosition(params);
  }
}
