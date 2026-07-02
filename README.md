# EncryptedAIBounty – Ritual-Native Encrypted Submissions

This contract uses Ritual's TEE (Trusted Execution Environment) to handle encrypted submissions. Answers are encrypted before submission and only decrypted inside the TEE for AI judging, ensuring complete privacy.

## How it works
1. Participants encrypt their answers with a symmetric key
2. The symmetric key is encrypted with the TEE public key
3. Both encrypted refs are stored on-chain
4. After deadline, owner triggers TEE judging
5. TEE decrypts, runs LLM, and returns results
6. Owner finalizes the winner

## Why encryption?
Answers stay completely hidden until after judging – no reveal phase needed.

## Contract Address (Ritual Testnet)
0x09Bb1faec065404948F06883B7C83BeD82FF682B

## Network
Ritual Chain Testnet (ID: 1979)

## Native Token
RIT (Ritual Token) – 18 decimals

## TEE Address
0xYOUR_TEE_ADDRESS
