FROM alpine:3.21

ARG OSSUTIL_VERSION=2.2.1
ARG TARGETARCH

RUN set -eux; \
    case "${TARGETARCH}" in \
      amd64) OSSUTIL_ARCH=amd64 ;; \
      arm64) OSSUTIL_ARCH=arm64 ;; \
      *) \
        echo "unsupported architecture: ${TARGETARCH}" >&2; \
        exit 1; \
        ;; \
    esac; \
    apk add --no-cache ca-certificates curl unzip; \
    curl -fsSL \
      "https://gosspublic.alicdn.com/ossutil/v2/${OSSUTIL_VERSION}/ossutil-${OSSUTIL_VERSION}-linux-${OSSUTIL_ARCH}.zip" \
      -o /tmp/ossutil.zip; \
    unzip -q /tmp/ossutil.zip -d /tmp/ossutil; \
    install -m 0755 "/tmp/ossutil/ossutil-${OSSUTIL_VERSION}-linux-${OSSUTIL_ARCH}/ossutil" /usr/local/bin/ossutil; \
    rm -rf /tmp/ossutil /tmp/ossutil.zip; \
    ossutil version

RUN addgroup -S ossutil && adduser -S -G ossutil ossutil

WORKDIR /data
COPY aliyun-ossutil /usr/local/bin/aliyun-ossutil
RUN chmod +x /usr/local/bin/aliyun-ossutil

USER ossutil

ENTRYPOINT ["/usr/local/bin/aliyun-ossutil"]
