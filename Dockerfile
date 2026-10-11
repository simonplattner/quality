# syntax=docker/dockerfile:1
# Every tool `lint` runs, at pinned versions; Renovate keeps them current (renovate.json). Each binary is a
# `# renovate:` comment plus a VERSION (the exact release tag) and SHA256 ARG pair, the shape Renovate's regex expects.
FROM python:3.13-slim-trixie

RUN apt-get update \
    && apt-get install --yes --no-install-recommends git \
    && rm -rf /var/lib/apt/lists/* \
    && git config --system --add safe.directory '*'

COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir --requirement /tmp/requirements.txt

# renovate: datasource=github-release-attachments depName=rhysd/actionlint
ARG ACTIONLINT_VERSION=v1.7.12
ARG ACTIONLINT_SHA256=8aca8db96f1b94770f1b0d72b6dddcb1ebb8123cb3712530b08cc387b349a3d8
ADD --checksum=sha256:${ACTIONLINT_SHA256} \
    https://github.com/rhysd/actionlint/releases/download/${ACTIONLINT_VERSION}/actionlint_${ACTIONLINT_VERSION#v}_linux_amd64.tar.gz \
    /tmp/dl/actionlint.tar.gz

# renovate: datasource=github-release-attachments depName=editorconfig-checker/editorconfig-checker
ARG EC_VERSION=v4.0.2
ARG EC_SHA256=44efaef3ed14c6ab52eb87481d78e5e5c204796dccf26e2f4598a61ba17f8003
ADD --checksum=sha256:${EC_SHA256} \
    https://github.com/editorconfig-checker/editorconfig-checker/releases/download/${EC_VERSION}/editorconfig-checker-linux-amd64.tar.gz \
    /tmp/dl/ec.tar.gz

# renovate: datasource=github-release-attachments depName=crate-ci/typos
ARG TYPOS_VERSION=v1.51.1
ARG TYPOS_SHA256=93c301fd4120ff076e2cc2a6d6a61cab4a4bdb81899287c0938b452e56d1f454
ADD --checksum=sha256:${TYPOS_SHA256} \
    https://github.com/crate-ci/typos/releases/download/${TYPOS_VERSION}/typos-${TYPOS_VERSION}-x86_64-unknown-linux-musl.tar.gz \
    /tmp/dl/typos.tar.gz

# renovate: datasource=github-release-attachments depName=gitleaks/gitleaks
ARG GITLEAKS_VERSION=v8.30.1
ARG GITLEAKS_SHA256=551f6fc83ea457d62a0d98237cbad105af8d557003051f41f3e7ca7b3f2470eb
ADD --checksum=sha256:${GITLEAKS_SHA256} \
    https://github.com/gitleaks/gitleaks/releases/download/${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION#v}_linux_x64.tar.gz \
    /tmp/dl/gitleaks.tar.gz

# renovate: datasource=github-release-attachments depName=koalaman/shellcheck
ARG SHELLCHECK_VERSION=v0.11.0
ARG SHELLCHECK_SHA256=b7af85e41cc99489dcc21d66c6d5f3685138f06d34651e6d34b42ec6d54fe6f6
ADD --checksum=sha256:${SHELLCHECK_SHA256} \
    https://github.com/koalaman/shellcheck/releases/download/${SHELLCHECK_VERSION}/shellcheck-${SHELLCHECK_VERSION}.linux.x86_64.tar.gz \
    /tmp/dl/shellcheck.tar.gz

# renovate: datasource=github-release-attachments depName=mvdan/sh
ARG SHFMT_VERSION=v3.14.1
ARG SHFMT_SHA256=76e77641faa025814b77f153b29796b8e6fa2fca03e0c76a691608b86c7ea7bf
ADD --checksum=sha256:${SHFMT_SHA256} \
    https://github.com/mvdan/sh/releases/download/${SHFMT_VERSION}/shfmt_${SHFMT_VERSION}_linux_amd64 \
    /usr/local/bin/shfmt

# renovate: datasource=github-release-attachments depName=hadolint/hadolint
ARG HADOLINT_VERSION=v2.15.1
ARG HADOLINT_SHA256=c7187db94eeeeca956519a6af171adc31453941a1e777961f6e680f697c8c507
ADD --checksum=sha256:${HADOLINT_SHA256} \
    https://github.com/hadolint/hadolint/releases/download/${HADOLINT_VERSION}/hadolint-linux-x86_64 \
    /usr/local/bin/hadolint

# renovate: datasource=github-release-attachments depName=docker/compose
ARG COMPOSE_VERSION=v5.6.0
ARG COMPOSE_SHA256=40343e21ca777173e69cff5dbafeb37c6f81f3b0d57d9e597f036e95eb63e76a
ADD --checksum=sha256:${COMPOSE_SHA256} \
    https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-linux-x86_64 \
    /usr/local/bin/docker-compose

WORKDIR /tmp/dl
RUN tar -xzf actionlint.tar.gz -C /usr/local/bin actionlint \
    && tar -xzf ec.tar.gz -C /usr/local/bin editorconfig-checker \
    && tar -xzf typos.tar.gz -C /usr/local/bin ./typos \
    && tar -xzf gitleaks.tar.gz -C /usr/local/bin gitleaks \
    && tar -xzf shellcheck.tar.gz --strip-components=1 -C /usr/local/bin "shellcheck-${SHELLCHECK_VERSION}/shellcheck" \
    && chmod +x /usr/local/bin/shfmt /usr/local/bin/hadolint /usr/local/bin/docker-compose \
    && rm -rf /tmp/dl

COPY config/ /etc/quality/
COPY lint /usr/local/bin/lint

WORKDIR /work
CMD ["lint"]
