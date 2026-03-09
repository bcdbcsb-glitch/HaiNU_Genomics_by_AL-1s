#!/bin/bash

# ================= 配置区域 =================
INPUT_DIR="/mnt/nas/bdt_bam"
REF_FASTA="/home/user/SScrofaRef/Sscrofa_genomic.fna"
MANTA_CONFIG="configManta.py" # 确保在环境变量中或使用绝对路径
# ===========================================

OUTPUT_DIR="results_manta"
mkdir -p "$OUTPUT_DIR"

for bam_file in "${INPUT_DIR}"/*.sorted.bam; do
    [ -e "$bam_file" ] || continue
    sample_name=$(basename "$bam_file" .sorted.bam)
    
    # Manta 需要独立的运行目录
    run_dir="${OUTPUT_DIR}/${sample_name}_run"
    
    echo "Configuring Manta for: $sample_name"
    
    $MANTA_CONFIG \
        --bam "$bam_file" \
        --referenceFasta "$REF_FASTA" \
        --runDir "$run_dir"
    
    echo "Running Manta for: $sample_name"
    
    # 执行 Workflow (使用 -j 设置线程数)
    "${run_dir}/runWorkflow.py" -j 32
    
    # 复制最终 VCF 出来并重命名，方便后续合并
    cp "${run_dir}/results/variants/diploidSV.vcf.gz" "${OUTPUT_DIR}/${sample_name}.manta.vcf.gz"
    gunzip -f "${OUTPUT_DIR}/${sample_name}.manta.vcf.gz"
    
    echo "Finished $sample_name"
done