export async function removeBackgroundFromPng(inputBytes: Buffer): Promise<Buffer> {
  const apiKey = process.env.REMOVE_BG_API_KEY;
  console.log('CATDEX_BG_REMOVAL_STARTED');
  console.log('CATDEX_BG_REMOVAL_METHOD', 'removebg');
  console.log('CATDEX_BG_REMOVAL_KEY_PRESENT', Boolean(apiKey));

  if (!apiKey) {
    console.log('CATDEX_BG_REMOVAL_SKIPPED', 'missing_REMOVE_BG_API_KEY');
    console.log('CATDEX_BG_REMOVAL_SUCCESS', false);
    return inputBytes;
  }

  try {
    const form = new FormData();
    form.append('image_file', new Blob([bufferToArrayBuffer(inputBytes)], { type: 'image/png' }), 'illustrated-cat.png');
    form.append('size', 'auto');
    form.append('format', 'png');

    const response = await fetch('https://api.remove.bg/v1.0/removebg', {
      method: 'POST',
      headers: {
        'X-Api-Key': apiKey,
      },
      body: form,
    });

    if (!response.ok) {
      const error = await response.text();
      console.log('CATDEX_BG_REMOVAL_SUCCESS', false);
      console.log('CATDEX_BG_REMOVAL_ERROR', error || `removebg_error_${response.status}`);
      return inputBytes;
    }

    const outputBytes = Buffer.from(await response.arrayBuffer());
    console.log('CATDEX_BG_REMOVAL_SUCCESS', true);
    return outputBytes;
  } catch (error) {
    console.log('CATDEX_BG_REMOVAL_SUCCESS', false);
    console.log('CATDEX_BG_REMOVAL_ERROR', error instanceof Error ? error.message : String(error));
    return inputBytes;
  }
}

function bufferToArrayBuffer(buffer: Buffer): ArrayBuffer {
  return buffer.buffer.slice(buffer.byteOffset, buffer.byteOffset + buffer.byteLength) as ArrayBuffer;
}
