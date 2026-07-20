---
tags: [llama.cpp, server, cli, inference, api]
date: 2026-07-20
type: documentation
category: docs
sources:
  - wiki/docs/llama-cpp-build-and-operations.md
  - raw/docs/llama-cpp-server-and-cli.md
related:
  - wiki/entities/llama-cpp.md
  - wiki/docs/llama-cpp-build-and-operations.md
---

# Llama.cpp: Server Setup and CLI Usage

This guide provides detailed information on running the llama.cpp HTTP server and using the CLI tool for inference.

---

## Server Setup

### Starting the Server

**Single model mode:**
```bash
./build/bin/llama-server -m models/model-Q4_K_M.gguf
```

**Router mode (multiple models, dynamic loading):**
```bash
./build/bin/llama-server
```

Then access models via the `/v1/models` endpoint or by calling `/models/load`.

### Hugging Face Integration

Download and run models directly from Hugging Face:

```bash
./build/bin/llama-server -hf ggml-org/gemma-3-1b-it-GGUF
```

Or with specific quantization:
```bash
./build/bin/llama-server -hf ggml-org/gemma-3-1b-it-GGUF:Q8_0
```

### Custom Model Paths

You can point the server to a local directory:
```bash
./build/bin/llama-server --models-dir ./my-models
```

Or specify a single custom model:
```bash
./build/bin/llama-server -m ./models/my-custom-model.gguf
```

### Multi-GPU Configuration

When running with multiple GPUs, you can split layers:

```bash
./build/bin/llama-server -m model.gguf -ngl 50
```

This places the first 50 layers on GPU and the rest on CPU. For finer control, use `--tensor-split`:

```bash
./build/bin/llama-server -m model.gguf -ngl auto -ts 0.5,0.5
```

### Server Configuration via Presets

For advanced users, use `.ini` preset files:

```ini
version = 1

[my-preset]
model = /path/to/model.gguf
c = 8192
n-gpu-layers = 8
jinja = true
```

Launch with:
```bash
./llama-server --models-preset my-preset.ini
```

### Monitoring and Metrics

Enable Prometheus metrics:
```bash
./llama-server -m model.gguf --metrics
```

Query at `http://localhost:8080/metrics`.

---

## Server API Reference

### Completion Endpoints

**Standard completions (OpenAI-compatible):**

```bash
curl http://localhost:8080/v1/completions \
  -H "Content-Type: application/json" \
  -d '{"model": "davinci-002", "prompt": "The meaning of life is", "max_tokens": 8}'
```

**Streaming mode:**

```bash
curl -N http://localhost:8080/v1/completions \
  -H "Content-Type: application/json" \
  -d '{"prompt": "Complete this: Once upon a time,"}'
```

**Chat completions:**

```bash
curl http://localhost:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-3.5-turbo",
    "messages": [
      {"role": "system", "content": "You are a helpful assistant."},
      {"role": "user", "content": "What is 2+2?"}
    ]
  }'
```

### Embeddings

```bash
curl http://localhost:8080/v1/embeddings \
  -H "Content-Type: application/json" \
  -d '{"input": "hello world", "model": "BAAI/bge-small-en-v1.5"}'
```

### Reranking

```bash
curl http://localhost:8080/v1/rerank \
  -H "Content-Type: application/json" \
  -d '{
    "model": "BAAI/bge-reranker-v2-m3",
    "query": "What is a panda?",
    "documents": ["A bear native to China"],
    "top_n": 1
  }'
```

### Tokenization

```bash
curl http://localhost:8080/tokenize -d '{"content": "hello"}'
```

### Properties and Slots

Get server info:
```bash
curl http://localhost:8080/props
```

Query slot state:
```bash
curl http://localhost:8080/slots
```

---

## CLI Usage

### Basic Inference

```bash
./build/bin/llama-cli -m models/model.gguf
```

### Using a Prompt File

```bash
./build/bin/llama-cli -m model.gguf -p "Your prompt here"
```

### Hugging Face Models

```bash
./build/bin/llama-cli -hf ggml-org/gemma-7b-it
```

### Context Size and Output Length

```bash
./build/bin/llama-cli -m model.gguf -c 2048 -n 128
```

### GPU Layer Offload

```bash
./build/bin/llama-cli -m model.gguf -ngl 99
```

### Batch Generation (multiple prompts)

```bash
./build/bin/llama-cli -m model.gguf -b 4 -t 4
```

### Interactive Chat Mode

```bash
./build/bin/llama-cli -m model.gguf -cnv
```

In interactive mode, type `/quit` to exit.

### System Prompt

```bash
./build/bin/llama-cli -m model.gguf -sys "You are a helpful coding assistant."
```

### Using LoRA Adapters

```bash
./build/bin/llama-cli -m base-model.gguf \
  --lora task-lora.gguf \
  --lora-scaled personality-lora.gguf:0.8
```

### Multimodal Inference

```bash
./build/bin/llama-cli \
  -m model.gguf \
  -ngl auto \
  --image input.jpg
```

### JSON Schema Generation

```bash
./build/bin/llama-cli -m model.gguf \
  --json-schema '{"type":"object","properties":{"name":{"type":"string"}}}'
```

### Mirostat Sampling

```bash
./build/bin/llama-cli -m model.gguf \
  --mirostat 2 --mirostat-ent 6.0 --mirostat-lr 0.1
```

---

## Common CLI Options

| Option | Description |
|--------|-------------|
| `-m, --model FNAME` | Path to model file |
| `-c, --ctx-size N` | Context size (default: from model) |
| `-n, --predict N` | Max tokens to generate (-1 = unlimited) |
| `-b, --batch-size N` | Logical max batch size (default: 2048) |
| `-ngl, --n-gpu-layers N` | GPU layers (0 = CPU-only) |
| `-t, --threads N` | CPU threads for generation |
| `--temp N` | Sampling temperature (default: 0.8) |
| `--top-k N` | Top-k sampling (default: 40) |
| `--top-p N` | Nucleus sampling (default: 0.95) |
| `--mirostat N` | Enable Mirostat (1 or 2) |
| `--jinja` | Use Jinja chat template |
| `--chat-template NAME` | Specific template (chatml, llama3, etc.) |
| `--verbose, -v` | Increase log verbosity |
| `--show-timings` | Display prompt/predict times |

---

## Environment Variables

Many CLI options can be set via environment variables:

- `LLAMA_ARG_THREADS` — number of threads
- `LLAMA_ARG_N_GPU_LAYERS` — GPU layer count
- `GGML_CUDA_ENABLE_UNIFIED_MEMORY=1` — enable swap on CUDA
- `CUDA_VISIBLE_DEVICES` — control which GPU to use
- `HF_TOKEN` — Hugging Face API token

Example:
```bash
export CUDA_VISIBLE_DEVICES=0
export LLAMA_ARG_THREADS=8
./build/bin/llama-cli -m model.gguf
```

---

## Troubleshooting

### CUDA out of memory

Reduce GPU layers:
```bash
./llama-server -m model.gguf -ngl 50
```

Enable unified memory:
```bash
./llama-server -m model.gguf -D GGML_CUDA_ENABLE_UNIFIED_MEMORY=1
```

### Context too short

Increase context size:
```bash
./llama-server -m model.gguf --ctx 8192
```

### Model not loading

Check the model file exists and is valid GGUF:
```bash
./llama-cli -m path/to/model.gguf
```

---

*This guide is based on the official llama.cpp repository documentation.*
