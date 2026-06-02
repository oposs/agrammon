#!/bin/sh
# install-patched-deps.sh — install merged-but-unreleased upstream Cro fixes,
# pinned to their merge commits, into the local Raku (zef) environment.
#
# Run this BEFORE `zef install --deps-only .` so the stock (unfixed) builds from
# the ecosystem are not pulled over these: zef then sees the dependency already
# satisfied and skips it. --force-install ensures a patched build replaces any
# same-version stock copy already present (the fixes did not bump the module
# version, so version alone cannot distinguish patched from stock).
#
# Pinned to the merge commits for reproducible builds. Remove an entry once a
# release containing its fix is published to the Raku ecosystem; then plain
# `zef install --deps-only .` (plus the META6.json version bound) suffices.
#
#   cro-http              #214  Cro::HTTP::Middleware::Conditional per-connection
#                               memory leak (early responses never complete).
#                               https://github.com/croservices/cro-http/pull/214
#   cro-openapi-routes... #15   Cro::HTTP::Router 0.8.12+ OperationHandler.name
#                               compatibility crash.
#                               https://github.com/croservices/cro-openapi-routes-from-definition/pull/15
set -eu

install_pinned() {
    repo=$1
    sha=$2
    tmp=$(mktemp -d)
    git clone --quiet "$repo" "$tmp/src"
    git -C "$tmp/src" checkout --quiet "$sha"
    zef install --/test --force-install "$tmp/src"
    rm -rf "$tmp"
}

install_pinned https://github.com/croservices/cro-http.git \
    a2949b64435a4bc98f112405a060bd933fe06c65
install_pinned https://github.com/croservices/cro-openapi-routes-from-definition.git \
    a38c4db6398174a0371f091bcfc57acb7fbc5d27
