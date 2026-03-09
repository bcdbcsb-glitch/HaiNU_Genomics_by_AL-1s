#!/bin/bash

# 1. 你的原始 BAM 文件夹
export INPUT_DIR="/mnt/nas/bdt_bam/weichongfu_with_rg"

# 2. 新建一个文件夹存放修复后的 BAM（建议不要直接覆盖原文件，以防万一）
export FIXED_BAM_DIR="/mnt/nas/bdt_bam/weichongfu_with_rg_fixed"

# 3. 每个 samtools 进程使用的线程数
export THREADS=4

mkdir -p "$FIXED_BAM_DIR"

fix_rg() {
    bam_file="$1"
    sample_name=$(basename "$bam_file" .sorted.bam)
    output_bam="$FIXED_BAM_DIR/${sample_name}.sorted.bam"
    
    echo "=================================================="
    echo "Fixing RG for $sample_name ..."
    
    # 使用 samtools addreplacerg 修复
    # -r 指定标准格式的 RG 字符串（\t 确保是制表符）
    # -m overwrite_all 强制覆盖每一条 Read 原有的错误 RG 标签
    samtools addreplacerg \
        -r "@RG\tID:${sample_name}\tSM:${sample_name}\tPL:ILLUMINA\tLB:lib1" \
        -m overwrite_all \
        -@ "$THREADS" \
        -o "$output_bam" \
        "$bam_file"
        
    echo "Indexing $sample_name ..."
    samtools index -@ "$THREADS" "$output_bam"
}

export -f fix_rg

echo "Starting parallel RG fix (Running 8 jobs concurrently)..."

# 启用 8 个并行任务（8个任务 * 4线程 = 32线程，请根据你的服务器配置调整 -P 的数值）
find "$INPUT_DIR" -maxdepth 1 -name "*.sorted.bam" | xargs -P 8 -I {} bash -c 'fix_rg "$@"' _ {}

echo "=================================================="
echo "All BAM files fixed and indexed! New files are in $FIXED_BAM_DIR"