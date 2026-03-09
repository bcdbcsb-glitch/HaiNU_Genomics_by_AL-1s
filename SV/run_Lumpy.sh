#!/bin/bash

# 输入BAM文件目录（请修改为实际路径）
export INPUT_DIR="/data/input_bams/"
# 参考基因组目录（请修改为实际路径）
export REF_FASTA_DIR="/data/reference/"
# 输出结果根目录（请修改为实际路径）
export BASE_OUTPUT_DIR="/data/output/sv_results/"
# 每个样本使用的CPU线程数
export THREADS_PER_SAMPLE=3

# 创建输出目录
mkdir -p "$BASE_OUTPUT_DIR"

# 处理单个样本的函数
process_sample() {
    bam_file="$1"
    sample_name=$(basename "$bam_file" .sorted.bam)

    SAMPLE_OUT_DIR="$BASE_OUTPUT_DIR/$sample_name"
    mkdir -p "$SAMPLE_OUT_DIR"
    
    echo "Processing $sample_name ... (Logs are being written to $SAMPLE_OUT_DIR/${sample_name}.log)"
    
    # 使用smoove docker容器进行结构变异检测
    docker run --rm \
        -v "$INPUT_DIR":/data \
        -v "$REF_FASTA_DIR":/ref \
        -v "$SAMPLE_OUT_DIR":/results \
        docker.xuanyuan.run/brentp/smoove \
        smoove call \
        --outdir "/results" \
        --name "$sample_name" \
        --fasta "/ref/Sscrofa_genomic.fna" \
        --processes "$THREADS_PER_SAMPLE" \
        "/data/$sample_name.sorted.bam" > "$SAMPLE_OUT_DIR/${sample_name}.log" 2>&1
}

# 导出函数以便并行调用
export -f process_sample

echo "Starting parallel processing (Max 12 jobs at a time)..."
echo "=================================================="

# 并行处理所有BAM文件（最多同时处理12个样本）
find "$INPUT_DIR" -maxdepth 1 -name "*.sorted.bam" | xargs -P 12 -I {} bash -c 'process_sample "$@"' _ {}

echo "=================================================="
echo "All samples processed. Check the subdirectories in $BASE_OUTPUT_DIR for results and logs."
