# CloudKit Server Examples (server-to-server)

Sadržaj:
- scripts/generate_jwt_node.js
- scripts/generate_jwt_python.py
- examples/cloudkit_client_node.js
- swift/CloudKitServerExamples.swift
- .github/workflows/cloudkit-server-example.yml

Security checklist:
- NEVER commit AuthKey_*.p8 into git.
- Store private key contents in CI secrets (e.g., GitHub Secrets -> APPLE_P8, APPLE_KEY_ID, APPLE_TEAM_ID).
- Use short-lived JWTs (<= 60 min).
- Restrict which CI runners / deploy keys have access to secrets.
- Log minimal information; never print full .p8 or persist in build logs.
- Use Development environment for testing. Promote schema to Production only after verification.

CI usage:
- Set following secrets in repository or org:
  - APPLE_P8 (content of .p8)
  - APPLE_KEY_ID
  - APPLE_TEAM_ID
  - CLOUDKIT_CONTAINER

Local usage:
- Run scripts/generate_jwt_node.js with env vars or run Python script with env vars.
- Use the returned JWT in Authorization: Bearer <JWT> header when calling CloudKit REST.
