---
tags: [llama.cpp, build, inference, gpu, optimization]
date: 2026-07-20
type: documentation
category: docs
sources:
  - raw/docs/llama-cpp-build-and-operations.md
related:
  - wiki/entities/llama-cpp.md
---

# Llama.cpp: Build Guide and Operations Reference

This guide covers building llama.cpp with various backends and understanding the supported GGML operations.

## Overview

llama.cpp is a C/C++ library for high-performance LLM inference on any hardware. It's used by projects including [Ollama](https://ollama.ai), [LM Studio](https://lmstudio.ai), and various chatbots.

## Building llama.cpp

### Quick Start

```bash
git clone https://github.com/ggml-org/llama.cpp
cd llama.cpp
cmake -B build
cmake --build build
```

Run: `./build/bin/llama-cli -m path/to/model.gguf`

### CMake Options Summary

| Option | Description |
|--------|-------------|
| `GGML_CUDA=ON` | Enable NVIDIA GPU acceleration |
| `GGML_METAL=ON` | Enable Apple Metal GPU acceleration (default on macOS) |
| `GGML_SYCL=ON` | Intel GPU acceleration (requires oneAPI) |
| `GGML_MUSA=ON` | AMD MUSA (Moore Threads) |
| `GGML_HIP=ON` | AMD ROCm (HIP) |
| `GGML_VULKAN=ON` | Vulkan backend |
| `GGML_OPENMP=ON` | Multi-threaded CPU builds |
| `GGML_BLAS=ON` | BLAS acceleration for batch processing |

### Build for Specific GPU

#### NVIDIA CUDA

```bash
cmake -B build -DGGML_CUDA=ON
cmake --build build
```

**Environment variables** (runtime):
- `CUDA_VISIBLE_DEVICES`: Control which GPUs are visible
- `GGML_CUDA_ENABLE_UNIFIED_MEMORY=1`: Swap to system RAM when VRAM is exhausted
- `GGML_CUDA_P2P`: Enable peer-to-peer access between GPUs (requires NVLink)

#### Apple Metal

Metal is enabled by default on macOS. To disable GPU:

```bash
cmake -B build -DGGML_METAL=OFF
```

Runtime: `./build/bin/llama-cli --n-gpu-layers 0`

#### Intel SYCL (oneAPI)

```bash
# Using Intel compilers
source /opt/intel/oneapi/setvars.sh
cmake -B build -DGGML_SYCL=ON
cmake --build build
```

### Multi-GPU / Hybrid CPU+GPU

Split layers between GPU and CPU:

```bash
# Use all 99 layers on GPU (if VRAM allows)
./build/bin/llama-cli -m model.gguf -ngl 99

# Or split: 50 on GPU, rest on CPU
./build/bin/llama-cli -m model.gguf -ngl 50
```

## Supported GGML Operations

The GGML library provides a large set of tensor operations. Below is a condensed summary by backend:

### CPU (default)

All operations available. Optimized for:
- AVX2/AVX512 on x86
- NEON on ARM

### CUDA

Strong support for most operations. Flash Attention, GEMM, and convolutions are highly optimized.

### Metal

Full support for all operations. Metal is first-class on Apple Silicon.

### SYCL

Subset of operations (focusing on Intel GPU compatibility).

### Vulkan

Partial support; good for Linux users without CUDA.

See `docs/ops.md` for the complete operation matrix.

## Main Tools

| Tool | Purpose |
|------|---------|
| `llama-cli` | Command-line inference |
| `llama-server` | OpenAI-compatible REST API + web UI |
| `export-lora` | Merge LoRA adapters into base model |
| `quantize` | Quantize models (Q4_K_M, Q5_K_S, etc.) |
| `imatrix` | Compute imatrix for quantization |
| `batched-bench` | Benchmark batch decoding performance |
| `perplexity` | Compute perplexity of a model |

### Quantizing a Model

```bash
# Build quantizer
python3 -m pip install -r tools/quantize/requirements.txt

# Quantize to Q5_K_M (good balance)
python3 tools/quantize/main.py \
    --model f16-model.gguf \
    --out q5_K_M-model.gguf
```

## License

llama.cpp is MIT-licensed. See `LICENSE` in the repo.

---

*This guide is based on the official llama.cpp repository documentation. For the latest information, refer to https://github.com/ggml-org/llama.cpp.*
