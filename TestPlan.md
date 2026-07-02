# Test Plan – EncryptedAIBounty

- Happy path: 2 participants submit encrypted answers → judge → finalize winner
- Cannot submit after deadline (reverts)
- Only owner can judge (reverts for others)
- Cannot judge before deadline (reverts)
- TEE callback updates bundle hash
