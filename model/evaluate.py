import os
import json
import torch
import numpy as np
from datasets import load_dataset
from transformers import AutoTokenizer, AutoModelForSequenceClassification
from sklearn.metrics import f1_score, precision_recall_fscore_support, hamming_loss

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

def sigmoid(x):
    return 1.0 / (1.0 + np.exp(-x))

def find_best_thresholds(probs, targets):
    best_thresholds = np.full(probs.shape[1], 0.5)
    candidate_thresholds = np.linspace(0.1, 0.9, 17)
    for class_idx in range(probs.shape[1]):
        best_f1 = -1.0
        best_th = 0.5
        y_true = targets[:, class_idx]
        if np.sum(y_true) == 0:
            best_thresholds[class_idx] = 0.5
            continue
        for th in candidate_thresholds:
            y_pred = (probs[:, class_idx] >= th).astype(int)
            score = f1_score(y_true, y_pred, zero_division=0)
            if score > best_f1:
                best_f1 = score
                best_th = th
        best_thresholds[class_idx] = best_th
    return best_thresholds

def run_inference(model, tokenizer, texts, device, max_length=128, batch_size=32):
    model.eval()
    all_probs = []
    with torch.no_grad():
        for i in range(0, len(texts), batch_size):
            batch_texts = texts[i : i + batch_size]
            encoded = tokenizer(
                batch_texts,
                padding=True,
                truncation=True,
                max_length=max_length,
                return_tensors="pt"
            ).to(device)
            outputs = model(**encoded)
            logits = outputs.logits.detach().cpu().numpy()
            probs = sigmoid(logits)
            all_probs.append(probs)
    return np.vstack(all_probs)

def main():
    model_dir = os.path.join(os.path.dirname(__file__), "artifacts", "distilbert")
    if not os.path.exists(model_dir):
        model_dir = "distilbert-base-uncased"

    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    tokenizer = AutoTokenizer.from_pretrained(model_dir)
    model = AutoModelForSequenceClassification.from_pretrained(model_dir, num_labels=len(LABEL_LIST)).to(device)

    eval_dataset_name = "joyboseroy/CognitiveDistortion-Eval"
    dataset = load_dataset(eval_dataset_name, split="train")

    texts = dataset["text"]
    labels_matrix = []
    for i in range(len(texts)):
        row = []
        for label_name in LABEL_LIST:
            val = 0
            if label_name in dataset.column_names:
                val = int(dataset[label_name][i])
            elif "labels" in dataset.column_names and isinstance(dataset["labels"][i], list):
                val = 1 if label_name in dataset["labels"][i] else 0
            row.append(val)
        labels_matrix.append(row)
    targets = np.array(labels_matrix)

    probs = run_inference(model, tokenizer, texts, device)

    default_preds = (probs >= 0.5).astype(int)
    default_macro = f1_score(targets, default_preds, average="macro", zero_division=0)
    default_micro = f1_score(targets, default_preds, average="micro", zero_division=0)

    best_thresholds = find_best_thresholds(probs, targets)
    tuned_preds = (probs >= best_thresholds).astype(int)

    tuned_macro = f1_score(targets, tuned_preds, average="macro", zero_division=0)
    tuned_micro = f1_score(targets, tuned_preds, average="micro", zero_division=0)
    h_loss = hamming_loss(targets, tuned_preds)

    precision_per_class, recall_per_class, f1_per_class, support_per_class = precision_recall_fscore_support(
        targets, tuned_preds, average=None, zero_division=0
    )

    results = {
        "dataset": eval_dataset_name,
        "sample_count": len(texts),
        "default_threshold_0.5": {
            "macro_f1": float(default_macro),
            "micro_f1": float(default_micro)
        },
        "tuned_thresholds": {
            "macro_f1": float(tuned_macro),
            "micro_f1": float(tuned_micro),
            "hamming_loss": float(h_loss)
        },
        "per_class": {}
    }

    for idx, name in enumerate(LABEL_LIST):
        results["per_class"][name] = {
            "threshold": float(best_thresholds[idx]),
            "f1": float(f1_per_class[idx]),
            "precision": float(precision_per_class[idx]),
            "recall": float(recall_per_class[idx]),
            "support": int(support_per_class[idx])
        }

    output_path = os.path.join(os.path.dirname(__file__), "artifacts", "evaluation_results.json")
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(results, f, indent=2)

    thresholds_path = os.path.join(os.path.dirname(__file__), "artifacts", "tuned_thresholds.json")
    threshold_mapping = {LABEL_LIST[i]: float(best_thresholds[i]) for i in range(len(LABEL_LIST))}
    with open(thresholds_path, "w", encoding="utf-8") as f:
        json.dump(threshold_mapping, f, indent=2)

    print(json.dumps(results, indent=2))

if __name__ == "__main__":
    main()
