/*
  cloudkit_client_node.js
  Minimal CloudKit REST wrapper (public DB lookup example).
  Usage: set CLOUDKIT_JWT or call generate_jwt_node.js and pipe result.
*/
const https = require('https');

function postJson(url, jwt, body) {
  return new Promise((resolve, reject) => {
    const u = new URL(url);
    const payload = JSON.stringify(body);
    const opts = {
      method: 'POST',
      hostname: u.hostname,
      path: u.pathname + u.search,
      headers: {
        'Authorization': 'Bearer ' + jwt,
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(payload)
      }
    };
    const req = https.request(opts, res => {
      let data = '';
      res.on('data', c => data += c);
      res.on('end', () => {
        try { resolve({ status: res.statusCode, body: JSON.parse(data) }); }
        catch (e) { resolve({ status: res.statusCode, body: data }); }
      });
    });
    req.on('error', reject);
    req.write(payload);
    req.end();
  });
}

// Example usage:
if (require.main === module) {
  (async () => {
    const jwt = process.env.CLOUDKIT_JWT;
    const container = process.env.CLOUDKIT_CONTAINER;
    if (!jwt || !container) { console.error('Set CLOUDKIT_JWT and CLOUDKIT_CONTAINER'); process.exit(2); }
    const url = `https://api.apple-cloudkit.com/database/1/${container}/production/public/records/lookup`;
    const body = { records: [{ recordName: 'someRecordID' }] };
    const res = await postJson(url, jwt, body);
    console.log(res.status, res.body);
  })().catch(e => { console.error(e); process.exit(1); });
}
module.exports = { postJson };
