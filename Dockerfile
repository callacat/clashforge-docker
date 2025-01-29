# 使用最精简的 Python 镜像
FROM python:3.11-slim

# 设置工作目录
WORKDIR /app

# 安装依赖
RUN apt-get update && apt-get install -y --no-install-recommends tzdata git \
    && ln -fs /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && dpkg-reconfigure -f noninteractive tzdata \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/fish2018/ClashForge.git \
    && mv ClashForge/* . \
    && rm -rf ClashForge

# 复制执行文件到容器中
COPY upload_gist.py .
COPY start.sh .

# 安装依赖
RUN chmod +x start.sh \
    && pip install --no-cache-dir -r requirements.txt \
    && rm -f requirements.txt \
    && mkdir input

# 启动脚本
CMD ["sh", "-c", "start.sh"]
