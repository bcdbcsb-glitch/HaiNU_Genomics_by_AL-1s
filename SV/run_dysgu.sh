#!/bin/bash

# ================= 配置区域 =================
INPUT_DIR="/mnt/nas/bdt_bam"
REF_FASTA="/home/user/SScrofaRef/Sscrofa_genomic.fna"
BASE_TEMP_DIR="./dysgu_temp"
# ===========================================

# 设置线程数
THREADS=32

OUTPUT_DIR="results_dysgu"
mkdir -p "$OUTPUT_DIR"
mkdir -p "$BASE_TEMP_DIR"

# 遍历所有BAM文件
for bam_file in "${INPUT_DIR}"/*.sorted.bam; do
    [ -e "$bam_file" ] || continue
    
    # 提取样本名
    sample_name=$(basename "$bam_file" .sorted.bam)
    output_vcf="${OUTPUT_DIR}/${sample_name}.dysgu.vcf"
    
    # 为每个样本创建独立的临时目录
    sample_temp_dir="${BASE_TEMP_DIR}/${sample_name}"
    mkdir -p "$sample_temp_dir"
    
    echo "========================================"
    echo "运行Dysgu检测: $sample_name"
    echo "输入BAM: $bam_file"
    echo "临时目录: $sample_temp_dir"
    echo "输出VCF: $output_vcf"
    echo "========================================"
    
    # 运行dysgu，为每个样本使用独立的临时目录
    dysgu run -x -p"$THREADS" "$REF_FASTA" "$sample_temp_dir" "$bam_file" > "$output_vcf" 2> "${OUTPUT_DIR}/${sample_name}.log"
    
    # 检查命令执行状态
    if [ $? -eq 0 ]; then
        echo "✓ $sample_name 处理完成"
        
        # 统计检测到的SV数量
        if [ -f "$output_vcf" ]; then
            sv_count=$(grep -c "^[^#]" "$output_vcf" 2>/dev/null || echo "0")
            echo "  检测到SV数量: $sv_count"
        fi
    else
        echo "✗ $sample_name 处理失败，请查看日志: ${OUTPUT_DIR}/${sample_name}.log"
    fi
    
    echo ""
done

echo "所有样本处理完成!"
echo "VCF文件保存在: $OUTPUT_DIR/"
echo "临时文件保存在: $BASE_TEMP_DIR/"

# 如果需要清理临时文件，可以取消下面的注释
# echo "清理临时文件..."
# rm -rf "$BASE_TEMP_DIR"
