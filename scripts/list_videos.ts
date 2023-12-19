import { ethers } from "hardhat";

async function main() {
	const [user] = await ethers.getSigners();
	const atomic = await ethers.getContractAt(
		"Atomic",
		process.env.ATOMIC_ADDR!,
		user
	);

	console.log(await atomic.getLatestVideos(5));
}

main();
