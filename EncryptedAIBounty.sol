// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract EncryptedAIBounty {
    struct Challenge {
        address owner;
        string prompt;
        uint256 reward;
        uint256 submissionDeadline;
        bool judged;
        bool finalized;
        address winner;
        bytes32 revealedBundleHash;
        string revealedBundleRef;
        address[] participants;
        mapping(address => bytes) encryptedAnswerRef;
        mapping(address => bytes) encryptedSymmetricKey;
        mapping(address => bool) hasSubmitted;
    }

    struct ChallengeInfo {
        address owner;
        string prompt;
        uint256 reward;
        uint256 submissionDeadline;
        bool judged;
        bool finalized;
        address winner;
        bytes32 revealedBundleHash;
        string revealedBundleRef;
        uint256 participantCount;
    }

    uint256 public challengeCounter;
    mapping(uint256 => Challenge) public challenges;

    address public ritualTEE = 0x0000000000000000000000000000000000000000; // Placeholder for actual TEE address

    event ChallengeCreated(uint256 indexed id, address indexed owner, uint256 reward);
    event EncryptedSubmission(uint256 indexed id, address indexed participant);
    event JudgmentComplete(uint256 indexed id, bytes32 bundleHash);
    event WinnerFinalized(uint256 indexed id, address indexed winner);

    modifier challengeExists(uint256 id) {
        require(challenges[id].owner != address(0), "Challenge does not exist");
        _;
    }

    modifier onlySubmissionPhase(uint256 id) {
        require(block.timestamp <= challenges[id].submissionDeadline, "Submission phase ended");
        _;
    }

    modifier onlyAfterSubmission(uint256 id) {
        require(block.timestamp > challenges[id].submissionDeadline, "Submission phase not over");
        _;
    }

    modifier onlyOwner(uint256 id) {
        require(msg.sender == challenges[id].owner, "Not challenge owner");
        _;
    }

    modifier onlyTEE() {
        require(msg.sender == ritualTEE, "Only TEE can call");
        _;
    }

    modifier notFinalized(uint256 id) {
        require(!challenges[id].finalized, "Already finalized");
        _;
    }

    function createChallenge(
        string calldata prompt,
        uint256 submissionDeadline
    ) external payable {
        require(msg.value > 0, "Reward must be > 0 RIT");
        require(submissionDeadline > block.timestamp, "Deadline must be in future");

        uint256 id = challengeCounter++;
        Challenge storage c = challenges[id];
        c.owner = msg.sender;
        c.prompt = prompt;
        c.reward = msg.value;
        c.submissionDeadline = submissionDeadline;

        emit ChallengeCreated(id, msg.sender, msg.value);
    }

    function submitEncryptedAnswer(
        uint256 id,
        bytes calldata encryptedRef,
        bytes calldata encryptedKey
    ) external 
        challengeExists(id)
        onlySubmissionPhase(id)
    {
        Challenge storage c = challenges[id];
        require(!c.hasSubmitted[msg.sender], "Already submitted");

        c.encryptedAnswerRef[msg.sender] = encryptedRef;
        c.encryptedSymmetricKey[msg.sender] = encryptedKey;
        c.hasSubmitted[msg.sender] = true;
        c.participants.push(msg.sender);

        emit EncryptedSubmission(id, msg.sender);
    }

    function judgeAll(uint256 id, bytes calldata teePayload) external 
        challengeExists(id)
        onlyOwner(id)
        onlyAfterSubmission(id)
    {
        Challenge storage c = challenges[id];
        require(c.participants.length > 0, "No participants");
        require(!c.judged, "Already judged");

        c.judged = true;

        emit JudgmentComplete(id, bytes32(0));
    }

    function onJudgmentComplete(
        uint256 id,
        bytes32 bundleHash,
        string calldata bundleRef
    ) external onlyTEE {
        Challenge storage c = challenges[id];
        require(c.judged, "Not judged yet");
        require(!c.finalized, "Already finalized");

        c.revealedBundleHash = bundleHash;
        c.revealedBundleRef = bundleRef;

        emit JudgmentComplete(id, bundleHash);
    }

    function finalizeWinner(uint256 id, address winner) external 
        challengeExists(id)
        onlyOwner(id)
        onlyAfterSubmission(id)
        notFinalized(id)
    {
        Challenge storage c = challenges[id];
        require(c.judged, "Must judge first");
        require(c.hasSubmitted[winner], "Winner must have submitted");
        require(c.revealedBundleHash != bytes32(0), "Bundle not revealed");

        c.finalized = true;
        c.winner = winner;

        payable(winner).transfer(c.reward);

        emit WinnerFinalized(id, winner);
    }

    function getChallengeInfo(uint256 id) external view returns (ChallengeInfo memory) {
        Challenge storage c = challenges[id];
        return ChallengeInfo({
            owner: c.owner,
            prompt: c.prompt,
            reward: c.reward,
            submissionDeadline: c.submissionDeadline,
            judged: c.judged,
            finalized: c.finalized,
            winner: c.winner,
            revealedBundleHash: c.revealedBundleHash,
            revealedBundleRef: c.revealedBundleRef,
            participantCount: c.participants.length
        });
    }

    function getEncryptedAnswer(uint256 id, address participant) external view returns (bytes memory) {
        require(msg.sender == challenges[id].owner || msg.sender == participant, "Not authorized");
        return challenges[id].encryptedAnswerRef[participant];
    }

    function getEncryptedKey(uint256 id, address participant) external view returns (bytes memory) {
        require(msg.sender == challenges[id].owner || msg.sender == participant, "Not authorized");
        return challenges[id].encryptedSymmetricKey[participant];
    }

    function getParticipants(uint256 id) external view returns (address[] memory) {
        return challenges[id].participants;
    }

    function hasSubmitted(uint256 id, address participant) external view returns (bool) {
        return challenges[id].hasSubmitted[participant];
    }
}
