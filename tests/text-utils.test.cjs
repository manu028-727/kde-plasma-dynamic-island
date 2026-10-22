const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const { test } = require('node:test');

// Run the same Qt JavaScript helper without requiring a Plasma session.
const source = fs.readFileSync(path.join(__dirname, '../contents/ui/TextUtils.js'), 'utf8');
const text = vm.createContext({});
vm.runInContext(source.replace(/^\.pragma library\s*/, ''), text);

test('cleanText strips markup and decodes entities', () => {
    assert.equal(text.cleanText('<b>Tom &amp; Jerry</b>'), 'Tom & Jerry');
    assert.equal(text.cleanText('&lt;hello&gt;'), '<hello>');
    assert.equal(text.cleanText('&#39;quoted&#39;'), "'quoted'");
    assert.equal(text.cleanText('&#x27;quoted&#x27;'), "'quoted'");
    assert.equal(text.cleanText('a&nbsp;&nbsp;b'), 'a b');
});

test('plainText preserves paragraphs and list items', () => {
    assert.equal(text.plainText('One<br>Two'), 'One\nTwo');
    assert.equal(text.plainText('<p>One</p><p>Two</p>'), 'One\nTwo');
    assert.equal(text.plainText('<ul><li>One</li><li>Two</li></ul>'), '• One\n• Two');
    assert.equal(text.plainText('Line 1\n\n\n\nLine 2'), 'Line 1\n\nLine 2');
});

test('cleanText collapses whitespace and malformed entities stay readable', () => {
    assert.equal(text.cleanText('  a \n\t b  '), 'a b');
    assert.equal(text.cleanText('a &#x110000; b'), 'a \uFFFD b');
    assert.equal(text.cleanText('&amp;lt;'), '&lt;');
});

test('truncate is safe for emoji and accented text', () => {
    assert.equal(text.truncate('😀😀😀😀😀😀', 5), '😀😀😀😀…');
    assert.equal(text.truncate('😀😀', 10), '😀😀');
    assert.equal(text.truncate('hello world', 8), 'hello w…');
    assert.equal(text.truncate('hello', 1), '…');
    assert.equal(text.truncate('hello', 0), '…');
});
