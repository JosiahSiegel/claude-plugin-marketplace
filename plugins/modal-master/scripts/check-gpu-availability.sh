#!/bin/bash
# Check Modal GPU availability and pricing

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo "=== Modal GPU Availability Check ==="
echo ""

# Check Modal CLI
if ! command -v modal &> /dev/null; then
    echo -e "${RED}Error: Modal CLI not installed${NC}"
    echo "Install with: pip install modal"
    exit 1
fi

# Check authentication
if ! modal token info &> /dev/null 2>&1; then
    echo -e "${RED}Error: Not authenticated with Modal${NC}"
    echo "Run: modal setup"
    exit 1
fi

echo -e "${GREEN}✓ Modal CLI installed and authenticated${NC}"
echo ""

# GPU types and pricing (2025 rates)
declare -A GPU_PRICES
GPU_PRICES[T4]="0.000164"
GPU_PRICES[L4]="0.000222"
GPU_PRICES[A10G]="0.000306"
GPU_PRICES[L40S]="0.000417"
GPU_PRICES[A100-40GB]="0.000556"
GPU_PRICES[A100-80GB]="0.000833"
GPU_PRICES[H100]="0.001389"
GPU_PRICES[H200]="0.001389"
GPU_PRICES[B200]="0.001736"

declare -A GPU_MEMORY
GPU_MEMORY[T4]="16"
GPU_MEMORY[L4]="24"
GPU_MEMORY[A10G]="24"
GPU_MEMORY[L40S]="48"
GPU_MEMORY[A100-40GB]="40"
GPU_MEMORY[A100-80GB]="80"
GPU_MEMORY[H100]="80"
GPU_MEMORY[H200]="141"
GPU_MEMORY[B200]="180+"

echo "=== GPU Types and Pricing ==="
echo ""
printf "%-14s %-10s %-15s %-10s\n" "GPU" "Memory" "Cost/sec" "Cost/hr"
printf "%-14s %-10s %-15s %-10s\n" "---" "------" "--------" "-------"

for gpu in T4 L4 A10G L40S A100-40GB A100-80GB H100 H200 B200; do
    price=${GPU_PRICES[$gpu]}
    memory=${GPU_MEMORY[$gpu]}
    hourly=$(echo "$price * 3600" | bc -l | xargs printf "%.2f")
    printf "%-14s %-10s \$%-14s \$%-10s\n" "$gpu" "${memory}GB" "$price" "$hourly"
done

echo ""
echo "=== Quick GPU Test ==="
echo ""
echo "Testing GPU availability with simple function..."
echo ""

# Create temp test file
TEMP_FILE=$(mktemp).py
cat > "$TEMP_FILE" << 'EOF'
import modal

app = modal.App("gpu-check")

@app.function(gpu="any", timeout=60)
def check_gpu():
    import subprocess
    result = subprocess.run(["nvidia-smi", "--query-gpu=name,memory.total", "--format=csv,noheader"],
                          capture_output=True, text=True)
    return result.stdout.strip()

@app.local_entrypoint()
def main():
    result = check_gpu.remote()
    print(f"Available GPU: {result}")
EOF

echo "Running GPU check..."
if modal run "$TEMP_FILE" 2>/dev/null; then
    echo -e "${GREEN}✓ GPU access verified${NC}"
else
    echo -e "${YELLOW}⚠ Could not verify GPU access${NC}"
fi

# Cleanup
rm -f "$TEMP_FILE"

echo ""
echo "=== GPU Selection Guide ==="
echo ""
echo "Small models (<7B params):     T4 or L4"
echo "Medium models (7B-13B):        A10G or L40S"
echo "Large models (13B-70B):        A100-80GB or H100"
echo "Training/Fine-tuning:          A100 or H100"
echo "Maximum performance:           H100 or H200"
echo "Largest models (70B+):         H200 or B200"
echo ""
echo "=== Fallback Configuration ==="
echo ""
echo 'For best availability, use fallbacks:'
echo '  gpu=["H100", "A100-80GB", "A100", "any"]'
echo ""
echo '"any" includes: L4, A10G, or T4'
echo ""
