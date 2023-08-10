import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import 'hardhat-dependency-compiler';
import { lyraContractPaths } from '@lyrafinance/protocol/dist/test/utils/package/index-paths';

const config: HardhatUserConfig = {
  solidity: "0.8.16",
  dependencyCompiler: {
    paths: lyraContractPaths,
  }
};

export default config;
