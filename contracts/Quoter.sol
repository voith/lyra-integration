//SPDX-License-Identifier:ISC
pragma solidity 0.8.16;
import {OptionMarket} from "@lyrafinance/protocol/contracts/OptionMarket.sol";
import {QuoterHelper} from "./QuoterHelper.sol";

/// @title Provides quote for opening an option
/// @notice Calculates the total cost of opening an option with actually opening an option
/// @dev This contract is inspired by UniswapV3 periphery contracts.
contract Quoter {
  QuoterHelper internal quoteHelper;

  constructor(address _quoteHelper) {
    quoteHelper = QuoterHelper(_quoteHelper);
  }

  /// @notice Calculates the total cost of opening an option
  function quoteOpenPosition(OptionMarket.TradeInputParameters memory params) external returns (uint256) {
    try quoteHelper.openPositionAndRevert(params) {} catch (bytes memory reason) {
      return parseRevertReason(reason);
    }
  }

  /// @dev Parses a revert reason that should contain the numeric quote
  function parseRevertReason(bytes memory reason) private pure returns (uint256) {
    if (reason.length != 32) {
      if (reason.length < 68) revert("Unexpected error");
      assembly {
        reason := add(reason, 0x04)
      }
      revert(abi.decode(reason, (string)));
    }
    return abi.decode(reason, (uint256));
  }
}
