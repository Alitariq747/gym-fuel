import {onCall, HttpsError} from "firebase-functions/v2/https";
import {defineSecret} from "firebase-functions/params";
import * as admin from "firebase-admin";

admin.initializeApp();

const geminiApiKey = defineSecret("GOOGLE_GENAI_API_KEY");
const primaryGeminiModel = "gemini-2.5-flash";
const fallbackGeminiModel = "gemini-2.5-flash-lite";
const REBALANCE_THRESHOLD = 60;

type GoalType = "lean_bulk" | "maintain" | "cut";
type InterpretationType = "food" | "exercise";

type InterpretationRequest = {
  text: string;
  goal: GoalType;
};

type MacroBreakdown = {
  calories: number;
  protein: number;
  carbs: number;
  fat: number;
};

type InterpretationResponse = {
  type: InterpretationType;
  title: string;
  detail: string | null;
  feedback: {
    explanation: string;
    assumptions: string[];
    confidence: number;
    estimatedCalories: number | null;
    macros: MacroBreakdown | null;
    goalFitScore: number | null;
    rebalanceHint: string | null;
  };
};

/**
 * Checks that a value is a non-empty string.
 * @param {unknown} value Value to inspect.
 * @return {boolean} Whether the value is a non-empty string.
 */
function isNonEmptyString(value: unknown): value is string {
  return typeof value === "string" && value.trim().length > 0;
}

/**
 * Checks that a value is either a string or null.
 * @param {unknown} value Value to inspect.
 * @return {boolean} Whether the value is a nullable string.
 */
function isNullableString(value: unknown): value is string | null {
  return value === null || typeof value === "string";
}

/**
 * Checks that a value is an array of non-empty strings.
 * @param {unknown} value Value to inspect.
 * @return {boolean} Whether the value is a valid string array.
 */
function isStringArray(value: unknown): value is string[] {
  return Array.isArray(value) &&
    value.every((item) => typeof item === "string" && item.trim().length > 0);
}

/**
 * Trims all strings in an array and drops empty values.
 * @param {string[]} value Array to normalize.
 * @return {string[]} Normalized array.
 */
function normalizeStringArray(value: string[]): string[] {
  return value.map((item) => item.trim()).filter(Boolean);
}

/**
 * Checks that a value is a whole number greater than or equal to zero.
 * @param {unknown} value Value to inspect.
 * @return {boolean} Whether the value is a valid whole number.
 */
function isWholeNumber(value: unknown): value is number {
  return (
    typeof value === "number" &&
    Number.isFinite(value) &&
    Number.isInteger(value) &&
    value >= 0
  );
}

/**
 * Checks that a value is either a valid whole number or null.
 * @param {unknown} value Value to inspect.
 * @return {boolean} Whether the value is a nullable whole number.
 */


/**
 * Checks that a confidence score is between zero and one.
 * @param {unknown} value Value to inspect.
 * @return {boolean} Whether the value is a valid confidence score.
 */
function isValidConfidence(value: unknown): value is number {
  return (
    typeof value === "number" &&
    Number.isFinite(value) &&
    value >= 0 &&
    value <= 1
  );
}

/**
 * Checks that a macros object matches the expected numeric shape.
 * @param {unknown} value Value to inspect.
 * @return {boolean} Whether the value is a valid macros object.
 */
function isValidMacros(value: unknown): value is MacroBreakdown {
  if (!value || typeof value !== "object") return false;

  const macros = value as Partial<MacroBreakdown>;
  return (
    isWholeNumber(macros.calories) &&
    isWholeNumber(macros.protein) &&
    isWholeNumber(macros.carbs) &&
    isWholeNumber(macros.fat)
  );
}

/**
 * Parses and validates callable input.
 * @param {unknown} data Raw callable payload.
 * @return {InterpretationRequest} Validated interpretation input.
 */
function parseInterpretationRequest(data: unknown): InterpretationRequest {
  const text =
    typeof (data as { text?: unknown })?.text === "string" ?
      (data as { text: string }).text.trim() : "";

  const rawGoal =
    typeof (data as { goal?: unknown })?.goal === "string" ?
      (data as { goal: string }).goal.trim() : "maintain";

  // Optional compatibility if the Swift app ever sends lean_gain.
  const normalizedGoal = rawGoal === "lean_gain" ? "lean_bulk" : rawGoal;

  if (!text) {
    throw new HttpsError("invalid-argument", "Text is required.");
  }

  if (
    normalizedGoal !== "lean_bulk" &&
    normalizedGoal !== "maintain" &&
    normalizedGoal !== "cut"
  ) {
    throw new HttpsError("invalid-argument", "Goal is invalid.");
  }

  return {text, goal: normalizedGoal};
}

/**
 * Calls Gemini and returns the raw JSON text payload.
 * @param {string} text User-provided log text.
 * @param {GoalType} goal User-selected body-composition goal.
 * @return {Promise<string>} Raw JSON string from Gemini.
 */
async function generateInterpretationJson(
  text: string,
  goal: GoalType,
): Promise<string> {
  const apiKey = geminiApiKey.value();

  const prompt = [
    "You are interpreting a single fitness log entry for the LiftEats app.",
    "Return exactly one JSON object and nothing else.",
    "Classify the entry as either food or exercise.",
    `Evaluate the entry against this user goal: ${goal}.`,
    "",
    "Core rules:",
    "- Food entries must return macros and set estimatedCalories to null.",
    "- Exercise entries must return estimatedCalories as calories burned.",
    "- For exercise set macros to null.",
    "- Never return both estimatedCalories and macros for the same entry.",
    "- Keep the same response shape for both food and exercise.",
    "- title must be a short, clean, normalized label.",
    "- detail should be a short optional clarification, otherwise null.",
    "",
    "Food scoring rules:",
    "- goalFitScore must be an integer from 0 to 100.",
    "- Score goal fit, not morality or generic healthiness.",
    "- Keep language factual, concise, and non-judgmental.",
    "- explanation should be concise reason about the score for this goal.",
    "",
    "Goal guidance:",
    [
      "- Evaluate meals based on overall goal alignment, not on a single",
      "macro or rigid rule.",
    ].join(" "),
    [
      "- Consider protein quality, likely energy contribution, satiety,",
      "training support, food composition, and how easy the meal would",
      "be to fit into the user's day for that goal.",
    ].join(" "),
    [
      "- For lean_bulk: favor meals that plausibly support recovery, muscle",
      "gain, and sufficient energy intake without being obviously poor",
      "quality or wildly excessive.",
    ].join(" "),
    [
      "- For maintain: favor meals that look reasonably balanced, practical",
      "to sustain, and unlikely to push intake far above or below a",
      "stable-maintenance pattern.",
    ].join(" "),
    [
      "- For cut: favor meals that provide useful protein and satiety for",
      "their likely calorie cost, while penalizing meals that are easy to",
      "overeat, low-satiety, or poorly matched to dieting adherence.",
    ].join(" "),
    [
      "- Penalize meals when the likely calorie load, composition, or",
      "satiety profile is meaningfully mismatched to the stated goal, even",
      "if one macro looks good in isolation.",
    ].join(" "),
    [
      "- Use judgment under uncertainty: if portions are unclear, score more",
      "conservatively and reflect that uncertainty in confidence and",
      "assumptions.",
    ].join(" "),
    "",
    "Rebalance guidance:",
    [
      `- If goalFitScore is below ${REBALANCE_THRESHOLD}, return rebalanceHint`,
      "only if there is a clear, useful next-step adjustment.",
    ].join(" "),
    [
      "- A good rebalanceHint should be pragmatic, brief, and directional:",
      "for example, suggesting more protein, fewer calorie-dense extras,",
      "lighter fats later, or adding fiber/produce for balance.",
    ].join(" "),
    [
      "- Base the hint on the most important mismatch for the stated goal,",
      "not on generic healthy-eating advice.",
    ].join(" "),
    [
      "- Do not prescribe an exact replacement meal or a full plan.",
      "Suggest a simple adjustment the user could realistically make later",
      "in the day or at the next meal.",
    ].join(" "),
    [
      "- If the meal is already reasonably workable for the goal, or there is",
      "no specific adjustment that would clearly help",
      "set rebalanceHint to null.",
    ].join(" "),
    "- Keep the tone calm, non-punishing, and non-moralizing.",
    "",
    "Exercise rules:",
    "- For exercise, set goalFitScore to null.",
    "- For exercise, set rebalanceHint to null.",
    "- For exercise, explanation should describe the session interpretation.",
    "- Estimate calories burned conservatively and round to a whole number.",
    "",
    "CONFIDENCE GUIDELINES",
    [
      "- 0.85-0.95: user provides measurable portions (grams, cups,",
      "pieces with size), or packaged item with nutrition facts.",
    ].join(" "),
    [
      "- 0.75-0.88: common meal with reasonable portions stated",
      "(e.g., \"1 bowl\", \"2 eggs\", \"1 cup rice\") and limited",
      "unknown oils/sauces.",
    ].join(" "),
    [
      "- 0.60-0.75: portions unclear OR multiple items OR cooking",
      "method/oils/sauces not specified.",
    ].join(" "),
    [
      "- 0.45-0.65: restaurant/brand item with unknown prep or",
      "portion; heavy sauces/fried foods with unclear amount.",
    ].join(" "),
    [
      "- 0.30-0.50: very vague description (\"ate dinner\") or many",
      "unknown components.",
    ].join(" "),
    "",
    "CALIBRATION RULES",
    "- Restaurant/brand (e.g., KFC, McDonald's) without exact nutrition facts:",
    "  - Add at least 1 assumption about likely prep or portion uncertainty.",
    "  - Set confidence <= 0.75.",
    "- If sauces/oils/butter/mayo are mentioned but not quantified:",
    "  - Assume ~1 tbsp per major item unless stated otherwise.",
    "  - Add an assumption about the quantity used.",
    "- If cooking method is unclear:",
    "  - Assume typical home-cooked method; add assumption.",
    "",
    "MACRO/ENERGY CONSISTENCY",
    "- Ensure calories are broadly consistent with macros:",
    "  calories ~= 4*protein + 4*carbs + 9*fat (within ~20%).",
    [
      "- If consistency requires adjustment, adjust macros/calories",
      "and add an assumption noting the consistency adjustment.",
    ].join(" "),
    "",
    "UNCERTAINTY HANDLING",
    "- Do NOT write step-by-step reasoning.",
    [
      "- Put uncertainty into assumptions: the exact portion/ingredient",
      "assumptions you made (short bullet-like strings).",
    ].join(" "),
    "",
    "Formatting rules:",
    "- Round all calorie and macro estimates to whole numbers.",
    [
      "- assumptions must always be an array. Use [] when there is",
      "nothing to add.",
    ].join(" "),
    "- Use null where specified.",
    "- Do not add extra keys.",
    "",
    "Return exactly this shape:",
    JSON.stringify({
      type: "food",
      title: "string",
      detail: "string or null",
      feedback: {
        explanation: "string",
        assumptions: ["string"],
        confidence: 0.0,
        estimatedCalories: null,
        macros: {calories: 0, protein: 0, carbs: 0, fat: 0},
        goalFitScore: 0,
        rebalanceHint: "string or null",
      },
    }),
    "",
    `User input: ${text}`,
  ].join("\n");

  try {
    return await generateInterpretationJsonForModel(
      primaryGeminiModel,
      apiKey,
      prompt,
    );
  } catch (error) {
    if (!shouldFallbackGeminiModel(error)) {
      throw error;
    }

    console.warn(
      `Primary Gemini model ${primaryGeminiModel} unavailable. ` +
      `Falling back to ${fallbackGeminiModel}.`,
    );

    return generateInterpretationJsonForModel(
      fallbackGeminiModel,
      apiKey,
      prompt,
    );
  }
}

/**
 * Calls a specific Gemini model and returns the raw JSON text payload.
 * @param {string} model Gemini model identifier.
 * @param {string} apiKey API key for Gemini requests.
 * @param {string} prompt Fully rendered prompt text.
 * @return {Promise<string>} Raw JSON string from Gemini.
 */
async function generateInterpretationJsonForModel(
  model: string,
  apiKey: string,
  prompt: string,
): Promise<string> {
  const response = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`,
    {
      method: "POST",
      headers: {"Content-Type": "application/json"},
      body: JSON.stringify({
        contents: [{parts: [{text: prompt}]}],
        generationConfig: {
          responseMimeType: "application/json",
          temperature: 0.2,
          responseSchema: {
            type: "object",
            required: ["type", "title", "detail", "feedback"],
            properties: {
              type: {type: "string", enum: ["food", "exercise"]},
              title: {type: "string"},
              detail: {type: "string", nullable: true},
              feedback: {
                type: "object",
                required: [
                  "explanation",
                  "assumptions",
                  "confidence",
                  "estimatedCalories",
                  "macros",
                  "goalFitScore",
                  "rebalanceHint",
                ],
                properties: {
                  explanation: {type: "string"},
                  assumptions: {
                    type: "array",
                    items: {type: "string"},
                  },
                  confidence: {
                    type: "number",
                    minimum: 0,
                    maximum: 1,
                  },
                  estimatedCalories: {
                    type: "integer",
                    nullable: true,
                    minimum: 0,
                  },
                  macros: {
                    type: "object",
                    nullable: true,
                    required: ["calories", "protein", "carbs", "fat"],
                    properties: {
                      calories: {type: "integer", minimum: 0},
                      protein: {type: "integer", minimum: 0},
                      carbs: {type: "integer", minimum: 0},
                      fat: {type: "integer", minimum: 0},
                    },
                  },
                  goalFitScore: {
                    type: "integer",
                    nullable: true,
                    minimum: 0,
                    maximum: 100,
                  },
                  rebalanceHint: {type: "string", nullable: true},
                },
              },
            },
          },
        },
      }),
    },
  );

  if (!response.ok) {
    const errorBody = await response.text();
    console.error(
      "Gemini HTTP error:",
      model,
      response.status,
      response.statusText,
      errorBody,
    );
    throw createGeminiRequestError(response.status,
      response.statusText, errorBody);
  }

  const data = (await response.json()) as {
    candidates?: Array<{ content?: { parts?: Array<{ text?: string }> } }>;
  };

  const jsonText = data.candidates?.[0]?.content?.parts?.[0]?.text?.trim();

  if (!jsonText) {
    throw new HttpsError("internal", "Gemini returned an empty response.");
  }

  return jsonText;
}

/**
 * Builds a normalized Gemini request error with metadata.
 * @param {number} status HTTP status code from Gemini.
 * @param {string} statusText HTTP status text from Gemini.
 * @param {string} errorBody Raw Gemini error response body.
 * @return {Error} Structured error with attached Gemini status metadata.
 */
function createGeminiRequestError(
  status: number,
  statusText: string,
  errorBody: string,
): Error & { geminiStatus?: number } {
  const error = new Error(`Gemini request failed: ${status} ${statusText}`) as
    Error & { geminiStatus?: number };

  error.geminiStatus = status;

  if (errorBody.includes("\"status\": \"UNAVAILABLE\"")) {
    error.message = "Gemini model unavailable.";
  }

  return error;
}

/**
 * Checks whether a Gemini error should trigger the fallback model.
 * @param {unknown} error Error raised by the primary Gemini request.
 * @return {boolean} Whether the request should retry on fallback.
 */
function shouldFallbackGeminiModel(error: unknown): boolean {
  if (!(error instanceof Error)) {
    return false;
  }

  const geminiError = error as Error & { geminiStatus?: number };
  return (
    geminiError.geminiStatus === 503 ||
    error.message.includes("Gemini model unavailable.")
  );
}

/**
 * Parses Gemini JSON into the callable response contract.
 * @param {string} jsonText Raw Gemini JSON text.
 * @return {InterpretationResponse} Validated callable response.
 */
function parseInterpretationResponse(jsonText: string): InterpretationResponse {
  let parsed: unknown;

  try {
    parsed = JSON.parse(jsonText);
  } catch {
    throw new HttpsError("internal", "Gemini returned invalid JSON.");
  }

  const response = parsed as Partial<InterpretationResponse>;
  const feedback = response.feedback;

  if (
    (response.type !== "food" && response.type !== "exercise") ||
    !isNonEmptyString(response.title) ||
    !isNullableString(response.detail)
  ) {
    throw new HttpsError(
      "internal",
      "Gemini response is missing required top-level fields.",
    );
  }

  if (
    !feedback ||
    !isNonEmptyString(feedback.explanation) ||
    !isStringArray(feedback.assumptions) ||
    !isValidConfidence(feedback.confidence)
  ) {
    throw new HttpsError("internal", "Gemini feedback is incomplete.");
  }

  if (response.type === "food") {
    if (!isValidMacros(feedback.macros)) {
      throw new HttpsError("internal", "Gemini returned invalid food macros.");
    }

    if (feedback.estimatedCalories !== null) {
      throw new HttpsError(
        "internal",
        "Food entries must not return estimatedCalories.",
      );
    }

    if (!isWholeNumber(feedback.goalFitScore)) {
      throw new HttpsError(
        "internal",
        "Food entries must return an integer goalFitScore.",
      );
    }

    if (feedback.goalFitScore < 0 || feedback.goalFitScore > 100) {
      throw new HttpsError(
        "internal",
        "Food goalFitScore must be between 0 and 100.",
      );
    }

    if (feedback.goalFitScore < REBALANCE_THRESHOLD) {
      if (!isNonEmptyString(feedback.rebalanceHint)) {
        throw new HttpsError(
          "internal",
          "Low-scoring food entries must include rebalanceHint.",
        );
      }
    } else if (feedback.rebalanceHint !== null) {
      throw new HttpsError(
        "internal",
        "High-scoring food entries must not include rebalanceHint.",
      );
    }
  }

  if (response.type === "exercise") {
    if (!isWholeNumber(feedback.estimatedCalories)) {
      throw new HttpsError(
        "internal",
        "Exercise entries must return estimatedCalories.",
      );
    }

    if (feedback.macros !== null) {
      throw new HttpsError(
        "internal",
        "Exercise entries must not return macros.",
      );
    }

    if (feedback.goalFitScore !== null) {
      throw new HttpsError(
        "internal",
        "Exercise entries must not return goalFitScore.",
      );
    }

    if (feedback.rebalanceHint !== null) {
      throw new HttpsError(
        "internal",
        "Exercise entries must not return rebalanceHint.",
      );
    }
  }

  return {
    type: response.type,
    title: response.title.trim(),
    detail: response.detail?.trim() ? response.detail.trim() : null,
    feedback: {
      explanation: feedback.explanation.trim(),
      assumptions: normalizeStringArray(feedback.assumptions),
      confidence: feedback.confidence,
      estimatedCalories: feedback.estimatedCalories,
      macros: feedback.macros,
      goalFitScore: feedback.goalFitScore,
      rebalanceHint: feedback.rebalanceHint?.trim() ?
        feedback.rebalanceHint.trim() : null,
    },
  };
}

export const deleteAccount = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Not signed in.");
  }

  const db = admin.firestore();
  const userRef = db.collection("users").doc(uid);

  await db.recursiveDelete(userRef);
  await admin.auth().deleteUser(uid);

  return {ok: true};
});

export const interpretText = onCall(
  {secrets: [geminiApiKey]},
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "Not signed in.");
    }

    try {
      const input = parseInterpretationRequest(request.data);
      const jsonText = await generateInterpretationJson(input.text, input.goal);

      console.log("interpretText Gemini JSON:", jsonText);
      return parseInterpretationResponse(jsonText);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      console.error("interpretText failed:", message);
      throw error;
    }
  },
);
