#!/usr/bin/env raku
# unbuffered output
$*OUT.out-buffer = False;
$*ERR.out-buffer = False;
use lib $*PROGRAM.resolve.parent(2) ~ '/lib';
# ModelCache spurts ~/.agrammon/<hash>.rakumod and then loads it. The
# cache-dir MUST be in the repo chain BEFORE any agrammon module is
# loaded, otherwise (on Rakudo 2026.04+ with fresh precomp state) the
# subsequent require() lands a compunit whose dependency-merge clashes
# with the parent's already-loaded Agrammon::Formula::ControlFlow on
# the GLOBAL `X::Agrammon::Formula::Died` class. Putting `use lib`
# here — before `use Agrammon::UI::CommandLine` — means the repo
# chain is consistent from the parent's first agrammon module load
# all the way through the cached-module load. Established installs
# (Rakudo 2025.12, or 2026.04 with prior precomp) happen to dodge it;
# fresh container builds hit it every time.
# Honors AGRAMMON_CACHE_DIR (kept in sync with &agrammon-cache-dir in
# Agrammon::ModelCache) so test/prod instances on one host can isolate
# their caches; falls back to ~/.agrammon.
use lib %*ENV<AGRAMMON_CACHE_DIR> // (%*ENV<HOME> ~ '/.agrammon');
use Agrammon::UI::CommandLine;
