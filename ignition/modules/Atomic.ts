import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("Atomic", (m) => {
	const contract = m.contract("Atomic");

	return { contract };
});
