#!/bin/bash

# 启动第一个脚本（假设是修改后的Python脚本）
# 请确保Python解释器路径正确
python "$PY_FILE" &

# 等待3秒
sleep 3

# 启动第二个脚本
# 请将下面路径替换为你的第二个脚本实际路径
OTHER_SCRIPT="upload_gist.py"
python "$OTHER_SCRIPT"