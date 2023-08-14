# LyraFinance Integration

This project does a basic with integration with lyra finance contracts and test-suite.

### Setup
```bash
git clone https://github.com/voith/lyra-integration.git
yarn setup
```

### Contracts
   #### StraddleStrategy
      This contract deploys a long straddle strategy by opening equal sized long call and long put options
   - `function quoteBuyStraddle(uint256 strikeId, uint256 size)`
      
      
      returns the cost for executing `buyStraddle`
   
   - `function buyStraddle(uint256 strikeId, uint256 size, uint256 maxCost)`
      

      deploys a long straddle strategy for a given `strikeId` and `size`. `maxCost` is the maximum amount of tokens the user is willing to pay to execute this function.

   #### Quoter
      Calculates the total cost of opening an option with actually opening an option.
   - `function quoteOpenPosition(OptionMarket.TradeInputParameters memory params)`


      returns the total cost of opening an option with given parameters.
      

### Scripts
1. Before running the scripts, start a node in the console
    ```bash
     yarn hardhat node
    ```
2. To buy an option using the local test suite, run the following in a different console
    ```bash
    yarn hardhat run scripts/deployBuyOption.ts
   ```
3. To deploy and test the buyStraddle functionality, run the following in a different console
   ```bash
   yarn hardhat run scripts/testStraddleStrategy.ts
   ```
