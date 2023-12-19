import { ethers } from "hardhat";
async function main() {
	const [user] = await ethers.getSigners();
	const atomic = await ethers.getContractAt(
		"Atomic",
		process.env.ATOMIC_ADDR!,
		user
	);
	console.log(await atomic.setNearID("jamieoliver.near"));
	console.log(
		await atomic.addVideo(
			"man jogging on the beach",
			"man jogging on the beach",
			"https://cdn.coverr.co/videos/coverr-man-jogging-on-the-beach-1390/1080p.mp4",
			"https://cdn.coverr.co/videos/coverr-man-jogging-on-the-beach-1390/thumbnail?width=640",
			12,
			["man", "jogging", "beach"]
		)
	);
}

main();
