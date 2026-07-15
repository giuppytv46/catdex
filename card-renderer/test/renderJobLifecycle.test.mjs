import assert from 'node:assert/strict';
import test from 'node:test';

import { resolveRenderJob } from '../lib/pipeline/renderJobLifecycle.ts';

test('request timeout keeps one active job and retry reuses it', async () => {
  const jobs = new Map();
  const deferred = createDeferred();
  let generateCalls = 0;
  let completedCalls = 0;
  let removedCalls = 0;

  const options = {
    jobs,
    key: 'card:discovery-1:v1',
    readCompleted: async () => undefined,
    createJob: () => {
      generateCalls += 1;
      return deferred.promise;
    },
    onCompleted: () => {
      completedCalls += 1;
    },
    onRemoved: () => {
      removedCalls += 1;
    },
  };

  const first = await resolveRenderJob(options);
  assert.equal(first.kind, 'active');
  assert.equal(first.created, true);
  assert.equal(generateCalls, 1);
  assert.equal(jobs.size, 1);

  await assert.rejects(
    waitWithTimeout(first.job, 5, 'CARD_GENERATION_TIMEOUT'),
    (error) => error?.code === 'CARD_GENERATION_TIMEOUT',
  );
  assert.equal(jobs.size, 1, 'HTTP timeout must not remove the underlying job');

  const second = await resolveRenderJob(options);
  assert.equal(second.kind, 'active');
  assert.equal(second.created, false);
  assert.equal(second.job, first.job);
  assert.equal(generateCalls, 1, 'two requests must create one AI job');

  const output = createOutput();
  deferred.resolve(output);
  assert.deepEqual(await second.job, output);
  await nextTurn();

  assert.equal(completedCalls, 1);
  assert.equal(removedCalls, 1);
  assert.equal(jobs.size, 0);
});

test('completed stored artifact skips generation entirely', async () => {
  const jobs = new Map();
  const output = createOutput();
  let generateCalls = 0;
  let existingResultCalls = 0;

  const resolution = await resolveRenderJob({
    jobs,
    key: 'card:discovery-1:v1',
    readCompleted: async () => output,
    createJob: async () => {
      generateCalls += 1;
      return output;
    },
    onExistingResult: () => {
      existingResultCalls += 1;
    },
  });

  assert.equal(resolution.kind, 'completed');
  assert.deepEqual(resolution.result, output);
  assert.equal(generateCalls, 0);
  assert.equal(existingResultCalls, 1);
  assert.equal(jobs.size, 0);
});

test('completed job is read from storage on the next request', async () => {
  const jobs = new Map();
  const deferred = createDeferred();
  const output = createOutput();
  let storedResult;
  let generateCalls = 0;

  const options = {
    jobs,
    key: 'card:discovery-1:v1',
    readCompleted: async () => storedResult,
    createJob: () => {
      generateCalls += 1;
      return deferred.promise;
    },
  };

  const first = await resolveRenderJob(options);
  storedResult = output;
  deferred.resolve(output);
  assert.deepEqual(await first.job, output);
  await nextTurn();

  const retry = await resolveRenderJob(options);
  assert.equal(retry.kind, 'completed');
  assert.deepEqual(retry.result, output);
  assert.equal(generateCalls, 1);
});

test('permanently failed job is removed and a later request may start once', async () => {
  const jobs = new Map();
  const firstDeferred = createDeferred();
  const secondDeferred = createDeferred();
  let generateCalls = 0;
  let failedCalls = 0;
  let removedCalls = 0;
  let unhandledRejection;
  const onUnhandledRejection = (error) => {
    unhandledRejection = error;
  };
  process.once('unhandledRejection', onUnhandledRejection);

  const options = {
    jobs,
    key: 'card:discovery-1:v1',
    readCompleted: async () => undefined,
    createJob: () => {
      generateCalls += 1;
      return generateCalls === 1 ? firstDeferred.promise : secondDeferred.promise;
    },
    onFailed: () => {
      failedCalls += 1;
    },
    onRemoved: () => {
      removedCalls += 1;
    },
  };

  try {
    const first = await resolveRenderJob(options);
    const reused = await resolveRenderJob(options);
    assert.equal(reused.job, first.job);
    assert.equal(generateCalls, 1);

    firstDeferred.reject(new Error('permanent failure'));
    await assert.rejects(first.job, /permanent failure/);
    await nextTurn();

    assert.equal(jobs.size, 0);
    assert.equal(failedCalls, 1);
    assert.equal(removedCalls, 1);

    const restarted = await resolveRenderJob(options);
    assert.equal(restarted.kind, 'active');
    assert.equal(restarted.created, true);
    assert.equal(generateCalls, 2);

    secondDeferred.resolve(createOutput());
    await restarted.job;
    await nextTurn();
    assert.equal(jobs.size, 0);
    assert.equal(unhandledRejection, undefined);
  } finally {
    process.removeListener('unhandledRejection', onUnhandledRejection);
  }
});

function createDeferred() {
  let resolve;
  let reject;
  const promise = new Promise((resolvePromise, rejectPromise) => {
    resolve = resolvePromise;
    reject = rejectPromise;
  });
  return { promise, resolve, reject };
}

function createOutput() {
  return {
    finalCardUrl: 'https://renderer.example/generated/discovery-1/final-card.png',
    illustratedCatUrl: 'https://renderer.example/generated/discovery-1/illustrated-cat.png',
    analysisJson: {},
    selectedTemplateKey: 'default/common',
  };
}

function nextTurn() {
  return new Promise((resolve) => setImmediate(resolve));
}

function waitWithTimeout(promise, timeoutMs, code) {
  let timeout;
  const timeoutPromise = new Promise((_, reject) => {
    timeout = setTimeout(() => {
      const error = new Error('Card generation timed out.');
      error.code = code;
      reject(error);
    }, timeoutMs);
  });
  return Promise.race([promise, timeoutPromise]).finally(() => {
    clearTimeout(timeout);
  });
}
