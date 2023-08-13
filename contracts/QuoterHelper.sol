//SPDX-License-Identifier:ISC
pragma solidity 0.8.16;
import {OptionMarket} from "@lyrafinance/protocol/contracts/OptionMarket.sol";
import {IERC20Decimals} from "@lyrafinance/protocol/contracts/interfaces/IERC20Decimals.sol";

/// @notice Helper contract for opening an option and reverting in an atomic transaction.
/// @dev This contracts needs to have quoteAsset balance for it to work.
contract QuoterHelper {
  OptionMarket internal optionMarket;

  constructor(address _optionMarket) {
    optionMarket = OptionMarket(_optionMarket);
    IERC20Decimals quoteAsset = IERC20Decimals(optionMarket.quoteAsset());
    quoteAsset.approve(_optionMarket, type(uint256).max);
  }

  /// @notice opens an option and reverts.
  /// @dev This contracts needs to have quoteAsset balance for this function to work.
  function openPositionAndRevert(OptionMarket.TradeInputParameters memory params) external {
    OptionMarket.Result memory callResult = optionMarket.openPosition(params);
    uint256 totalCost = callResult.totalCost;
    assembly {
      let ptr := mload(0x40)
      mstore(ptr, totalCost)
      revert(ptr, 32)
    }
  }
}
