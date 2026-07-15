export type PipelineBreakdownKey =
  | 'Download'
  | 'OpenAI'
  | 'BackgroundRemoval'
  | 'Composition'
  | 'Upload'
  | 'Persistence';

type PerformanceContext = {
  discoveryId?: string;
  idempotencyKey?: string;
};

export class PipelinePerformanceTrace {
  private readonly startedAtTimestamp = Date.now();
  private readonly startedAtMonotonic = performance.now();
  private readonly durations = new Map<PipelineBreakdownKey, number>();
  private readonly context: PerformanceContext;
  private finished = false;

  constructor(context: PerformanceContext) {
    this.context = context;
  }

  startStep(step: string, breakdownKey?: PipelineBreakdownKey): PerformanceStep {
    return new PerformanceStep(step, this.context, (elapsedMs) => {
      if (!breakdownKey) {
        return;
      }
      this.durations.set(
        breakdownKey,
        (this.durations.get(breakdownKey) ?? 0) + elapsedMs,
      );
    });
  }

  async measure<T>(
    step: string,
    breakdownKey: PipelineBreakdownKey,
    operation: () => Promise<T>,
  ): Promise<T> {
    const timing = this.startStep(step, breakdownKey);
    try {
      return await operation();
    } finally {
      timing.end();
    }
  }

  finish(): void {
    if (this.finished) {
      return;
    }
    this.finished = true;
    const totalMs = Math.max(
      0,
      Math.round(performance.now() - this.startedAtMonotonic),
    );
    const context = formatContext(this.context);
    console.log(
      'CATDEX_PIPELINE_BREAKDOWN',
      `Download=${this.duration('Download')}ms`,
      `OpenAI=${this.duration('OpenAI')}ms`,
      `BackgroundRemoval=${this.duration('BackgroundRemoval')}ms`,
      `Composition=${this.duration('Composition')}ms`,
      `Upload=${this.duration('Upload')}ms`,
      `Persistence=${this.duration('Persistence')}ms`,
      `Total=${totalMs}ms`,
      context,
    );
    console.log(
      'CATDEX_PIPELINE_TOTAL_TIME',
      `startTimestamp=${new Date(this.startedAtTimestamp).toISOString()}`,
      `endTimestamp=${new Date().toISOString()}`,
      `elapsedMs=${totalMs}`,
      context,
    );
  }

  private duration(key: PipelineBreakdownKey): number {
    return this.durations.get(key) ?? 0;
  }
}

export class PerformanceStep {
  private readonly startedAtTimestamp = Date.now();
  private readonly startedAtMonotonic = performance.now();
  private readonly step: string;
  private readonly context: PerformanceContext;
  private readonly onEnd?: (elapsedMs: number) => void;
  private ended = false;

  constructor(
    step: string,
    context: PerformanceContext = {},
    onEnd?: (elapsedMs: number) => void,
  ) {
    this.step = step;
    this.context = context;
    this.onEnd = onEnd;
    console.log(
      `CATDEX_PERF_${step}_START`,
      `timestamp=${new Date(this.startedAtTimestamp).toISOString()}`,
      formatContext(context),
    );
  }

  end(): number {
    if (this.ended) {
      return 0;
    }
    this.ended = true;
    const elapsedMs = Math.max(
      0,
      Math.round(performance.now() - this.startedAtMonotonic),
    );
    console.log(
      `CATDEX_PERF_${this.step}_END`,
      `timestamp=${new Date().toISOString()}`,
      `elapsedMs=${elapsedMs}`,
      formatContext(this.context),
    );
    this.onEnd?.(elapsedMs);
    return elapsedMs;
  }
}

function formatContext(context: PerformanceContext): string {
  return [
    context.discoveryId ? `discoveryId=${context.discoveryId}` : '',
    context.idempotencyKey ? `idempotencyKey=${context.idempotencyKey}` : '',
  ]
    .filter(Boolean)
    .join(' ');
}
