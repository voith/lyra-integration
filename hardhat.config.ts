import "@nomiclabs/hardhat-ethers";
import { HardhatUserConfig } from "hardhat/config";
import "hardhat-dependency-compiler";
import { lyraContractPaths } from "@lyrafinance/protocol/dist/test/utils/package/index-paths";

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.16",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000,
      },
    },
  },
  allowUnlimitedContractSize: true,
  dependencyCompiler: {
    paths: lyraContractPaths,
  },
};

export default config;
