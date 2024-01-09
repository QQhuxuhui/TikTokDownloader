@echo off
setlocal enabledelayedexpansion

REM 设置输入文件夹路径和输出文件夹路径
set "input_folder=%~1"
set "output_folder=%~2"


REM 检查输出文件夹是否存在，如果不存在则创建
if not exist "%output_folder%" (
  echo 检测到输出文件夹：%output_folder% 不存在，现在创建一个
  mkdir "%output_folder%"
  echo 已创建输出文件夹: %output_folder%
)


REM 创建临时文件夹
set "temp_folder=%TEMP%\%random%"
md "%temp_folder%"


REM 遍历文件夹中的所有视频文件
for %%I in ("%input_folder%\*.mp4") do (
  if exist "%%I" (
    REM 提取文件名（不包括扩展名）
    set "filename=%%~nI"

    REM 创建新的没有空格的文件名
    set "new_filename=!filename: =_!"

    REM 复制源文件到一个没有空格的新文件名
    copy "%%I" "%temp_folder%\!new_filename!.mp4"

    REM 执行 ffmpeg 操作 - 步骤 1 镜像
    ffmpeg -i "%temp_folder%\!new_filename!.mp4" -y -vf hflip -c:a copy "%temp_folder%\!new_filename!_temp.mp4"

    REM 执行 ffmpeg 操作 - 步骤 2 变速
    ffmpeg -i "%temp_folder%\!new_filename!_temp.mp4" -y -vf setpts=PTS/0.97 -af atempo=0.97 "%temp_folder%\!new_filename!_temp1.mp4"

    REM 执行 ffmpeg 操作 - 步骤 3 旋转1% 截去斜边
    ffmpeg -i "%temp_folder%\!new_filename!_temp1.mp4" -y -vf "rotate=1*PI/180,crop=in_w*0.92:in_h*0.94" "%temp_folder%\!new_filename!_temp2.mp4"

    REM 执行 ffmpeg 操作 - 步骤 4 抽帧
    ffmpeg -i "%temp_folder%\!new_filename!_temp2.mp4" -y -vf "select='mod(n,20)'" -fps_mode vfr "%output_folder%\!new_filename!_out.mp4"

    REM 删除中间文件
    call :cleanup_temp_files
  )
)

echo 处理完成！

REM 函数：删除中间文件
:cleanup_temp_files
del /q "%temp_folder%\*.mp4" >nul 2>nul
goto :eof

REM 函数：删除临时文件夹
:cleanup
rmdir /s /q "%temp_folder%"
goto :eof


call :cleanup
