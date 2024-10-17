#!/usr/bin/env bash
set -euo pipefail


export PIP_NO_CLEAN=1


pip3 wheel . \
  -Cbuilddir=eugo_build_whl \
  --no-cache-dir \
  --no-build-isolation \
  --no-deps