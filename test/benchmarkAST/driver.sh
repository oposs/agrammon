set -u
export MAKEFLAGS=-j6   # shared server: cap build parallelism
REPO=/home/zaucker/checkouts/agrammon/agrammon6
OFF=~/opt/rakudo-moar-2026.05-01-linux-x86_64-gcc
RES=/tmp/bench-results.txt
SRC=~/opt/rks
: > "$RES"
echo "[$(date +%H:%M)] start; cores capped at -j6" >> "$RES"

cd ~/opt
[ -d "$SRC" ] || git clone -q https://github.com/rakudo/rakudo rks
cd "$SRC"; git fetch -q origin 2>/dev/null
git config user.email b@l 2>/dev/null; git config user.name b 2>/dev/null

build() {  # $1=ref $2=prefix $3=tag
  cd "$SRC"; git bisect reset 2>/dev/null; git checkout -q -- . 2>/dev/null
  git checkout -q "$1"; git clean -fdxq
  echo "[$(date +%H:%M)] building $3 ($1)..." >> "$RES"
  rm -rf "$2"
  perl Configure.pl --prefix="$2" --backend=moar --gen-moar --gen-nqp >/tmp/cfg-$3.log 2>&1 || { echo "$3: CFG-FAIL" >> "$RES"; return 1; }
  make           >/tmp/make-$3.log 2>&1 || { echo "$3: BUILD-FAIL"; tail -5 /tmp/make-$3.log; echo "$3: BUILD-FAIL" >> "$RES"; return 1; }
  make install   >/tmp/inst-$3.log 2>&1 || { echo "$3: INSTALL-FAIL" >> "$RES"; return 1; }
  rm -rf "$2/share/perl6/site"; cp -a "$OFF/share/perl6/site" "$2/share/perl6/site"
  rm -rf "$2/share/perl6/site/precomp"
  echo "[$(date +%H:%M)] built $3: $("$2/bin/raku" --version 2>&1 | grep -o 'Rakudo.*')" >> "$RES"
}

bench() {  # $1=raku-bin $2=label $3=env-assign-or-empty
  cd "$REPO"
  rm -rf ~/.agrammon/*.rakumod ~/.agrammon/.precomp 2>/dev/null
  local out
  out=$(env ${3:+$3} "$1" -Ilib TODO/bench/bench.raku --n=30 2>/dev/null | grep LOAD)
  echo "RESULT | $2 | ${out:-FAILED (no result — see below)}" >> "$RES"
  [ -z "$out" ] && { env ${3:+$3} "$1" -Ilib TODO/bench/bench.raku --n=3 2>&1 | grep -iE 'SORRY|MVMContext|error|No such' | head -2 >> "$RES"; }
}

build 2026.05     ~/opt/rk-2605-self s2605 || true
build origin/main ~/opt/rk-main-self  smain || true

echo "[$(date +%H:%M)] benchmarking..." >> "$RES"
bench "$OFF/bin/raku"             "official-2605  legacy" ""
[ -x ~/opt/rk-2605-self/bin/raku ] && bench ~/opt/rk-2605-self/bin/raku "self-2605      legacy" ""
[ -x ~/opt/rk-main-self/bin/raku ] && bench ~/opt/rk-main-self/bin/raku "main-self      legacy" ""
[ -x ~/opt/rk-main-self/bin/raku ] && bench ~/opt/rk-main-self/bin/raku "main-self      RakuAST" "RAKUDO_RAKUAST=1"
echo "[$(date +%H:%M)] DONE" >> "$RES"
