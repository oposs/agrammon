// =============================================================================
// Agrammon PDF export — typst template (DRAFT, side-by-side with pdfexport.crotmp)
// Rendered by Cro::WebApp::Template; output piped to `typst compile`.
//
// Cro tags use METHOD calls on the iteration item, so field names that
// collide with Raku built-ins (`.first` and `.head` on Hash) must use the
// explicit subscript form. This template hits one such case, on the
// section-marker key `first` (see the outputs loop below).
// =============================================================================

#set page(
  paper: "a4",
  margin: (top: 1.8cm, bottom: 2.5cm, x: 1.5cm),
  footer: [
    #set text(size: 8pt)
    #grid(
      columns: (1fr, auto),
      align: (left, right),
      [fritz.zaucker\@oetiker.ch --- TestDataset \
       Agrammon 6.0 --- Timestamp],
      context counter(page).display(),
    )
  ],
)
#set text(font: "Liberation Sans", size: 10pt)
#set par(justify: false, leading: 0.5em)
#set heading(numbering: "1.")
#show heading.where(level: 1): set text(size: 14pt, weight: "bold")
#show heading.where(level: 2): set text(size: 12pt, weight: "bold")
#show heading.where(level: 3): set text(size: 10pt, weight: "bold")

// ── Title (no number — matches LaTeX `\section*{}`). Rendered as
// styled text rather than a heading so it doesn't increment the
// level-1 counter (would make subsequent sections start at "0.1.").
#align(left)[#text(size: 14pt, weight: "bold")[Report]]
#v(0.5em)

// ── Dataset metadata block ────────────────────────────────────────
= Section

#table(
  columns: (auto, 1fr),
  stroke: none,
  inset: (x: 3pt, y: 2pt),
  align: (left, left),
  [*Dataset:*], [TestDataset],
  [*Username:*], [fritz.zaucker\@oetiker.ch],
  [*Version:*], [Single],
)


// ── Outputs section ───────────────────────────────────────────────
// Streaming-table trick (mirrors the LaTeX template):
//   * each section header opens `#table( … `
//   * each data row appends a cell tuple
//   * the closing `)` is emitted by the NEXT section header (when not the
//     first) and once at the end of the @outputs loop
= Results

== Module
#table(
  columns: (auto, 1fr, auto, auto),
  stroke: none,
  fill: (_, y) => if calc.odd(y) { rgb("#eaeaea") },
  inset: (x: 4pt, y: 3pt),
  align: (col, _) => if col == 2 { right } else { left },
  [], [Weide NH3-Emission], [5], [kg N / yr],
  [], [Stall und Laufhof NH3-Emission], [50], [kg N / yr],
)

== Log

#text(size: 9pt)[
- *Module[]*: comment 1
- *Module[]*: comment 2
]

// ── Inputs section ────────────────────────────────────────────────
// Same streaming-table pattern, but with module+instance nesting
// (each instance opens a new table; module headers close+open).
#pagebreak()
= Inputs

#set text(size: 8pt)

== Module




#table(
  columns: (auto, auto, 1fr, auto, auto),
  stroke: none,
  fill: (_, y) => if calc.odd(y) { rgb("#eaeaea") },
  inset: (x: 4pt, y: 2pt),
  align: (col, _) => if col == 3 { right } else { left },
  [], [], [Input], [42], [Unit],
)
