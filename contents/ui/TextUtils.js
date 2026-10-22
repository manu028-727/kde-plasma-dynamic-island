.pragma library

// Notification bodies and summaries sometimes contain a small amount of HTML.
// Keep the conversion in one place so titles and bodies are handled consistently.
function codePointToString(code) {
    if (!isFinite(code) || code < 0 || code > 0x10FFFF)
        return "\uFFFD";

    if (code <= 0xFFFF)
        return String.fromCharCode(code);

    const value = code - 0x10000;
    return String.fromCharCode(0xD800 + (value >> 10), 0xDC00 + (value & 0x3FF));
}

function decodeEntities(text) {
    return String(text || "")
        .replace(/&#x([0-9a-f]+);/gi, function(match, hex) {
            return codePointToString(parseInt(hex, 16));
        })
        .replace(/&#(\d+);/g, function(match, decimal) {
            return codePointToString(parseInt(decimal, 10));
        })
        .replace(/&nbsp;/gi, " ")
        .replace(/&hellip;/gi, "…")
        .replace(/&mdash;/gi, "—")
        .replace(/&ndash;/gi, "–")
        .replace(/&lsquo;/gi, "‘")
        .replace(/&rsquo;/gi, "’")
        .replace(/&ldquo;/gi, "“")
        .replace(/&rdquo;/gi, "”")
        .replace(/&lt;/gi, "<")
        .replace(/&gt;/gi, ">")
        .replace(/&quot;/gi, "\"")
        .replace(/&#39;|&apos;/gi, "'")
        // Keep ampersand last so already-encoded entities are not decoded twice.
        .replace(/&amp;/gi, "&");
}

function plainText(text) {
    const withoutTags = String(text || "")
        .replace(/<br\s*\/?\s*>/gi, "\n")
        .replace(/<\/(p|div|li)\s*>/gi, "\n")
        .replace(/<li(?:\s[^>]*)?>/gi, "• ")
        .replace(/<[^>]*>/g, "");

    return decodeEntities(withoutTags)
        .replace(/\r\n?/g, "\n")
        .replace(/[\t\f\v ]+/g, " ")
        .replace(/ *\n */g, "\n")
        .replace(/\n{3,}/g, "\n\n")
        .trim();
}

function cleanText(text) {
    return plainText(text).replace(/\s+/g, " ").trim();
}

// Truncate by Unicode code point so emoji and other surrogate pairs are not
// split in half. Grapheme clusters (emoji modifiers) may still be split.
function truncate(text, limit) {
    const string = String(text || "");
    const numericLimit = Number(limit);
    const maximum = isFinite(numericLimit) ? Math.max(1, Math.round(numericLimit)) : 1;
    const characters = Array.from(string);
    if (characters.length <= maximum)
        return string;
    if (maximum === 1)
        return "…";

    return characters.slice(0, maximum - 1).join("").replace(/\s+$/, "") + "…";
}
