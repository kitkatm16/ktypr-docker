FROM python:3.10-slim-bookworm

ARG KTYPR_REF=master
ENV PYTHONNOUSERSITE=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    LC_ALL=C.UTF-8

RUN apt-get update \
    && apt-get install -y --no-install-recommends bash procps ca-certificates git build-essential bash procps \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /opt/ktypr-source /opt/ktypr-build /work \
    && git -C /opt/ktypr-source init \
    && git -C /opt/ktypr-source remote add origin https://github.com/SushiLab/kTYPr.git \
    && git -C /opt/ktypr-source fetch --depth 1 origin "$KTYPR_REF" \
    && git -C /opt/ktypr-source checkout --detach FETCH_HEAD \
    && git -C /opt/ktypr-source rev-parse HEAD > /opt/ktypr-build/source-commit.txt \
    && python -m pip install --no-cache-dir /opt/ktypr-source \
    && python -m pip check \
    && python -m pip freeze > /opt/ktypr-build/installed-packages.txt \
    && cp /opt/ktypr-source/LICENSE /opt/ktypr-build/LICENSE \
    && rm -rf /opt/ktypr-source/.git \
    && chmod -R a+rX /opt/ktypr-source /opt/ktypr-build

COPY smoke-test.py /opt/ktypr-build/smoke-test.py
RUN ktypr --help && /bin/bash --version && ps -p 1

LABEL org.opencontainers.image.title="kTYPr" \
      org.opencontainers.image.description="kTYPr with reference data, Bash and procps"

WORKDIR /work
# No application ENTRYPOINT: Nextflow must be able to run its Bash task script.
CMD ["ktypr", "--help"]
