export type RenderJobResolution<T> =
  | { kind: 'completed'; result: T }
  | { kind: 'active'; job: Promise<T>; created: boolean };

type ResolveRenderJobOptions<T> = {
  jobs: Map<string, Promise<T>>;
  key: string;
  readCompleted: () => Promise<T | undefined>;
  createJob: () => Promise<T>;
  onExistingResult?: () => void;
  onCreated?: () => void;
  onReused?: () => void;
  onCompleted?: (result: T) => void;
  onFailed?: (error: unknown) => void;
  onRemoved?: () => void;
};

export async function resolveRenderJob<T>({
  jobs,
  key,
  readCompleted,
  createJob,
  onExistingResult,
  onCreated,
  onReused,
  onCompleted,
  onFailed,
  onRemoved,
}: ResolveRenderJobOptions<T>): Promise<RenderJobResolution<T>> {
  const completed = await readCompleted();
  if (completed !== undefined) {
    safelyNotify(onExistingResult);
    return { kind: 'completed', result: completed };
  }

  const existingJob = jobs.get(key);
  if (existingJob) {
    safelyNotify(onReused);
    return { kind: 'active', job: existingJob, created: false };
  }

  const job = createJob();
  jobs.set(key, job);
  safelyNotify(onCreated);

  void job.then(
    (result) => {
      safelyNotify(onCompleted, result);
      removeSettledJob(jobs, key, job, onRemoved);
    },
    (error: unknown) => {
      safelyNotify(onFailed, error);
      removeSettledJob(jobs, key, job, onRemoved);
    },
  );

  return { kind: 'active', job, created: true };
}

function removeSettledJob<T>(
  jobs: Map<string, Promise<T>>,
  key: string,
  job: Promise<T>,
  onRemoved?: () => void,
): void {
  if (jobs.get(key) !== job) {
    return;
  }
  jobs.delete(key);
  safelyNotify(onRemoved);
}

function safelyNotify<T>(callback: ((value: T) => void) | undefined, value: T): void;
function safelyNotify(callback: (() => void) | undefined): void;
function safelyNotify<T>(callback: ((value?: T) => void) | undefined, value?: T): void {
  if (!callback) {
    return;
  }
  try {
    callback(value);
  } catch (error) {
    console.error(
      'CATDEX_RENDERER_JOB_LIFECYCLE_CALLBACK_FAILED',
      error instanceof Error ? error.message : String(error),
    );
  }
}
