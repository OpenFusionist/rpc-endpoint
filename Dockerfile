# docker buildx create --use --name multiarch-builder
# docker buildx build --platform linux/amd64,linux/arm64 --push -t ohko4711/rpc-endpoint  .
FROM --platform=$BUILDPLATFORM golang:1.22-alpine as builder
WORKDIR /build
ADD . /build
RUN apk add --no-cache gcc musl-dev linux-headers git make
ARG TARGETPLATFORM
ARG BUILDPLATFORM
RUN --mount=type=cache,target=/root/.cache/go-build \
    GOOS=$(echo $TARGETPLATFORM | cut -d'/' -f1) \
    GOARCH=$(echo $TARGETPLATFORM | cut -d'/' -f2) \
    make build-for-docker

FROM --platform=$TARGETPLATFORM alpine:latest
WORKDIR /app
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /build/rpc-endpoint /app/rpc-endpoint
ENV LISTEN_ADDR=":8080"
EXPOSE 8080
CMD ["/app/rpc-endpoint"]
