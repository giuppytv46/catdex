type AnalyzeCatPhotoRequest = {
  image_url?: string;
  base64_image?: string;
  photoReference?: string;
  user_id?: string;
  locale?: string;
  metadata?: {
    source?: string;
    sizeBytes?: number;
    capturedAt?: string;
    activeEventId?: string;
  };
  activeEventId?: string;
};

type TraitJson = {
  name: string;
  value: string;
  rarityWeight?: number;
};

type CandidateJson = {
  breed: string;
  confidence: number;
};

type AnalysisJson = {
  breed: string;
  confidence: number;
  candidates: CandidateJson[];
  coatColor: string;
  coatPattern: string;
  eyeColor: string;
  hairLength: string;
  estimatedAge: string;
  traits: TraitJson[];
  personality: string;
  rarity: string;
  variant: string;
  story: string;
  funFact: string;
  safetyStatus: "safe" | "no_cat" | "inappropriate" | "malformed";
  analyzedAt: string;
};

type JsonResponseBody = Record<string, unknown>;

const defaultOpenAiModel = "gpt-4o-mini";
const openAiModel = openAiModelFromEnv();
const jsonHeaders = {
  "Content-Type": "application/json",
};
const allowedRarities = [
  "common",
  "uncommon",
  "rare",
  "epic",
  "legendary",
  "mythic",
];
const allowedVariants = [
  "normal",
  "shiny",
  "golden",
  "albino",
  "melanistic",
  "heterochromia",
  "midnight",
  "lucky",
  "event_edition",
];
const allowedPersonalities = [
  "sleepy",
  "curious",
  "boss",
  "friendly",
  "royal",
  "mischievous",
  "silly",
  "mysterious",
  "brave",
  "lazy",
  "relaxed",
  "playful",
];
const allowedBreedIds = [
  "domestic_shorthair_cat",
  "domestic_tabby_cat",
  "domestic_black_cat",
  "domestic_white_cat",
  "domestic_tuxedo_cat",
  "domestic_calico_cat",
  "domestic_orange_cat",
  "domestic_gray_cat",
  "domestic_longhair_cat",
  "european_shorthair",
  "maine_coon",
  "persian",
  "siamese",
  "british_shorthair",
  "ragdoll",
  "bengal",
  "sphynx",
  "russian_blue",
  "norwegian_forest_cat",
  "abyssinian",
  "scottish_fold",
  "american_shorthair",
];
const rareBreedIds = [
  "cymric",
  "lykoi",
  "khao_manee",
  "peterbald",
  "sokoke",
  "toyger",
  "chausie",
  "savannah",
  "serengeti",
  "burmilla",
];

Deno.serve(async (request: Request) => {
  const requestId = crypto.randomUUID();
  console.log(`[analyze_cat_photo] request received`, {
    requestId,
    method: request.method,
  });

  if (request.method !== "POST") {
    return jsonResponse(
      {
        error: "method_not_allowed",
        message: "Use POST for cat photo analysis.",
      },
      405,
    );
  }

  let body: AnalyzeCatPhotoRequest;
  try {
    body = await request.json();
  } catch (_) {
    console.log(`[analyze_cat_photo] invalid JSON body`, { requestId });
    return invalidImageResponse("Request body must be valid JSON.");
  }

  console.log(`[analyze_cat_photo] request body accepted`, {
    requestId,
    hasImageUrl: Boolean(body.image_url),
    hasBase64Image: Boolean(body.base64_image),
    hasPhotoReference: Boolean(body.photoReference),
    hasActiveEvent: hasActiveEvent(body),
  });

  const validationError = validateRequest(body);
  if (validationError !== null) {
    console.log(`[analyze_cat_photo] validation failed`, {
      requestId,
      validationError,
    });
    return invalidImageResponse(validationError);
  }

  const openAiKey = Deno.env.get("OPENAI_API_KEY");
  console.log(`[analyze_cat_photo] OPENAI_API_KEY status`, {
    requestId,
    present: Boolean(openAiKey),
  });
  if (!openAiKey) {
    console.log(`[analyze_cat_photo] using mock fallback`, {
      requestId,
      reason: "missing_key",
    });
    return jsonResponse(mockAnalysisResult("missing_key"), 200);
  }

  const imageInput = await imageInputFor(body);
  if (imageInput === null) {
    console.log(`[analyze_cat_photo] image input unavailable`, { requestId });
    return invalidImageResponse(
      "image_url, base64_image, or resolvable photoReference is required for real AI analysis.",
    );
  }

  try {
    const aiJson = await analyzeWithOpenAi({
      imageInput,
      locale: body.locale ?? "en",
      openAiKey,
      requestId,
    });
    const analysis = validateAnalysisJson(aiJson, hasActiveEvent(body));
    console.log(`[analyze_cat_photo] JSON validation complete`, {
      requestId,
      safetyStatus: analysis.safetyStatus,
      breed: analysis.breed,
      confidence: analysis.confidence,
      rarity: analysis.rarity,
      variant: analysis.variant,
    });

    if (analysis.safetyStatus === "no_cat") {
      return jsonResponse(
        {
          error: "no_cat_detected",
          message: "CatDex could not find a cat in this image.",
        },
        422,
      );
    }

    if (analysis.safetyStatus === "inappropriate") {
      return jsonResponse(
        {
          error: "invalid_image",
          message: "CatDex cannot analyze this image.",
        },
        422,
      );
    }

    return jsonResponse(toResultEnvelope(analysis), 200);
  } catch (error) {
    console.error(`[analyze_cat_photo] analysis failed, using mock fallback`, {
      requestId,
      errorName: error instanceof Error ? error.name : "unknown",
      errorMessage: error instanceof Error ? error.message : String(error),
    });

    return jsonResponse(
      mockAnalysisResult(openAiFallbackReason(error)),
      200,
    );
  }
});

function openAiModelFromEnv(): string {
  const configuredModel = Deno.env.get("OPENAI_MODEL")?.trim();
  if (!configuredModel) {
    return defaultOpenAiModel;
  }

  if (!isSupportedVisionModelName(configuredModel)) {
    console.warn(`[analyze_cat_photo] unsupported OPENAI_MODEL, using default`, {
      configuredModel,
      defaultOpenAiModel,
    });
    return defaultOpenAiModel;
  }

  return configuredModel;
}

function isSupportedVisionModelName(model: string): boolean {
  return [
    "gpt-4o",
    "gpt-4o-mini",
    "gpt-4.1",
    "gpt-4.1-mini",
    "gpt-5",
    "gpt-5-mini",
    "gpt-5.5",
  ].some((prefix) => model === prefix || model.startsWith(`${prefix}-`));
}

function validateRequest(body: AnalyzeCatPhotoRequest): string | null {
  const hasImage = Boolean(body.image_url) || Boolean(body.base64_image) ||
    Boolean(body.photoReference);
  if (!hasImage) {
    return "image_url or base64_image is required.";
  }

  if (
    body.metadata?.sizeBytes !== undefined &&
    (typeof body.metadata.sizeBytes !== "number" || body.metadata.sizeBytes <= 0)
  ) {
    return "metadata.sizeBytes must be a positive number.";
  }

  return null;
}

async function imageInputFor(
  body: AnalyzeCatPhotoRequest,
): Promise<string | null> {
  if (body.image_url) {
    return body.image_url;
  }

  if (body.base64_image) {
    if (body.base64_image.startsWith("data:image/")) {
      return body.base64_image;
    }

    return `data:image/jpeg;base64,${body.base64_image}`;
  }

  if (body.photoReference) {
    return signedStorageUrlFor(body.photoReference);
  }

  return null;
}

async function signedStorageUrlFor(
  photoReference: string,
): Promise<string | null> {
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceRoleKey) {
    return null;
  }

  const normalizedPath = photoReference.replace(/^\/+/, "");
  const bucketName = "cat-photos";
  const storagePath = normalizedPath.startsWith(`${bucketName}/`)
    ? normalizedPath.slice(bucketName.length + 1)
    : normalizedPath;
  const response = await fetch(
    `${supabaseUrl}/storage/v1/object/sign/${bucketName}/${storagePath}`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${serviceRoleKey}`,
        apikey: serviceRoleKey,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ expiresIn: 300 }),
    },
  );

  if (!response.ok) {
    return null;
  }

  const payload = await response.json() as {
    signedURL?: string;
    signedUrl?: string;
  };
  const signedPath = payload.signedURL ?? payload.signedUrl;
  if (!signedPath) {
    return null;
  }

  return signedPath.startsWith("http")
    ? signedPath
    : `${supabaseUrl}/storage/v1${signedPath}`;
}

async function analyzeWithOpenAi({
  imageInput,
  locale,
  openAiKey,
  requestId,
}: {
  imageInput: string;
  locale: string;
  openAiKey: string;
  requestId: string;
}): Promise<unknown> {
  console.log(`[analyze_cat_photo] OpenAI request started`, {
    requestId,
    model: openAiModel,
  });

  const response = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${openAiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: openAiModel,
      max_tokens: 900,
      temperature: 0.2,
      response_format: {
        type: "json_schema",
        json_schema: {
          name: "catdex_cat_analysis",
          strict: true,
          schema: analysisJsonSchema(),
        },
      },
      messages: [
        {
          role: "user",
          content: [
            {
              type: "text",
              text: analysisPrompt(locale),
            },
            {
              type: "image_url",
              image_url: {
                url: imageInput,
              },
            },
          ],
        },
      ],
    }),
  });

  console.log(`[analyze_cat_photo] OpenAI response status`, {
    requestId,
    status: response.status,
    ok: response.ok,
  });

  if (!response.ok) {
    const errorBody = await response.text();
    console.error(`[analyze_cat_photo] OpenAI error body`, {
      requestId,
      status: response.status,
      body: safeForLog(errorBody, 1200),
    });
    throw new OpenAiRequestError(response.status, errorBody);
  }

  const payload = await response.json();
  const text = extractOutputText(payload);
  if (text === null) {
    console.error(`[analyze_cat_photo] OpenAI output text missing`, {
      requestId,
    });
    throw new MalformedAiResponseError();
  }

  const parsed = parseJsonObject(text);
  console.log(`[analyze_cat_photo] JSON parsing result`, {
    requestId,
    parsed: typeof parsed === "object" && parsed !== null,
    keys: typeof parsed === "object" && parsed !== null
      ? Object.keys(parsed as Record<string, unknown>)
      : [],
  });

  return parsed;
}

function analysisJsonSchema(): Record<string, unknown> {
  return {
    type: "object",
    additionalProperties: false,
    required: [
      "breed",
      "confidence",
      "candidates",
      "coatColor",
      "coatPattern",
      "eyeColor",
      "hairLength",
      "estimatedAge",
      "traits",
      "personality",
      "rarity",
      "variant",
      "story",
      "funFact",
      "safetyStatus",
    ],
    properties: {
      breed: { type: "string" },
      confidence: { type: "number" },
      candidates: {
        type: "array",
        items: {
          type: "object",
          additionalProperties: false,
          required: ["breed", "confidence"],
          properties: {
            breed: { type: "string" },
            confidence: { type: "number" },
          },
        },
      },
      coatColor: { type: "string" },
      coatPattern: { type: "string" },
      eyeColor: { type: "string" },
      hairLength: { type: "string" },
      estimatedAge: { type: "string" },
      traits: {
        type: "array",
        items: {
          type: "object",
          additionalProperties: false,
          required: ["name", "value", "rarityWeight"],
          properties: {
            name: { type: "string" },
            value: { type: "string" },
            rarityWeight: { type: "number" },
          },
        },
      },
      personality: { type: "string" },
      rarity: { type: "string" },
      variant: { type: "string" },
      story: { type: "string" },
      funFact: { type: "string" },
      safetyStatus: { type: "string" },
    },
  };
}

function safeForLog(value: string, maxLength: number): string {
  const redacted = value
    .replace(/Bearer\s+[^\s"']+/gi, "Bearer [redacted]")
    .replace(/sk-[A-Za-z0-9_-]+/g, "sk-[redacted]")
    .replace(/https?:\/\/[^\s"')]+/g, "[url]")
    .replace(/data:image\/[A-Za-z0-9.+-]+;base64,[A-Za-z0-9+/=]+/g, "[image]");

  return redacted.length <= maxLength
    ? redacted
    : `${redacted.slice(0, maxLength)}...`;
}

function analysisPrompt(locale: string): string {
  return [
    "You are CatDex Vision, a safety-first cat collection game analyzer.",
    "Analyze only the cat. Ignore humans and never identify people.",
    "Reject inappropriate images. If no cat is visible, set safetyStatus to no_cat.",
    "Return JSON only, with no markdown.",
    "Use CatDex ids for breed and variant.",
    `Allowed breed ids: ${allowedBreedIds.join(", ")}.`,
    "Allowed rarity: common, uncommon, rare, epic, legendary, mythic.",
    `Allowed variants: ${allowedVariants.join(", ")}.`,
    `Allowed personalities: ${allowedPersonalities.join(", ")}.`,
    "If breed confidence is below 0.80, breed must be domestic_shorthair_cat or european_shorthair.",
    "Rare breed ids are allowed only with confidence >= 0.90. Never invent exotic breeds.",
    "Legendary rarity must be extremely rare and only for very strong visual evidence.",
    "Never return event_edition unless an active event is explicitly provided.",
    "Return story, funFact, trait names, and trait values in Italian.",
    "JSON keys: breed, confidence, candidates, coatColor, coatPattern, eyeColor, hairLength, estimatedAge, traits, personality, rarity, variant, story, funFact, safetyStatus.",
    `Requested locale is ${locale}, but CatDex alpha requires Italian user-facing text.`,
  ].join(" ");
}

function extractOutputText(payload: unknown): string | null {
  if (typeof payload !== "object" || payload === null) {
    return null;
  }

  const outputText = (payload as { output_text?: unknown }).output_text;
  if (typeof outputText === "string" && outputText.trim().length > 0) {
    return outputText;
  }

  const choices = (payload as { choices?: unknown }).choices;
  if (Array.isArray(choices)) {
    for (const choice of choices) {
      if (typeof choice !== "object" || choice === null) {
        continue;
      }

      const message = (choice as { message?: unknown }).message;
      if (typeof message !== "object" || message === null) {
        continue;
      }

      const content = (message as { content?: unknown }).content;
      if (typeof content === "string" && content.trim().length > 0) {
        return content;
      }

      if (Array.isArray(content)) {
        for (const part of content) {
          if (typeof part !== "object" || part === null) {
            continue;
          }

          const text = (part as { text?: unknown }).text;
          if (typeof text === "string" && text.trim().length > 0) {
            return text;
          }
        }
      }
    }
  }

  const output = (payload as { output?: unknown }).output;
  if (!Array.isArray(output)) {
    return null;
  }

  for (const item of output) {
    if (typeof item !== "object" || item === null) {
      continue;
    }

    const content = (item as { content?: unknown }).content;
    if (!Array.isArray(content)) {
      continue;
    }

    for (const part of content) {
      if (typeof part !== "object" || part === null) {
        continue;
      }

      const text = (part as { text?: unknown }).text;
      if (typeof text === "string" && text.trim().length > 0) {
        return text;
      }
    }
  }

  return null;
}

function parseJsonObject(text: string): unknown {
  const trimmed = text.trim();
  try {
    return JSON.parse(trimmed);
  } catch (_) {
    const start = trimmed.indexOf("{");
    const end = trimmed.lastIndexOf("}");
    if (start < 0 || end <= start) {
      throw new MalformedAiResponseError();
    }

    return JSON.parse(trimmed.slice(start, end + 1));
  }
}

function validateAnalysisJson(
  value: unknown,
  activeEvent: boolean,
): AnalysisJson {
  if (typeof value !== "object" || value === null) {
    throw new MalformedAiResponseError();
  }

  const item = value as Record<string, unknown>;
  const safetyStatus = stringValue(item.safetyStatus);
  if (
    safetyStatus === "no_cat" ||
    safetyStatus === "inappropriate"
  ) {
    return {
      ...safeFallbackAnalysis(),
      safetyStatus,
      story: stringValue(item.story) || safeFallbackAnalysis().story,
    };
  }

  const analysis: AnalysisJson = {
    breed: stringValue(item.breed) || "domestic_shorthair_cat",
    confidence: numberValue(item.confidence),
    candidates: candidateList(item.candidates),
    coatColor: stringValue(item.coatColor) || "Unknown",
    coatPattern: stringValue(item.coatPattern) || "Unknown",
    eyeColor: stringValue(item.eyeColor) || "Unknown",
    hairLength: stringValue(item.hairLength) || "Unknown",
    estimatedAge: stringValue(item.estimatedAge) || "adulto",
    traits: traitList(item.traits),
    personality: allowedValue(
      stringValue(item.personality),
      allowedPersonalities,
      "curious",
    ),
    rarity: allowedValue(stringValue(item.rarity), allowedRarities, "common"),
    variant: allowedValue(stringValue(item.variant), allowedVariants, "normal"),
    story: stringValue(item.story) || safeFallbackAnalysis().story,
    funFact: stringValue(item.funFact) || safeFallbackAnalysis().funFact,
    safetyStatus: "safe",
    analyzedAt: new Date().toISOString(),
  };

  if (analysis.confidence < 0 || analysis.confidence > 1) {
    throw new MalformedAiResponseError();
  }

  return applyRealismRules(analysis, activeEvent);
}

function candidateList(value: unknown): CandidateJson[] {
  if (!Array.isArray(value)) {
    return [{ breed: "domestic_shorthair_cat", confidence: 0.35 }];
  }

  const candidates = value.flatMap((item) => {
    if (typeof item !== "object" || item === null) {
      return [];
    }

    const row = item as Record<string, unknown>;
    const breed = realisticBreedId(
      stringValue(row.breed) || "domestic_shorthair_cat",
      numberValue(row.confidence),
    );
    const confidence = numberValue(row.confidence);

    if (confidence < 0 || confidence > 1) {
      return [];
    }

    return [{ breed, confidence }];
  });

  return candidates.length === 0
    ? [{ breed: "domestic_shorthair_cat", confidence: 0.35 }]
    : candidates.slice(0, 3);
}

function traitList(value: unknown): TraitJson[] {
  if (!Array.isArray(value)) {
    return [{ name: "Umore", value: "Curioso", rarityWeight: 1 }];
  }

  const traits = value.flatMap((item) => {
    if (typeof item !== "object" || item === null) {
      return [];
    }

    const row = item as Record<string, unknown>;
    const name = stringValue(row.name);
    const value = stringValue(row.value);
    if (!name || !value) {
      return [];
    }

    return [{
      name,
      value,
      rarityWeight: Math.max(1, numberValue(row.rarityWeight) || 1),
    }];
  });

  return traits.length === 0
    ? [{ name: "Umore", value: "Curioso", rarityWeight: 1 }]
    : traits.slice(0, 6);
}

function toResultEnvelope(analysis: AnalysisJson): JsonResponseBody {
  return {
    breed: analysis.breed,
    confidence: analysis.confidence,
    candidates: analysis.candidates,
    coatColor: analysis.coatColor,
    coatPattern: analysis.coatPattern,
    eyeColor: analysis.eyeColor,
    hairLength: analysis.hairLength,
    estimatedAge: analysis.estimatedAge,
    traits: analysis.traits,
    personality: analysis.personality,
    rarity: analysis.rarity,
    variant: analysis.variant,
    story: analysis.story,
    funFact: analysis.funFact,
    safetyStatus: analysis.safetyStatus,
    analyzedAt: analysis.analyzedAt,
  };
}

function safeFallbackAnalysis(): AnalysisJson {
  return {
    breed: "domestic_shorthair_cat",
    confidence: 0.35,
    candidates: [{ breed: "domestic_shorthair_cat", confidence: 0.35 }],
    coatColor: "Unknown",
    coatPattern: "Unknown",
    eyeColor: "Unknown",
    hairLength: "Unknown",
    estimatedAge: "adulto",
    traits: [{ name: "Umore", value: "Curioso", rarityWeight: 1 }],
    personality: "curious",
    rarity: "common",
    variant: "normal",
    story:
      "Questo gatto di quartiere resta un piccolo mistero, ma merita comunque una carta CatDex tutta sua.",
    funFact:
      "Molti gatti domestici hanno origini miste: CatDex privilegia una classificazione prudente quando la razza non e chiara.",
    safetyStatus: "safe",
    analyzedAt: new Date().toISOString(),
  };
}

function mockAnalysisResult(mockReason: string): JsonResponseBody {
  return {
    ...toResultEnvelope({
      breed: "domestic_tabby_cat",
      confidence: 0.82,
      candidates: [
        { breed: "domestic_tabby_cat", confidence: 0.82 },
        { breed: "domestic_shorthair_cat", confidence: 0.64 },
        { breed: "european_shorthair", confidence: 0.48 },
      ],
      coatColor: "Brown",
      coatPattern: "Tabby",
      eyeColor: "Green",
      hairLength: "Short",
      estimatedAge: "adulto",
      traits: [
        { name: "Posa", value: "In osservazione", rarityWeight: 1 },
        { name: "Umore", value: "Curioso", rarityWeight: 1 },
      ],
      personality: "curious",
      rarity: "common",
      variant: "normal",
      story:
        "Questo gatto curioso sembra pronto a diventare il protagonista di una nuova carta CatDex.",
      funFact:
        "I gatti tigrati domestici sono molto comuni e possono avere pattern molto diversi tra loro.",
      safetyStatus: "safe",
      analyzedAt: new Date().toISOString(),
    }),
    backend: {
      mock: true,
      mockReason: safeForLog(mockReason, 260),
    },
  };
}

function openAiFallbackReason(error: unknown): string {
  if (error instanceof OpenAiRequestError) {
    const summary = openAiErrorSummary(error.responseBody);
    return [
      "openai_error",
      `status_${error.status}`,
      summary.type,
      summary.code,
      summary.message,
    ].filter((part) => part.length > 0).join("|");
  }

  if (error instanceof MalformedAiResponseError) {
    return "openai_malformed_response";
  }

  if (error instanceof Error) {
    return `openai_error|${error.name}|${error.message}`;
  }

  return "openai_error|unknown";
}

function openAiErrorSummary(body: string): {
  type: string;
  code: string;
  message: string;
} {
  try {
    const parsed = JSON.parse(body) as {
      error?: {
        type?: unknown;
        code?: unknown;
        message?: unknown;
      };
    };
    const error = parsed.error;
    if (!error) {
      return { type: "", code: "", message: safeForLog(body, 160) };
    }

    return {
      type: stringValue(error.type),
      code: stringValue(error.code),
      message: safeForLog(stringValue(error.message), 160),
    };
  } catch (_) {
    return { type: "", code: "", message: safeForLog(body, 160) };
  }
}

function applyRealismRules(
  analysis: AnalysisJson,
  activeEvent: boolean,
): AnalysisJson {
  const breed = realisticBreedId(analysis.breed, analysis.confidence);
  const candidates = analysis.candidates
    .map((candidate) => ({
      breed: realisticBreedId(candidate.breed, candidate.confidence),
      confidence: candidate.confidence,
    }))
    .filter((candidate, index, list) =>
      list.findIndex((item) => item.breed === candidate.breed) === index
    )
    .slice(0, 3);

  return {
    ...analysis,
    breed,
    candidates: candidates.length === 0
      ? [{ breed, confidence: analysis.confidence }]
      : candidates,
    rarity: realisticRarity(analysis.rarity, analysis.confidence),
    variant: analysis.variant === "event_edition" && !activeEvent
      ? "normal"
      : analysis.variant,
  };
}

function realisticBreedId(breed: string, confidence: number): string {
  const normalized = breed.trim().toLowerCase();
  if (confidence < 0.8) {
    return normalized.includes("european")
      ? "european_shorthair"
      : "domestic_shorthair_cat";
  }

  if (rareBreedIds.includes(normalized) && confidence < 0.9) {
    return "domestic_shorthair_cat";
  }

  return allowedBreedIds.includes(normalized)
    ? normalized
    : "domestic_shorthair_cat";
}

function realisticRarity(rarity: string, confidence: number): string {
  if ((rarity === "legendary" && confidence < 0.98) || rarity === "mythic") {
    return "rare";
  }

  return rarity;
}

function hasActiveEvent(body: AnalyzeCatPhotoRequest): boolean {
  return Boolean(body.activeEventId || body.metadata?.activeEventId);
}

function invalidImageResponse(message: string): Response {
  return jsonResponse(
    {
      error: "invalid_image",
      message,
    },
    400,
  );
}

function jsonResponse(body: JsonResponseBody, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: jsonHeaders,
  });
}

function stringValue(value: unknown): string {
  return typeof value === "string" ? value.trim() : "";
}

function numberValue(value: unknown): number {
  return typeof value === "number" && Number.isFinite(value) ? value : 0;
}

function allowedValue(
  value: string,
  allowedValues: string[],
  fallback: string,
): string {
  return allowedValues.includes(value) ? value : fallback;
}

class OpenAiRequestError extends Error {
  constructor(
    readonly status: number,
    readonly responseBody: string,
  ) {
    super(`OpenAI request failed: ${status}`);
  }
}

class MalformedAiResponseError extends Error {}
