import { HardhatUserConfig } from "hardhat/config";

import "@typechain/hardhat";
import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-chai-matchers";
import "@nomicfoundation/hardhat-ignition-ethers";

const config: HardhatUserConfig = {
	solidity: {
		version: "0.8.22",
		settings: {
			optimizer: {
				enabled: true,
				runs: 10000,
				details: {
					yul: true,
				},
			},
		},
	},
	networks: {
		bitkub_mainnet: {
			url: `https://rpc.bitkubchain.io`,
			accounts: [
				process.env.WALLET_PK
					? process.env.WALLET_PK
					: "0x0000000000000000000000000000000000000000000000000000000000000000",
			],
			gasPrice: "auto",
		},
		bitkub_testnet: {
			url: `https://rpc-testnet.bitkubchain.io`,
			accounts: [
				process.env.WALLET_PK
					? process.env.WALLET_PK
					: "0x0000000000000000000000000000000000000000000000000000000000000000",
			],
			gasPrice: "auto",
		},
	},
	etherscan: {
		apiKey: {
			"Bitkub Testnet": "env-test",
		},
		customChains: [
			{
				network: "Bitkub Testnet",
				chainId: 25925,
				urls: {
					apiURL: "https://rpc-testnet.bitkubchain.io",
					browserURL: "https://testnet.bkcscan.com/",
				},
			},
		],
	},
	sourcify: {
		enabled: false,
	},
};

export default config;
