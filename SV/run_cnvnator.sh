#!/bin/bash

# ================ 勇者装备配置区 ================
# 存放BAM文件（勇者的冒险记录）的文件夹路径
INPUT_DIR="/mnt/nas/bdt_bam"
# 大飞柱邮箱的参考基因组（勇者的地图）路径
REF_FASTA="/home/User/SScrofaRef/Sscrofa_genomic.fna"
# 扫描窗口大小（就像勇者探索地图的视野范围）
BIN_SIZE=200
# ===========================================

# 创建存放成果的文件夹（勇者的战利品仓库）
OUTPUT_DIR="results_cnvnator_BIN_SIZE_200"
mkdir -p "$OUTPUT_DIR"

# 先确认勇者的冒险记录（BAM文件）是否存在～
if [ ! -d "$INPUT_DIR" ]; then
    echo "Error: Input directory $INPUT_DIR does not exist."
    exit 1
fi

for bam_file in "${INPUT_DIR}"/*.sorted.bam; do
    # 如果找到BAM文件，就开始逐个挑战！
    [ -e "$bam_file" ] || continue

    sample_name=$(basename "$bam_file" .sorted.bam)
    echo "Processing CNVnator for: $sample_name"
    
    # 第1步：提取信号（就像收集勇者的技能数据）
    cnvnator -root "${OUTPUT_DIR}/${sample_name}.root" -tree "$bam_file"
    
    # 第2步：生成直方图（绘制冒险地图的等高线）
    cnvnator -root "${OUTPUT_DIR}/${sample_name}.root" -his $BIN_SIZE -d "$(dirname "$REF_FASTA")"
    
    # 第3步：统计（整理战利品清单）
    cnvnator -root "${OUTPUT_DIR}/${sample_name}.root" -stat $BIN_SIZE
    
    # 第4步：分区（划分冒险区域）
    cnvnator -root "${OUTPUT_DIR}/${sample_name}.root" -partition $BIN_SIZE
    
    # 第5步：Call CNV 并导出结果（最终BOSS战！）
    cnvnator -root "${OUTPUT_DIR}/${sample_name}.root" -call $BIN_SIZE > "${OUTPUT_DIR}/${sample_name}.cnvnator.out"
    
    # 第6步：把CNVnator格式转换成VCF格式（就像把冒险日记翻译成通用语言）
    # 需要提前从GitHub下载cnvnator2VCF.pl放在脚本同目录下哦～
    cnvnator2VCF.pl -prefix ${sample_name} -reference Sscrofa \
      "${OUTPUT_DIR}/${sample_name}.cnvnator.out" \
      "$(dirname "$REF_FASTA")" \
      > "${OUTPUT_DIR}/${sample_name}.cnvnator.vcf"
    
    echo "Finished $sample_name"
done