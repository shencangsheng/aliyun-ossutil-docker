FROM alpine:3.21

ARG OSSUTIL_VERSION=2.2.1
ARG TARGETARCH

# amd64 / arm64 checksums from Alibaba Cloud docs
# https://www.alibabacloud.com/help/en/oss/developer-reference/ossutil-overview/
RUN set -eux; \
    case "${TARGETARCH}" in \
      amd64) \
        OSSUTIL_ARCH=amd64; \
        OSSUTIL_SHA256=fbf1026bd383a5d9bee051cd64a6226c730357ba569491f7c7b91af66560ef1d; \
        ;; \
      arm64) \
        OSSUTIL_ARCH=arm64; \
        OSSUTIL_SHA256=b7680e79aec0adc9d42a12b795612680a58efec1fad24b0ceb9e13b2390c6652; \
        ;; \
      *) \
        echo "unsupported architecture: ${TARGETARCH}" >&2; \
        exit 1; \
        ;; \
    esac; \
    apk add --no-cache ca-certificates curl unzip; \
    curl -fsSL \
      "https://gosspublic.alicdn.com/ossutil/v2/${OSSUTIL_VERSION}/ossutil-${OSSUTIL_VERSION}-linux-${OSSUTIL_ARCH}.zip" \
      -o /tmp/ossutil.zip; \
    echo "${OSSUTIL_SHA256}  /tmp/ossutil.zip" | sha256sum -c -; \
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
