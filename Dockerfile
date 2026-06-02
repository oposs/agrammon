# syntax=docker/dockerfile:1.6
#
# Multi-stage build for Agrammon.
#
# Stage 1 (builder): debian:bookworm-slim + all *-dev headers, build-essential,
# cpanminus, git. Installs Rakudo 2026.04 (rakudo.org prebuild), zef, all Raku
# deps, Excel::Writer::XLSX via cpanm into a private --local-lib at /opt/perl5,
# patches Cro::OpenAPI::RoutesFromDefinition with upstream PR #15 (not yet
# merged), and runs a compile-check against lib/Agrammon/Model.rakumod.
#
# Stage 2 (runtime): debian:bookworm-slim + runtime libs only (libperl, libxml2,
# libarchive13, libuuid1, libssl3, libpq5, Perl XML/IO/Archive deps,
# ghostscript, fonts-liberation, ca-certificates). Copies /opt/rakudo, the
# zef-installed site repo state under /root/.raku, /opt/perl5, /usr/local/bin/typst,
# and the /app tree from the builder.
#
# Build-arg pins are fixed but overridable for one-off bumps:
#   --build-arg RAKUDO_VERSION=2026.04-01
#   --build-arg TYPST_VERSION=0.14.2

# ─────────────────────────── Stage 0: fe-builder ────────────────────────
# Compiles the Qooxdoo frontend (target=build) into /work/frontend/compiled/build,
# which the runtime stage copies to /app/public. Independent of the Raku
# builder below; the two run in parallel.
FROM node:20-bookworm-slim AS fe-builder

ENV DEBIAN_FRONTEND=noninteractive

# Activate the pnpm version that frontend/package.json pins.
RUN corepack enable && corepack prepare pnpm@10.4.1 --activate

WORKDIR /work/frontend

# Manifest + lockfile first → dependency layer caches across source edits.
COPY frontend/package.json frontend/pnpm-lock.yaml /work/frontend/
RUN pnpm install --frozen-lockfile

# Now the rest of the frontend tree (sources, compile.json, qx_packages
# manifest, translations, resources).
COPY frontend/ /work/frontend/

# qx compile does a plain `mkdir` (not -p) for the output, so the parent
# directory must exist; the .dockerignore strips compiled/{source,build}
# but doesn't recreate compiled/ itself if the local checkout had it
# populated.  Just create it.
RUN mkdir -p /work/frontend/compiled

# Production build into compiled/build/. --feedback=false silences the
# progress UI; --update-po-files keeps translation timestamps in sync so
# the layer is reproducible.
RUN pnpm exec qx compile --target=build --feedback=false --update-po-files

# Reality check — index.html must end up at the root of compiled/build
# for the Cro route `static "$root/index.html"` (lib/Agrammon/Web/Routes.rakumod
# build-mode branch) to find it.
RUN test -f /work/frontend/compiled/build/index.html


# ─────────────────────────── Stage 1: builder ───────────────────────────
FROM debian:bookworm-slim AS builder

ENV DEBIAN_FRONTEND=noninteractive

#   - libperl-dev, cpanminus, build-essential, pkg-config →
#       Inline::Perl5 + Excel::Writer::XLSX + native Raku module compile
#   - libxml2-dev libarchive-dev uuid-dev libssl-dev libpq-dev →
#       C headers for Raku native modules (LibXML, Libarchive, LibUUID,
#       OpenSSL, DB::Pg)
#   - ca-certificates, curl, xz-utils, git → fetch Rakudo + typst tarballs
#                                            + clone zef + patch Cro::OpenAPI
RUN apt-get update && apt-get install -y --no-install-recommends \
        perl libperl-dev cpanminus \
        libxml2-dev libarchive-dev uuid-dev libssl-dev libpq-dev \
        build-essential pkg-config \
        ca-certificates curl xz-utils git \
    && rm -rf /var/lib/apt/lists/*

# Rakudo from rakudo.org prebuilt tarball — bone-stock (no zef, no deps).
# Matches the host's working build (2026.04). The rakudo-star image (2026.03)
# crashes formula EVAL with "duplicate definition of symbol Died" so we pin.
ARG RAKUDO_VERSION=2026.04-01
RUN curl -fsSL "https://rakudo.org/dl/rakudo/rakudo-moar-${RAKUDO_VERSION}-linux-x86_64-gcc.tar.gz" \
        -o /tmp/rakudo.tar.gz \
    && mkdir -p /opt/rakudo \
    && tar -xzf /tmp/rakudo.tar.gz -C /opt/rakudo --strip-components=1 \
    && rm /tmp/rakudo.tar.gz
ENV PATH=/opt/rakudo/bin:/opt/rakudo/share/perl6/site/bin:/opt/rakudo/share/perl6/vendor/bin:/opt/rakudo/share/perl6/core/bin:$PATH

# zef from upstream — not bundled with bare Rakudo.
RUN git clone --depth 1 https://github.com/ugexe/zef /tmp/zef \
    && cd /tmp/zef \
    && raku -I. bin/zef install --/test . \
    && cd / && rm -rf /tmp/zef \
    && zef --version

# typst — single ~30 MB static binary. Built in builder so the smoke step
# can validate it, then COPY'd into the runtime stage.
ARG TYPST_VERSION=0.14.2
RUN curl -fsSL "https://github.com/typst/typst/releases/download/v${TYPST_VERSION}/typst-x86_64-unknown-linux-musl.tar.xz" \
        -o /tmp/typst.tar.xz \
    && tar -xJf /tmp/typst.tar.xz -C /tmp \
    && install -m 0755 /tmp/typst-x86_64-unknown-linux-musl/typst /usr/local/bin/typst \
    && rm -rf /tmp/typst.tar.xz /tmp/typst-x86_64-unknown-linux-musl \
    && typst --version

# Excel::Writer::XLSX — not a Debian package. Installed into a private
# --local-lib so the runtime stage can COPY a single /opt/perl5 tree
# instead of merging with the system Perl module path.
RUN cpanm --local-lib /opt/perl5 --notest --quiet Excel::Writer::XLSX \
    && rm -rf /root/.cpanm

WORKDIR /app

# Build context optimisation: META6.json first → unchanged when only source
# files change → zef cache hit on rebuild.
COPY META6.json /app/

# Inline/perl5 must be in place before zef install (Inline::Perl5 looks at
# PERL5LIB at compile time).
COPY Inline/ /app/Inline/
ENV PERL5LIB=/opt/perl5/lib/perl5:/app/Inline/perl5

# Pin Text::CSV 0.015 — Spreadsheet::XLSX hard-pins it. Without the explicit
# pre-install, zef also pulls 0.022 to satisfy the unpinned project dep;
# having both installed is cosmetic only (single-version tree is cleaner).
RUN zef install --/test 'Text::CSV:ver<0.015>:auth<zef:Tux>'

# All other Raku deps from META6.json.
RUN zef install --/test --deps-only . \
    && rm -rf ~/.zef

# Cro::OpenAPI::RoutesFromDefinition compatibility patch (upstream PR #15,
# unmerged as of 2026-05). Without it, agrammon's `route { include … }`
# block crashes at compile time with:
#   No such method 'name' for invocant of type
#   'Cro::OpenAPI::RoutesFromDefinition::OperationSet::OperationHandler'
# This is a Cro::HTTP::Router 0.8.12+ regression that affects every
# OpenAPI-based Cro app. Drop this RUN when the PR merges.
# https://github.com/croservices/cro-openapi-routes-from-definition/pull/15
RUN git clone --depth 1 https://github.com/croservices/cro-openapi-routes-from-definition /tmp/cro-openapi \
    && cd /tmp/cro-openapi \
    && curl -fsSL https://github.com/croservices/cro-openapi-routes-from-definition/pull/15.patch \
        -o /tmp/pr15.patch \
    && git apply --whitespace=nowarn /tmp/pr15.patch \
    && zef install --/test --force-install . \
    && cd / && rm -rf /tmp/cro-openapi /tmp/pr15.patch ~/.zef

# App code — last so frequent edits don't bust the dep-install cache.
COPY lib/    /app/lib/
COPY bin/    /app/bin/
COPY share/  /app/share/
RUN mkdir -p /app/public

# Build-time smoke — catches Raku compile errors inside lib/ before runtime.
RUN raku -Ilib -e 'use Agrammon::Model; say "compile OK"'

# ────────────────────────── Stage 2: runtime ────────────────────────────
FROM debian:bookworm-slim AS runtime

ENV DEBIAN_FRONTEND=noninteractive

# Runtime-only set — no compilers, no headers, no cpanm/git/curl/build tools.
#   - perl + libperl5.36 → host Perl + libperl.so for Inline::Perl5
#   - libxml-libxml-perl libio-stringy-perl libarchive-zip-perl →
#       Excel::Writer::XLSX Perl-side runtime deps
#   - libxml2 libarchive13 libuuid1 libssl3 libpq5 →
#       shared libs the Raku native modules linked against in stage 1
#   - ghostscript → optional typst PDF re-compression (General.ghostscript:)
#   - fonts-liberation → "Liberation Sans" used by pdfexport.crotmp
#   - ca-certificates → outbound TLS (e.g. to API consumers, future SMTP)
RUN apt-get update && apt-get install -y --no-install-recommends \
        perl libperl5.36 \
        libxml-libxml-perl libio-stringy-perl libarchive-zip-perl \
        libxml2 libarchive13 libuuid1 libssl3 libpq5 \
        ghostscript fonts-liberation \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && ln -sf libssl.so.3    /usr/lib/x86_64-linux-gnu/libssl.so \
    && ln -sf libcrypto.so.3 /usr/lib/x86_64-linux-gnu/libcrypto.so
# ^ Raku's IO::Socket::Async::SSL dlopens 'libssl.so' (unversioned). The
#   libssl-dev package would supply both symlinks but pulls in compiler
#   headers; libssl3 (runtime) does not. Cheaper to symlink directly.

# Rakudo + zef-installed site repo (deps live under share/perl6/site/).
COPY --from=builder /opt/rakudo /opt/rakudo
ENV PATH=/opt/rakudo/bin:/opt/rakudo/share/perl6/site/bin:/opt/rakudo/share/perl6/vendor/bin:/opt/rakudo/share/perl6/core/bin:$PATH

# zef may have left state under the home repo as well (precomp cache for
# anything site-scope couldn't precompile at install time).
COPY --from=builder /root/.raku /root/.raku

# cpanm --local-lib output (Excel::Writer::XLSX + its Perl deps).
COPY --from=builder /opt/perl5 /opt/perl5

# typst binary.
COPY --from=builder /usr/local/bin/typst /usr/local/bin/typst

# App tree (Raku source, share/, empty public/).
COPY --from=builder /app /app

# Qooxdoo build output. Routes.rakumod's build-mode branch serves
# /index.html, /agrammon/*, /resource/* directly out of /app/public.
COPY --from=fe-builder /work/frontend/compiled/build /app/public

WORKDIR /app

ENV PERL5LIB=/opt/perl5/lib/perl5:/app/Inline/perl5
ENV AGRAMMON_PORT=8080

EXPOSE 8080
ENTRYPOINT ["raku", "-Ilib", "/app/bin/agrammon.raku"]
CMD ["--help"]
