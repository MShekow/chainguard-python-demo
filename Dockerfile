ARG VIRTUAL_ENV=/app/.venv
ARG BASE_IMAGE_DEV=ghcr.io/mshekow/python-chainguard:3.12-dev@sha256:127de78904914f7f930afa7d0f567b5ae7ac5036974e47d983b53a904a42418e
ARG BASE_IMAGE=ghcr.io/mshekow/python-chainguard:3.12@sha256:69949510246ebd9df53faf4cc2764086a6728de99a23a53c7698a5aa2f17a156

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
