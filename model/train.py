import os
import json
import torch
import numpy as np
from datasets import load_dataset
from transformers import (
    AutoTokenizer,
    AutoModelForSequenceClassification,
    Trainer,
    TrainingArguments,
    DataCollatorWithPadding
)
from sklearn.metrics import f1_score, precision_recall_fscore_support

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

class MultiLabelTrainer(Trainer):
    def __init__(self, *args, pos_weight=None, **kwargs):
        super().__init__(*args, **kwargs)
        self.pos_weight = pos_weight
        if self.pos_weight is not None:
            self.loss_fn = torch.nn.BCEWithLogitsLoss(pos_weight=self.pos_weight)
        else:
            self.loss_fn = torch.nn.BCEWithLogitsLoss()

    def compute_loss(self, model, inputs, return_outputs=False, num_items_in_batch=None):
        labels = inputs.pop("labels")
        outputs = model(**inputs)
        logits = outputs.logits
        if self.pos_weight is not None and self.pos_weight.device != logits.device:
            self.loss_fn = torch.nn.BCEWithLogitsLoss(pos_weight=self.pos_weight.to(logits.device))
        loss = self.loss_fn(logits, labels.float())
        return (loss, outputs) if return_outputs else loss

def compute_metrics(eval_pred):
    logits, labels = eval_pred
    probs = 1.0 / (1.0 + np.exp(-logits))
    preds = (probs >= 0.5).astype(int)
    
    macro_f1 = f1_score(labels, preds, average="macro", zero_division=0)
    micro_f1 = f1_score(labels, preds, average="micro", zero_division=0)
    precision, recall, per_class_f1, _ = precision_recall_fscore_support(
        labels, preds, average=None, zero_division=0
    )
    
    metrics = {
        "macro_f1": float(macro_f1),
        "micro_f1": float(micro_f1)
    }
    for idx, name in enumerate(LABEL_LIST):
        metrics[f"f1_{name}"] = float(per_class_f1[idx])
    return metrics

def preprocess_function(examples, tokenizer):
    tokenized = tokenizer(
        examples["text"],
        max_length=128,
        truncation=True,
        padding=False
    )
    labels_matrix = []
    num_samples = len(examples["text"])
    for i in range(num_samples):
        row = []
        for label_name in LABEL_LIST:
            val = 0
            if label_name in examples:
                val = int(examples[label_name][i])
            elif "labels" in examples and isinstance(examples["labels"][i], list):
                val = 1 if label_name in examples["labels"][i] else 0
            row.append(val)
        labels_matrix.append(row)
    tokenized["labels"] = labels_matrix
    return tokenized

def main():
    model_name = "distilbert-base-uncased"
    dataset_name = "masked-kunsiquat/shreevastava-cognitive-distortions"
    output_dir = os.path.join(os.path.dirname(__file__), "artifacts", "checkpoint")
    os.makedirs(output_dir, exist_ok=True)

    tokenizer = AutoTokenizer.from_pretrained(model_name)
    raw_datasets = load_dataset(dataset_name)

    if "validation" not in raw_datasets and "test" in raw_datasets:
        dataset_splits = raw_datasets
    elif "train" in raw_datasets and "test" not in raw_datasets:
        split_data = raw_datasets["train"].train_test_split(test_size=0.15, seed=42)
        dataset_splits = split_data
    else:
        dataset_splits = raw_datasets

    train_data = dataset_splits["train"]
    eval_key = "validation" if "validation" in dataset_splits else "test"
    eval_data = dataset_splits[eval_key]

    tokenized_train = train_data.map(
        lambda x: preprocess_function(x, tokenizer),
        batched=True,
        remove_columns=train_data.column_names
    )
    tokenized_eval = eval_data.map(
        lambda x: preprocess_function(x, tokenizer),
        batched=True,
        remove_columns=eval_data.column_names
    )

    all_train_labels = np.array(tokenized_train["labels"])
    pos_counts = np.sum(all_train_labels, axis=0)
    total_samples = len(all_train_labels)
    neg_counts = total_samples - pos_counts
    pos_weights = np.where(pos_counts > 0, neg_counts / (pos_counts + 1e-5), 1.0)
    pos_weight_tensor = torch.tensor(pos_weights, dtype=torch.float)

    id2label = {idx: label for idx, label in enumerate(LABEL_LIST)}
    label2id = {label: idx for idx, label in enumerate(LABEL_LIST)}

    model = AutoModelForSequenceClassification.from_pretrained(
        model_name,
        num_labels=len(LABEL_LIST),
        problem_type="multi_label_classification",
        id2label=id2label,
        label2id=label2id
    )

    training_args = TrainingArguments(
        output_dir=output_dir,
        num_train_epochs=3,
        per_device_train_batch_size=16,
        per_device_eval_batch_size=16,
        learning_rate=2e-5,
        warmup_steps=50,
        weight_decay=0.01,
        eval_strategy="epoch",
        save_strategy="epoch",
        load_best_model_at_end=True,
        metric_for_best_model="macro_f1",
        greater_is_better=True,
        logging_steps=20,
        report_to="none",
        fp16=torch.cuda.is_available()
    )

    trainer = MultiLabelTrainer(
        model=model,
        args=training_args,
        train_dataset=tokenized_train,
        eval_dataset=tokenized_eval,
        data_collator=DataCollatorWithPadding(tokenizer=tokenizer),
        compute_metrics=compute_metrics,
        pos_weight=pos_weight_tensor
    )

    trainer.train()

    final_model_dir = os.path.join(os.path.dirname(__file__), "artifacts", "distilbert")
    trainer.save_model(final_model_dir)
    tokenizer.save_pretrained(final_model_dir)

    metadata = {
        "labels": LABEL_LIST,
        "id2label": id2label,
        "label2id": label2id,
        "max_length": 128
    }
    with open(os.path.join(final_model_dir, "metadata.json"), "w", encoding="utf-8") as f:
        json.dump(metadata, f, indent=2)

if __name__ == "__main__":
    main()
