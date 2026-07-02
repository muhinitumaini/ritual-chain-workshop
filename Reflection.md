# Reflection: Ritual-Native Encrypted Submissions

This variant uses Ritual's TEE for privacy-preserving AI judging, which is more advanced than the standard commit-reveal pattern.

Public vs Hidden: Encrypted answer refs and TEE-encrypted keys are public. The actual answers are hidden until the TEE decrypts them during judging.

AI vs Human: The AI (LLM) does the judging inside the TEE. The human (owner) only finalizes the winner, maintaining accountability.

Advantages over commit-reveal: No reveal phase means answers are never exposed before judging, even to the owner. This provides stronger privacy guarantees.

Trade-off: Requires TEE infrastructure, but offers complete privacy and verifiable execution.
