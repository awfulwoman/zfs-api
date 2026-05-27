FROM ubuntu:24.04

LABEL maintainer="ZFS API"
LABEL description="REST API for ZFS pool, dataset, and snapshot monitoring"

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3.12 \
        python3-pip \
        zfsutils-linux \
        ca-certificates && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
RUN pip install --break-system-packages --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
