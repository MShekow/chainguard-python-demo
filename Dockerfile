ARG VIRTUAL_ENV=/app/.venv
ARG BASE_IMAGE_DEV=ghcr.io/mshekow/python-chainguard:3.12-dev@sha256:3d280751a4b4792c537604b7d746157264069f8f0ae170a22dfb860ff2a2f066
ARG BASE_IMAGE=ghcr.io/mshekow/python-chainguard:3.12@sha256:b8cdaa7ccf5f4c02d13ff3d019a92907f75681590cb3cfd9be51bf3ac2116028

FROM alpine:latest AS image-verifier
RUN apk add -u cosign
ARG BASE_IMAGE
RUN cosign verify $BASE_IMAGE \
  --certificate-identity https://github.com/MShekow/chainguard-python-demo/.github/workflows/build-python-base-images.yml@refs/heads/main \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com
RUN touch /marker

FROM alpine:latest AS image-verifier-dev
RUN apk add -u cosign
ARG BASE_IMAGE_DEV
RUN cosign verify $BASE_IMAGE_DEV \
  --certificate-identity https://github.com/MShekow/chainguard-python-demo/.github/workflows/build-python-base-images.yml@refs/heads/main \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com
RUN touch /marker

FROM $BASE_IMAGE_DEV AS builder
COPY --from=image-verifier-dev /marker /ignore-me
ARG VIRTUAL_ENV
WORKDIR /app

RUN python -m venv .venv
COPY requirements.txt .
RUN .venv/bin/pip install --no-cache-dir -r requirements.txt

COPY app.py .
COPY gunicorn.conf.py .


FROM $BASE_IMAGE AS final
COPY --from=image-verifier /marker /ignore-me
ARG VIRTUAL_ENV
WORKDIR /app
ENV PATH="$VIRTUAL_ENV/bin:$PATH"
ENV PYTHONUNBUFFERED=1
EXPOSE 8000
COPY --from=builder /app /app
ENTRYPOINT ["gunicorn", "--config", "gunicorn.conf.py", "app:app"]
