# 构建应用镜像
FROM python:3.11-slim

# 设置时区
ENV TZ=Asia/Shanghai

# 安装运行时依赖
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    libcap2-bin \
    tzdata \
    && ln -fs /usr/share/zoneinfo/$TZ /etc/localtime \
    && dpkg-reconfigure -f noninteractive tzdata \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 设置工作目录
WORKDIR /app

# 克隆仓库并应用补丁
RUN apt-get update && \
    apt-get install -y --no-install-recommends git && \
    git clone https://github.com/fish2018/ClashForge.git && \
    mv ClashForge/* . && \
    rm -rf ClashForge && \
    sed -i 's|https://slink.ltd/|https://ghproxy.dsdog.tk/|g' ClashForge.py && \
    sed -i 's|https://gitdl.cn/|https://ghproxy.dsdog.tk/|g' ClashForge.py && \
    sed -i 's|https://api.github.com/|https://ghapi.dsdog.tk/|g' ClashForge.py && \
    apt-get purge -y git && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*

# 复制应用文件
COPY upload_gist.py .
COPY start.sh .

# 安装Python依赖
RUN pip install --no-cache-dir -r requirements.txt && \
    rm -f requirements.txt && \
    mkdir input && \
    chmod +x start.sh

# 容器入口
CMD ["sh", "-c", "./start.sh"]