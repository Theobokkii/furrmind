import json
import os
import numpy as np
import onnxruntime as ort
from transformers import AutoTokenizer

from app.config import settings

LABEL_LIST = [
    "All-or-Nothing Thinking",
    "Overgeneralization",
    "Mental Filter",
    "Disqualifying the Positive",
    "Mind Reading",
    "Fortune-Telling",
    "Catastrophizing",
    "Emotional Reasoning",
    "Should Statements",
    "Labeling",
    "Personalization",
    "Blame"
]

_session: ort.InferenceSession | None = None
_tokenizer: AutoTokenizer | None = None
_thresholds: dict | None = None


def _load_artifacts():
    global _session, _tokenizer, _thresholds

    if _session is not None:
        return

    onnx_path = settings.model_onnx_path
    tokenizer_path = settings.tokenizer_path
    thresholds_path = settings.thresholds_path

    if not os.path.exists(onnx_path):
        raise FileNotFoundError(f"ONNX model not found at: {onnx_path}")

    _session = ort.InferenceSession(onnx_path, providers=["CPUExecutionProvider"])
    _tokenizer = AutoTokenizer.from_pretrained(tokenizer_path)

    if os.path.exists(thresholds_path):
        with open(thresholds_path, "r", encoding="utf-8") as f:
            _thresholds = json.load(f)
    else:
        _thresholds = {label: 0.5 for label in LABEL_LIST}


def is_model_loaded() -> bool:
    try:
        _load_artifacts()
        return True
    except Exception:
        return False


def predict(text: str) -> list[dict]:
    _load_artifacts()

    encoded = _tokenizer(
        text,
        return_tensors="np",
        padding="max_length",
        max_length=128,
        truncation=True
    )

    ort_inputs = {
        "input_ids": encoded["input_ids"].astype(np.int64),
        "attention_mask": encoded["attention_mask"].astype(np.int64)
    }

    logits = _session.run(None, ort_inputs)[0][0]
    probs = 1.0 / (1.0 + np.exp(-logits))

    results = []
    for idx, label in enumerate(LABEL_LIST):
        threshold = _thresholds.get(label, 0.5)
        confidence = float(probs[idx])
        results.append({
            "label": label,
            "confidence": round(confidence, 4),
            "triggered": confidence >= threshold
        })

    results.sort(key=lambda x: x["confidence"], reverse=True)
    return results
