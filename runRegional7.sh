#! /bin/bash
# Regional v7.0.0 instance on port 20003 (single7 uses 20002).
export AGRAMMON_PORT=20003
# Serve the qooxdoo source target (frontend/compiled/source/) so frontend
# edits are picked up after `npx qx compile`, instead of the public/ build.
export SOURCE_MODE=1
exec raku -Ilib bin/agrammon.raku --cfg-file=etc/agrammon.regional7.yaml web version7.0.0/End.nhd
