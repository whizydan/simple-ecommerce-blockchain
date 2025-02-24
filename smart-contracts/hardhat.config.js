require("@nomicfoundation/hardhat-ethers");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.28",
  networks: {
    ganache: {
      url: 'HTTP://127.0.0.1:7545', // Use your local IP address here
      accounts: ['0x8bf7f0eb93096c07eb4fc2ba8152f5a72ff510e79d12096c376f4fd65b79aaf6']  // Use your Ganache account private key
    }
  }
};
