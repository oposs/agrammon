#! /bin/bash
# Launches the v6.5.2 single-farm model instance on port 20001.
# Pair with runSingle7.sh on port 20002 to test the version switcher dropdown.
export AGRAMMON_PORT=20001
# Serve from frontend/compiled/source/ so edits picked up after `npx qx compile`.
export SOURCE_MODE=1
exec raku -Ilib bin/agrammon.raku --cfg-file=etc/agrammon.single6.5.2.yaml web version6.5.2/End.nhd
