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

  error QuoteTransferFailed(address thrower, address from, address to, uint amount);

  constructor(address _optionMarket, address _exchangeAdapter, address _optionGreekCache) {
    optionMarket = OptionMarket(_optionMarket);
    exchangeAdapter = BaseExchangeAdapter(_exchangeAdapter);
    optionGreekCache = OptionGreekCache(_optionGreekCache);
    quoteAsset = IERC20Decimals(optionMarket.quoteAsset());
  }

  function buyStraddle(uint256 strikeId, uint256 size) external {
    (uint256 callCollateral, uint256 putCollateral) = getMinCollateral(strikeId, size);
    uint256 totalCollateral = callCollateral + putCollateral;

    if (!quoteAsset.transferFrom(msg.sender, address(this), totalCollateral)) {
      revert QuoteTransferFailed(address(this), msg.sender, address(this), totalCollateral);
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
    optionMarket.openPosition(params);
    params.optionType = OptionMarket.OptionType.LONG_PUT;
    params.setCollateralTo = putCollateral;
    optionMarket.openPosition(params);
  }

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
