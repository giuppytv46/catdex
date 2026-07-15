import assert from 'node:assert/strict';
import test from 'node:test';

import {
  PerformanceStep,
  PipelinePerformanceTrace,
} from '../lib/pipeline/performanceInstrumentation.ts';

test('pipeline performance trace logs step timing and final breakdown', async () => {
  const logs = [];
  const originalLog = console.log;
  console.log = (...values) => logs.push(values.join(' '));

  try {
    const requestStep = new PerformanceStep('REQUEST_RECEIVED', {
      discoveryId: 'discovery-1',
    });
    requestStep.end();

    const trace = new PipelinePerformanceTrace({
      discoveryId: 'discovery-1',
      idempotencyKey: 'card:discovery-1:v1',
    });
    await trace.measure('IMAGE_DOWNLOAD', 'Download', async () => {
      await new Promise((resolve) => setTimeout(resolve, 2));
    });
    trace.finish();

    assert.match(joinedLogs(logs), /CATDEX_PERF_REQUEST_RECEIVED_START/);
    assert.match(joinedLogs(logs), /CATDEX_PERF_REQUEST_RECEIVED_END/);
    assert.match(joinedLogs(logs), /CATDEX_PERF_IMAGE_DOWNLOAD_START/);
    assert.match(joinedLogs(logs), /CATDEX_PERF_IMAGE_DOWNLOAD_END/);
    assert.match(joinedLogs(logs), /CATDEX_PIPELINE_BREAKDOWN Download=\d+ms/);
    assert.match(joinedLogs(logs), /CATDEX_PIPELINE_TOTAL_TIME/);
    assert.match(joinedLogs(logs), /startTimestamp=/);
    assert.match(joinedLogs(logs), /endTimestamp=/);
    assert.match(joinedLogs(logs), /elapsedMs=/);
  } finally {
    console.log = originalLog;
  }
});

function joinedLogs(logs) {
  return logs.join('\n');
}
