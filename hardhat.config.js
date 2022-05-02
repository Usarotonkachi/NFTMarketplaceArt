require('dotenv').config();
require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-etherscan");

module.exports = {
  defaultNetwork: "matic",
  networks: {
    hardhat: {
    },
    matic: {
      url: "https://rpc-mumbai.maticvigil.com",
      accounts: ["7cabc77209351c828629c77decbeb09a5725bfea645cecd8608e87d221aaddc0"]
    }
  },
  etherscan: {
    apiKey: "FGHT4VSWHKUSGRS6SSZG66NEHKDJYBREAD"
  },
  solidity: {
    version: "0.8.7",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
}