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

    REM 执行 ffmpeg 镜像  变速  旋转1% 截去斜边 抽帧
    ffmpeg -i "%%I" -y -filter_complex "[0:v]hflip,setpts=PTS/0.97,rotate=1*PI/180,crop=in_w*0.92:in_h*0.94,select='mod(n,20)'[outv];[0:a]atempo=0.97[aout]" -map "[outv]" -map "[aout]" -c:v libx264 -c:a aac -strict experimental "%output_folder%\!new_filename!_out.mp4"

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
