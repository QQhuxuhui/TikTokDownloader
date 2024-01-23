#!/bin/bash

# 检查输入参数
if [ $# -ne 2 ]; then
  echo "用法: $0 <视频文件夹路径> <输出文件夹路径>"
  exit 1
fi

# 设置输入文件夹路径和输出文件夹路径
input_folder="$1"
output_folder="$2"

# 检查输出文件夹是否存在，如果不存在则创建
if [ ! -d "$output_folder" ]; then
  mkdir -p "$output_folder"
  echo "已创建输出文件夹: $output_folder"
fi


# 创建临时文件夹
temp_folder=$(mktemp -d)

# 函数：删除中间文件
cleanup_temp_files() {
  rm -f "$temp_folder"/*.mp4
}

# 函数：删除临时文件夹
cleanup() {
  rm -rf "$temp_folder"
}

# 注册退出时的清理操作
trap cleanup EXIT

# 遍历文件夹中的所有视频文件
for input_file in "$input_folder"/*.mp4; do
  if [ -f "$input_file" ]; then
    # 提取文件名（不包括扩展名）
    filename=$(basename "$input_file" .mp4)

    # 创建新的没有空格的文件名
    new_filename="${filename// /_}"
    	
    # 执行 ffmpeg 镜像  变速  旋转1% 截去斜边 抽帧
    ffmpeg -i "$input_file" -y -filter_complex "[0:v]hflip,setpts=PTS/0.97,rotate=1*PI/180,crop=in_w*0.92:in_h*0.94,select='mod(n,20)'[outv];[0:a]atempo=0.97[aout]" -map "[outv]" -map "[aout]" -c:v libx264 -c:a aac -strict experimental "$output_folder/${new_filename}_out.mp4"

    # 删除中间文件
    cleanup_temp_files
  fi
done

echo "处理完成！"