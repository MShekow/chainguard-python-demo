# chainguard-python-demo
Demonstrates how to build a minimal Flask-based Python application using a self-built Python image from Chainguard.

This repo creates a daily re-build of Python 3.12 base images (see [workflow](.github/workflows/build-python-base-images.yml)), and pushes them in case the contained packages were changed. It builds a _dev_ variant (that contains `pip`) and a minimal _run-time_ variant. The images are signed with Cosign.

The [Dockerfile](Dockerfile) demonstrates how to use a multi-stage build and to verify the base images with Cosign during the build.

To start the demo app, run `docker run --rm -p 8000:8000 ghcr.io/mshekow/python-chainguard-demo-app:latest` and access it on http://localhost:8000/.
