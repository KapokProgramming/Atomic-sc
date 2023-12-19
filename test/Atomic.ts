import {
	time,
	loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("Atomic", function () {
	// We define a fixture to reuse the same setup in every test.
	// We use loadFixture to run this setup once, snapshot that state,
	// and reset Hardhat Network to that snapshot in every test.
	async function deploy() {
		const [owner, user_1, user_2, user_3, user_4, user_5] =
			await ethers.getSigners();

		const Atomic = await ethers.getContractFactory("Atomic");
		const atomic = await Atomic.deploy();
		atomic.connect(user_1).setNearID("jamieoliver.near");
		atomic.connect(user_2).setNearID("jamieoliver.near");
		atomic.connect(user_3).setNearID("kan_k.near");

		return { atomic, owner, user_1, user_2, user_3, user_4, user_5 };
	}

	describe("Withdrawals", function () {
		describe("Transfers", function () {
			it("Paid Comment n-1", async function () {
				const { atomic, owner, user_1, user_2, user_3, user_4 } =
					await loadFixture(deploy);
				var amount_tx = 1_000_000;
				var amount_owner = amount_tx * 0.1;
				var amount_user_1 = amount_tx - amount_owner;
				atomic.connect(user_1).addVideo("J1", "J1", "J1", "J1", 0, []);
				await expect(
					atomic.connect(user_4).addComment(1, "Hello", {
						value: amount_tx,
					})
				).to.changeEtherBalances(
					[user_4, owner, user_1],
					[-amount_tx, amount_owner, amount_user_1]
				);
			});
			it("Paid Comment n-2", async function () {
				const { atomic, owner, user_1, user_2, user_3, user_4 } =
					await loadFixture(deploy);
				var amount_tx = 1_000_000;
				var amount_owner = amount_tx * 0.1;
				var amount_users = (amount_tx - amount_owner) / 2;
				atomic.connect(user_1).addVideo("J1", "J1", "J1", "J1", 0, []);
				atomic.connect(user_2).addVideo("J2", "J2", "J2", "J2", 1, []);
				atomic.connect(user_2).setAttributions(2, [1]);
				await expect(
					atomic.connect(user_4).addComment(2, "Hello", {
						value: amount_tx,
					})
				).to.changeEtherBalances(
					[user_4, owner, user_1, user_2],
					[-amount_tx, amount_owner, amount_users, amount_users]
				);
			});
			it("Paid Comment n-3", async function () {
				const { atomic, owner, user_1, user_2, user_3, user_4 } =
					await loadFixture(deploy);
				var amount_tx = 1_000_000;
				var amount_owner = amount_tx * 0.1;
				var amount_users = (amount_tx - amount_owner) / 3;
				atomic.connect(user_1).addVideo("J1", "J1", "J1", "J1", 1, []);
				atomic.connect(user_2).addVideo("J2", "J2", "J2", "J2", 2, []);
				atomic.connect(user_2).setAttributions(2, [1]);
				atomic.connect(user_3).addVideo("K1", "K1", "K1", "K1", 3, []);
				atomic.connect(user_3).setAttributions(3, [2]);
				await expect(
					atomic.connect(user_4).addComment(3, "Hello", {
						value: amount_tx,
					})
				).to.changeEtherBalances(
					[user_4, owner, user_1, user_2, user_3],
					[
						-amount_tx,
						amount_owner,
						amount_users,
						amount_users,
						amount_users,
					]
				);
			});
			it("Paid Comment n-4", async function () {
				const { atomic, owner, user_1, user_2, user_3, user_4, user_5 } =
					await loadFixture(deploy);
				var amount_tx = 1_000_000;
				var amount_owner = amount_tx * 0.1;
				var amount_users = (amount_tx - amount_owner) / 4;
				atomic.connect(user_1).addVideo("J1", "J1", "J1", "J1", 1, []);
				atomic.connect(user_2).addVideo("J2", "J2", "J2", "J2", 2, []);
				atomic.connect(user_2).setAttributions(2, [1]);
				atomic.connect(user_3).addVideo("K1", "K1", "K1", "K1", 3, []);
				atomic.connect(user_3).setAttributions(3, [2]);
				atomic.connect(user_4).addVideo("N1", "N1", "N1", "N1", 4, []);
				atomic.connect(user_4).setAttributions(4, [3]);
				await expect(
					atomic.connect(user_5).addComment(4, "Hello", {
						value: amount_tx,
					})
				).to.changeEtherBalances(
					[user_5, owner, user_1, user_2, user_3, user_4],
					[
						-amount_tx,
						amount_owner,
						amount_users,
						amount_users,
						amount_users,
						amount_users
					]
				);
			});
		});
	});
});
