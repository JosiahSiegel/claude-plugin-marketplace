---
name: ml-fine-tuning
description: |
  This skill should be used when the user asks to adapt pretrained, foundation, language, vision, multimodal, or embedding models. PROACTIVELY activate for: (1) transfer learning, full fine-tuning, frozen backbones, adapters, LoRA, QLoRA, AdaLoRA, PEFT, (2) Hugging Face Transformers, Diffusers, Accelerate, TRL, RLHF, DPO, preference tuning, alignment, (3) dataset preparation, instruction tuning, chat templates, tokenization, packing, catastrophic forgetting, (4) RAG, vector databases, embedding optimization, reranking, (5) multimodal and edge fine-tuning. Provides: safe, efficient fine-tuning and adaptation guidance.
---

# ML Fine-Tuning

## Overview

Use this skill for adapting pretrained models to new tasks, domains, styles, instructions, modalities, or constraints. Fine-tuning is not always the right first step: compare prompting, retrieval-augmented generation, feature extraction, classical heads, and smaller task-specific models before training a large foundation model.

## Choose the Adaptation Method

| Method | Use when | Trade-offs |
|---|---|---|
| Prompting/system instructions | Behavior change is simple and context fits | No training cost; limited persistence and control |
| RAG | Need factual/domain knowledge that changes or must be cited | Requires retrieval quality, chunking, and grounding evaluation |
| Feature extraction + head | Small labeled dataset and strong pretrained embeddings | Efficient; limited deep adaptation |
| Partial fine-tuning | Need domain adaptation with limited compute | Must choose layers carefully |
| Full fine-tuning | Large dataset, high task specificity, enough compute | Highest cost and forgetting risk |
| LoRA/adapters/PEFT | Need efficient adaptation and many variants | Slight capacity limits; target modules matter |
| QLoRA | Fine-tune large LLMs on constrained GPUs | Quantization and optimizer choices affect stability |
| Preference tuning/RLHF/DPO | Need behavior alignment to preferences | Reward/preference data quality dominates |
| Distillation | Need smaller/faster deployable model | Requires teacher quality and representative data |

## Dataset Preparation

Fine-tuning quality is usually data quality. Deduplicate, remove corrupted samples, filter unsafe or irrelevant content, balance tasks, standardize labels, and preserve evaluation holdouts. For instruction tuning, use consistent schemas and chat templates matching the base model. For classification, check label definitions and inter-annotator agreement. For retrieval/embedding fine-tuning, mine hard negatives and avoid false negatives.

Split data by entity, time, source, or document when examples are correlated. Never let near-duplicates, prompt variants, chunks from the same document, or generated paraphrases cross train/validation/test boundaries. For generative tasks, keep a human-reviewable validation set with representative hard cases.

## QLoRA and PEFT (Hugging Face Blueprint)

QLoRA keeps the base model frozen in 4-bit while training small low-rank adapters, saving massive amounts of GPU VRAM.

### 1. Initialize 4-Bit Base Model (BitsAndBytesConfig)
```python
import torch
from transformers import AutoModelForCausalLM, AutoTokenizer, BitsAndBytesConfig

model_id = "meta-llama/Meta-Llama-3-8B-Instruct"

# Configure 4-bit quantization details
bnb_config = BitsAndBytesConfig(
    load_in_4bit=True,
    bnb_4bit_use_double_quant=True,
    bnb_4bit_quant_type="nf4", # Normalized Float 4 (optimal for zero-mean normal weights)
    bnb_4bit_compute_dtype=torch.bfloat16 # Compute in BF16 for training stability
)

tokenizer = AutoTokenizer.from_pretrained(model_id)
model = AutoModelForCausalLM.from_pretrained(
    model_id,
    quantization_config=bnb_config,
    device_map="auto"
)
```

### 2. Configure LoRA Parameters & Prepare Model
```python
from peft import LoraConfig, get_peft_model, prepare_model_for_kbit_training

# Prepare frozen model for quantized adapter training
model = prepare_model_for_kbit_training(model)

# Define Low-Rank Adaptation (LoRA) Config
peft_config = LoraConfig(
    r=16, # Rank dimension (typically 8, 16, 32, or 64)
    lora_alpha=32, # Scaling factor (usually 2 * rank)
    target_modules=["q_proj", "k_proj", "v_proj", "o_proj", "gate_proj", "up_proj", "down_proj"],
    lora_dropout=0.05,
    bias="none",
    task_type="CAUSAL_LM"
)

# Wrap base model with LoRA adapters
model = get_peft_model(model, peft_config)
model.print_trainable_parameters()
```

## TRL (Transformer Reinforcement Learning) Training Setup

TRL provides wrappers such as `SFTTrainer` for Supervised Fine-Tuning and `DPOTrainer` for Direct Preference Optimization.

### 1. Supervised Fine-Tuning (`SFTTrainer`)
```python
from trl import SFTTrainer
from transformers import TrainingArguments

training_args = TrainingArguments(
    output_dir="./results",
    per_device_train_batch_size=4,
    gradient_accumulation_steps=4,
    learning_rate=2e-4,
    logging_steps=10,
    max_steps=500,
    fp16=False,
    bf16=True, # Optimal on Ampere/Hopper architecture GPUs
    optim="paged_adamw_8bit" # Page state out to host memory to prevent OOMs
)

trainer = SFTTrainer(
    model=model,
    train_dataset=dataset,
    peft_config=peft_config,
    dataset_text_field="text",
    max_seq_length=512,
    tokenizer=tokenizer,
    args=training_args
)

# trainer.train()
```

### 2. Direct Preference Optimization (`DPOTrainer`)
DPO directly trains a model on pairs of preferred/rejected outputs without needing a separate reward model.
```python
from trl import DPOTrainer

dpo_trainer = DPOTrainer(
    model=model,
    ref_model=None, # TRL will implicitly handle ref_model under PEFT by disabling adapters
    args=training_args,
    beta=0.1, # Temperature parameter for DPO loss (scales difference from reference policy)
    train_dataset=preference_dataset,
    tokenizer=tokenizer,
    max_length=512,
    max_prompt_length=256
)
# dpo_trainer.train()
```

## SentenceTransformers Custom Embedding Model Fine-Tuning

Embedding fine-tuning creates custom vector spaces for retrieval-heavy (RAG) applications.

```python
from sentence_transformers import SentenceTransformer, InputExample, losses
from torch.utils.data import DataLoader

model = SentenceTransformer("all-MiniLM-L6-v2")

# Create positive pairs (e.g., query and matching document)
train_examples = [
    InputExample(texts=["How to initialize FSDP in PyTorch?", "Use FullyShardedDataParallel wrapper..."]),
    InputExample(texts=["What is QLoRA?", "QLoRA trains adapters over a frozen 4-bit base model..."])
]

train_dataloader = DataLoader(train_examples, shuffle=True, batch_size=16)

# MultipleNegativesRankingLoss treats other pairs in the batch as implicit negative examples
train_loss = losses.MultipleNegativesRankingLoss(model=model)

# model.fit(
#     train_objectives=[(train_dataloader, train_loss)], 
#     epochs=3, 
#     warmup_steps=100
# )
```

## Training Stability

Use conservative learning rates for fine-tuning. Warmup often helps. Monitor train and validation loss, task metrics, generation quality, and overfitting. For LLMs, watch for format drift, verbosity changes, refusal regressions, hallucination, tool-use regressions, and safety issues. Use gradient clipping for instability and validate that labels are masked correctly for instruction tuning.

Catastrophic forgetting appears when the model improves on new data but loses general ability. Mitigate with smaller LR, fewer epochs, mixed-domain data, replay examples, adapters instead of full fine-tuning, regularization, or multi-task balancing.

## Sources

- Hugging Face Transformers documentation: https://huggingface.co/docs/transformers
- Hugging Face PEFT documentation: https://huggingface.co/docs/peft
- Hugging Face TRL documentation: https://huggingface.co/docs/trl
- Hugging Face Diffusers training docs: https://huggingface.co/docs/diffusers/training/overview
- Sentence Transformers documentation: https://www.sbert.net/
- Ray and Accelerate distributed training docs: https://docs.ray.io/ and https://huggingface.co/docs/accelerate
