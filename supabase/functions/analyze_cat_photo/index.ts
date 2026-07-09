type AnalyzeCatPhotoRequest = {
  image_url?: string;
  base64_image?: string;
  photoReference?: string;
  mode?: string;
  task?: string;
  instruction?: string;
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

const CATDEX_ANALYSIS_VERSION = "visual-inspection-v3-general-debug";

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
  dominantVisibleCoatColor?: string;
  visualEvidence?: string;
  visibleEvidence?: string;
  coatColorConfidence?: number;
  colorConfidence?: number;
  coatPattern: string;
  coatPatternConfidence?: number;
  patternConfidence?: number;
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
  uncertaintyReason?: string;
  needsReview?: boolean;
  analyzedAt: string;
};

type CatVisionObservation = {
  baseColor: string | null;
  secondaryColor: string | null;
  whitePresent: boolean;
  orangePresent: boolean;
  blackPresent: boolean;
  coatPattern: string | null;
  eyeColor: string | null;
  hairLength: string | null;
  estimatedAge: string | null;
  posture: string | null;
  expression: string | null;
  environment: string | null;
  visibleConfidence: number;
  safetyStatus: "safe" | "no_cat" | "inappropriate" | "malformed";
};

type CatVisualInspectionConfidence = {
  coatBaseColor: number;
  hasWhite: number;
  coatPattern: number;
  eyeColor: number;
  hairLength: number;
};

type CatVisualInspection = {
  coatBaseColor: string | null;
  hasWhite: boolean;
  coatPattern: string | null;
  eyeColor: string | null;
  hairLength: string | null;
  visibleEyes: boolean;
  estimatedAge: string | null;
  posture: string | null;
  expression: string | null;
  environment: string | null;
  confidence: CatVisualInspectionConfidence;
  reasoningShort: string;
  safetyStatus: "safe" | "no_cat" | "inappropriate" | "malformed";
};

type CatRuleClassification = {
  breed: string;
  confidence: number;
  candidates: CandidateJson[];
  coatColor: string;
  coatPattern: string;
  eyeColor: string;
  hairLength: string;
  estimatedAge: string;
  personality: string;
  rarity: string;
  variant: string;
};

type CatBreedCandidateInspection = {
  breed: string;
  confidence: number;
  reason: string;
};

type CatBreedEvidence = {
  bodySize?: string;
  faceShape?: string;
  earTufts?: boolean;
  lynxTips?: boolean;
  ruffMane?: boolean;
  coatLength?: string;
  tailShape?: string;
  muzzleShape?: string;
};

type CatBreedInspection = {
  primaryBreed: string;
  breedConfidence: number;
  possibleBreeds: CatBreedCandidateInspection[];
  breedEvidence: CatBreedEvidence;
  shouldUseBreedName: boolean;
  reasoningShort: string;
};

type CatLore = {
  story: string;
  funFact: string;
};

type JsonResponseBody = Record<string, unknown>;

const defaultOpenAiModel = "gpt-4o";
const openAiModel = openAiModelFromEnv();
const jsonHeaders = {
  "Content-Type": "application/json",
};
const observedColors = [
  "black",
  "gray",
  "blue_gray",
  "white",
  "orange",
  "cream",
  "brown",
  "chocolate",
  "cinnamon",
  "lilac",
  "calico",
  "tortoiseshell",
  "unknown",
] as const;
const observedPatterns = [
  "solid",
  "mackerel_tabby",
  "classic_tabby",
  "spotted_tabby",
  "ticked_tabby",
  "tabby",
  "bicolor",
  "tuxedo",
  "calico",
  "tortoiseshell",
  "colorpoint",
  "smoke",
  "shaded",
  "unknown",
] as const;
const observedEyeColors = [
  "amber",
  "yellow",
  "green",
  "blue",
  "copper",
  "hazel",
  "odd_eyes",
  "unknown",
] as const;
const observedHairLengths = ["short", "medium", "long", "unknown"] as const;
const observedAges = ["kitten", "adult", "senior", "unknown"] as const;
const observedPostures = [
  "sitting",
  "lying",
  "standing",
  "walking",
  "crouching",
  "unknown",
] as const;
const observedExpressions = [
  "alert",
  "curious",
  "relaxed",
  "sleeping",
  "playful",
  "unknown",
] as const;
const observedEnvironments = [
  "indoor",
  "outdoor",
  "garden",
  "street",
  "house",
  "unknown",
] as const;
const allowedBreedInspectionBreeds = [
  "maine_coon",
  "norwegian_forest_cat",
  "siberian_cat",
  "persian_cat",
  "ragdoll_cat",
  "birman_cat",
  "siamese_cat",
  "british_shorthair_cat",
  "russian_blue_cat",
  "bengal_cat",
  "sphynx_cat",
  "scottish_fold_cat",
  "abyssinian_cat",
  "domestic_longhair_cat",
  "domestic_mediumhair_cat",
  "domestic_shorthair_cat",
  "unknown",
] as const;
Deno.serve(async (request: Request) => {
  const requestId = crypto.randomUUID();
  console.log(`CATDEX_SUPABASE_ANALYSIS_VERSION ${CATDEX_ANALYSIS_VERSION}`);
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
    if (isEyeColorOnlyRequest(body)) {
      const eyeColor = await detectEyeColorFromPhoto({
        imageInput,
        openAiKey,
        requestId,
      });
      return jsonResponse({ eyeColor: eyeColor ?? "Non rilevato" }, 200);
    }

    if (isCoatColorOnlyRequest(body)) {
      const coatBaseColor = await detectCoatBaseColorFromPhoto({
        imageInput,
        openAiKey,
        requestId,
      });
      const coatColor = coatBaseColor === "orange"
        ? "arancione tigrato"
        : coatBaseColor === "gray" || coatBaseColor === "blue_gray"
        ? "grigio tigrato"
        : coatBaseColor === "black"
        ? "nero tigrato"
        : coatBaseColor === "brown"
        ? "marrone/grigio tigrato"
        : "altro";
      return jsonResponse({ coatColor }, 200);
    }

    console.log("CATDEX_VISUAL_INSPECTION_STARTED");
    const aiJson = await analyzeWithOpenAi({
      imageInput,
      locale: body.locale ?? "en",
      openAiKey,
      requestId,
    });
    console.log(`CATDEX_VISUAL_INSPECTION_RAW_JSON ${safeForLog(JSON.stringify(aiJson), 1600)}`);
    const inspection = parseCatVisualInspection(aiJson);
    const finalInspection = await visualInspectionWithRetries({
      inspection,
      imageInput,
      openAiKey,
      requestId,
    });
    const observation = observationFromVisualInspection(finalInspection);
    const breedInspection = await breedInspectionWithFallback({
      visualInspection: finalInspection,
      imageInput,
      openAiKey,
      requestId,
    });
    const analysis = analysisFromObservation(observation, {
      activeEventId: activeEventIdFor(body),
      breedInspection,
    });
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

    console.log(`CATDEX_FINAL_BREED ${analysis.breed}`);
    console.log(`CATDEX_FINAL_COAT_COLOR ${analysis.coatColor}`);
    console.log(`CATDEX_FINAL_COAT_PATTERN ${analysis.coatPattern}`);
    console.log(`CATDEX_FINAL_EYE_COLOR ${analysis.eyeColor}`);
    console.log(`CATDEX_FINAL_DEBUG_VERSION ${CATDEX_ANALYSIS_VERSION}`);
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

function isEyeColorOnlyRequest(body: AnalyzeCatPhotoRequest): boolean {
  return body.task === "eye_color_only" || body.mode === "eye_color_recheck";
}

function isCoatColorOnlyRequest(body: AnalyzeCatPhotoRequest): boolean {
  return body.task === "coat_color_only" || body.mode === "coat_color_recheck";
}

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
          name: "catdex_cat_visual_inspection",
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

async function analyzeBreedWithOpenAi({
  visualInspection,
  imageInput,
  openAiKey,
  requestId,
}: {
  visualInspection: CatVisualInspection;
  imageInput: string;
  openAiKey: string;
  requestId: string;
}): Promise<unknown> {
  console.log("CATDEX_BREED_INSPECTION_STARTED");
  console.log(`[analyze_cat_photo] breed OpenAI request started`, {
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
      temperature: 0,
      response_format: {
        type: "json_schema",
        json_schema: {
          name: "catdex_cat_breed_inspection",
          strict: true,
          schema: breedInspectionJsonSchema(),
        },
      },
      messages: [
        {
          role: "user",
          content: [
            {
              type: "text",
              text: breedInspectionPrompt(visualInspection),
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

  console.log(`[analyze_cat_photo] breed OpenAI response status`, {
    requestId,
    status: response.status,
    ok: response.ok,
  });

  if (!response.ok) {
    const errorBody = await response.text();
    console.error(`[analyze_cat_photo] breed OpenAI error body`, {
      requestId,
      status: response.status,
      body: safeForLog(errorBody, 1200),
    });
    throw new OpenAiRequestError(response.status, errorBody);
  }

  const payload = await response.json();
  const text = extractOutputText(payload);
  if (text === null) {
    throw new MalformedAiResponseError();
  }

  const parsed = parseJsonObject(text);
  console.log(`CATDEX_BREED_INSPECTION_RAW_JSON ${safeForLog(JSON.stringify(parsed), 1600)}`);
  return parsed;
}

async function breedInspectionWithFallback({
  visualInspection,
  imageInput,
  openAiKey,
  requestId,
}: {
  visualInspection: CatVisualInspection;
  imageInput: string;
  openAiKey: string;
  requestId: string;
}): Promise<CatBreedInspection> {
  try {
    const rawBreedInspection = await analyzeBreedWithOpenAi({
      visualInspection,
      imageInput,
      openAiKey,
      requestId,
    });
    const breedInspection = parseCatBreedInspection(rawBreedInspection);
    logBreedInspection(breedInspection);
    return breedInspection;
  } catch (error) {
    console.error(`[analyze_cat_photo] breed inspection failed`, {
      requestId,
      errorName: error instanceof Error ? error.name : "unknown",
      errorMessage: error instanceof Error ? error.message : String(error),
    });
    const fallback = safeFallbackBreedInspection(visualInspection);
    console.log("CATDEX_BREED_INSPECTION_RAW_JSON fallback");
    logBreedInspection(fallback);
    return fallback;
  }
}

async function detectEyeColorFromPhoto({
  imageInput,
  openAiKey,
  requestId,
}: {
  imageInput: string;
  openAiKey: string;
  requestId: string;
}): Promise<string | null> {
  console.log(`[analyze_cat_photo] targeted eye color request started`, {
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
      max_tokens: 120,
      temperature: 0,
      response_format: {
        type: "json_schema",
        json_schema: {
          name: "catdex_eye_color_recheck",
          strict: true,
          schema: eyeColorRecheckJsonSchema(),
        },
      },
      messages: [
        {
          role: "user",
          content: [
            {
              type: "text",
              text: eyeColorRecheckPrompt(),
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

  console.log(`[analyze_cat_photo] targeted eye color response status`, {
    requestId,
    status: response.status,
    ok: response.ok,
  });

  if (!response.ok) {
    const errorBody = await response.text();
    console.error(`[analyze_cat_photo] targeted eye color error body`, {
      requestId,
      status: response.status,
      body: safeForLog(errorBody, 800),
    });
    return null;
  }

  const payload = await response.json();
  const text = extractOutputText(payload);
  if (text === null) {
    return null;
  }

  const parsed = parseJsonObject(text);
  if (typeof parsed !== "object" || parsed === null) {
    return null;
  }

  const eyeColor = stringValue((parsed as Record<string, unknown>).eyeColor);
  return normalizeDetectedEyeColor(eyeColor);
}

async function detectEyeColorEnumFromPhoto({
  imageInput,
  openAiKey,
  requestId,
}: {
  imageInput: string;
  openAiKey: string;
  requestId: string;
}): Promise<string | null> {
  const value = await targetedSingleFieldInspection({
    imageInput,
    openAiKey,
    requestId,
    schemaName: "catdex_eye_color_enum_recheck",
    fieldName: "eyeColor",
    enumValues: [
      "amber",
      "yellow",
      "green",
      "blue",
      "copper",
      "hazel",
      "odd_eyes",
      "unknown",
    ],
    prompt: eyeColorEnumRecheckPrompt(),
  });
  return nullableAllowedValue(value, observedEyeColors);
}

async function detectCoatBaseColorFromPhoto({
  imageInput,
  openAiKey,
  requestId,
}: {
  imageInput: string;
  openAiKey: string;
  requestId: string;
}): Promise<string | null> {
  const value = await targetedSingleFieldInspection({
    imageInput,
    openAiKey,
    requestId,
    schemaName: "catdex_coat_base_color_recheck",
    fieldName: "coatBaseColor",
    enumValues: [
      "black",
      "gray",
      "blue_gray",
      "white",
      "orange",
      "cream",
      "brown",
      "chocolate",
      "cinnamon",
      "lilac",
      "calico",
      "tortoiseshell",
      "unknown",
    ],
    prompt: coatBaseColorRecheckPrompt(),
  });
  return nullableAllowedValue(value, observedColors);
}

async function detectCoatPatternFromPhoto({
  imageInput,
  openAiKey,
  requestId,
}: {
  imageInput: string;
  openAiKey: string;
  requestId: string;
}): Promise<string | null> {
  const value = await targetedSingleFieldInspection({
    imageInput,
    openAiKey,
    requestId,
    schemaName: "catdex_coat_pattern_recheck",
    fieldName: "coatPattern",
    enumValues: [
      "solid",
      "bicolor",
      "tuxedo",
      "tabby",
      "mackerel_tabby",
      "spotted_tabby",
      "classic_tabby",
      "ticked_tabby",
      "calico",
      "tortoiseshell",
      "colorpoint",
      "smoke",
      "shaded",
      "unknown",
    ],
    prompt: coatPatternRecheckPrompt(),
  });
  return nullableAllowedValue(value, observedPatterns);
}

async function targetedSingleFieldInspection({
  imageInput,
  openAiKey,
  requestId,
  schemaName,
  fieldName,
  enumValues,
  prompt,
}: {
  imageInput: string;
  openAiKey: string;
  requestId: string;
  schemaName: string;
  fieldName: string;
  enumValues: string[];
  prompt: string;
}): Promise<string | null> {
  console.log(`[analyze_cat_photo] targeted ${fieldName} request started`, {
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
      max_tokens: 80,
      temperature: 0,
      response_format: {
        type: "json_schema",
        json_schema: {
          name: schemaName,
          strict: true,
          schema: singleFieldJsonSchema(fieldName, enumValues),
        },
      },
      messages: [
        {
          role: "user",
          content: [
            { type: "text", text: prompt },
            { type: "image_url", image_url: { url: imageInput } },
          ],
        },
      ],
    }),
  });

  if (!response.ok) {
    const errorBody = await response.text();
    console.error(`[analyze_cat_photo] targeted ${fieldName} error`, {
      requestId,
      status: response.status,
      body: safeForLog(errorBody, 800),
    });
    return null;
  }

  const payload = await response.json();
  const text = extractOutputText(payload);
  if (text === null) {
    return null;
  }

  const parsed = parseJsonObject(text);
  if (typeof parsed !== "object" || parsed === null) {
    return null;
  }

  const value = stringValue((parsed as Record<string, unknown>)[fieldName]);
  return value.length === 0 ? null : value;
}

function observationJsonSchema(): Record<string, unknown> {
  return {
    type: "object",
    additionalProperties: false,
    required: [
      "coatBaseColor",
      "hasWhite",
      "coatPattern",
      "eyeColor",
      "hairLength",
      "visibleEyes",
      "estimatedAge",
      "posture",
      "expression",
      "environment",
      "confidence",
      "reasoningShort",
      "safetyStatus",
    ],
    properties: {
      coatBaseColor: nullableEnumSchema(observedColors),
      hasWhite: { type: "boolean" },
      coatPattern: nullableEnumSchema(observedPatterns),
      eyeColor: nullableEnumSchema(observedEyeColors),
      hairLength: nullableEnumSchema(observedHairLengths),
      visibleEyes: { type: "boolean" },
      estimatedAge: nullableEnumSchema(observedAges),
      posture: nullableEnumSchema(observedPostures),
      expression: nullableEnumSchema(observedExpressions),
      environment: nullableEnumSchema(observedEnvironments),
      confidence: {
        type: "object",
        additionalProperties: false,
        required: [
          "coatBaseColor",
          "hasWhite",
          "coatPattern",
          "eyeColor",
          "hairLength",
        ],
        properties: {
          coatBaseColor: { type: "number" },
          hasWhite: { type: "number" },
          coatPattern: { type: "number" },
          eyeColor: { type: "number" },
          hairLength: { type: "number" },
        },
      },
      reasoningShort: { type: "string" },
      safetyStatus: { type: "string" },
    },
  };
}

function breedInspectionJsonSchema(): Record<string, unknown> {
  return {
    type: "object",
    additionalProperties: false,
    required: [
      "primaryBreed",
      "breedConfidence",
      "possibleBreeds",
      "breedEvidence",
      "shouldUseBreedName",
      "reasoningShort",
    ],
    properties: {
      primaryBreed: {
        type: "string",
        enum: allowedBreedInspectionBreeds,
      },
      breedConfidence: { type: "number" },
      possibleBreeds: {
        type: "array",
        maxItems: 5,
        items: {
          type: "object",
          additionalProperties: false,
          required: ["breed", "confidence", "reason"],
          properties: {
            breed: {
              type: "string",
              enum: allowedBreedInspectionBreeds,
            },
            confidence: { type: "number" },
            reason: { type: "string" },
          },
        },
      },
      breedEvidence: {
        type: "object",
        additionalProperties: false,
        required: [
          "bodySize",
          "faceShape",
          "earTufts",
          "lynxTips",
          "ruffMane",
          "coatLength",
          "tailShape",
          "muzzleShape",
        ],
        properties: {
          bodySize: { type: "string" },
          faceShape: { type: "string" },
          earTufts: { type: "boolean" },
          lynxTips: { type: "boolean" },
          ruffMane: { type: "boolean" },
          coatLength: { type: "string" },
          tailShape: { type: "string" },
          muzzleShape: { type: "string" },
        },
      },
      shouldUseBreedName: { type: "boolean" },
      reasoningShort: { type: "string" },
    },
  };
}

function eyeColorRecheckJsonSchema(): Record<string, unknown> {
  return {
    type: "object",
    additionalProperties: false,
    required: ["eyeColor"],
    properties: {
      eyeColor: {
        type: "string",
        enum: [
          "occhi ambrati",
          "occhi gialli",
          "occhi verdi",
          "occhi azzurri",
          "occhi eterocromi",
          "Non rilevato",
        ],
      },
    },
  };
}

function singleFieldJsonSchema(
  fieldName: string,
  enumValues: string[],
): Record<string, unknown> {
  return {
    type: "object",
    additionalProperties: false,
    required: [fieldName],
    properties: {
      [fieldName]: {
        type: "string",
        enum: enumValues,
      },
    },
  };
}

function nullableEnumSchema(values: readonly string[]): Record<string, unknown> {
  return {
    anyOf: [
      { type: "string", enum: values },
      { type: "null" },
    ],
  };
}

function coatBaseColorRecheckPrompt(): string {
  return [
    "Look only at the cat's main fur base color, ignoring shadows and stripe darkness.",
    "Return JSON only.",
    "Return exactly one: black, gray, blue_gray, white, orange, cream, brown, chocolate, cinnamon, lilac, calico, tortoiseshell, unknown.",
    "orange, ginger, marmalade, red, golden-orange, or warm copper fur => orange.",
    "cool gray, silver, slate, or blue-gray fur => gray or blue_gray.",
    "brown or taupe non-orange fur => brown.",
    "mixed orange/black mottled fur => tortoiseshell.",
    "white + orange + black patches => calico.",
    "Do not return brown or gray for orange/ginger cats.",
  ].join(" ");
}

function coatPatternRecheckPrompt(): string {
  return [
    "Look only at the cat's coat markings and white distribution.",
    "Return JSON only.",
    "Return exactly one: solid, bicolor, tuxedo, tabby, mackerel_tabby, classic_tabby, spotted_tabby, ticked_tabby, calico, tortoiseshell, colorpoint, smoke, shaded, unknown.",
    "visible stripes => tabby or a more specific tabby subtype.",
    "narrow vertical stripes => mackerel_tabby.",
    "swirled bullseye markings => classic_tabby.",
    "spots => spotted_tabby.",
    "agouti/ticked fur with subtle stripes => ticked_tabby.",
    "large white patches with another color => bicolor.",
    "black/white formal pattern => tuxedo.",
    "orange/black mottling => tortoiseshell.",
    "white/orange/black patches => calico.",
  ].join(" ");
}

function eyeColorEnumRecheckPrompt(): string {
  return [
    "Look only at the cat's irises.",
    "If the eyes are partially visible but shadowed, choose the closest visible color.",
    "Return JSON only.",
    "Return exactly one: amber, yellow, green, blue, copper, hazel, odd_eyes, unknown.",
    "If eyes are visible, do not return unknown.",
    "amber, orange, copper, or golden-orange eyes => amber or copper.",
    "yellow or gold eyes => yellow.",
    "green eyes => green.",
    "blue eyes => blue.",
    "two different eye colors => odd_eyes.",
    "Use unknown only if eyes are closed, too dark, hidden, blurred, or impossible to see.",
  ].join(" ");
}

function eyeColorRecheckPrompt(): string {
  return [
    "Look only at the cat's eyes.",
    "Are the cat's eyes visible? If yes, choose the closest eye color.",
    "Return JSON only.",
    "Return one of exactly: occhi ambrati, occhi gialli, occhi verdi, occhi azzurri, occhi eterocromi, Non rilevato.",
    "Use occhi ambrati for amber, copper, orange, yellow-orange, or golden-orange eyes.",
    "Use occhi gialli for yellow or gold eyes.",
    "Use Non rilevato only if the eyes are closed, hidden, outside frame, or impossible to see.",
    "For gray/white bicolor cats with visible orange or yellow-orange eyes, prefer occhi ambrati.",
  ].join(" ");
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
    "You are a cat visual inspector.",
    "Analyze ONLY the visible cat in the image.",
    "Ignore humans and never identify people.",
    "Reject inappropriate images. If no cat is visible, set safetyStatus to no_cat.",
    "Return strict JSON only. No markdown. No explanation outside JSON.",
    "Analyze only objective visible cat facts. Do not return breed, rarity, variant, story, funFact, personality, or candidates.",
    "Do not guess breed before visual traits. First identify objective visual traits.",
    "Separate color from pattern.",
    "coatBaseColor = main visible fur color.",
    "hasWhite = true if there are visible white fur areas.",
    "coatPattern = markings or structure such as tabby, bicolor, tuxedo, solid, calico, tortoiseshell, colorpoint.",
    "Important color rules:",
    "orange, ginger, marmalade, red, golden-orange, warm copper fur => coatBaseColor orange.",
    "cool gray, silver, slate, blue-gray fur => coatBaseColor gray or blue_gray.",
    "true black fur => coatBaseColor black.",
    "pure white or mostly white fur => coatBaseColor white.",
    "cream or pale warm beige fur => coatBaseColor cream.",
    "brown or taupe non-orange fur => coatBaseColor brown.",
    "mixed orange/black mottled fur => coatPattern tortoiseshell.",
    "white + orange + black patches => coatPattern calico.",
    "Important pattern rules:",
    "visible stripes => tabby or a more specific tabby subtype.",
    "narrow vertical stripes => mackerel_tabby.",
    "swirled bullseye markings => classic_tabby.",
    "spots => spotted_tabby.",
    "agouti/ticked fur with subtle stripes => ticked_tabby.",
    "two-color cat with white patches => bicolor.",
    "black, gray, orange, or brown plus white chest/face/paws can be bicolor.",
    "black/white formal pattern can be tuxedo.",
    "Siamese-like darker ears/face/paws/tail => colorpoint.",
    "no visible markings => solid.",
    "Important eye rules:",
    "If the cat's eyes are visible, visibleEyes must be true and eyeColor must NOT be unknown.",
    "amber/orange/copper/golden-orange eyes => amber or copper.",
    "yellow/gold eyes => yellow.",
    "green eyes => green.",
    "blue eyes => blue.",
    "two different eye colors => odd_eyes.",
    "Only use unknown eyeColor when eyes are closed, hidden, blurred, or outside frame.",
    "Use hairLength long only if fur is clearly long; otherwise choose short, medium, or unknown.",
    "All confidence values must be numbers from 0.0 to 1.0.",
    "reasoningShort must be one short non-user-facing sentence.",
    "Allowed coatBaseColor values only: black, gray, blue_gray, white, orange, cream, brown, chocolate, cinnamon, lilac, calico, tortoiseshell, unknown, null.",
    "Allowed coatPattern values only: solid, bicolor, tuxedo, tabby, mackerel_tabby, classic_tabby, spotted_tabby, ticked_tabby, calico, tortoiseshell, colorpoint, smoke, shaded, unknown, null.",
    "Allowed eyeColor values only: amber, yellow, green, blue, copper, hazel, odd_eyes, unknown, null.",
    "Allowed hairLength values only: short, medium, long, unknown, null.",
    "Allowed estimatedAge values only: kitten, adult, senior, unknown, null.",
    "Allowed posture values only: sitting, lying, standing, walking, crouching, unknown, null.",
    "Allowed expression values only: alert, curious, relaxed, sleeping, playful, unknown, null.",
    "Allowed environment values only: indoor, outdoor, garden, street, house, unknown, null.",
    "JSON keys: coatBaseColor, hasWhite, coatPattern, eyeColor, hairLength, visibleEyes, estimatedAge, posture, environment, expression, confidence, reasoningShort, safetyStatus.",
    `Requested locale is ${locale}; observation values may be simple English visual labels because the backend rule engine localizes final output.`,
  ].join(" ");
}

function breedInspectionPrompt(visualInspection: CatVisualInspection): string {
  return [
    "You are a cautious cat breed visual inspector.",
    "Use the image and the already detected visual traits to estimate whether the cat resembles a known breed.",
    "Do not force a breed. Most cats are mixed domestic cats.",
    "Only choose a specific breed when multiple strong visual traits match.",
    "If evidence is weak, choose a domestic hair-length breed and set shouldUseBreedName false.",
    "Already detected visual traits:",
    JSON.stringify({
      coatBaseColor: visualInspection.coatBaseColor,
      hasWhite: visualInspection.hasWhite,
      coatPattern: visualInspection.coatPattern,
      eyeColor: visualInspection.eyeColor,
      visibleEyes: visualInspection.visibleEyes,
      hairLength: visualInspection.hairLength,
      estimatedAge: visualInspection.estimatedAge,
      posture: visualInspection.posture,
      expression: visualInspection.expression,
      environment: visualInspection.environment,
    }),
    "Maine Coon indicators: large or robust body, long shaggy coat, prominent neck ruff or mane, large ears, lynx tips or ear tufts, square muzzle, long bushy tail, wild or majestic facial structure.",
    "Norwegian Forest Cat indicators: long waterproof-looking coat, triangular head, almond eyes, strong body, bushy tail, less square muzzle than Maine Coon.",
    "Siberian indicators: rounded strong body, dense triple coat, rounded face, medium-large ears, less square muzzle than Maine Coon.",
    "Persian indicators: very flat or round face, short nose, long dense coat, round eyes.",
    "Ragdoll or Birman indicators: colorpoint pattern, blue eyes, semi-long coat.",
    "Siamese indicators: colorpoint pattern, blue eyes, slim body, short coat.",
    "British Shorthair indicators: dense plush short coat, round head, round eyes, stocky body.",
    "Russian Blue indicators: solid blue-gray coat, green eyes, elegant body, short plush coat.",
    "Bengal indicators: rosettes or strong spotted pattern, athletic body, wild-looking markings.",
    "Sphynx indicators: hairless or nearly hairless body.",
    "Scottish Fold indicators: folded ears.",
    "Abyssinian indicators: ticked coat, slender athletic body, wedge-shaped head.",
    "If the cat is simply long-haired but breed evidence is weak, return primaryBreed domestic_longhair_cat and shouldUseBreedName false.",
    "If the cat strongly resembles Maine Coon, return primaryBreed maine_coon, breedConfidence >= 0.75, and shouldUseBreedName true.",
    "If confidence is medium, include possible breeds but set shouldUseBreedName false.",
    "Return strict JSON only. No markdown. No extra text.",
  ].join("\n");
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

function buildAnalysisFromAiResponse(
  value: unknown,
  context: { activeEventId: string | null; breedInspection?: CatBreedInspection },
): AnalysisJson {
  const observation = observationFromVisualInspection(
    parseCatVisualInspection(value),
  );
  return analysisFromObservation(observation, context);
}

function parseCatVisualInspection(value: unknown): CatVisualInspection {
  if (typeof value !== "object" || value === null) {
    throw new MalformedAiResponseError();
  }

  const item = value as Record<string, unknown>;
  const safetyStatus = stringValue(item.safetyStatus);
  if (safetyStatus === "no_cat" || safetyStatus === "inappropriate") {
    return {
      ...safeFallbackVisualInspection(),
      safetyStatus,
    };
  }

  const confidenceMap = typeof item.confidence === "object" &&
      item.confidence !== null
    ? item.confidence as Record<string, unknown>
    : {};

  const inspection: CatVisualInspection = {
    coatBaseColor: nullableAllowedValue(item.coatBaseColor, observedColors),
    hasWhite: booleanValue(item.hasWhite),
    coatPattern: nullableAllowedValue(item.coatPattern, observedPatterns),
    eyeColor: nullableAllowedValue(item.eyeColor, observedEyeColors),
    hairLength: nullableAllowedValue(item.hairLength, observedHairLengths),
    visibleEyes: booleanValue(item.visibleEyes),
    estimatedAge: nullableAllowedValue(item.estimatedAge, observedAges),
    posture: nullableAllowedValue(item.posture, observedPostures),
    expression: nullableAllowedValue(item.expression, observedExpressions),
    environment: nullableAllowedValue(item.environment, observedEnvironments),
    confidence: {
      coatBaseColor: confidenceValue(confidenceMap.coatBaseColor),
      hasWhite: confidenceValue(confidenceMap.hasWhite),
      coatPattern: confidenceValue(confidenceMap.coatPattern),
      eyeColor: confidenceValue(confidenceMap.eyeColor),
      hairLength: confidenceValue(confidenceMap.hairLength),
    },
    reasoningShort: safeForLog(stringValue(item.reasoningShort), 180),
    safetyStatus: "safe",
  };

  validateVisualInspection(inspection);
  return inspection;
}

function validateVisualInspection(inspection: CatVisualInspection): void {
  for (const value of Object.values(inspection.confidence)) {
    if (value < 0 || value > 1) {
      throw new MalformedAiResponseError();
    }
  }
}

function parseCatBreedInspection(value: unknown): CatBreedInspection {
  if (typeof value !== "object" || value === null) {
    throw new MalformedAiResponseError();
  }

  const item = value as Record<string, unknown>;
  const possibleBreedsValue = Array.isArray(item.possibleBreeds)
    ? item.possibleBreeds
    : [];
  const possibleBreeds = possibleBreedsValue
    .map((entry): CatBreedCandidateInspection | null => {
      if (typeof entry !== "object" || entry === null) {
        return null;
      }
      const candidate = entry as Record<string, unknown>;
      const breed = allowedBreedValue(candidate.breed);
      if (breed === null) {
        return null;
      }
      return {
        breed,
        confidence: confidenceValue(candidate.confidence),
        reason: safeForLog(stringValue(candidate.reason), 180),
      };
    })
    .filter((entry): entry is CatBreedCandidateInspection => entry !== null)
    .slice(0, 5);

  const evidenceValue = typeof item.breedEvidence === "object" &&
      item.breedEvidence !== null
    ? item.breedEvidence as Record<string, unknown>
    : {};

  const breedInspection: CatBreedInspection = {
    primaryBreed: allowedBreedValue(item.primaryBreed) ?? "unknown",
    breedConfidence: confidenceValue(item.breedConfidence),
    possibleBreeds,
    breedEvidence: {
      bodySize: stringValue(evidenceValue.bodySize),
      faceShape: stringValue(evidenceValue.faceShape),
      earTufts: booleanValue(evidenceValue.earTufts),
      lynxTips: booleanValue(evidenceValue.lynxTips),
      ruffMane: booleanValue(evidenceValue.ruffMane),
      coatLength: stringValue(evidenceValue.coatLength),
      tailShape: stringValue(evidenceValue.tailShape),
      muzzleShape: stringValue(evidenceValue.muzzleShape),
    },
    shouldUseBreedName: booleanValue(item.shouldUseBreedName),
    reasoningShort: safeForLog(stringValue(item.reasoningShort), 180),
  };

  if (breedInspection.breedConfidence < 0 || breedInspection.breedConfidence > 1) {
    throw new MalformedAiResponseError();
  }

  return breedInspection;
}

function allowedBreedValue(value: unknown): string | null {
  const raw = stringValue(value);
  return (allowedBreedInspectionBreeds as readonly string[]).includes(raw)
    ? raw
    : null;
}

function safeFallbackBreedInspection(
  visualInspection: CatVisualInspection,
): CatBreedInspection {
  const domesticBreed = domesticBreedForHairLength(
    realisticHairLength(visualInspection.hairLength),
  );
  return {
    primaryBreed: domesticBreed,
    breedConfidence: 0.35,
    possibleBreeds: [{ breed: domesticBreed, confidence: 0.35, reason: "Fallback domestic classification." }],
    breedEvidence: {
      bodySize: "unknown",
      faceShape: "unknown",
      earTufts: false,
      lynxTips: false,
      ruffMane: false,
      coatLength: visualInspection.hairLength ?? "unknown",
      tailShape: "unknown",
      muzzleShape: "unknown",
    },
    shouldUseBreedName: false,
    reasoningShort: "Fallback breed inspection.",
  };
}

function logBreedInspection(breedInspection: CatBreedInspection): void {
  console.log(`CATDEX_BREED_PRIMARY ${breedInspection.primaryBreed}`);
  console.log(`CATDEX_BREED_CONFIDENCE ${breedInspection.breedConfidence}`);
  console.log(`CATDEX_BREED_SHOULD_USE_NAME ${breedInspection.shouldUseBreedName}`);
  console.log(
    `CATDEX_BREED_CANDIDATES ${
      safeForLog(JSON.stringify(breedInspection.possibleBreeds), 1200)
    }`,
  );
}

function safeFallbackVisualInspection(): CatVisualInspection {
  return {
    coatBaseColor: null,
    hasWhite: false,
    coatPattern: null,
    eyeColor: null,
    hairLength: null,
    visibleEyes: false,
    estimatedAge: null,
    posture: null,
    expression: null,
    environment: null,
    confidence: {
      coatBaseColor: 0.35,
      hasWhite: 0.35,
      coatPattern: 0.35,
      eyeColor: 0.35,
      hairLength: 0.35,
    },
    reasoningShort: "Fallback visual inspection.",
    safetyStatus: "safe",
  };
}

function catFaceLikelyVisible(inspection: CatVisualInspection): boolean {
  if (inspection.visibleEyes) {
    return true;
  }

  const expression = normalizeVisualValue(inspection.expression ?? "");
  const posture = normalizeVisualValue(inspection.posture ?? "");
  const reasoning = normalizeVisualValue(inspection.reasoningShort);
  return (
    expression.length > 0 && expression !== "unknown"
  ) ||
    reasoning.includes("face") ||
    reasoning.includes("eyes") ||
    reasoning.includes("muzzle") ||
    reasoning.includes("head") ||
    posture.includes("sitting") ||
    posture.includes("standing");
}

function observationFromVisualInspection(
  inspection: CatVisualInspection,
): CatVisionObservation {
  const baseColor = inspection.coatBaseColor;
  return {
    baseColor,
    secondaryColor: inspection.hasWhite ? "white" : null,
    whitePresent: inspection.hasWhite,
    orangePresent: baseColor === "orange",
    blackPresent: baseColor === "black",
    coatPattern: inspection.coatPattern,
    eyeColor: inspection.eyeColor,
    hairLength: inspection.hairLength,
    estimatedAge: inspection.estimatedAge,
    posture: inspection.posture,
    expression: inspection.expression,
    environment: inspection.environment,
    visibleConfidence: averageConfidence(inspection.confidence),
    safetyStatus: inspection.safetyStatus,
  };
}

async function visualInspectionWithRetries({
  inspection,
  imageInput,
  openAiKey,
  requestId,
}: {
  inspection: CatVisualInspection;
  imageInput: string;
  openAiKey: string;
  requestId: string;
}): Promise<CatVisualInspection> {
  let updated = inspection;
  console.log("CATDEX_VISUAL_INSPECTION_VALID true");

  const retryReasons: string[] = [];
  const recheckedFields = new Set<string>();
  const lowConfidenceThreshold = 0.75;

  const recheckEyeColor = async (reason: string) => {
    if (recheckedFields.has("eyeColor")) {
      return;
    }
    recheckedFields.add("eyeColor");
    retryReasons.push(reason);
    console.log("CATDEX_RECHECK_FIELD eyeColor");
    console.log("CATDEX_RECHECK_STARTED true");
    const eyeColor = await detectEyeColorEnumFromPhoto({
      imageInput,
      openAiKey,
      requestId,
    });
    console.log(`CATDEX_RECHECK_RESULT ${eyeColor ?? "-"}`);
    console.log(`CATDEX_EYE_RECHECK_RESULT ${eyeColor ?? "-"}`);
    if (!isUnknownValue(eyeColor)) {
      updated = {
        ...updated,
        eyeColor,
        confidence: { ...updated.confidence, eyeColor: 0.9 },
      };
      console.log("CATDEX_RECHECK_APPLIED true");
      console.log("CATDEX_EYE_RECHECK_APPLIED true");
      return;
    }
    console.log("CATDEX_RECHECK_APPLIED false");
    console.log("CATDEX_EYE_RECHECK_APPLIED false");
  };

  const recheckCoatBaseColor = async (reason: string) => {
    if (recheckedFields.has("coatBaseColor")) {
      return;
    }
    recheckedFields.add("coatBaseColor");
    retryReasons.push(reason);
    console.log("CATDEX_RECHECK_FIELD coatBaseColor");
    console.log("CATDEX_RECHECK_STARTED true");
    const coatBaseColor = await detectCoatBaseColorFromPhoto({
      imageInput,
      openAiKey,
      requestId,
    });
    console.log(`CATDEX_RECHECK_RESULT ${coatBaseColor ?? "-"}`);
    if (!isUnknownValue(coatBaseColor)) {
      updated = {
        ...updated,
        coatBaseColor,
        confidence: { ...updated.confidence, coatBaseColor: 0.9 },
      };
      console.log("CATDEX_RECHECK_APPLIED true");
      return;
    }
    console.log("CATDEX_RECHECK_APPLIED false");
  };

  const recheckCoatPattern = async (reason: string) => {
    if (recheckedFields.has("coatPattern")) {
      return;
    }
    recheckedFields.add("coatPattern");
    retryReasons.push(reason);
    console.log("CATDEX_RECHECK_FIELD coatPattern");
    console.log("CATDEX_RECHECK_STARTED true");
    const coatPattern = await detectCoatPatternFromPhoto({
      imageInput,
      openAiKey,
      requestId,
    });
    console.log(`CATDEX_RECHECK_RESULT ${coatPattern ?? "-"}`);
    if (!isUnknownValue(coatPattern)) {
      updated = {
        ...updated,
        coatPattern,
        confidence: { ...updated.confidence, coatPattern: 0.9 },
      };
      console.log("CATDEX_RECHECK_APPLIED true");
      return;
    }
    console.log("CATDEX_RECHECK_APPLIED false");
  };

  const faceVisibleEyeRecheckNeeded = isUnknownValue(updated.eyeColor) &&
    !updated.visibleEyes &&
    catFaceLikelyVisible(updated);
  console.log(
    `CATDEX_EYE_RECHECK_FOR_FACE_VISIBLE_STARTED ${faceVisibleEyeRecheckNeeded}`,
  );
  if (
    (updated.visibleEyes &&
      (isUnknownValue(updated.eyeColor) ||
        updated.confidence.eyeColor < lowConfidenceThreshold)) ||
    faceVisibleEyeRecheckNeeded
  ) {
    await recheckEyeColor(
      faceVisibleEyeRecheckNeeded
        ? "eyeColor_unknown_face_visible"
        : isUnknownValue(updated.eyeColor)
        ? "eyeColor_unknown_visibleEyes"
        : "eyeColor_low_confidence",
    );
  }

  if (
    isUnknownValue(updated.coatBaseColor) ||
    updated.confidence.coatBaseColor < lowConfidenceThreshold
  ) {
    await recheckCoatBaseColor(
      isUnknownValue(updated.coatBaseColor)
        ? "coatBaseColor_unknown"
        : "coatBaseColor_low_confidence",
    );
  }

  if (
    isUnknownValue(updated.coatPattern) ||
    updated.confidence.coatPattern < lowConfidenceThreshold
  ) {
    await recheckCoatPattern(
      isUnknownValue(updated.coatPattern)
        ? "coatPattern_unknown"
        : "coatPattern_low_confidence",
    );
  }

  if (
    isTabbyPattern(updated.coatPattern ?? "") &&
    (updated.coatBaseColor === "brown" ||
      updated.coatBaseColor === "gray" ||
      isUnknownValue(updated.coatBaseColor))
  ) {
    await recheckCoatBaseColor("tabby_base_color_ambiguous");
  }

  if (
    updated.hasWhite &&
    !isBicolorPattern(updated.coatPattern ?? "") &&
    updated.coatPattern !== "calico" &&
    updated.coatPattern !== "colorpoint"
  ) {
    await recheckCoatPattern("hasWhite_pattern_guard");
  }

  if (
    isBicolorPattern(updated.coatPattern ?? "") &&
    isUnknownValue(updated.coatBaseColor)
  ) {
    await recheckCoatBaseColor("bicolor_base_color_unknown");
  }

  console.log(
    `CATDEX_VISUAL_INSPECTION_RETRY_REASON ${
      retryReasons.length === 0 ? "-" : retryReasons.join(",")
    }`,
  );
  console.log(
    `CATDEX_VISUAL_INSPECTION_FINAL_JSON ${
      safeForLog(JSON.stringify(updated), 1600)
    }`,
  );
  return updated;
}

async function observationWithTargetedEyeColor({
  observation,
  imageInput,
  openAiKey,
  requestId,
}: {
  observation: CatVisionObservation;
  imageInput: string;
  openAiKey: string;
  requestId: string;
}): Promise<CatVisionObservation> {
  const mainEyeColor = realisticEyeColor(observation.eyeColor);
  const needsRecheck = isMissingEyeColor(mainEyeColor);
  console.log(`CATDEX_EYE_COLOR_MAIN_ANALYSIS ${mainEyeColor}`);
  console.log(`CATDEX_EYE_COLOR_RECHECK_STARTED ${needsRecheck}`);

  if (
    !needsRecheck ||
    observation.safetyStatus === "no_cat" ||
    observation.safetyStatus === "inappropriate"
  ) {
    console.log("CATDEX_EYE_COLOR_RECHECK_RESULT -");
    console.log(`CATDEX_EYE_COLOR_NORMALIZED ${mainEyeColor}`);
    console.log("CATDEX_EYE_COLOR_DECISION main_analysis");
    return observation;
  }

  const recheckResult = await detectEyeColorFromPhoto({
    imageInput,
    openAiKey,
    requestId,
  });
  const normalizedRecheck = realisticEyeColor(recheckResult);
  console.log(`CATDEX_EYE_COLOR_RECHECK_RESULT ${normalizedRecheck}`);

  if (!isMissingEyeColor(normalizedRecheck)) {
    console.log(`CATDEX_EYE_COLOR_NORMALIZED ${normalizedRecheck}`);
    console.log("CATDEX_EYE_COLOR_DECISION recheck");
    return {
      ...observation,
      eyeColor: eyeColorEnumFromItalian(normalizedRecheck),
    };
  }

  console.log(`CATDEX_EYE_COLOR_NORMALIZED ${mainEyeColor}`);
  console.log("CATDEX_EYE_COLOR_DECISION not_visible");
  return observation;
}

function parseVisionEngineObservation(value: unknown): CatVisionObservation {
  // Vision Engine: OpenAI is allowed to return only controlled, objective
  // morphology observations. Breed, rarity, story, funFact, and personality are
  // intentionally ignored even if a model tries to include them.
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
    baseColor: nullableAllowedValue(item.baseColor, observedColors),
    secondaryColor: nullableAllowedValue(item.secondaryColor, observedColors),
    whitePresent: booleanValue(item.whitePresent),
    orangePresent: booleanValue(item.orangePresent),
    blackPresent: booleanValue(item.blackPresent),
    coatPattern: nullableAllowedValue(item.coatPattern, observedPatterns),
    eyeColor: nullableAllowedValue(item.eyeColor, observedEyeColors),
    hairLength: nullableAllowedValue(item.hairLength, observedHairLengths),
    estimatedAge: nullableAllowedValue(item.estimatedAge, observedAges),
    posture: nullableAllowedValue(item.posture, observedPostures),
    expression: nullableAllowedValue(item.expression, observedExpressions),
    environment: nullableAllowedValue(item.environment, observedEnvironments),
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
    dominantVisibleCoatColor: analysis.dominantVisibleCoatColor,
    visualEvidence: analysis.visualEvidence,
    visibleEvidence: analysis.visibleEvidence,
    coatColorConfidence: analysis.coatColorConfidence,
    colorConfidence: analysis.colorConfidence,
    coatPattern: analysis.coatPattern,
    coatPatternConfidence: analysis.coatPatternConfidence,
    patternConfidence: analysis.patternConfidence,
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
    uncertaintyReason: analysis.uncertaintyReason,
    needsReview: analysis.needsReview,
    analyzedAt: analysis.analyzedAt,
    debugVersion: CATDEX_ANALYSIS_VERSION,
  };
}

function safeFallbackObservation(): CatVisionObservation {
  return {
    baseColor: null,
    secondaryColor: null,
    whitePresent: false,
    orangePresent: false,
    blackPresent: false,
    coatPattern: null,
    eyeColor: null,
    hairLength: null,
    estimatedAge: null,
    posture: null,
    expression: null,
    environment: null,
    visibleConfidence: 0.35,
    safetyStatus: "safe",
  };
}

function analysisFromObservation(
  observation: CatVisionObservation,
  context: { activeEventId: string | null; breedInspection?: CatBreedInspection },
): AnalysisJson {
  if (
    observation.safetyStatus === "no_cat" ||
    observation.safetyStatus === "inappropriate"
  ) {
    return {
      ...safeFallbackAnalysis(),
      safetyStatus: observation.safetyStatus,
    };
  }

  const classification = classifyWithRuleEngine(observation, context);
  const lore = generateLoreWithLoreEngine(observation, classification);

  return {
    breed: classification.breed,
    confidence: classification.confidence,
    candidates: classification.candidates,
    coatColor: classification.coatColor,
    coatPattern: classification.coatPattern,
    eyeColor: classification.eyeColor,
    hairLength: classification.hairLength,
    estimatedAge: classification.estimatedAge,
    traits: traitsFromObservation({
      coatColor: classification.coatColor,
      coatPattern: classification.coatPattern,
      eyeColor: classification.eyeColor,
      hairLength: classification.hairLength,
      estimatedAge: classification.estimatedAge,
      posture: observation.posture,
      expression: observation.expression,
      environment: observation.environment,
    }),
    personality: classification.personality,
    rarity: classification.rarity,
    variant: classification.variant,
    story: lore.story,
    funFact: lore.funFact,
    safetyStatus: "safe",
    analyzedAt: new Date().toISOString(),
  };
}

function classifyWithRuleEngine(
  observation: CatVisionObservation,
  context: { activeEventId: string | null; breedInspection?: CatBreedInspection },
): CatRuleClassification {
  // Rule Engine: deterministic backend classification only. No GPT breed,
  // rarity, or variant classifications are consumed here.
  const coatPattern = realisticCoatPattern(
    observation.coatPattern ?? "unknown",
  );
  const rawCoatColor = coatColorFromObservation(
    observation.baseColor,
    observation.secondaryColor,
    observation.whitePresent,
    observation.orangePresent,
    observation.blackPresent,
    coatPattern,
  );
  const coatColor = normalizeCoatColorFromObservation(
    observation,
    rawCoatColor,
    coatPattern,
  );
  const hairLength = realisticHairLength(observation.hairLength);
  const eyeColor = realisticEyeColor(observation.eyeColor);
  const estimatedAge = italianAgeOrFallback(observation.estimatedAge, "adulto");
  const confidence = Math.max(0.35, observation.visibleConfidence);
  const visualBreed = breedFromObservationRules({
    coatColor,
    coatPattern,
    hairLength,
    eyeColor,
    confidence,
  });
  const breed = breedFromBreedInspection({
    visualBreed,
    hairLength,
    breedInspection: context.breedInspection,
  });
  const finalConfidence = confidenceForFinalBreed(
    breed,
    confidence,
    context.breedInspection,
  );
  const candidates = candidatesForBreed({
    breed,
    confidence: finalConfidence,
    coatPattern,
    breedInspection: context.breedInspection,
    visualBreed,
  });
  console.log(`CATDEX_BREED_FINAL ${breed}`);
  const personality = personalityFromObservation(observation);
  const rarity = rarityFromObservationRules(breed);
  const variant = variantFromRuleEngine(context.activeEventId);

  console.log(`CATDEX_VISUAL_COAT_BASE_COLOR ${observation.baseColor ?? "-"}`);
  console.log(`CATDEX_VISUAL_HAS_WHITE ${observation.whitePresent}`);
  console.log(`CATDEX_VISUAL_COAT_PATTERN ${observation.coatPattern ?? "-"}`);
  console.log(`CATDEX_VISUAL_EYE_COLOR ${observation.eyeColor ?? "-"}`);
  console.log(`CATDEX_VISUAL_VISIBLE_EYES ${!isMissingEyeColor(eyeColor)}`);
  console.log(`CATDEX_VISUAL_HAIR_LENGTH ${observation.hairLength ?? "-"}`);
  console.log(`CATDEX_MAPPED_COAT_COLOR ${coatColor}`);
  console.log(`CATDEX_MAPPED_COAT_PATTERN ${coatPattern}`);
  console.log(`CATDEX_MAPPED_EYE_COLOR ${eyeColor}`);
  console.log(`CATDEX_MAPPED_BREED ${breed}`);
  console.log(`CATDEX_MAPPED_DISPLAY_SPECIES ${displaySpeciesFromMappedValues({
    breed,
    coatColor,
    coatPattern,
  })}`);
  console.log(`CATDEX_ORANGE_TABBY_DETECTED ${
    isOrangeColor(coatColor) && isTabbyPattern(coatPattern)
  }`);
  console.log(`CATDEX_BICOLOR_DETECTED ${isBicolorPattern(coatPattern)}`);
  console.log(`CATDEX_CALICO_DETECTED ${isCalicoPattern(coatPattern)}`);
  console.log(`CATDEX_TORTOISESHELL_DETECTED ${
    isTortoiseshellPattern(coatPattern)
  }`);

  return {
    breed,
    confidence: finalConfidence,
    candidates,
    coatColor,
    coatPattern,
    eyeColor,
    hairLength,
    estimatedAge,
    personality,
    rarity,
    variant,
  };
}

function displaySpeciesFromMappedValues({
  breed,
  coatColor,
  coatPattern,
}: {
  breed: string;
  coatColor: string;
  coatPattern: string;
}): string {
  if (isOrangeColor(coatColor) && isTabbyPattern(coatPattern)) {
    return "Gatto domestico arancione tigrato";
  }

  if (isSpecificBreed(breed)) {
    return italianBreedName(breed);
  }

  if (isBicolorPattern(coatPattern)) {
    return "Gatto domestico bicolore";
  }

  if (isCalicoPattern(coatPattern)) {
    return "Gatto domestico calico";
  }

  if (isTortoiseshellPattern(coatPattern)) {
    return "Gatto domestico tartarugato";
  }

  if (breed === "domestic_tabby_cat") {
    return "Gatto domestico tigrato";
  }

  return italianBreedName(breed);
}

function coatColorFromObservation(
  baseColor: string | null,
  secondaryColor: string | null,
  whitePresent: boolean,
  orangePresent: boolean,
  blackPresent: boolean,
  coatPattern: string,
): string {
  return realisticCoatColor(
    baseColor ?? "unknown",
    coatPattern,
    secondaryColor,
    {
      whitePresent,
      orangePresent,
      blackPresent,
    },
  );
}

function normalizeCoatColorFromObservation(
  observation: CatVisionObservation,
  currentColor: string,
  coatPattern: string,
): string {
  const pattern = normalizeVisualValue(coatPattern);
  const current = normalizeVisualValue(currentColor);
  const baseColor = normalizeVisualValue(observation.baseColor ?? "");
  const secondaryColor = normalizeVisualValue(observation.secondaryColor ?? "");
  const tabby = isTabbyPattern(pattern);
  const secondaryUnknown = secondaryColor.length === 0 ||
    secondaryColor === "unknown" ||
    secondaryColor === "null";

  if (isBlackWhiteBicolorObservation(observation, pattern)) {
    return "nero/bianco";
  }

  if (isBicolorPattern(pattern)) {
    return bicolorCoatColorFromObservation(
      observation,
      currentColor,
      baseColor,
      secondaryColor,
      pattern,
    );
  }

  if (!tabby) {
    return currentColor;
  }

  if (baseColor === "orange" && observation.orangePresent) {
    return "arancione tigrato";
  }

  const orangeAllowed = observation.orangePresent &&
    baseColor === "orange" &&
    observation.visibleConfidence >= 0.9 &&
    !isBrownColor(secondaryColor) &&
    !isGrayColor(secondaryColor) &&
    !isCreamColor(secondaryColor) &&
    secondaryColor !== "mixed" &&
    !secondaryUnknown &&
    !observation.blackPresent;

  if (current.includes("arancione") && !orangeAllowed) {
    return "marrone/grigio tigrato";
  }

  if (
    !orangeAllowed &&
    (isBrownColor(baseColor) ||
      isGrayColor(baseColor) ||
      isBrownColor(secondaryColor) ||
      isGrayColor(secondaryColor) ||
      isCreamColor(secondaryColor) ||
      secondaryColor === "mixed" ||
      secondaryUnknown ||
      observation.blackPresent)
  ) {
    return "marrone/grigio tigrato";
  }

  return currentColor;
}

function bicolorCoatColorFromObservation(
  observation: CatVisionObservation,
  currentColor: string,
  baseColor: string,
  secondaryColor: string,
  coatPattern: string,
): string {
  const current = normalizeVisualValue(currentColor);
  const combined = normalizeVisualValue(
    `${currentColor} ${observation.baseColor ?? ""} ${
      observation.secondaryColor ?? ""
    } ${coatPattern}`,
  );

  if (
    combined.includes("nero/bianco") ||
    combined.includes("bianco/nero") ||
    combined.includes("black/white") ||
    combined.includes("white/black") ||
    combined.includes("tuxedo") ||
    (observation.blackPresent &&
      !isGrayColor(baseColor) &&
      !isGrayColor(secondaryColor))
  ) {
    return "nero/bianco";
  }

  if (
    isGrayColor(baseColor) ||
    isGrayColor(secondaryColor) ||
    combined.includes("grigio") ||
    combined.includes("gray") ||
    combined.includes("grey") ||
    combined.includes("silver") ||
    combined.includes("smoke")
  ) {
    return "grigio/bianco";
  }

  if (
    observation.orangePresent ||
    isOrangeColor(baseColor) ||
    isOrangeColor(secondaryColor) ||
    combined.includes("ginger") ||
    combined.includes("rosso")
  ) {
    return "arancione/bianco";
  }

  if (
    isBrownColor(baseColor) ||
    isBrownColor(secondaryColor) ||
    combined.includes("marrone")
  ) {
    return "marrone/bianco";
  }

  if (current.length > 0 && current !== "unknown" && current !== "null") {
    return currentColor;
  }

  return "bicolore";
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

  if (
    normalized.includes("odd_eyes") ||
    normalized.includes("heterochromia") ||
    normalized.includes("eterocrom") ||
    normalized.includes("mixed")
  ) {
    return "occhi eterocromi";
  }

  if (normalized.includes("green") || normalized.includes("verd")) {
    return "occhi verdi";
  }

  if (
    normalized.includes("amber") ||
    normalized.includes("ambr") ||
    normalized.includes("orange") ||
    normalized.includes("copper") ||
    normalized.includes("rame") ||
    normalized.includes("golden") ||
    normalized.includes("yellow-orange")
  ) {
    return "occhi ambrati";
  }

  if (normalized.includes("hazel") || normalized.includes("nocciola")) {
    return "occhi nocciola";
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

function normalizeDetectedEyeColor(eyeColor: string): string {
  const normalized = normalizeVisualValue(eyeColor);
  if (
    normalized.includes("ambr") ||
    normalized.includes("amber") ||
    normalized.includes("orange") ||
    normalized.includes("arancione") ||
    normalized.includes("copper") ||
    normalized.includes("rame") ||
    normalized.includes("yellow-orange") ||
    normalized.includes("golden-orange")
  ) {
    return "occhi ambrati";
  }

  if (
    normalized.includes("giall") ||
    normalized.includes("yellow") ||
    normalized.includes("gold") ||
    normalized.includes("dorat")
  ) {
    return "occhi gialli";
  }

  if (normalized.includes("verd") || normalized.includes("green")) {
    return "occhi verdi";
  }

  if (
    normalized.includes("azzurr") ||
    normalized.includes("blu") ||
    normalized.includes("blue")
  ) {
    return "occhi azzurri";
  }

  if (
    normalized.includes("eterocrom") ||
    normalized.includes("heterochromia") ||
    normalized.includes("mixed")
  ) {
    return "occhi eterocromi";
  }

  return "Non rilevato";
}

function eyeColorEnumFromItalian(eyeColor: string): string {
  const normalized = normalizeVisualValue(eyeColor);
  if (normalized.includes("ambr")) {
    return "amber";
  }
  if (normalized.includes("giall")) {
    return "yellow";
  }
  if (normalized.includes("verd")) {
    return "green";
  }
  if (normalized.includes("azzurr")) {
    return "blue";
  }
  return "unknown";
}

function isMissingEyeColor(eyeColor: string | null): boolean {
  const normalized = normalizeVisualValue(eyeColor ?? "");
  return normalized.length === 0 ||
    normalized === "-" ||
    normalized === "unknown" ||
    normalized === "null" ||
    normalized.includes("non rilevato");
}

function italianAgeOrFallback(value: string | null, fallback: string): string {
  return {
    kitten: "cucciolo",
    adult: "adulto",
    senior: "anziano",
  }[value ?? ""] ?? fallback;
}

function breedFromObservationRules({
  coatColor,
  coatPattern,
  hairLength,
  eyeColor,
  confidence,
}: {
  coatColor: string;
  coatPattern: string;
  hairLength: string;
  eyeColor: string;
  confidence: number;
}): string {
  const pattern = normalizeVisualValue(coatPattern);
  const shortOrMediumHair = hairLength === "pelo corto" ||
    hairLength === "pelo medio";
  const blackWhiteBicolor = isBlackWhiteBicolorCoat(coatColor, coatPattern);

  // Phase 2 rule engine: common visual morphology wins over breed guessing.
  // Pure breeds require very strong visual evidence; otherwise CatDex defaults
  // to conservative domestic classifications.
  if (isCalicoPattern(coatPattern)) {
    return "domestic_calico_cat";
  }

  if (isTortoiseshellPattern(coatPattern)) {
    return "domestic_tortoiseshell_cat";
  }

  if (blackWhiteBicolor) {
    return pattern.includes("tuxedo")
      ? "domestic_tuxedo_cat"
      : "domestic_black_white_cat";
  }

  if (isTabbyPattern(coatPattern) && shortOrMediumHair) {
    return "domestic_tabby_cat";
  }

  if (isTabbyPattern(coatPattern)) {
    return "domestic_tabby_cat";
  }

  if (isSolidPattern(coatPattern) && isBlackColor(coatColor)) {
    return "domestic_black_cat";
  }

  if (hairLength === "pelo lungo") {
    return "domestic_longhair_cat";
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

  if (pattern.includes("colorpoint")) {
    return confidence > 0.95 && normalizeVisualValue(eyeColor).includes("azzurr")
      ? "siamese_cat"
      : "domestic_shorthair_cat";
  }

  if (
    shortOrMediumHair &&
    (pattern.includes("bicolore") ||
      pattern.includes("tuxedo") ||
      pattern.includes("calico") ||
      pattern.includes("tartarugato"))
  ) {
    return "domestic_shorthair_cat";
  }

  return "domestic_shorthair_cat";
}

function variantFromRuleEngine(activeEventId: string | null): string {
  // Event variants are reserved for explicit backend event context.
  return activeEventId === null ? "normal" : "event_edition";
}

function breedFromBreedInspection({
  visualBreed,
  hairLength,
  breedInspection,
}: {
  visualBreed: string;
  hairLength: string;
  breedInspection?: CatBreedInspection;
}): string {
  if (!breedInspection) {
    return visualBreed;
  }

  if (
    breedInspection.shouldUseBreedName &&
    breedInspection.breedConfidence >= 0.75 &&
    isSpecificBreed(breedInspection.primaryBreed)
  ) {
    return breedInspection.primaryBreed;
  }

  if (
    visualBreed === "domestic_shorthair_cat" ||
    visualBreed === "domestic_longhair_cat" ||
    visualBreed === "domestic_mediumhair_cat"
  ) {
    return domesticBreedForHairLength(hairLength);
  }

  return visualBreed;
}

function confidenceForFinalBreed(
  breed: string,
  visualConfidence: number,
  breedInspection?: CatBreedInspection,
): number {
  if (
    breedInspection &&
    breed === breedInspection.primaryBreed &&
    isSpecificBreed(breed)
  ) {
    return breedInspection.breedConfidence;
  }

  return visualConfidence;
}

function domesticBreedForHairLength(hairLength: string): string {
  if (hairLength === "pelo lungo") {
    return "domestic_longhair_cat";
  }

  if (hairLength === "pelo medio") {
    return "domestic_mediumhair_cat";
  }

  return "domestic_shorthair_cat";
}

function isSpecificBreed(breed: string): boolean {
  return !breed.startsWith("domestic_") && breed !== "unknown";
}

function candidatesForBreed({
  breed,
  confidence,
  coatPattern,
  breedInspection,
  visualBreed,
}: {
  breed: string;
  confidence: number;
  coatPattern: string;
  breedInspection?: CatBreedInspection;
  visualBreed: string;
}): CandidateJson[] {
  const candidates: CandidateJson[] = [
    { breed, confidence },
  ];

  if (breedInspection) {
    for (const candidate of breedInspection.possibleBreeds) {
      if (candidate.breed === "unknown") {
        continue;
      }
      addCandidate(candidates, {
        breed: candidate.breed,
        confidence: candidate.confidence,
      });
    }
  }

  if (visualBreed !== breed) {
    addCandidate(candidates, {
      breed: visualBreed,
      confidence: Math.max(0.35, confidence - 0.1),
    });
  }

  if (breed !== "domestic_shorthair_cat") {
    addCandidate(candidates, {
      breed: "domestic_shorthair_cat",
      confidence: Math.max(0.35, confidence - 0.18),
    });
  }

  if (breed !== "domestic_tabby_cat" && isTabbyPattern(coatPattern)) {
    addCandidate(candidates, {
      breed: "domestic_tabby_cat",
      confidence: Math.max(0.35, confidence - 0.12),
    });
  }

  return candidates.slice(0, 3);
}

function addCandidate(candidates: CandidateJson[], candidate: CandidateJson): void {
  if (candidates.some((item) => item.breed === candidate.breed)) {
    return;
  }
  candidates.push(candidate);
}

function rarityFromObservationRules(breed: string): string {
  if (breed.startsWith("domestic_")) {
    return "common";
  }

  return "uncommon";
}

function personalityFromObservation(
  observation: CatVisionObservation,
): string {
  const expression = normalizeVisualValue(observation.expression ?? "");
  if (expression.includes("sleep") || expression.includes("relaxed")) {
    return "relaxed";
  }

  if (expression.includes("play")) {
    return "playful";
  }

  if (expression.includes("alert")) {
    return "alert";
  }

  const posture = normalizeVisualValue(observation.posture ?? "");
  if (posture.includes("lying")) {
    return "relaxed";
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
  expression,
  environment,
}: {
  coatColor: string;
  coatPattern: string;
  eyeColor: string;
  hairLength: string;
  estimatedAge: string;
  posture: string | null;
  expression: string | null;
  environment: string | null;
}): TraitJson[] {
  const traits: TraitJson[] = [
    { name: "Mantello", value: `${coatColor}, ${coatPattern}`, rarityWeight: 1 },
    { name: "Occhi", value: eyeColor, rarityWeight: 1 },
    { name: "Pelo", value: hairLength, rarityWeight: 1 },
    { name: "Eta stimata", value: estimatedAge, rarityWeight: 1 },
  ];

  if (posture) {
    const poseText = italianPosture(posture);
    if (poseText.length > 0) {
      traits.push({ name: "Posa", value: poseText, rarityWeight: 1 });
    }
  }

  if (expression) {
    const expressionText = italianExpression(expression);
    if (expressionText.length > 0) {
      traits.push({ name: "Espressione", value: expressionText, rarityWeight: 1 });
    }
  }

  if (environment) {
    const environmentText = italianEnvironment(environment);
    if (environmentText.length > 0) {
      traits.push({ name: "Ambiente", value: environmentText, rarityWeight: 1 });
    }
  }

  return traits.slice(0, 6);
}

function generateLoreWithLoreEngine(
  observation: CatVisionObservation,
  classification: CatRuleClassification,
): CatLore {
  // Lore Engine: Italian text is generated only after deterministic Rule Engine
  // classification. It uses final breed plus observed traits and strips any
  // unknown/null placeholders from user-facing lore.
  try {
    return {
      story: cleanLoreText(storyFromObservation({
        breed: classification.breed,
        coatColor: classification.coatColor,
        coatPattern: classification.coatPattern,
        posture: observation.posture,
        expression: observation.expression,
        environment: observation.environment,
      })),
      funFact: cleanLoreText(
        funFactForBreed(classification.breed, classification.coatPattern),
      ),
    };
  } catch (_) {
    return deterministicLoreFallback(classification);
  }
}

function storyFromObservation({
  breed,
  coatColor,
  coatPattern,
  posture,
  expression,
  environment,
}: {
  breed: string;
  coatColor: string;
  coatPattern: string;
  posture: string | null;
  expression: string | null;
  environment: string | null;
}): string {
  const breedName = italianBreedName(breed);
  const coatText = visualPhrase([coatColor, coatPattern]);
  const poseText = italianPosture(posture);
  const expressionText = italianExpression(expression);
  const environmentText = italianEnvironment(environment);
  return [
    `Un ${breedName}`,
    coatText.length === 0 ? "" : `dal mantello ${coatText}`,
    poseText,
    expressionText.length === 0 ? "" : `con espressione ${expressionText}`,
    environmentText,
    "entra nel tuo CatDex con un'aria curiosa e attenta.",
  ].filter((part) => part.trim().length > 0).join(" ");
}

function funFactForBreed(breed: string, coatPattern: string): string {
  if (breed === "domestic_black_white_cat" || breed === "domestic_tuxedo_cat") {
    return "I gatti bicolori hanno aree di mantello ben distinte: CatDex li riconosce come nero/bianco solo quando entrambi i colori sono chiaramente visibili.";
  }

  if (breed === "domestic_tabby_cat" || isTabbyPattern(coatPattern)) {
    return "Il disegno tigrato e uno dei mantelli piu comuni nei gatti domestici e puo apparire in tonalita marroni, grigie o arancioni.";
  }

  if (breed === "domestic_black_cat") {
    return "I gatti neri solidi possono mostrare riflessi marroni alla luce del sole, ma CatDex li considera neri solo quando il mantello e quasi interamente scuro.";
  }

  return "Molti gatti domestici hanno origini miste: CatDex privilegia una classificazione prudente quando la razza non e chiara.";
}

function deterministicLoreFallback(classification: CatRuleClassification): CatLore {
  const breedName = italianBreedName(classification.breed);
  return {
    story:
      `Un ${breedName} entra nel tuo CatDex con una nuova carta pronta da scoprire.`,
    funFact:
      "I gatti domestici possono mostrare grande varieta di mantelli anche senza appartenere a una razza pura.",
  };
}

function cleanLoreText(text: string): string {
  const normalized = normalizeVisualValue(text);
  if (
    normalized.length === 0 ||
    normalized.includes("unknown") ||
    normalized.includes("null")
  ) {
    return "Un gatto domestico entra nel tuo CatDex con una nuova storia tutta da scoprire.";
  }

  return text;
}

function italianBreedName(breed: string): string {
  return {
    domestic_tabby_cat: "gatto domestico tigrato",
    domestic_shorthair_cat: "gatto domestico a pelo corto",
    domestic_black_cat: "gatto domestico nero",
    domestic_black_white_cat: "gatto domestico bicolore",
    domestic_tuxedo_cat: "gatto tuxedo domestico",
    domestic_white_cat: "gatto domestico bianco",
    domestic_calico_cat: "gatto calico domestico",
    domestic_tortoiseshell_cat: "gatto domestico tartarugato",
    domestic_orange_cat: "gatto domestico arancione",
    domestic_gray_cat: "gatto domestico",
    domestic_longhair_cat: "gatto domestico a pelo lungo",
    domestic_mediumhair_cat: "gatto domestico a pelo medio",
    siamese: "gatto siamese",
    maine_coon: "Maine Coon",
    norwegian_forest_cat: "gatto Norvegese delle Foreste",
    siberian_cat: "gatto Siberiano",
    persian_cat: "Persiano",
    ragdoll_cat: "Ragdoll",
    birman_cat: "Sacro di Birmania",
    siamese_cat: "Siamese",
    british_shorthair_cat: "British Shorthair",
    russian_blue_cat: "Blu di Russia",
    bengal_cat: "Bengala",
    sphynx_cat: "Sphynx",
    scottish_fold_cat: "Scottish Fold",
    abyssinian_cat: "Abissino",
  }[breed] ?? "gatto domestico";
}

function visualPhrase(parts: string[]): string {
  return parts
    .map((part) => part.trim())
    .filter((part) =>
      part.length > 0 &&
      normalizeVisualValue(part) !== "unknown" &&
      normalizeVisualValue(part) !== "null" &&
      normalizeVisualValue(part) !== "non rilevato"
    )
    .join(" ");
}

function italianPosture(posture: string | null): string {
  return {
    sitting: "seduto",
    lying: "disteso",
    standing: "in piedi",
    walking: "in movimento",
    crouching: "accucciato",
  }[posture ?? ""] ?? "";
}

function italianExpression(expression: string | null): string {
  return {
    alert: "vigile",
    curious: "curiosa",
    relaxed: "rilassata",
    sleeping: "addormentata",
    playful: "giocosa",
  }[expression ?? ""] ?? "";
}

function italianEnvironment(environment: string | null): string {
  return {
    indoor: "in un ambiente interno",
    outdoor: "all'aperto",
    garden: "in giardino",
    street: "in strada",
    house: "in casa",
  }[environment ?? ""] ?? "";
}

function safeFallbackAnalysis(): AnalysisJson {
  return {
    breed: "domestic_cat",
    confidence: 0.2,
    candidates: [{ breed: "domestic_cat", confidence: 0.2 }],
    coatColor: "Non rilevato",
    dominantVisibleCoatColor: "unknown",
    visualEvidence: "Analisi non riuscita",
    visibleEvidence: "Analisi non riuscita",
    coatColorConfidence: 0.2,
    colorConfidence: 0.2,
    coatPattern: "Non rilevato",
    coatPatternConfidence: 0.2,
    patternConfidence: 0.2,
    eyeColor: "Non rilevato",
    hairLength: "Non rilevato",
    estimatedAge: "Non rilevato",
    traits: [],
    personality: "unknown",
    rarity: "common",
    variant: "normal",
    story: "Analisi non riuscita. Puoi correggere i dettagli manualmente.",
    funFact: "Ogni gatto ha caratteristiche uniche.",
    safetyStatus: "safe",
    uncertaintyReason: "safe_fallback_analysis",
    needsReview: true,
    analyzedAt: new Date().toISOString(),
  };
}

function mockAnalysisResult(mockReason: string): JsonResponseBody {
  console.log("CATDEX_EDGE_MOCK_ANALYSIS_RETURNED_SAFE_UNKNOWN");
  console.log("CATDEX_EDGE_MOCK_BROWN_TABBY_DISABLED");
  return {
    ...toResultEnvelope({
      breed: "domestic_cat",
      confidence: 0.2,
      candidates: [{ breed: "domestic_cat", confidence: 0.2 }],
      coatColor: "Non rilevato",
      dominantVisibleCoatColor: "unknown",
      visualEvidence: "Analisi non riuscita",
      visibleEvidence: "Analisi non riuscita",
      coatColorConfidence: 0.2,
      colorConfidence: 0.2,
      coatPattern: "Non rilevato",
      coatPatternConfidence: 0.2,
      patternConfidence: 0.2,
      eyeColor: "Non rilevato",
      hairLength: "Non rilevato",
      estimatedAge: "Non rilevato",
      traits: [],
      personality: "unknown",
      rarity: "common",
      variant: "normal",
      story: "Analisi non riuscita. Puoi correggere i dettagli manualmente.",
      funFact: "Ogni gatto ha caratteristiche uniche.",
      safetyStatus: "safe",
      uncertaintyReason: "real_ai_analysis_failed_or_mock_disabled",
      needsReview: true,
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

function realisticCoatColor(
  coatColor: string,
  coatPattern: string,
  secondaryColor: string | null,
  presence: {
    whitePresent: boolean;
    orangePresent: boolean;
    blackPresent: boolean;
  },
): string {
  const color = normalizeVisualValue(coatColor);
  const secondary = normalizeVisualValue(secondaryColor ?? "");
  const pattern = normalizeVisualValue(coatPattern);
  const tabby = isTabbyPattern(pattern);
  const solid = isSolidPattern(pattern);

  if (isBlackWhiteBicolorVisual(pattern, color, secondary, presence)) {
    return "nero/bianco";
  }

  if (pattern.includes("calico") || isCalicoColor(color)) {
    return "calico";
  }

  if (pattern.includes("tartarugato") || color.includes("tortoiseshell")) {
    return "tartarugato";
  }

  if (tabby) {
    if (isCat03LikeTabby(color, secondary, presence)) {
      return "marrone/grigio tigrato";
    }

    if (isClearlyOrangeTabby(color, secondary, presence)) {
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

    if (secondary.includes("gray") || secondary.includes("blue_gray")) {
      return "grigio tigrato";
    }

    if (secondary.includes("brown")) {
      return "marrone tigrato";
    }
  }

  if (solid && isBlackColor(color)) {
    return "nero solido";
  }

  if (isWhiteColor(color)) {
    return "bianco";
  }

  if (isGrayColor(color)) {
    return "grigio";
  }

  if (isOrangeColor(color)) {
    return "arancione";
  }

  if (isBrownColor(color)) {
    return "marrone";
  }

  return "marrone/grigio";
}

function realisticCoatPattern(coatPattern: string): string {
  const normalized = normalizeVisualValue(coatPattern);
  if (normalized.includes("tuxedo")) {
    return "tuxedo";
  }

  if (normalized.includes("bicolor") || normalized.includes("bicolore")) {
    return "bicolore";
  }

  if (
    normalized.includes("tortoiseshell") ||
    normalized.includes("tortie") ||
    normalized.includes("tartarugat")
  ) {
    return "tartarugato";
  }

  if (normalized.includes("tabby")) {
    if (normalized.includes("mackerel")) {
      return "tigrato mackerel";
    }

    if (normalized.includes("classic")) {
      return "tigrato classico";
    }

    if (normalized.includes("spotted")) {
      return "tigrato maculato";
    }

    if (normalized.includes("ticked")) {
      return "tigrato ticked";
    }

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

function isBicolorPattern(coatPattern: string): boolean {
  const normalized = normalizeVisualValue(coatPattern);
  return normalized.includes("bicolor") ||
    normalized.includes("bicolore") ||
    normalized.includes("tuxedo");
}

function isCalicoPattern(coatPattern: string): boolean {
  return normalizeVisualValue(coatPattern).includes("calico");
}

function isTortoiseshellPattern(coatPattern: string): boolean {
  const normalized = normalizeVisualValue(coatPattern);
  return normalized.includes("tortoiseshell") ||
    normalized.includes("tortie") ||
    normalized.includes("tartarugat");
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
    normalized.includes("blue_gray") ||
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

function isCreamColor(coatColor: string): boolean {
  const normalized = normalizeVisualValue(coatColor);
  return normalized.includes("cream") ||
    normalized.includes("crema") ||
    normalized.includes("beige");
}

function isCalicoColor(coatColor: string): boolean {
  return normalizeVisualValue(coatColor).includes("calico");
}

function isColorpointColor(coatColor: string): boolean {
  const normalized = normalizeVisualValue(coatColor);
  return normalized.includes("colorpoint") || normalized.includes("pointed");
}

function isBlackWhiteBicolorObservation(
  observation: CatVisionObservation,
  coatPattern: string,
): boolean {
  const baseColor = normalizeVisualValue(observation.baseColor ?? "");
  const secondaryColor = normalizeVisualValue(observation.secondaryColor ?? "");
  return isBicolorPattern(coatPattern) &&
    observation.whitePresent &&
    observation.blackPresent &&
    !observation.orangePresent &&
    (isBlackColor(baseColor) ||
      isBlackColor(secondaryColor) ||
      baseColor === "mixed" ||
      secondaryColor === "mixed");
}

function isBlackWhiteBicolorCoat(
  coatColor: string,
  coatPattern: string,
): boolean {
  return isBicolorPattern(coatPattern) &&
    isBlackColor(coatColor) &&
    isWhiteColor(coatColor);
}

function isBlackWhiteBicolorVisual(
  coatPattern: string,
  color: string,
  secondary: string,
  presence: {
    whitePresent: boolean;
    orangePresent: boolean;
    blackPresent: boolean;
  },
): boolean {
  return isBicolorPattern(coatPattern) &&
    presence.whitePresent &&
    presence.blackPresent &&
    !presence.orangePresent &&
    (isBlackColor(color) || isBlackColor(secondary) || color === "mixed");
}

function isCat03LikeTabby(
  color: string,
  secondary: string,
  presence: {
    whitePresent: boolean;
    orangePresent: boolean;
    blackPresent: boolean;
  },
): boolean {
  return presence.blackPresent &&
    presence.orangePresent &&
    (isBrownColor(color) ||
      isGrayColor(color) ||
      isBrownColor(secondary) ||
      isGrayColor(secondary) ||
      presence.whitePresent);
}

function isClearlyOrangeTabby(
  color: string,
  secondary: string,
  presence: {
    whitePresent: boolean;
    orangePresent: boolean;
    blackPresent: boolean;
  },
): boolean {
  return isOrangeColor(color) &&
    !isBrownColor(secondary) &&
    !isGrayColor(secondary) &&
    !isCreamColor(secondary) &&
    secondary !== "mixed" &&
    !presence.blackPresent &&
    presence.orangePresent;
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

function activeEventIdFor(body: AnalyzeCatPhotoRequest): string | null {
  const activeEventId = body.activeEventId ?? body.metadata?.activeEventId;
  return typeof activeEventId === "string" && activeEventId.trim().length > 0
    ? activeEventId.trim()
    : null;
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
  const normalized = normalizeVisualValue(text);
  return text.length === 0 || normalized === "unknown" || normalized === "null"
    ? null
    : text;
}

function nullableAllowedValue(
  value: unknown,
  allowedValues: readonly string[],
): string | null {
  const text = nullableStringValue(value);
  if (text === null) {
    return null;
  }

  return allowedValues.includes(text) ? text : null;
}

function numberValue(value: unknown): number {
  return typeof value === "number" && Number.isFinite(value) ? value : 0;
}

function confidenceValue(value: unknown): number {
  const confidence = numberValue(value);
  return Math.min(1, Math.max(0, confidence));
}

function averageConfidence(confidence: CatVisualInspectionConfidence): number {
  return (
    confidence.coatBaseColor +
    confidence.hasWhite +
    confidence.coatPattern +
    confidence.eyeColor +
    confidence.hairLength
  ) / 5;
}

function booleanValue(value: unknown): boolean {
  return value === true;
}

function isUnknownValue(value: string | null): boolean {
  return value === null ||
    value.trim().length === 0 ||
    value === "-" ||
    value === "unknown" ||
    value === "null";
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
