#! /bin/bash
# Launches the v7.0.0 single-farm model instance on port 20002.
# Pair with runSingle6.5.2.sh on port 20001 to test the version switcher dropdown.
export AGRAMMON_PORT=20002
# Serve from frontend/compiled/source/ so edits picked up after `npx qx compile`.
export SOURCE_MODE=1
exec raku -Ilib bin/agrammon.raku --cfg-file=etc/agrammon.single7.yaml web version7.0.0/End.nhd
