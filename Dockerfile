# 第一阶段：构建二进制文件
FROM --platform=$BUILDPLATFORM alpine:3.18 as builder

# 安装构建工具
RUN apk add --no-cache curl gzip tar

# 根据目标架构设置参数
ARG TARGETARCH
ARG MIOMO_VERSION="v1.18.0"

# 下载对应架构的二进制文件
RUN case "${TARGETARCH}" in \
    "amd64") \
      FILENAME="mihomo-linux-amd64-compatible" \
      DOWNLOAD_URL="https://ghproxy.dsdog.tk/https://github.com/MetaCubeX/mihomo/releases/download/${MIOMO_VERSION}/${FILENAME}.gz" ;; \
    "arm64") \
      FILENAME="mihomo-linux-arm64" \
      DOWNLOAD_URL="https://ghproxy.dsdog.tk/https://github.com/MetaCubeX/mihomo/releases/download/${MIOMO_VERSION}/${FILENAME}.gz" ;; \
    *) echo "Unsupported architecture: ${TARGETARCH}" && exit 1 ;; \
  esac && \
  curl -L -o "${FILENAME}.gz" "${DOWNLOAD_URL}" && \
  gzip -d "${FILENAME}.gz" && \
  mv "${FILENAME}" /clash && \
  chmod +x /clash

# 第二阶段：构建应用镜像
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

# 从构建阶段复制二进制文件
COPY --from=builder /clash /app/clash

# 设置网络权限
RUN setcap cap_net_bind_service=+ep /app/clash

# 克隆仓库并应用补丁
RUN apt-get update && \
    apt-get install -y --no-install-recommends git && \
    git clone https://ghproxy.dsdog.tk/https://github.com/fish2018/ClashForge.git && \
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