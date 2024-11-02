require("@nomicfoundation/hardhat-toolbox");
const YOUR_PRIVATE_KEY=`fb905d07769b7dc708a318d0407134e4f90c6622ff0e429ba59f233c00e7c0d2`
/** @type import('hardhat/config').HardhatUserConfig */
/** @type import('hardhat/config').HardhatUserConfig */
require("@xyrusworx/hardhat-solidity-json");
module.exports = {
  solidity: "0.8.9",
  networks: {
    matic: {
      url: "https://rpc-mumbai.maticvigil.com",
      accounts: [`0x${YOUR_PRIVATE_KEY}`],
    },
  },
  etherscan: {
    apiKey: "UTZ66AFSB94PI4QF5D7EVDWAV19HWU2G1X"
  }
};
