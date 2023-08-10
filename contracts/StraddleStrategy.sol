//SPDX-License-Identifier:ISC
pragma solidity 0.8.16;

import {IOptionMarket} from "@lyrafinance/protocol/contracts/interfaces/IOptionMarket.sol";

contract StraddleStrategy {

    IOptionMarket public optionMarket;

    constructor(address _optionMarket) {
        optionMarket = IOptionMarket(_optionMarket);
    }
    // TODO: This function is added as a placeholder for testing.
    // This needs to be replaced by a buyStraddle function.
    function openPosition(IOptionMarket.TradeInputParameters memory params) external {
        optionMarket.openPosition(params);
    }
}
