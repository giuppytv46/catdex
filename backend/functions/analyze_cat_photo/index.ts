type AnalyzeCatPhotoRequest = {
  photoReference?: string;
  metadata?: {
    source?: string;
    sizeBytes?: number;
    capturedAt?: string;
  };
};

type JsonResponseBody = Record<string, unknown>;

const jsonHeaders = {
  "Content-Type": "application/json",
};

Deno.serve(async (request: Request) => {
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
    return invalidImageResponse("Request body must be valid JSON.");
  }

  const validationError = validateRequest(body);
  if (validationError !== null) {
    return invalidImageResponse(validationError);
  }

  const hasOpenAiKey = Boolean(Deno.env.get("OPENAI_API_KEY"));
  const result = mockAnalysisResult({
    photoReference: body.photoReference!,
    mockReason: hasOpenAiKey ? "openai_call_not_enabled_yet" : "missing_key",
  });

  return jsonResponse(result, 200);
});

function validateRequest(body: AnalyzeCatPhotoRequest): string | null {
  if (typeof body.photoReference !== "string" || body.photoReference === "") {
    return "photoReference is required.";
  }

  if (body.metadata === undefined) {
    return "metadata is required.";
  }

  if (
    typeof body.metadata.sizeBytes !== "number" ||
    body.metadata.sizeBytes <= 0
  ) {
    return "metadata.sizeBytes must be a positive number.";
  }

  if (
    typeof body.metadata.source !== "string" ||
    body.metadata.source === ""
  ) {
    return "metadata.source is required.";
  }

  return null;
}

function mockAnalysisResult({
  photoReference,
  mockReason,
}: {
  photoReference: string;
  mockReason: string;
}): JsonResponseBody {
  return {
    primaryBreed: {
      speciesId: "domestic_tabby_cat",
      confidence: 0.82,
    },
    breedCandidates: [
      {
        speciesId: "domestic_tabby_cat",
        confidence: 0.82,
      },
      {
        speciesId: "domestic_shorthair_cat",
        confidence: 0.64,
      },
      {
        speciesId: "european_shorthair",
        confidence: 0.48,
      },
    ],
    visualTraits: {
      coatColor: "Brown",
      coatPattern: "Tabby",
      eyeColor: "Green",
      hairLength: "Short",
      notableTraits: [
        {
          name: "Pose",
          value: "Watching",
          rarityWeight: 1,
        },
        {
          name: "Mood",
          value: "Curious",
          rarityWeight: 1,
        },
      ],
    },
    confidence: 0.82,
    rarity: "common",
    variantId: "normal",
    personality: "curious",
    story:
      "This curious local cat looks ready to become the star of a cozy CatDex card.",
    analyzedAt: new Date().toISOString(),
    backend: {
      photoReference,
      mock: true,
      mockReason,
    },
  };
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
