# packwiz, built from a pinned source commit, on a small Python runtime.
# python3 is needed by scripts/make-servers-dat.py. There are no package
# manager calls, so the only pins are the two base images and the commit.
FROM docker.io/library/golang:1.25-alpine@sha256:1ae0735f00daffa3aaf1363a5184c0d2dc55c78e3db4ec70241cdac97bf84b59 AS builder
ARG PACKWIZ_COMMIT=170b22d785959dda5876b54b7f16e1b807a57fb6
ENV CGO_ENABLED=0
RUN go install "github.com/packwiz/packwiz@${PACKWIZ_COMMIT}"

FROM docker.io/library/python:3.14-alpine@sha256:eb2c62658b8d51bff0acc408504b76521d02030de56a8a3c1e830083e89b89d2
COPY --from=builder /go/bin/packwiz /usr/local/bin/packwiz
# compose runs this image as the host user; keep HOME writable for any uid.
ENV HOME=/tmp
USER 1000:1000
WORKDIR /work
ENTRYPOINT ["packwiz"]
CMD ["--help"]
