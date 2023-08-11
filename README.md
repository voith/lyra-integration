# LyraFinance Integration

This project does a basic with integration with lyra finance contracts and test-suite.

### Setup
```bash
git clone https://github.com/voith/lyra-integration.git
yarn
```

### Contracts
   #### StraddleStrategy
      This contract deploys a long straddle strategy by opening equal sized long call and long put options
   - `function getMinCollateral(uint256 strikeId, uint256 size)`
      
    This function calculates the minimum collateral that is needed to execute `buyStraddle`
   
   - `function buyStraddle(uint256 strikeId, uint256 size)`
      

      This is the main entry point for deploying a long straddle strategy for a given `strikeId` and `size`.
      

### Scripts
1. Before running the scripts, start a node in the console
    ```bash
     yarn hardhat node
    ```
2. To buy an option using the local test suite, run the following in a different console
    ```bash
    yarn hardhat run scripts/deployBuyOption.ts
   ```
3. To deploy and test the buyStraddle strategy, run the following in a different console
   ```bash
   yarn hardhat run scripts/testStraddleStrategy.ts
   ```
