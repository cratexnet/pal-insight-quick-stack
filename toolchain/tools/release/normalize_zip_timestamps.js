'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');

function normalizeExtraTimestamps(buffer, start, length, epochSeconds, label) {
  const end = start + length;
  let offset = start;
  while (offset < end) {
    assert(offset + 4 <= end, `${label} has a truncated ZIP extra-field header`);
    const fieldId = buffer.readUInt16LE(offset);
    const fieldLength = buffer.readUInt16LE(offset + 2);
    const dataStart = offset + 4;
    const next = dataStart + fieldLength;
    assert(next <= end, `${label} has a truncated ZIP extra field`);
    if (fieldId === 0x5455) {
      assert(fieldLength >= 1, `${label} has an empty extended timestamp field`);
      const flags = buffer[dataStart];
      let timestampOffset = dataStart + 1;
      for (let bit = 0; bit < 3; bit += 1) {
        if ((flags & (1 << bit)) === 0) continue;
        assert(timestampOffset + 4 <= next,
          `${label} has a truncated extended timestamp value`);
        buffer.writeUInt32LE(epochSeconds, timestampOffset);
        timestampOffset += 4;
      }
    }
    offset = next;
  }
  assert.equal(offset, end, `${label} ZIP extra fields do not end cleanly`);
}

function normalizeZipExtendedTimestamps(file, epochSeconds) {
  assert(Number.isInteger(epochSeconds) && epochSeconds >= 0
    && epochSeconds <= 0xffffffff,
  'ZIP timestamp epoch must be an unsigned 32-bit integer');
  const buffer = fs.readFileSync(file);
  const minimumEocd = 22;
  const maximumComment = 0xffff;
  let eocd = -1;
  for (let offset = buffer.length - minimumEocd;
    offset >= Math.max(0, buffer.length - minimumEocd - maximumComment);
    offset -= 1) {
    if (buffer.readUInt32LE(offset) === 0x06054b50
      && offset + minimumEocd + buffer.readUInt16LE(offset + 20) === buffer.length) {
      eocd = offset;
      break;
    }
  }
  assert(eocd >= 0, 'ZIP has no end-of-central-directory record');
  assert.equal(buffer.readUInt16LE(eocd + 4), 0, 'ZIP must not span multiple disks');
  assert.equal(buffer.readUInt16LE(eocd + 6), 0,
    'ZIP central directory must stay on the first disk');
  const entryCount = buffer.readUInt16LE(eocd + 10);
  assert.notEqual(entryCount, 0xffff, 'ZIP unexpectedly requires ZIP64');
  let centralOffset = buffer.readUInt32LE(eocd + 16);
  assert.notEqual(centralOffset, 0xffffffff,
    'ZIP central directory unexpectedly requires ZIP64');

  for (let index = 0; index < entryCount; index += 1) {
    assert.equal(buffer.readUInt32LE(centralOffset), 0x02014b50,
      `ZIP central entry ${index} is malformed`);
    const nameLength = buffer.readUInt16LE(centralOffset + 28);
    const extraLength = buffer.readUInt16LE(centralOffset + 30);
    const commentLength = buffer.readUInt16LE(centralOffset + 32);
    const localOffset = buffer.readUInt32LE(centralOffset + 42);
    assert.notEqual(localOffset, 0xffffffff,
      `ZIP entry ${index} unexpectedly requires ZIP64`);
    normalizeExtraTimestamps(buffer, centralOffset + 46 + nameLength,
      extraLength, epochSeconds, `ZIP central entry ${index}`);

    assert.equal(buffer.readUInt32LE(localOffset), 0x04034b50,
      `ZIP local entry ${index} is malformed`);
    const localNameLength = buffer.readUInt16LE(localOffset + 26);
    const localExtraLength = buffer.readUInt16LE(localOffset + 28);
    normalizeExtraTimestamps(buffer, localOffset + 30 + localNameLength,
      localExtraLength, epochSeconds, `ZIP local entry ${index}`);

    centralOffset += 46 + nameLength + extraLength + commentLength;
  }
  fs.writeFileSync(file, buffer);
}

module.exports = { normalizeZipExtendedTimestamps };
