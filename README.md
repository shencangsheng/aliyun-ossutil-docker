# aliyun-ossutil-docker

[![GitHub](https://img.shields.io/badge/GitHub-shencangsheng%2Faliyun--ossutil--docker-blue?logo=github)](https://github.com/shencangsheng/aliyun-ossutil-docker)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

基于 [ossutil 2.0](https://www.alibabacloud.com/help/en/oss/developer-reference/ossutil-overview/) 的 OSS 上传容器，适合 CI/CD 或一次性上传任务。

镜像：`shencangsheng/aliyun-ossutil`（Docker Hub 官方发布）

## 本地构建

开发者自行构建时使用本地 tag，无需与发布镜像同名：

```bash
docker build -t aliyun-ossutil:local .
```

运行时将下文示例中的 `shencangsheng/aliyun-ossutil` 替换为 `aliyun-ossutil:local` 即可。

支持 `linux/amd64` 与 `linux/arm64`（依赖 buildx 的 `TARGETARCH`）。

打 tag 时，GitHub Actions（[`.github/workflows/build.yml`](.github/workflows/build.yml)）会自动构建并推送镜像。

## 默认行为：上传文件/目录

```bash
docker run --rm \
  -e OSS_ACCESS_KEY_ID=your-key-id \
  -e OSS_ACCESS_KEY_SECRET=your-key-secret \
  -e OSS_BUCKET=my-bucket \
  -e OSS_REGION=cn-hangzhou \
  -e SOURCE=/data/release.tar.gz \
  -e DEST=artifacts/release.tar.gz \
  -v "$(pwd)/release.tar.gz:/data/release.tar.gz:ro" \
  shencangsheng/aliyun-ossutil
```

上传多个文件到同一 OSS 目录：

```bash
docker run --rm \
  -e OSS_ACCESS_KEY_ID=your-key-id \
  -e OSS_ACCESS_KEY_SECRET=your-key-secret \
  -e OSS_BUCKET=my-bucket \
  -e OSS_REGION=cn-hangzhou \
  -e SOURCES="/data/app.tar.gz,/data/manifest.json" \
  -e DEST=artifacts/v1.0.0 \
  -v "$(pwd)/app.tar.gz:/data/app.tar.gz:ro" \
  -v "$(pwd)/manifest.json:/data/manifest.json:ro" \
  shencangsheng/aliyun-ossutil
```

结果：

```
oss://my-bucket/artifacts/v1.0.0/app.tar.gz
oss://my-bucket/artifacts/v1.0.0/manifest.json
```

`SOURCES` 与 `SOURCE` 二选一；设置 `SOURCES` 时必须指定 `DEST` 目录前缀。路径用逗号分隔，可含空格，例如 `/data/my file.tar.gz,/data/manifest.json`。

### 环境变量

| 变量                    | 必填     | 说明                                                     |
| ----------------------- | -------- | -------------------------------------------------------- |
| `OSS_BUCKET`            | 是       | 目标 Bucket                                              |
| `OSS_ACCESS_KEY_ID`     | 通常必填 | AccessKey ID                                             |
| `OSS_ACCESS_KEY_SECRET` | 通常必填 | AccessKey Secret                                         |
| `OSS_REGION`            | 推荐     | 区域，如 `cn-hangzhou`                                   |
| `OSS_ENDPOINT`          | 否       | 兼容旧配置；未设置 `OSS_REGION` 时会尝试从 endpoint 推导 |
| `OSS_SESSION_TOKEN`     | 否       | STS 临时凭证                                             |
| `OSS_MODE`              | 否       | 认证模式：`AK` / `StsToken` / `EcsRamRole` 等            |
| `OSS_ECS_ROLE_NAME`     | 否       | ECS 实例 RAM 角色名（`EcsRamRole` 模式）                 |
| `SOURCE`                | 否       | 本地路径，默认 `/data`（单文件/目录）                    |
| `SOURCES`               | 否       | 多个本地路径，逗号 `,` 分隔；需配合 `DEST` 作为 OSS 目录前缀 |
| `DEST`                  | 否       | OSS 对象前缀/路径；`SOURCES` 模式下为目录前缀            |
| `RECURSIVE`             | 否       | `auto`（默认，目录自动递归）/ `true` / `false`           |
| `FORCE`                 | 否       | 覆盖已有对象，默认 `true`                                |
| `DRY_RUN`               | 否       | 设为 `true` 时只预演不上传                               |
| `META`                  | 否       | 对象元数据，如 `Cache-Control:public,max-age=600`        |
| `OSSUTIL_EXTRA_ARGS`    | 否       | 追加传给 `ossutil cp` 的参数                             |

在 ECS 上使用实例 RAM 角色：

```bash
docker run --rm \
  --network host \
  -e OSS_MODE=EcsRamRole \
  -e OSS_ECS_ROLE_NAME=your-role-name \
  -e OSS_BUCKET=my-bucket \
  -e OSS_REGION=cn-hangzhou \
  -e SOURCE=/data \
  -v "$(pwd)/dist:/data:ro" \
  shencangsheng/aliyun-ossutil
```

## 自定义 ossutil 命令

传入参数时会透传给 `ossutil`（凭证仍从环境变量读取）：

```bash
docker run --rm \
  -e OSS_ACCESS_KEY_ID=your-key-id \
  -e OSS_ACCESS_KEY_SECRET=your-key-secret \
  -e OSS_REGION=cn-hangzhou \
  shencangsheng/aliyun-ossutil ls oss://my-bucket/
```

## CI/CD 用法

### 凭证配置

在 **Settings → Secrets and variables → Actions** 中配置：

| 名称                    | 类型     | 说明                   |
| ----------------------- | -------- | ---------------------- |
| `OSS_ACCESS_KEY_ID`     | Secret   | AccessKey ID           |
| `OSS_ACCESS_KEY_SECRET` | Secret   | AccessKey Secret       |
| `OSS_BUCKET`            | Variable | 目标 Bucket            |
| `OSS_REGION`            | Variable | 区域，如 `cn-hangzhou` |

### GitHub Actions

**作为 Container Job（推荐）**

```yaml
name: Upload to OSS

on:
  push:
    tags: ["*"]

jobs:
  upload:
    runs-on: ubuntu-latest
    container:
      image: shencangsheng/aliyun-ossutil:latest
      options: --entrypoint ""
    env:
      OSS_ACCESS_KEY_ID: ${{ secrets.OSS_ACCESS_KEY_ID }}
      OSS_ACCESS_KEY_SECRET: ${{ secrets.OSS_ACCESS_KEY_SECRET }}
      OSS_BUCKET: ${{ vars.OSS_BUCKET }}
      OSS_REGION: ${{ vars.OSS_REGION }}
      FORCE: "true"
      RECURSIVE: "false"
    steps:
      - uses: actions/checkout@v4

      - name: Build artifact
        run: tar -czf release.tar.gz dist/

      - name: Upload to OSS
        env:
          SOURCE: ${{ github.workspace }}/release.tar.gz
          DEST: releases/${{ github.event.repository.name }}/${{ github.ref_name }}/release.tar.gz
        run: |
          test -f "${SOURCE}"
          aliyun-ossutil
```

上传多个文件：

```yaml
- name: Upload artifacts
  env:
    SOURCES: ${{ github.workspace }}/app.tar.gz,${{ github.workspace }}/manifest.json
    DEST: artifacts/${{ github.ref_name }}
  run: aliyun-ossutil
```

**docker run 步骤**

```yaml
- name: Upload to OSS
  env:
    OSS_ACCESS_KEY_ID: ${{ secrets.OSS_ACCESS_KEY_ID }}
    OSS_ACCESS_KEY_SECRET: ${{ secrets.OSS_ACCESS_KEY_SECRET }}
    OSS_BUCKET: ${{ vars.OSS_BUCKET }}
    OSS_REGION: ${{ vars.OSS_REGION }}
  run: |
    docker run --rm \
      -e OSS_ACCESS_KEY_ID \
      -e OSS_ACCESS_KEY_SECRET \
      -e OSS_BUCKET \
      -e OSS_REGION \
      -e SOURCE=/data/release.tar.gz \
      -e DEST=artifacts/${{ github.ref_name }}/release.tar.gz \
      -v "${{ github.workspace }}/release.tar.gz:/data/release.tar.gz:ro" \
      shencangsheng/aliyun-ossutil:latest
```

**ECS 实例 RAM 角色**

Runner 跑在阿里云 ECS 且绑定了 RAM 角色时，无需配置 AccessKey：

```yaml
env:
  OSS_MODE: EcsRamRole
  OSS_ECS_ROLE_NAME: your-ecs-role-name
```

需确保 Runner 能访问 ECS 元数据服务（`--network host` 或同等网络配置）。

### GitLab CI

GitLab 项目同样可用本镜像，在 **Settings → CI/CD → Variables** 中配置凭证：

**作为 Job 镜像（推荐）**

```yaml
.upload-to-oss:
  image:
    name: shencangsheng/aliyun-ossutil:latest
    entrypoint: [""]
  variables:
    FORCE: "true"
    RECURSIVE: "false"
  script:
    - test -f "${SOURCE}"
    - aliyun-ossutil

upload-release:
  extends: .upload-to-oss
  stage: deploy
  needs: [build]
  variables:
    SOURCE: ${CI_PROJECT_DIR}/dist/app.tar.gz
    DEST: releases/${CI_PROJECT_NAME}/${CI_COMMIT_TAG}/app.tar.gz
  rules:
    - if: $CI_COMMIT_TAG
```

上传多个文件到同一 OSS 目录：

```yaml
upload-artifacts:
  extends: .upload-to-oss
  variables:
    SOURCES: ${CI_PROJECT_DIR}/app.tar.gz,${CI_PROJECT_DIR}/manifest.json
    DEST: releases/${CI_PROJECT_NAME}/${CI_COMMIT_TAG}
```

**Shell Runner + docker run**

```yaml
upload-artifact:
  stage: deploy
  tags: [docker]
  script:
    - |
      docker run --rm \
        -e OSS_ACCESS_KEY_ID \
        -e OSS_ACCESS_KEY_SECRET \
        -e OSS_BUCKET \
        -e OSS_REGION \
        -e SOURCE=/data/release.tar.gz \
        -e DEST=artifacts/${CI_COMMIT_TAG}/release.tar.gz \
        -v "${CI_PROJECT_DIR}/release.tar.gz:/data/release.tar.gz:ro" \
        shencangsheng/aliyun-ossutil:latest
```

## License

[MIT](LICENSE)
