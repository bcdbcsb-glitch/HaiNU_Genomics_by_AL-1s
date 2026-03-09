#!/bin/bash

# ================= 配置区域 =================
INPUT_DIR="/mnt/nas/bdt_bam"
REF_FASTA="/home/user/SScrofaRef/Sscrofa_genomic.fna"
OUTPUT_DIR="results_delly"
THREADS=32
# ===========================================

mkdir -p "$OUTPUT_DIR"

# 定义执行函数
run_delly() {
    local bam_file=$1
    local ref=$2
    local out_dir=$3
    
    sample_name=$(basename "$bam_file" .sorted.bam)
    output_bcf="${out_dir}/${sample_name}.delly.bcf"
    output_vcf="${out_dir}/${sample_name}.delly.vcf"
    
    echo "Processing: $sample_name"
    # 这里每个 delly 进程只使用 1 个线程，由 parallel 控制并行度
    OMP_NUM_THREADS=1 delly call -g "$ref" -o "$output_bcf" "$bam_file"
    bcftools view "$output_bcf" > "$output_vcf"
}

# 导出函数供 parallel 调用
export -f run_delly

# 搜索所有 bam 并通过 parallel 运行
# -j 32 表示同时并行 32 个任务
find "$INPUT_DIR" -name "*.sorted.bam" | parallel -j "$THREADS" run_delly {} "$REF_FASTA" "$OUTPUT_DIR"

echo "All samples finished."