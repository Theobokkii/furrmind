CRISIS_KEYWORDS = [
    "suicide", "suicidal", "kill myself", "end my life", "want to die",
    "don't want to live", "self harm", "self-harm", "cutting myself",
    "overdose", "hang myself", "jump off", "no reason to live",
    "better off dead", "harm myself", "end it all"
]

DISTRESS_KEYWORDS = [
    "hopeless", "worthless", "helpless", "i can't go on", "can't take it anymore",
    "nothing matters", "no one cares", "i give up", "hate myself",
    "i'm a burden", "i feel empty", "i'm broken"
]

CRISIS_RESOURCES = [
    "Into The Light Indonesia: 119 ext 8",
    "Yayasan Pulih: (021) 788-42580",
    "International Association for Suicide Prevention: https://www.iasp.info/resources/Crisis_Centres/"
]


def check_guardrail(text: str) -> dict:
    lowered = text.lower()

    for keyword in CRISIS_KEYWORDS:
        if keyword in lowered:
            return {
                "type": "crisis",
                "message": "It sounds like you might be going through a very difficult time. Please know you're not alone.",
                "resources": CRISIS_RESOURCES,
                "action": "Please reach out to a mental health professional or crisis hotline immediately."
            }

    for keyword in DISTRESS_KEYWORDS:
        if keyword in lowered:
            return {
                "type": "distress",
                "tone_modifier": "extra_empathetic"
            }

    return {"type": "safe"}
