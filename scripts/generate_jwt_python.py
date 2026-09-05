#!/usr/bin/env python3
# generate_jwt_python.py
# Usage:
#   env: PY_P8_PATH, PY_KEY_ID, PY_TEAM_ID, PY_CONTAINER
#   python3 scripts/generate_jwt_python.py

import os, time, sys
import jwt

p8_path = os.environ.get('PY_P8_PATH')
key_id = os.environ.get('PY_KEY_ID')
team_id = os.environ.get('PY_TEAM_ID')
container = os.environ.get('PY_CONTAINER') or os.environ.get('CLOUDKIT_CONTAINER')

if not all([p8_path, key_id, team_id, container]):
    print("Missing env vars: PY_P8_PATH, PY_KEY_ID, PY_TEAM_ID, PY_CONTAINER")
    sys.exit(2)

with open(p8_path, 'r') as f:
    private_key = f.read()

now = int(time.time())
payload = {
    'iss': team_id,
    'sub': container,
    'aud': 'https://appleid.apple.com',
    'iat': now,
    'exp': now + 3600
}
headers = {'kid': key_id}

token = jwt.encode(payload, private_key, algorithm='ES256', headers=headers)
# PyJWT returns bytes in some versions, ensure str
if isinstance(token, bytes):
    token = token.decode('utf-8')
print(token)
