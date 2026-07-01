#!/usr/bin/env bash
set -ex
echo "Building torchvision ${TORCHVISION_VERSION}"

BRANCH_VERSION=$(echo "$TORCHVISION_VERSION" | sed 's/^\([0-9]*\.[0-9]*\)\.0$/\1/')
git clone --branch=v${TORCHVISION_VERSION} --recursive --depth=1 https://github.com/pytorch/vision /opt/torchvision ||
git clone --branch=release/${BRANCH_VERSION} --recursive --depth=1 https://github.com/pytorch/vision /opt/torchvision ||
git clone --recursive --depth=1 https://github.com/pytorch/vision /opt/torchvision
cd /opt/torchvision

BUILD_VERSION=${TORCHVISION_VERSION} \
python3 setup.py --verbose bdist_wheel --dist-dir /opt

cd ../
rm -rf /opt/torchvision

uv pip install /opt/torchvision*.whl
uv pip show torchvision && python3 -c 'import torchvision; print(torchvision.__version__);'

# Install the cudastack TensorRT python wheel into the venv HERE. cudastack copies
# the wheels to dist-packages but can't pip-install them (no uv/venv that early), so
# `import tensorrt` otherwise fails in /opt/venv (and trips preflight). This final
# stage has uv + the venv; the wheels are already on disk (no network/index).
TRT_SITE="/usr/local/lib/python$(python3 -c 'import sys;print(f"{sys.version_info.major}.{sys.version_info.minor}")')/dist-packages"
if ls "${TRT_SITE}"/tensorrt-*.whl >/dev/null 2>&1; then
  uv pip install --no-index --find-links "${TRT_SITE}" tensorrt \
    && python3 -c 'import tensorrt; print("tensorrt", tensorrt.__version__)' \
    || echo "WARNING: tensorrt venv install failed (wheels present but not installed)"
fi

# Only upload when real credentials were provided (default PIP_UPLOAD_PASS='none',
# and the jetson-ai-lab upload host is offline here) -- skip to avoid DNS-retry waits.
if [ "${TWINE_PASSWORD:-none}" != "none" ]; then
  twine upload --verbose /opt/torchvision*.whl || echo "failed to upload wheel to ${TWINE_REPOSITORY_URL}"
else
  echo "skipping torchvision wheel upload (no TWINE_PASSWORD / PIP_UPLOAD_PASS set)"
fi
