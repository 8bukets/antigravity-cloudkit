/*
  generate_jwt_node.js
  Node.js example using jose to sign a JWT with ES256 (.p8 key).
  Usage:
    NODE_P8_PATH=./AuthKey_ABC.p8 NODE_KEY_ID=ABC... NODE_TEAM_ID=TEAM... NODE_CONTAINER=iCloud.com.example.node node scripts/generate_jwt_node.js
*/
const fs = require('fs');
const { SignJWT, importPKCS8 } = require('jose');

async function makeJwt() {
  const p8Path = process.env.NODE_P8_PATH;
  const keyId = process.env.NODE_KEY_ID;
  const teamId = process.env.NODE_TEAM_ID;
  const container = process.env.NODE_CONTAINER || process.env.CLOUDKIT_CONTAINER;
  if (!p8Path || !keyId || !teamId || !container) {
    console.error('Missing env vars: NODE_P8_PATH, NODE_KEY_ID, NODE_TEAM_ID, NODE_CONTAINER');
    process.exit(2);
  }
  const privateKeyPem = fs.readFileSync(p8Path, 'utf8');
  const key = await importPKCS8(privateKeyPem, 'ES256');

  const jwt = await new SignJWT({ sub: container })
    .setProtectedHeader({ alg: 'ES256', kid: keyId })
    .setIssuer(teamId)
    .setAudience('https://appleid.apple.com')
    .setIssuedAt()
    .setExpirationTime('60m')
    .sign(key);

  console.log(jwt);
}

makeJwt().catch(err => { console.error(err); process.exit(1); });
