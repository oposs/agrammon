# SPIKE.md — opt-in fast write path for `Spreadsheet::XLSX`

**Date:** 2026-06-01
**Branch / HEAD:** `feature/model-run-perf` @ `d6646c79`
**Spec:** `docs/superpowers/specs/2026-06-01-spreadsheet-xlsx-fast-write-spike-design.md`
**Plan:** `docs/superpowers/plans/2026-06-01-spreadsheet-xlsx-fast-write-spike.md`
**Running log (primary source):** `test/excel/spike/FINDINGS-spike.md`
**Library under test:** `Spreadsheet::XLSX` v0.3.5 (`raku-community-modules/Spreadsheet-XLSX`,
commit `0a1d559b`), source extracted in `test/excel/_src/`, editable copy in
`test/excel/spike/_lib/`.

> All work is scratch under `test/excel/spike/`. No library or production code was changed.

---

## TL;DR

- **Correctness:** the string serializer correctly round-trips **value + type (number vs
  text) + basic style (bold, number-format)** for the Number/Text subset — a type-aware,
  style-aware round-trip oracle reports **0 diffs**. It does **not** cover `<cols>`,
  rich-text, or shared-string cells.
- **Performance:** the standalone/delegating serializer is **NOT faster** than the DOM
  path — it is **break-even to ~3-6% slower** (0.9-1.0×) at 200/800/2000 rows. This is
  **structural**: it calls the full DOM `to-blob` *and then* rebuilds `sheetData` + re-zips.
  A true speed-up was **not measured** and would require a different architecture (see
  §2, §4).
- **Wiring:** the `:fast` seam is **low-friction** (one signature widening + one extracted
  private method + one shim + a 4-line guard). But it is **not a drop-in** for the full
  write surface: **2 of 4** upstream write tests pass through it; the 2 failures are
  genuine data-loss gaps.
- **Recommendation:** **do NOT productize as-is.** Document-and-stop, with a clear spec of
  what a worthwhile version would require. See §4.

---

## 1. Per-feature correctness table

Oracle = the DOM `to-blob` output, compared via a **round-trip** comparator
(`test/excel/spike/compare.rakumod`): both blobs are re-loaded with the library's own
loader and the resulting models are diffed per populated cell on **presence, type
(`.WHAT`), value, `.style.bold`, `.style.number-format`**. The comparator's negative
controls confirm it bites (it catches number-vs-text type mismatch, planted value diffs,
and missing bold/number-format) — see FINDINGS "Task 4 follow-up" and "Task 6 / Oracle is
now style-aware".

Gate test: `test/excel/spike/t/01-roundtrip.rakutest` → **5/5 PASS, 0 diffs** (re-run
2026-06-01, confirmed).

| feature | how handled | oracle result | semantic discrepancy |
|---|---|---|---|
| Number cells (`<v>`) | **string-path** (built from public cell model) | round-trips, type preserved | none |
| Text cells (`t="inlineStr"`) | **string-path** | round-trips, type preserved | none |
| XML escaping (`&`, `<`, `>`) | **string-path** (`xml-escape`) | round-trips | none (upstream `escaping` test passes through `:fast`) |
| Multiple worksheets | **string-path** (rewrites each `sheetN.xml` in sheet order) | round-trips | none |
| Cell style index `s="…"` (bold, number-format) | **string-path**, id read from **public** `$cell.style.style-id` after the DOM sync pass | bold + number-format round-trip | none — *but only valid on the first/single `to-blob`* (see "to-blob non-idempotency" below) |
| `styles.xml` / `cellXfs` / fonts / numFmts | **delegated-to-DOM** (byte-for-byte from the DOM baseline; verified `styles.xml SAME? True`) | identical by construction | none |
| `[Content_Types].xml`, rels, `workbook.xml`, sharedStrings part | **delegated-to-DOM** (byte-for-byte) | identical by construction | none |
| Column widths `<cols>` | **not reproduced** | — | **dropped** — round-trip loses column widths (upstream `new-basic` fails; see §3) |
| Rich-text / shared-string cells | **not reachable** (coerced to a single flattened `inlineStr`) | — | **data loss + unreadable output** — loader rejects the emitted `<t>` on reload (upstream `styles` fails; see §3) |
| Resolved style-id *without first running the DOM sync* | **not reachable** via public API | — | there is no standalone public "resolve styles" entry point; the id is only populated by the DOM sync pass, and is corrupted by a 2nd `to-blob` |
| Per-built-workbook extent (max-row/max-col) | **not reachable** for a *built* (non-loaded) workbook (`Cells.max-row` → -1; no public max-col) | — | the serializer needs caller-supplied extent **hints**, or it falls back to probing a fixed 1024×64 grid |

### Two library quirks that constrain any in-place seam

- **`to-blob` is NOT idempotent w.r.t. style resolution.** `CellStyle.sync-style-id`
  mutates shared format state and resets pending changes; a **second** `to-blob` on the
  same workbook re-resolves every cell to **style-id 0** (bold/number-format lost). The
  style-id is therefore only reliable on the **first/single** serialization. Any fast seam
  must read style-ids from that same first sync pass and must never re-run `to-blob` on an
  already-serialized workbook. (FINDINGS Task 6, "KEY NEW FINDING".)
- **Style-id reachability was *revised* mid-spike.** Task 5 assumed the resolved id was
  private-only (it is, on the *Cell*: `has UInt $!style-id`, no accessor). Task 6 found it
  IS reachable on the **CellStyle** via the **public** `$.style-id` accessor *after* the
  DOM sync pass populates it. So for the Number/Text + basic-style subset, the string path
  is correct using only public API. (FINDINGS Task 6, "Investigation".)

**Subset verdict:** for **Number/Text cells + bold + number-format**, the string
serializer is correct (oracle-clean). It is **not** correct for `<cols>`, rich-text, or
shared-string cells — see §3.

---

## 2. Performance table

Benchmark: `test/excel/spike/bench.raku`, micro7 methodology — median of 3 runs per size,
8 columns/row (alternating Number/Text), with extent hints supplied to
`string-serialize` (mandatory; see caveat). Numbers below are the recorded Task-7 run
(FINDINGS Task 7).

| # rows | DOM `to-blob` (s) | `string-serialize` (s) | speedup |
|---:|---:|---:|---:|
| 200  |  4.521 |  4.686 | 1.0× |
| 800  | 18.347 | 19.506 | 0.9× |
| 2000 | 46.294 | 49.227 | 0.9× |

**Caveat — "fast includes one DOM pass for delegated parts" (decisive).**
`string-serialize` calls `$wb.to-blob` (the full DOM build) **once internally** to obtain
the byte baseline of every non-sheet part, **then** rebuilds `<sheetData>` as strings,
**then** re-zips. So it measures *DOM-pass + string-rebuild + re-zip*. By construction it
can only ever be **slower** than a bare DOM `to-blob`, and it is (~0.9-1.0×). This is the
realistic standalone/delegating opt-in number, not a sheet-only floor.

**`to-blob(:fast)` is not separately tabled** because, under this delegating architecture,
it routes to the same `string-serialize` (via the `dom-blob` shim for the baseline), so its
cost equals the `string-serialize` column above; mounting it in-place did not change the
arithmetic — it still does DOM work plus extra work.

**What was NOT measured (important):** the spike did **not** measure — and did **not**
prove achievable — the speed of a *true in-place writer* that would **replace** the DOM
`<sheetData>` construction entirely (skip building those nodes, keep only the cheap
scaffold parts). The delegating architecture **cannot** yield a speed-up; a genuine
replace-the-sheetData-build approach is a **different architecture** and its potential
speed is **unmeasured**.

> Minor transparency note (FINDINGS Task 7): the bench times DOM first and string-serialize
> second in a fixed (non-interleaved) order — a small uncontrolled variable that slightly
> favors the second-timed path, i.e. if anything it *flatters* string-serialize. It does
> not reverse the negative verdict.

---

## 3. Wiring verdict

### What the `:fast` seam required (in `test/excel/spike/_lib/Spreadsheet/XLSX.rakumod`)

1. **Signature change:** `method to-blob(--> Blob)` → `method to-blob(Bool :$fast --> Blob)`.
2. **Private extraction:** the original DOM body moved verbatim into
   `method !to-blob-dom(--> Blob)` (byte-identical logic, no behavioural change).
3. **Recursion-avoidance shim (`dom-blob`):** `method dom-blob(--> Blob) { self!to-blob-dom }`.
   The serializer needs the DOM bytes as its baseline; if it called `$wb.to-blob` it would
   re-enter the fast path → infinite recursion. It fetches the baseline through `dom-blob`,
   which goes straight to the DOM path.
4. **Capability guard (spike-only):** the shared `StringSerializer` runs against both the
   unmodified `_src` (Phase 1, no `dom-blob`) and `_lib` (Phase 2, has `dom-blob`), so it
   uses `$wb.^can('dom-blob') ?? $wb.dom-blob !! $wb.to-blob`.
5. **Lazy `require` (not top-of-file `use`):** a top-level `use` would create a load cycle
   (`Spreadsheet::XLSX` → StringSerializer → `compare` → `Spreadsheet::XLSX`); a lazy
   `require Spreadsheet::XLSX::StringSerializer <&string-serialize>` inside the `:fast`
   branch breaks the cycle.
6. **Env-var fallback (spike-only harness):** `my $use-fast = $fast // ?%*ENV<AGRAMMON_XLSX_FORCE_FAST>`
   so the unmodified upstream tests (which call plain `to-blob`) can be forced through the
   fast path with no shim.

Seam gate: `test/excel/spike/t/02-fast-seam.rakutest` → **3/3 PASS** (re-run 2026-06-01),
including proof the `:fast` path genuinely routes through the string serializer (its blob
is byte-different from the DOM blob and carries a `xml:space="preserve"` marker the DOM
path never emits) while the comparator still reports 0 diffs.

### How many upstream write tests passed through `:fast`

Upstream suite = `raku-community-modules/Spreadsheet-XLSX` tag **0.3.5**
(`upstream-checkout/`, git-ignored). The write subset is 4 tests; all 4 **PASS on the
baseline** (normal DOM path through `_lib`) before touching `:fast`. Through `:fast`
(re-run 2026-06-01, results match FINDINGS Task 9):

| upstream test | feature(s) | baseline | through `:fast` | failure class |
|---|---|---|---|---|
| `escaping` | Text w/ `&` `<`, round-trip | PASS | **PASS** | — |
| `set-convenience` | `.set` bold/font/number-format styles, Text+Number round-trip | PASS | **PASS** | — |
| `new-basic` | Text+Number round-trip, then **column widths** | PASS | **FAIL** (59/68 ok, dies at line 176) | genuine gap — `<cols>` dropped |
| `styles` | round-trip of **rich-text / shared-string** cells | PASS | **FAIL** (exit 1, dies in `cell-from-xml`) | genuine gap — unreadable `inlineStr` output |

**2 of 4 pass.** Both failures trace to **one systemic cause**: the fast path rebuilds
**only** `<sheetData>` (Number → `<v>`, everything-else → `inlineStr`) and reproduces
nothing else of the worksheet. Consequences:

- **`new-basic`:** `<cols>` (column widths) is never re-emitted; on reload
  `worksheets[0].columns[0]` is `Any` and the test dies (`No such method 'custom-width'`).
  The cell payload itself round-trips (the Text/Number value assertions passed under
  `:fast`); only the structural `<cols>` block is lost.
- **`styles`:** shared-string / rich-text cells are coerced to a flattened `inlineStr`,
  which (a) loses the rich-text run structure / shared-string identity and (b) for
  empty/structured values emits a `<t>` the loader **rejects on reload** (dies in
  `from-xml-element` → `cell-from-xml`). This is *wrong output the library cannot read
  back*, not different-but-equivalent.

The two that pass (`escaping`, `set-convenience`) only write plain Text + Number cells
with simple styles and no `<cols>` — exactly the subset the fast path supports.

### Clean / messy judgement

**The seam itself is clean (low-friction).** Three small additions plus a signature
widening; no read-path plumbing disturbed; no other library code touched. A real upstream
patch would be of comparable size. The capability-guard, lazy-require harness, and env-var
trigger are **spike-only scaffolding** a real PR would not need (a real PR ships one class
and `use`s it normally).

**But "clean seam" ≠ "drop-in."** The seam mounts cleanly; the *serializer behind it* is
not a complete replacement for the library's write surface (2/4). So: **mounts cleanly,
does not disturb the read path — but is not feature-complete.**

---

## 4. Recommendation

**Do not productize this serializer as-is. Document-and-stop (neither an upstream in-place
PR nor a standalone module is warranted in its current form).**

### Reasoning (grounded in the evidence above)

1. **No speed-up, by construction (§2).** The whole point of a "fast write path" is speed.
   The delegating architecture the spike built is break-even-to-slower because it does DOM
   work *plus* extra work. It cannot beat the DOM path. So shipping it would add a `:fast`
   flag that is **not actually faster** — misleading and pointless.
2. **A genuine speed-up requires a different, unbuilt architecture.** The only path that
   can beat DOM is a **true in-place writer that REPLACES the `<sheetData>` build** (skips
   constructing those DOM nodes entirely), reading the worksheet's own `@!rows` and each
   cell's already-resolved style-id directly — inside the library, right after the existing
   style-resolution sync and before its state is reset. That writer was **not built and not
   measured** here. Its feasibility is *plausible* (FINDINGS Phase 1 conclusion argues the
   in-place shape is strictly cleaner), but its actual speed is **unproven**.
3. **Correctness holds only for a subset (§1, §3).** Even setting speed aside, the
   serializer is correct only for Number/Text + basic styles. A real contribution must
   either (a) close the gaps — `<cols>`, shared strings, rich text, all cell types — or
   (b) explicitly **gate** the fast path to "Number/Text + simple-style workbooks" and fall
   back to DOM otherwise. Neither is done.
4. **No internal demand pulls for this.** Agrammon's own Excel exporter already uses a
   bespoke string writer (`lib/Agrammon/OutputFormatter/XLSXWriter.rakumod`) and does **not**
   depend on this fast path. This spike was solely about whether to contribute a fast write
   path **upstream**. Given (1)-(3), there is no evidence-backed case to do so yet.

### What a worthwhile version would require (for a future plan)

If the contribution is revisited, the right shape is an **in-place writer that replaces the
`<sheetData>` DOM build**, with:

- direct reads of the worksheet's `@!rows` (no public extent, no grid-probe);
- style-ids taken from the single existing sync pass (respecting `to-blob`
  non-idempotency);
- full cell-kind coverage: Number, Text, **shared strings, rich text**, formulas — or an
  explicit capability gate that falls back to DOM for anything unsupported;
- structural worksheet parts beyond `<sheetData>` preserved: **`<cols>`**, merged cells,
  spans;
- a **measured** speed-up over DOM at realistic sizes (the bare sheet-only floor, not the
  delegating number) — this is the gating evidence the spike did **not** produce.

A standalone `Spreadsheet::XLSX::…Writer` module would face the same correctness and speed
requirements; it offers no advantage over an in-place writer here, and an in-place writer
is the only shape that can both reuse the resolved style-ids cleanly and skip the DOM
sheetData build. So **if** revisited, prefer the **in-place** shape — but only after the
true-replacement writer is built and its speed-up is measured.

---

## 5. The four spike questions, answered with evidence

From the spec's "Success criteria for the spike itself":

1. **Can a string serializer reproduce the full current write capability?**
   **No — yes only for a subset.** Number/Text + bold + number-format round-trip
   oracle-clean (`t/01-roundtrip.rakutest` 5/5, 0 diffs). `<cols>`, rich-text, and
   shared-string cells are not reproduced — 2 of 4 upstream write tests fail through
   `:fast` (`new-basic`, `styles`) with genuine data-loss (§1, §3).

2. **Does it mount cleanly behind the existing API without disturbing the read path?**
   **Yes — the seam mounts cleanly and does not touch the read path** (signature widening +
   `!to-blob-dom` extraction + `dom-blob` shim + lazy `require`; `t/02-fast-seam.rakutest`
   3/3). Caveat: the serializer behind it is not feature-complete, so a clean seam still
   does not make it a drop-in (§3).

3. **What is the measured speed-up?**
   **None.** The standalone/delegating path is 0.9-1.0× (break-even to ~3-6% slower) at
   200/800/2000 rows — slower by construction (it does a full DOM pass plus a string
   rebuild plus a re-zip). A true replace-the-sheetData writer is unmeasured (§2).

4. **Which productization path?**
   **Neither, as-is — document-and-stop.** No speed-up by construction, correctness only
   for a subset, and no internal dependency. A worthwhile version requires a from-scratch
   **in-place** writer that replaces the `<sheetData>` build with full feature coverage (or
   explicit subset-gating) and a *measured* speed-up — none of which this spike produced
   (§4).

> Per the spec, a well-evidenced **negative/conditional** conclusion is a valid and
> successful spike outcome. The spike answered all four questions with evidence; the answer
> is "not worth productizing as-is, and here's exactly what a worthwhile version would
> require."
