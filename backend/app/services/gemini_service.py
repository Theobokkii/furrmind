from google import genai
from google.genai import types
from app.config import settings

SYSTEM_PROMPT = """You are a compassionate CBT (Cognitive Behavioral Therapy) assistant named Furrmind.
Your role is to help users reframe negative, distorted thinking patterns identified in their journal entries.
You provide evidence-based reframing suggestions grounded in CBT principles.
Always be empathetic, non-judgmental, and supportive.
This is a wellness tool, not a substitute for professional mental health care.
Never provide clinical diagnoses."""

_client: genai.Client | None = None


def _get_client() -> genai.Client:
    global _client
    if _client is None:
        _client = genai.Client(api_key=settings.gemini_api_key)
    return _client


def build_reframe_prompt(text: str, distortions: list[str], is_distressed: bool = False) -> str:
    distortions_str = ", ".join(distortions) if distortions else "general negative thinking"
    tone = "Be especially gentle and empathetic in your response." if is_distressed else ""

    return f"""A user wrote the following journal entry:
"{text}"

The following cognitive distortion patterns were detected: {distortions_str}.

Please provide:
1. A compassionate reframing of their thought, addressing the detected distortions.
2. A brief explanation of why this reframe is helpful from a CBT perspective.
3. A list of 2-3 CBT techniques or principles that are relevant (e.g., "Cognitive Restructuring", "Thought Records", "Behavioral Activation").

Format your response as:
REFRAME: [your reframing suggestion]
EXPLANATION: [brief CBT explanation]
TECHNIQUES: [technique1], [technique2], [technique3]

{tone}"""


def reframe(text: str, distortions: list[str], is_distressed: bool = False) -> dict:
    client = _get_client()
    prompt = build_reframe_prompt(text, distortions, is_distressed)

    response = client.models.generate_content(
        model="gemini-2.0-flash",
        contents=prompt,
        config=types.GenerateContentConfig(
            system_instruction=SYSTEM_PROMPT,
            temperature=0.7
        )
    )

    raw = response.text.strip()
    reframe_text = ""
    explanation_text = ""
    sources = []

    for line in raw.splitlines():
        if line.startswith("REFRAME:"):
            reframe_text = line.replace("REFRAME:", "").strip()
        elif line.startswith("EXPLANATION:"):
            explanation_text = line.replace("EXPLANATION:", "").strip()
        elif line.startswith("TECHNIQUES:"):
            techniques_raw = line.replace("TECHNIQUES:", "").strip()
            sources = [t.strip() for t in techniques_raw.split(",") if t.strip()]

    if not reframe_text:
        reframe_text = raw

    return {
        "reframe": reframe_text,
        "explanation": explanation_text,
        "sources": sources
    }


async def reframe_stream(text: str, distortions: list[str], is_distressed: bool = False):
    client = _get_client()
    prompt = build_reframe_prompt(text, distortions, is_distressed)

    for chunk in client.models.generate_content_stream(
        model="gemini-2.0-flash",
        contents=prompt,
        config=types.GenerateContentConfig(
            system_instruction=SYSTEM_PROMPT,
            temperature=0.7
        )
    ):
        if chunk.text:
            yield chunk.text
