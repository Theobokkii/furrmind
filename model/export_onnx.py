import os
import shutil
import torch
import numpy as np
import onnx
import onnxruntime as ort
from transformers import AutoTokenizer, AutoModelForSequenceClassification

def export_to_onnx():
    base_dir = os.path.dirname(__file__)
    model_dir = os.path.join(base_dir, "artifacts", "distilbert")
    if not os.path.exists(model_dir):
        model_dir = "distilbert-base-uncased"

    output_dir = os.path.join(base_dir, "artifacts")
    onnx_path = os.path.join(output_dir, "model.onnx")
    tokenizer_dir = os.path.join(output_dir, "tokenizer")
    os.makedirs(output_dir, exist_ok=True)
    os.makedirs(tokenizer_dir, exist_ok=True)

    tokenizer = AutoTokenizer.from_pretrained(model_dir)
    tokenizer.save_pretrained(tokenizer_dir)

    model = AutoModelForSequenceClassification.from_pretrained(model_dir, num_labels=12)
    model.eval()

    dummy_text = "I feel like I am failing at everything and everyone is against me."
    dummy_inputs = tokenizer(
        dummy_text,
        return_tensors="pt",
        padding="max_length",
        max_length=128,
        truncation=True
    )

    input_names = ["input_ids", "attention_mask"]
    output_names = ["logits"]
    dynamic_axes = {
        "input_ids": {0: "batch_size", 1: "sequence_length"},
        "attention_mask": {0: "batch_size", 1: "sequence_length"},
        "logits": {0: "batch_size"}
    }

    torch.onnx.export(
        model,
        (dummy_inputs["input_ids"], dummy_inputs["attention_mask"]),
        onnx_path,
        input_names=input_names,
        output_names=output_names,
        dynamic_axes=dynamic_axes,
        opset_version=14,
        do_constant_folding=True
    )

    onnx_model = onnx.load(onnx_path)
    onnx.checker.check_model(onnx_model)

    ort_session = ort.InferenceSession(onnx_path, providers=["CPUExecutionProvider"])
    ort_inputs = {
        "input_ids": dummy_inputs["input_ids"].numpy(),
        "attention_mask": dummy_inputs["attention_mask"].numpy()
    }
    ort_outputs = ort_session.run(None, ort_inputs)

    with torch.no_grad():
        torch_outputs = model(**dummy_inputs).logits.numpy()

    diff = np.max(np.abs(torch_outputs - ort_outputs[0]))
    assert diff < 1e-4, f"ONNX and PyTorch outputs mismatch with max diff {diff}"

    thresholds_src = os.path.join(output_dir, "tuned_thresholds.json")
    if os.path.exists(thresholds_src):
        shutil.copy(thresholds_src, os.path.join(tokenizer_dir, "tuned_thresholds.json"))

    print(f"Export successful: {onnx_path}")
    print(f"Max absolute discrepancy: {diff}")

if __name__ == "__main__":
    export_to_onnx()
