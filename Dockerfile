ARG GOLANG_VERSION="1.22"

FROM golang:${GOLANG_VERSION}-alpine AS golang-build
ARG BRANCH="master"
ARG REPOSITORY
ARG OUTPUT_NAME

RUN apk add --update --no-cache build-base upx git
WORKDIR /app
RUN \
  echo "BRANCH: ${BRANCH}"; echo "REPO:   ${REPOSITORY?Repository name is required.}"; \
  mkdir src build && \
  git config --global advice.detachedHead false && \
  git clone -b ${BRANCH} "${REPOSITORY}" src && \
  cd src && \
  go mod tidy -v && \
  go mod verify

RUN \
  cd src && \
  env GOOS=linux CGO_ENABLED=0 go build \
    -ldflags "-s -w -extldflags '-static c'" \
    -o /app/build/${OUTPUT_NAME} && \
  upx -9 -q /app/build/${OUTPUT_NAME} >/dev/null 2>/dev/null && \
  apk del -q build-base git

FROM scratch AS final
ARG OUTPUT_NAME
WORKDIR /app
ENV HOME=/app
COPY --from=golang-build /app/build/${OUTPUT_NAME} /usr/bin/${OUTPUT_NAME}

# Use ENTRYPOINT in here.
