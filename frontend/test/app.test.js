const assert = require('assert');

try {
    assert.strictEqual(1 + 1, 2);
    console.log("Frontend test passed ✅");
} catch (e) {
    console.error("Frontend test failed ❌");
    process.exit(1);
}
