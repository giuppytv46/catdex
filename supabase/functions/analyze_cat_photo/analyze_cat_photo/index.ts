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

type CatVisionObservation = {
  coatBaseColor: string | null;
  coatPattern: string | null;
  eyeColor: string | null;
  hairLength: string | null;
  posture: string | null;
  environment: string | null;
  estimatedAge: string | null;
  visibleConfidence: number;
  safetyStatus: "safe" | "no_cat" | "inappropriate" | "malformed";
};

type JsonResponseBody = Record<string, unknown>;

const defaultOpenAiModel = "gpt-4o-mini";
const openAiModel = openAiModelFromEnv();
const jsonHeaders = {
  "Content-Type": "application/json",
};
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
    const analysis = validateAnalysisJson(aiJson);
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
          name: "catdex_cat_observation",
          strict: true,
          schema: observationJsonSchema(),
        },
      },
      messages: [
        {
          role: "user",
          content: [
            {
              type: "text",
              text: observationPrompt(locale),
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

function observationJsonSchema(): Record<string, unknown> {
  return {
    type: "object",
    additionalProperties: false,
    required: [
      "coatBaseColor",
      "coatPattern",
      "eyeColor",
      "hairLength",
      "posture",
      "environment",
      "estimatedAge",
      "visibleConfidence",
      "safetyStatus",
    ],
    properties: {
      coatBaseColor: nullableStringSchema(),
      coatPattern: nullableStringSchema(),
      eyeColor: nullableStringSchema(),
      hairLength: nullableStringSchema(),
      posture: nullableStringSchema(),
      environment: nullableStringSchema(),
      estimatedAge: nullableStringSchema(),
      visibleConfidence: { type: "number" },
      safetyStatus: { type: "string" },
    },
  };
}

function nullableStringSchema(): Record<string, unknown> {
  return { type: ["string", "null"] };
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

function observationPrompt(locale: string): string {
  return [
    "You are CatDex Vision Step 1, a safety-first visual observation tool.",
    "Analyze only the cat. Ignore humans and never identify people.",
    "Reject inappropriate images. If no cat is visible, set safetyStatus to no_cat.",
    "Return JSON only, with no markdown.",
    "Return only visible facts: coatBaseColor, coatPattern, eyeColor, hairLength, posture, environment, estimatedAge, visibleConfidence, safetyStatus.",
    "Do not return breed, rarity, variant, personality, story, funFact, or candidates.",
    "If a visual fact is uncertain, return null for that field. Do not guess.",
    "Never guess calico, tortoiseshell, colorpoint, blue eyes, or long hair unless clearly visible.",
    "For tabby cats, distinguish brown tabby, gray tabby, and orange tabby from solid black.",
    "Use coatPattern tabby only when stripes, rings, or spotted tabby markings are visible.",
    "Use coatPattern calico only when clear white, orange, and black patches are visible.",
    "Use coatPattern tortoiseshell only when mixed black or brown and orange mottling is visible.",
    "Use coatPattern colorpoint only when Siamese-like darker ears, face, tail, or paws are visible.",
    "Use coatBaseColor black only if the cat is mostly solid black.",
    "Use coatBaseColor white only if the cat is mostly white.",
    "Use eyeColor blue only if the eyes are clearly blue.",
    "Use hairLength long only if the fur is clearly long; otherwise prefer short or null.",
    "Allowed coatBaseColor examples: brown, gray, orange, black, white, cream, mixed, null.",
    "Allowed coatPattern examples: tabby, solid, bicolor, tuxedo, calico, tortoiseshell, colorpoint, spotted, smoke, null.",
    "visibleConfidence must be 0.0 to 1.0 and reflect only visual fact confidence.",
    "JSON keys: coatBaseColor, coatPattern, eyeColor, hairLength, posture, environment, estimatedAge, visibleConfidence, safetyStatus.",
    `Requested locale is ${locale}; observation values may be simple English visual labels because the backend rule engine localizes final output.`,
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

function validateAnalysisJson(value: unknown): AnalysisJson {
  const observation = validateVisionObservation(value);
  return analysisFromObservation(observation);
}

function validateVisionObservation(value: unknown): CatVisionObservation {
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
      ...safeFallbackObservation(),
      safetyStatus,
    };
  }

  const observation: CatVisionObservation = {
    coatBaseColor: nullableStringValue(item.coatBaseColor),
    coatPattern: nullableStringValue(item.coatPattern),
    eyeColor: nullableStringValue(item.eyeColor),
    hairLength: nullableStringValue(item.hairLength),
    posture: nullableStringValue(item.posture),
    environment: nullableStringValue(item.environment),
    estimatedAge: nullableStringValue(item.estimatedAge),
    visibleConfidence: numberValue(item.visibleConfidence),
    safetyStatus: "safe",
  };

  if (
    observation.visibleConfidence < 0 ||
    observation.visibleConfidence > 1
  ) {
    throw new MalformedAiResponseError();
  }

  return observation;
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

function safeFallbackObservation(): CatVisionObservation {
  return {
    coatBaseColor: null,
    coatPattern: null,
    eyeColor: null,
    hairLength: null,
    posture: null,
    environment: null,
    estimatedAge: null,
    visibleConfidence: 0.35,
    safetyStatus: "safe",
  };
}

function analysisFromObservation(observation: CatVisionObservation): AnalysisJson {
  if (
    observation.safetyStatus === "no_cat" ||
    observation.safetyStatus === "inappropriate"
  ) {
    return {
      ...safeFallbackAnalysis(),
      safetyStatus: observation.safetyStatus,
    };
  }

  const coatPattern = realisticCoatPattern(
    observation.coatPattern ?? "unknown",
  );
  const coatColor = coatColorFromObservation(
    observation.coatBaseColor,
    coatPattern,
  );
  const hairLength = realisticHairLength(observation.hairLength);
  const eyeColor = realisticEyeColor(observation.eyeColor);
  const estimatedAge = italianOrFallback(observation.estimatedAge, "adulto");
  const confidence = Math.max(0.35, observation.visibleConfidence);
  const breed = breedFromObservationRules({
    coatColor,
    coatPattern,
    hairLength,
    confidence,
  });
  const candidates = candidatesForBreed(breed, confidence, coatPattern);
  const personality = personalityFromObservation(observation);
  const rarity = rarityFromObservationRules(breed);
  const variant = "normal";

  return {
    breed,
    confidence,
    candidates,
    coatColor,
    coatPattern,
    eyeColor,
    hairLength,
    estimatedAge,
    traits: traitsFromObservation({
      coatColor,
      coatPattern,
      eyeColor,
      hairLength,
      estimatedAge,
      posture: observation.posture,
      environment: observation.environment,
    }),
    personality,
    rarity,
    variant,
    story: storyFromObservation({
      breed,
      coatColor,
      coatPattern,
      posture: observation.posture,
      environment: observation.environment,
    }),
    funFact: funFactForBreed(breed, coatPattern),
    safetyStatus: "safe",
    analyzedAt: new Date().toISOString(),
  };
}

function coatColorFromObservation(
  coatBaseColor: string | null,
  coatPattern: string,
): string {
  return realisticCoatColor(coatBaseColor ?? "unknown", coatPattern);
}

function realisticHairLength(hairLength: string | null): string {
  const normalized = normalizeVisualValue(hairLength ?? "");
  if (normalized.includes("long") || normalized.includes("lung")) {
    return "pelo lungo";
  }

  if (normalized.includes("medium") || normalized.includes("medio")) {
    return "pelo medio";
  }

  if (normalized.includes("short") || normalized.includes("cort")) {
    return "pelo corto";
  }

  return "pelo corto";
}

function realisticEyeColor(eyeColor: string | null): string {
  const normalized = normalizeVisualValue(eyeColor ?? "");
  if (normalized.includes("blue") || normalized.includes("azzurr")) {
    return "occhi azzurri";
  }

  if (normalized.includes("green") || normalized.includes("verd")) {
    return "occhi verdi";
  }

  if (normalized.includes("amber") || normalized.includes("ambr")) {
    return "occhi ambrati";
  }

  if (
    normalized.includes("yellow") ||
    normalized.includes("gold") ||
    normalized.includes("giall") ||
    normalized.includes("dorat")
  ) {
    return "occhi gialli";
  }

  return "Non rilevato";
}

function italianOrFallback(value: string | null, fallback: string): string {
  return stringValue(value) || fallback;
}

function breedFromObservationRules({
  coatColor,
  coatPattern,
  hairLength,
  confidence,
}: {
  coatColor: string;
  coatPattern: string;
  hairLength: string;
  confidence: number;
}): string {
  if (isTabbyPattern(coatPattern) && hairLength !== "pelo lungo") {
    return "domestic_tabby_cat";
  }

  if (isTabbyPattern(coatPattern)) {
    return "domestic_tabby_cat";
  }

  if (normalizeVisualValue(coatPattern).includes("calico")) {
    return "domestic_calico_cat";
  }

  if (isSolidPattern(coatPattern) && isBlackColor(coatColor)) {
    return "domestic_black_cat";
  }

  if (isWhiteColor(coatColor)) {
    return "domestic_white_cat";
  }

  if (isOrangeColor(coatColor)) {
    return "domestic_orange_cat";
  }

  if (isGrayColor(coatColor)) {
    return "domestic_gray_cat";
  }

  if (normalizeVisualValue(coatPattern).includes("colorpoint")) {
    return confidence >= 0.9 ? "siamese" : "domestic_shorthair_cat";
  }

  if (hairLength === "pelo lungo") {
    return "domestic_longhair_cat";
  }

  return "domestic_shorthair_cat";
}

function candidatesForBreed(
  breed: string,
  confidence: number,
  coatPattern: string,
): CandidateJson[] {
  const candidates: CandidateJson[] = [
    { breed, confidence },
  ];

  if (breed !== "domestic_shorthair_cat") {
    candidates.push({
      breed: "domestic_shorthair_cat",
      confidence: Math.max(0.35, confidence - 0.18),
    });
  }

  if (breed !== "domestic_tabby_cat" && isTabbyPattern(coatPattern)) {
    candidates.push({
      breed: "domestic_tabby_cat",
      confidence: Math.max(0.35, confidence - 0.12),
    });
  }

  return candidates.slice(0, 3);
}

function rarityFromObservationRules(breed: string): string {
  return breed.startsWith("domestic_") ? "common" : "uncommon";
}

function personalityFromObservation(
  observation: CatVisionObservation,
): string {
  const posture = normalizeVisualValue(observation.posture ?? "");
  if (posture.includes("sleep") || posture.includes("rest")) {
    return "relaxed";
  }

  if (posture.includes("play")) {
    return "playful";
  }

  return "curious";
}

function traitsFromObservation({
  coatColor,
  coatPattern,
  eyeColor,
  hairLength,
  estimatedAge,
  posture,
  environment,
}: {
  coatColor: string;
  coatPattern: string;
  eyeColor: string;
  hairLength: string;
  estimatedAge: string;
  posture: string | null;
  environment: string | null;
}): TraitJson[] {
  const traits: TraitJson[] = [
    { name: "Mantello", value: `${coatColor}, ${coatPattern}`, rarityWeight: 1 },
    { name: "Occhi", value: eyeColor, rarityWeight: 1 },
    { name: "Pelo", value: hairLength, rarityWeight: 1 },
    { name: "Eta stimata", value: estimatedAge, rarityWeight: 1 },
  ];

  if (posture) {
    traits.push({ name: "Posa", value: posture, rarityWeight: 1 });
  }

  if (environment) {
    traits.push({ name: "Ambiente", value: environment, rarityWeight: 1 });
  }

  return traits.slice(0, 6);
}

function storyFromObservation({
  breed,
  coatColor,
  coatPattern,
  posture,
  environment,
}: {
  breed: string;
  coatColor: string;
  coatPattern: string;
  posture: string | null;
  environment: string | null;
}): string {
  const breedName = italianBreedName(breed);
  const poseText = posture ? ` in posa ${posture}` : "";
  const environmentText = environment ? `, avvistato in ${environment}` : "";
  return `Un ${breedName} dal mantello ${coatColor} ${coatPattern}${poseText}${environmentText} entra nel tuo CatDex con un'aria curiosa e attenta.`;
}

function funFactForBreed(breed: string, coatPattern: string): string {
  if (breed === "domestic_tabby_cat" || isTabbyPattern(coatPattern)) {
    return "Il disegno tigrato e uno dei mantelli piu comuni nei gatti domestici e puo apparire in tonalita marroni, grigie o arancioni.";
  }

  if (breed === "domestic_black_cat") {
    return "I gatti neri solidi possono mostrare riflessi marroni alla luce del sole, ma CatDex li considera neri solo quando il mantello e quasi interamente scuro.";
  }

  return "Molti gatti domestici hanno origini miste: CatDex privilegia una classificazione prudente quando la razza non e chiara.";
}

function italianBreedName(breed: string): string {
  return {
    domestic_tabby_cat: "gatto domestico tigrato",
    domestic_shorthair_cat: "gatto domestico a pelo corto",
    domestic_black_cat: "gatto domestico nero",
    domestic_white_cat: "gatto domestico bianco",
    domestic_calico_cat: "gatto calico domestico",
    domestic_orange_cat: "gatto domestico arancione",
    domestic_gray_cat: "gatto domestico grigio",
    domestic_longhair_cat: "gatto domestico a pelo lungo",
    siamese: "gatto siamese",
  }[breed] ?? "gatto domestico";
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
      coatColor: "marrone",
      coatPattern: "tigrato",
      eyeColor: "occhi ambrati",
      hairLength: "pelo corto",
      estimatedAge: "adulto",
      traits: [
        { name: "Posa", value: "in osservazione", rarityWeight: 1 },
        { name: "Umore", value: "curioso", rarityWeight: 1 },
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

function realisticCoatColor(coatColor: string, coatPattern: string): string {
  const color = normalizeVisualValue(coatColor);
  const pattern = normalizeVisualValue(coatPattern);
  const tabby = isTabbyPattern(pattern);
  const solid = isSolidPattern(pattern);

  if (tabby) {
    if (isOrangeColor(color)) {
      return "arancione tigrato";
    }

    if (isGrayColor(color)) {
      return "grigio tigrato";
    }

    if (
      isWhiteColor(color) ||
      isCalicoColor(color) ||
      isColorpointColor(color)
    ) {
      return "marrone/grigio tigrato";
    }

    if (isBlackColor(color) && !solid) {
      return "marrone/grigio tigrato";
    }

    if (color.includes("tigrat")) {
      return coatColor;
    }

    if (isBrownColor(color) || color.length === 0 || color === "unknown") {
      return "marrone tigrato";
    }
  }

  if (solid && isBlackColor(color)) {
    return "Nero";
  }

  if (isWhiteColor(color)) {
    return "Bianco";
  }

  return coatColor;
}

function realisticCoatPattern(coatPattern: string): string {
  const normalized = normalizeVisualValue(coatPattern);
  if (
    normalized.includes("tortoiseshell") ||
    normalized.includes("tortie") ||
    normalized.includes("tartarugat")
  ) {
    return "tartarugato";
  }

  if (normalized.includes("tabby")) {
    return "tigrato";
  }

  if (normalized.includes("tigrat")) {
    return "tigrato";
  }

  if (normalized.includes("calico")) {
    return "calico";
  }

  if (normalized.includes("colorpoint") || normalized.includes("pointed")) {
    return "colorpoint";
  }

  if (normalized.includes("solid") || normalized.includes("solido")) {
    return "solido";
  }

  if (normalized.includes("bicolor") || normalized.includes("bicolore")) {
    return "bicolore";
  }

  return coatPattern;
}

function isTabbyPattern(coatPattern: string): boolean {
  const normalized = normalizeVisualValue(coatPattern);
  return normalized.includes("tabby") ||
    normalized.includes("tigrat") ||
    normalized.includes("striped");
}

function isSolidPattern(coatPattern: string): boolean {
  const normalized = normalizeVisualValue(coatPattern);
  return normalized.includes("solid") || normalized.includes("solido");
}

function isBlackColor(coatColor: string): boolean {
  const normalized = normalizeVisualValue(coatColor);
  return normalized.includes("nero") ||
    normalized.includes("black") ||
    normalized.includes("nero solido");
}

function isWhiteColor(coatColor: string): boolean {
  const normalized = normalizeVisualValue(coatColor);
  return normalized.includes("bianco") || normalized.includes("white");
}

function isBrownColor(coatColor: string): boolean {
  const normalized = normalizeVisualValue(coatColor);
  return normalized.includes("marrone") ||
    normalized.includes("brown") ||
    normalized.includes("bruno");
}

function isGrayColor(coatColor: string): boolean {
  const normalized = normalizeVisualValue(coatColor);
  return normalized.includes("grigio") ||
    normalized.includes("gray") ||
    normalized.includes("grey");
}

function isOrangeColor(coatColor: string): boolean {
  const normalized = normalizeVisualValue(coatColor);
  return normalized.includes("arancione") ||
    normalized.includes("orange") ||
    normalized.includes("rosso") ||
    normalized.includes("ginger");
}

function isCalicoColor(coatColor: string): boolean {
  return normalizeVisualValue(coatColor).includes("calico");
}

function isColorpointColor(coatColor: string): boolean {
  const normalized = normalizeVisualValue(coatColor);
  return normalized.includes("colorpoint") || normalized.includes("pointed");
}

function normalizeVisualValue(value: string): string {
  return value
    .trim()
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "");
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

function nullableStringValue(value: unknown): string | null {
  const text = stringValue(value);
  return text.length === 0 ? null : text;
}

function numberValue(value: unknown): number {
  return typeof value === "number" && Number.isFinite(value) ? value : 0;
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
