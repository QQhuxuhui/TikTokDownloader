#!/bin/bash

# 检查输入参数
if [ $# -ne 2 ]; then
  echo "用法: $0 <视频文件夹路径> <输出文件夹路径>"
  exit 1
fi

# 设置输入文件夹路径和输出文件夹路径
input_folder="$1"
output_folder="$2"

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

    # 复制源文件到一个没有空格的新文件名
    cp "$input_file" "$temp_folder/${new_filename}.mp4"

    # 执行 ffmpeg 操作 - 步骤 1 镜像
    ffmpeg -i "$temp_folder/${new_filename}.mp4" -y -vf hflip -c:a copy "$temp_folder/${new_filename}_temp.mp4"

    # 执行 ffmpeg 操作 - 步骤 2 变速
    ffmpeg -i "$temp_folder/${new_filename}_temp.mp4" -y -vf setpts=PTS/0.97 -af atempo=0.97 "$temp_folder/${new_filename}_temp2.mp4"

    # 执行 ffmpeg 操作 - 步骤 3 色彩饱和度
    ffmpeg -i "$temp_folder/${new_filename}_temp2.mp4" -y -vf eq=contrast=1.04:brightness=0.01:saturation=1.5 -r 25 -vcodec libx264 -crf 26 "$temp_folder/${new_filename}_temp3.mp4"

	# 执行 ffmpeg 操作 - 步骤 4 旋转1% 截去斜边
    ffmpeg -i "$temp_folder/${new_filename}_temp3.mp4" -y -vf "rotate=1*PI/180,crop=in_w*0.92:in_h*0.94" "$temp_folder/${new_filename}_temp4.mp4"

	# 执行 ffmpeg 操作 - 步骤 5 抽帧
	ffmpeg -i "$temp_folder/${new_filename}_temp4.mp4" -y -vf "select='mod(n,20)'" -vsync vfr "$temp_folder/${new_filename}_temp5.mp4"
	
	# 执行 ffmpeg 操作 - 步骤 6 开幕闭幕
#	ffmpeg -i "$temp_folder/${new_filename}_temp5.mp4" -y -vf "zoompan=z='min(max(zoom,pzoom)+0.0001,1.5)':d=1, fade=in:0:2, setsar=1, boxblur=10:5:enable='between(t,0,2)'" -c:a copy -c:v libx264 -crf 18 -preset veryfast "$temp_folder/${new_filename}_temp6.mp4"
	
    # 执行 ffmpeg 操作 - 步骤 7 视频广角
    ffmpeg -i "$temp_folder/${new_filename}_temp4.mp4" -y -vf "lenscorrection=cx=0.5:cy=0.5:k1=-0.2:k2=-0.1" "$output_folder/${new_filename}_out.mp4"
	
    # 删除中间文件
    cleanup_temp_files
  fi
done

echo "处理完成！"