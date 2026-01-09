#!/bin/bash
# Estimate Modal costs for a workload

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo "=== Modal Cost Estimator ==="
echo ""

# GPU pricing ($/second) - 2025 rates
declare -A GPU_SEC_PRICES
GPU_SEC_PRICES[T4]="0.000164"
GPU_SEC_PRICES[L4]="0.000222"
GPU_SEC_PRICES[A10G]="0.000306"
GPU_SEC_PRICES[L40S]="0.000417"
GPU_SEC_PRICES[A100]="0.000556"
GPU_SEC_PRICES[A100-40GB]="0.000556"
GPU_SEC_PRICES[A100-80GB]="0.000833"
GPU_SEC_PRICES[H100]="0.001389"
GPU_SEC_PRICES[H200]="0.001389"
GPU_SEC_PRICES[B200]="0.001736"

# CPU pricing: $0.0000131/core/sec
CPU_PRICE="0.0000131"

# Memory pricing: $0.00000222/GiB/sec
MEM_PRICE="0.00000222"

print_usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --gpu <type>         GPU type (T4, L4, A10G, L40S, A100, H100, H200, B200)"
    echo "  --gpu-count <n>      Number of GPUs per container (default: 1)"
    echo "  --cpu <cores>        CPU cores per container (default: 2)"
    echo "  --memory <gb>        Memory in GB per container (default: 8)"
    echo "  --duration <sec>     Duration per request in seconds"
    echo "  --requests <n>       Number of requests per day"
    echo "  --containers <n>     Average concurrent containers"
    echo "  --warm <sec>         Idle warm time per day (seconds)"
    echo ""
    echo "Examples:"
    echo "  $0 --gpu A100 --duration 5 --requests 1000"
    echo "  $0 --gpu T4 --cpu 4 --memory 16 --duration 10 --requests 10000"
    echo "  $0 --cpu 2 --memory 4 --duration 1 --requests 100000"
    echo ""
}

# Default values
GPU_TYPE=""
GPU_COUNT=1
CPU_CORES=2
MEMORY_GB=8
DURATION_SEC=0
REQUESTS_PER_DAY=0
CONTAINERS=1
WARM_SEC=0

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --gpu)
            GPU_TYPE="$2"
            shift 2
            ;;
        --gpu-count)
            GPU_COUNT="$2"
            shift 2
            ;;
        --cpu)
            CPU_CORES="$2"
            shift 2
            ;;
        --memory)
            MEMORY_GB="$2"
            shift 2
            ;;
        --duration)
            DURATION_SEC="$2"
            shift 2
            ;;
        --requests)
            REQUESTS_PER_DAY="$2"
            shift 2
            ;;
        --containers)
            CONTAINERS="$2"
            shift 2
            ;;
        --warm)
            WARM_SEC="$2"
            shift 2
            ;;
        --help|-h)
            print_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            print_usage
            exit 1
            ;;
    esac
done

# Validate required inputs
if [ "$DURATION_SEC" -eq 0 ] || [ "$REQUESTS_PER_DAY" -eq 0 ]; then
    echo -e "${YELLOW}Interactive mode: Enter workload details${NC}"
    echo ""

    echo "GPU type (T4/L4/A10G/L40S/A100/H100/H200/B200, or 'none'):"
    read GPU_TYPE
    if [ "$GPU_TYPE" = "none" ]; then
        GPU_TYPE=""
    fi

    if [ -n "$GPU_TYPE" ]; then
        echo "Number of GPUs per container (default: 1):"
        read GPU_COUNT
        GPU_COUNT=${GPU_COUNT:-1}
    fi

    echo "CPU cores per container (default: 2):"
    read CPU_CORES
    CPU_CORES=${CPU_CORES:-2}

    echo "Memory in GB per container (default: 8):"
    read MEMORY_GB
    MEMORY_GB=${MEMORY_GB:-8}

    echo "Duration per request in seconds:"
    read DURATION_SEC

    echo "Number of requests per day:"
    read REQUESTS_PER_DAY

    echo "Daily warm/idle time in seconds (0 for scale-to-zero):"
    read WARM_SEC
    WARM_SEC=${WARM_SEC:-0}
fi

echo ""
echo "=== Workload Configuration ==="
echo ""
if [ -n "$GPU_TYPE" ]; then
    echo "GPU: ${GPU_TYPE} x${GPU_COUNT}"
fi
echo "CPU: ${CPU_CORES} cores"
echo "Memory: ${MEMORY_GB} GB"
echo "Duration/request: ${DURATION_SEC} sec"
echo "Requests/day: ${REQUESTS_PER_DAY}"
echo "Warm time/day: ${WARM_SEC} sec"
echo ""

# Calculate costs
echo "=== Cost Breakdown ==="
echo ""

# Total compute seconds per day
COMPUTE_SEC=$(echo "$DURATION_SEC * $REQUESTS_PER_DAY" | bc -l)
TOTAL_SEC=$(echo "$COMPUTE_SEC + $WARM_SEC" | bc -l)

# GPU cost
if [ -n "$GPU_TYPE" ]; then
    GPU_PRICE=${GPU_SEC_PRICES[$GPU_TYPE]}
    if [ -z "$GPU_PRICE" ]; then
        echo -e "${RED}Unknown GPU type: $GPU_TYPE${NC}"
        exit 1
    fi
    GPU_DAILY=$(echo "$GPU_PRICE * $TOTAL_SEC * $GPU_COUNT" | bc -l)
    printf "GPU (${GPU_TYPE} x${GPU_COUNT}):   \$%.4f/day\n" "$GPU_DAILY"
else
    GPU_DAILY=0
fi

# CPU cost
CPU_DAILY=$(echo "$CPU_PRICE * $CPU_CORES * $TOTAL_SEC" | bc -l)
printf "CPU (${CPU_CORES} cores):       \$%.4f/day\n" "$CPU_DAILY"

# Memory cost
MEM_DAILY=$(echo "$MEM_PRICE * $MEMORY_GB * $TOTAL_SEC" | bc -l)
printf "Memory (${MEMORY_GB} GB):       \$%.4f/day\n" "$MEM_DAILY"

# Total
DAILY_TOTAL=$(echo "$GPU_DAILY + $CPU_DAILY + $MEM_DAILY" | bc -l)
MONTHLY_TOTAL=$(echo "$DAILY_TOTAL * 30" | bc -l)
YEARLY_TOTAL=$(echo "$DAILY_TOTAL * 365" | bc -l)

echo ""
echo "=== Total Estimated Costs ==="
echo ""
printf "Daily:     \$%.2f\n" "$DAILY_TOTAL"
printf "Monthly:   \$%.2f\n" "$MONTHLY_TOTAL"
printf "Yearly:    \$%.2f\n" "$YEARLY_TOTAL"

# Cost per request
if [ "$REQUESTS_PER_DAY" -gt 0 ]; then
    COST_PER_REQUEST=$(echo "$DAILY_TOTAL / $REQUESTS_PER_DAY" | bc -l)
    echo ""
    printf "Cost per request: \$%.6f\n" "$COST_PER_REQUEST"
fi

echo ""
echo "=== Cost Optimization Tips ==="
echo ""

if [ -n "$GPU_TYPE" ]; then
    # GPU optimization tips
    if [ "$GPU_TYPE" = "H100" ] || [ "$GPU_TYPE" = "H200" ] || [ "$GPU_TYPE" = "B200" ]; then
        echo "• Consider A100 for cost savings if H100/H200 performance isn't required"
    fi
    if [ "$GPU_TYPE" = "A100" ] || [ "$GPU_TYPE" = "A100-80GB" ]; then
        echo "• A10G or L40S may suffice for inference workloads"
    fi
    if [ "$WARM_SEC" -gt 3600 ]; then
        echo "• Reduce warm time with container_idle_timeout to lower idle costs"
    fi
fi

if [ "$DURATION_SEC" -gt 60 ]; then
    echo "• Consider breaking long tasks into smaller chunks with .map()"
fi

echo "• Use @modal.batched for inference to maximize GPU utilization"
echo "• Use @modal.concurrent to handle multiple requests per container"
echo ""
echo -e "${YELLOW}Note: Actual costs may vary based on region and availability.${NC}"
echo "Check Modal dashboard for real-time usage: https://modal.com/usage"
echo ""
