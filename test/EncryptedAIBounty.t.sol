// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "forge-std/Test.sol";
import "../src/EncryptedAIBounty.sol";

contract EncryptedAIBountyTest is Test {
    EncryptedAIBounty public bounty;
    address owner = address(0x1);
    address alice = address(0x2);
    address bob = address(0x3);
    uint256 challengeId;
    uint256 reward = 1 ether;
    bytes encryptedRef = bytes("ipfs://encrypted-answer");
    bytes encryptedKey = bytes("encrypted-symmetric-key");

    function setUp() public {
        vm.deal(owner, 10 ether);
        vm.deal(alice, 1 ether);
        vm.deal(bob, 1 ether);
        bounty = new EncryptedAIBounty();
        vm.startPrank(owner);
        uint256 submissionDeadline = block.timestamp + 1 days;
        bounty.createChallenge{value: reward}("Test", submissionDeadline);
        challengeId = 0;
        vm.stopPrank();
    }

    function testFullFlow() public {
        vm.startPrank(alice);
        bounty.submitEncryptedAnswer(challengeId, encryptedRef, encryptedKey);
        vm.stopPrank();

        vm.startPrank(bob);
        bounty.submitEncryptedAnswer(challengeId, encryptedRef, encryptedKey);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 days + 1);

        vm.startPrank(owner);
        bounty.judgeAll(challengeId, bytes(""));
        vm.stopPrank();

        vm.startPrank(address(0x0));
        bounty.onJudgmentComplete(challengeId, keccak256("bundle"), "ipfs://bundle");
        vm.stopPrank();

        vm.startPrank(owner);
        bounty.finalizeWinner(challengeId, bob);
        vm.stopPrank();

        EncryptedAIBounty.ChallengeInfo memory info = bounty.getChallengeInfo(challengeId);
        assertTrue(info.finalized);
        assertEq(info.winner, bob);
        assertEq(bob.balance, 1 ether + reward);
    }

    function testCannotSubmitAfterDeadline() public {
        vm.warp(block.timestamp + 1 days + 1);
        vm.startPrank(alice);
        vm.expectRevert("Submission phase ended");
        bounty.submitEncryptedAnswer(challengeId, encryptedRef, encryptedKey);
        vm.stopPrank();
    }

    function testOnlyOwnerCanJudge() public {
        vm.warp(block.timestamp + 1 days + 1);
        vm.startPrank(alice);
        vm.expectRevert("Not challenge owner");
        bounty.judgeAll(challengeId, bytes(""));
        vm.stopPrank();
    }

    function testCannotJudgeBeforeDeadline() public {
        vm.startPrank(owner);
        vm.expectRevert("Submission phase not over");
        bounty.judgeAll(challengeId, bytes(""));
        vm.stopPrank();
    }
}
