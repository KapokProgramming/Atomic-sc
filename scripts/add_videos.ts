import { ethers } from "hardhat";
async function main() {
	const [user] = await ethers.getSigners();
	const atomic = await ethers.getContractAt(
		"Atomic",
		process.env.ATOMIC_ADDR!,
		user
	);
	// console.log(
	// 	await atomic.addVideo(
	// 		{
	// 			_title: "man jogging on the beach",
	// 			_description: "man jogging on the beach",
	// 			_url: "https://cdn.coverr.co/videos/coverr-man-jogging-on-the-beach-1390/1080p.mp4",
	// 			_thumb_url:
	// 				"https://cdn.coverr.co/videos/coverr-man-jogging-on-the-beach-1390/thumbnail?width=640",
	// 			_duration: 12,
	// 			_keywords: ["man", "jogging", "beach"],
	// 		},
	// 		[],
	// 		"jamieoliver.near"
	// 	)
	// );
	console.log(
		await atomic.addComment(4, "test comment", {
			value: ethers.parseEther("0.25"),
		})
	);
}

main();
