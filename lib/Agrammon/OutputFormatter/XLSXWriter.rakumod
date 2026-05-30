use v6;
use Libarchive::Simple;

# A small, fast, write-only XLSX generator.
#
# It builds the worksheet XML as strings (no DOM, no per-node FFI) with a shared
# style table referenced by index — the way Excel itself and Excel::Writer::XLSX
# store workbooks — then packs the parts into the .xlsx zip with Libarchive (the
# same library Spreadsheet::XLSX already uses for zipping).
#
# Why this exists: the DOM-based Spreadsheet::XLSX path is ~30x slower than the
# Perl Excel::Writer::XLSX path because it makes several LibXML/FFI calls per
# cell. This writer is ~7x faster than even the Perl path on a realistic report,
# because it pays neither per-node FFI nor Inline::Perl5 marshalling.
#
# The API intentionally mirrors the subset of Excel::Writer::XLSX that
# Agrammon's exporter uses (add_worksheet/set_column/add_format/write), so
# swapping the production formatter over is close to mechanical.

unit module Agrammon::OutputFormatter::XLSXWriter;

# ---- XML helpers -----------------------------------------------------------

my sub xml-escape(Str() $s --> Str) {
    $s.subst('&', '&amp;', :g)
      .subst('<', '&lt;',  :g)
      .subst('>', '&gt;',  :g)
}

my sub attr-escape(Str() $s --> Str) {
    xml-escape($s).subst('"', '&quot;', :g)
}

#| Convert a 0-based column index to its A1-style column letter (0 -> A, 26 -> AA).
#| Accepts anything Int-coercible because hash keys come back as strings.
sub col-name(Int() $col is copy --> Str) is export {
    my $s = '';
    loop {
        $s = chr(ord('A') + $col % 26) ~ $s;
        $col = $col div 26 - 1;
        last if $col < 0;
    }
    $s
}

# ---- Format ----------------------------------------------------------------

#| A cell format: bold font, a number-format code, and/or horizontal alignment.
#| Obtained from Workbook.add-format; opaque to callers apart from its id.
class Format {
    has Int  $.id;            # index into cellXfs
    has Bool $.bold = False;
    has Str  $.num-format;    # e.g. '0.000'  (Nil = General)
    has Str  $.align;         # 'left'|'center'|'right'  (Nil = default)

    method key(--> Str) {
        ($!bold ?? 'b' !! '-') ~ '|' ~ ($!num-format // '') ~ '|' ~ ($!align // '')
    }
}

# ---- Worksheet -------------------------------------------------------------

class Worksheet {
    has Str   $.name;
    has       @.rows;          # @rows[$r]{$c} = % :kind, :value, :fmt(Int)
    has       %!cols;          # col-index => width
    has Int   $.max-col = -1;

    #| Set the width of column $col (0-based). Excel "characters" width units.
    method set-column(Int:D $col, Real:D $width --> Nil) {
        %!cols{$col} = $width;
        $!max-col = $col if $col > $!max-col;
    }

    method !put(Int:D $row, Int:D $col, %cell --> Nil) {
        @!rows[$row] //= {};
        @!rows[$row]{$col} = %cell;
        $!max-col = $col if $col > $!max-col;
    }

    #| Write a string cell (stored as an inline string).
    method write-string(Int:D $row, Int:D $col, Str() $value, Format :$format --> Nil) {
        self!put($row, $col, %( kind => 'str', :$value, fmt => ($format ?? $format.id !! 0) ));
    }

    #| Write a numeric cell (raw value; the format only controls display).
    method write-number(Int:D $row, Int:D $col, Real() $value, Format :$format --> Nil) {
        self!put($row, $col, %( kind => 'num', :$value, fmt => ($format ?? $format.id !! 0) ));
    }

    #| Polymorphic convenience, matching Excel::Writer::XLSX.write — auto-detects
    #| numbers vs text. Single method (not multi) so allomorphs from collect-data
    #| (IntStr/RatStr/NumStr, which do BOTH Real and Str) dispatch unambiguously:
    #| anything Real-typed and numeric-looking becomes a number cell, everything
    #| else a text cell.
    method write(Int:D $row, Int:D $col, $value, Format $format? --> Nil) {
        if !$value.defined {
            self.write-string($row, $col, '', :$format);
        }
        elsif $value ~~ Real && $value !~~ Bool {
            # plain numbers and numeric allomorphs (IntStr "42", RatStr "1.5", …)
            self.write-number($row, $col, $value.Real, :$format);
        }
        else {
            self.write-string($row, $col, $value.Str, :$format);
        }
    }

    method !cols-xml(--> Str) {
        return '' unless %!cols;
        my @c = %!cols.keys.sort({ $^a <=> $^b }).map: -> $col {
            my $w = %!cols{$col};
            my $n = $col + 1;     # 1-based in <col>
            '<col min="' ~ $n ~ '" max="' ~ $n ~ '" width="' ~ $w ~ '" customWidth="1"/>'
        };
        '<cols>' ~ @c.join ~ '</cols>'
    }

    method to-xml(--> Str) {
        my @p;
        @p.push: '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>';
        @p.push: '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">';
        @p.push: self!cols-xml;
        @p.push: '<sheetData>';
        for ^@!rows.elems -> $r {
            my %cells := @!rows[$r] // next;
            next unless %cells;
            my $rownum = $r + 1;
            my @cs = %cells.keys.sort({ $^a <=> $^b });
            my $span = (@cs[0] + 1) ~ ':' ~ (@cs[*-1] + 1);
            @p.push: '<row r="' ~ $rownum ~ '" spans="' ~ $span ~ '">';
            for @cs -> $c {
                my %cell := %cells{$c};
                my $ref  = col-name($c) ~ $rownum;
                my $s    = %cell<fmt>;
                my $sa   = $s ?? ' s="' ~ $s ~ '"' !! '';
                if %cell<kind> eq 'num' {
                    @p.push: '<c r="' ~ $ref ~ '"' ~ $sa ~ '><v>' ~ %cell<value> ~ '</v></c>';
                }
                else {
                    my $t = xml-escape(%cell<value>);
                    @p.push: '<c r="' ~ $ref ~ '"' ~ $sa ~ ' t="inlineStr"><is><t xml:space="preserve">'
                             ~ $t ~ '</t></is></c>';
                }
            }
            @p.push: '</row>';
        }
        @p.push: '</sheetData></worksheet>';
        @p.join
    }
}

# ---- Workbook --------------------------------------------------------------

class Workbook is export {
    has Worksheet @.worksheets;
    has Format    @!formats;       # @formats[0] is always the default (plain)
    has %!format-cache;            # Format.key => Format
    has %!numfmt-ids;              # num-format code => numFmtId (>=164)
    has Int       $!next-numfmt = 164;

    submethod TWEAK {
        # Index 0 is the mandatory default cell format.
        my $f = Format.new(:id(0));
        @!formats[0] = $f;
        %!format-cache{$f.key} = $f;
    }

    #| Create a worksheet. Names are truncated to Excel's 31-char limit.
    method add-worksheet(Str:D $name --> Worksheet) {
        my $ws = Worksheet.new(name => $name.substr(0, 31));
        @!worksheets.push: $ws;
        $ws
    }

    #| Register (or look up) a cell format. Returns a Format whose .id is the
    #| cellXfs index referenced by cells. Identical formats are de-duplicated.
    method add-format(Bool :$bold, Str :$num-format, Str :$align --> Format) {
        my $probe = Format.new(:id(-1), :bold($bold // False), :$num-format, :$align);
        with %!format-cache{$probe.key} {
            return $_;
        }
        if $num-format && !%!numfmt-ids{$num-format} {
            %!numfmt-ids{$num-format} = $!next-numfmt++;
        }
        my $f = Format.new(
            id         => @!formats.elems,
            bold       => ($bold // False),
            :$num-format,
            :$align,
        );
        @!formats.push: $f;
        %!format-cache{$f.key} = $f;
        $f
    }

    # ---- styles.xml ----

    method !styles-xml(--> Str) {
        my @numfmts = %!numfmt-ids.sort(*.value).map: -> (:key($code), :value($id)) {
            '<numFmt numFmtId="' ~ $id ~ '" formatCode="' ~ attr-escape($code) ~ '"/>'
        };
        my $numfmts-block = @numfmts
            ?? '<numFmts count="' ~ @numfmts.elems ~ '">' ~ @numfmts.join ~ '</numFmts>'
            !! '';

        # Two fonts: 0 = default, 1 = bold. Cell formats reference fontId 1 if bold.
        my $fonts =
            '<fonts count="2">'
            ~ '<font><sz val="11"/><name val="Calibri"/></font>'
            ~ '<font><b/><sz val="11"/><name val="Calibri"/></font>'
            ~ '</fonts>';

        # Excel expects at least these two default fills.
        my $fills =
            '<fills count="2">'
            ~ '<fill><patternFill patternType="none"/></fill>'
            ~ '<fill><patternFill patternType="gray125"/></fill>'
            ~ '</fills>';

        my $borders = '<borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>';

        my $cellstylexfs = '<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>';

        my @xfs = @!formats.map: -> $f {
            my $numfmt-id = $f.num-format ?? %!numfmt-ids{$f.num-format} !! 0;
            my $font-id   = $f.bold ?? 1 !! 0;
            my @attrs = (
                'numFmtId="' ~ $numfmt-id ~ '"',
                'fontId="' ~ $font-id ~ '"',
                'fillId="0"',
                'borderId="0"',
                'xfId="0"',
            );
            @attrs.push: 'applyNumberFormat="1"' if $f.num-format;
            @attrs.push: 'applyFont="1"'         if $f.bold;
            @attrs.push: 'applyAlignment="1"'    if $f.align;
            my $open = '<xf ' ~ @attrs.join(' ') ~ '>';
            my $body = $f.align
                ?? '<alignment horizontal="' ~ $f.align ~ '"/>'
                !! '';
            $open ~ $body ~ '</xf>'
        };
        my $cellxfs = '<cellXfs count="' ~ @xfs.elems ~ '">' ~ @xfs.join ~ '</cellXfs>';

        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        ~ '<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
        ~ $numfmts-block ~ $fonts ~ $fills ~ $borders ~ $cellstylexfs ~ $cellxfs
        ~ '</styleSheet>'
    }

    # ---- package scaffolding ----

    method !content-types-xml(--> Str) {
        my @ov;
        @ov.push: '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>';
        @ov.push: '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>';
        for ^@!worksheets.elems -> $i {
            @ov.push: '<Override PartName="/xl/worksheets/sheet' ~ ($i+1)
                ~ '.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>';
        }
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        ~ '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
        ~ '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
        ~ '<Default Extension="xml" ContentType="application/xml"/>'
        ~ @ov.join
        ~ '</Types>'
    }

    method !root-rels-xml(--> Str) {
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        ~ '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        ~ '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>'
        ~ '</Relationships>'
    }

    method !workbook-xml(--> Str) {
        my @sheets = @!worksheets.kv.map: -> $i, $ws {
            '<sheet name="' ~ attr-escape($ws.name) ~ '" sheetId="' ~ ($i+1)
                ~ '" r:id="rId' ~ ($i+1) ~ '"/>'
        };
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        ~ '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"'
        ~ ' xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
        ~ '<sheets>' ~ @sheets.join ~ '</sheets>'
        ~ '</workbook>'
    }

    method !workbook-rels-xml(--> Str) {
        my @rels;
        for ^@!worksheets.elems -> $i {
            @rels.push: '<Relationship Id="rId' ~ ($i+1)
                ~ '" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet"'
                ~ ' Target="worksheets/sheet' ~ ($i+1) ~ '.xml"/>';
        }
        # styles gets the next free rId
        my $sid = @!worksheets.elems + 1;
        @rels.push: '<Relationship Id="rId' ~ $sid
            ~ '" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles"'
            ~ ' Target="styles.xml"/>';
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        ~ '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        ~ @rels.join
        ~ '</Relationships>'
    }

    #| Serialise the whole workbook to an .xlsx blob.
    method to-blob(--> Blob) {
        my @parts =
            '[Content_Types].xml'        => self!content-types-xml,
            '_rels/.rels'                => self!root-rels-xml,
            'xl/workbook.xml'            => self!workbook-xml,
            'xl/_rels/workbook.xml.rels' => self!workbook-rels-xml,
            'xl/styles.xml'              => self!styles-xml,
            ;
        for @!worksheets.kv -> $i, $ws {
            @parts.push: ('xl/worksheets/sheet' ~ ($i+1) ~ '.xml') => $ws.to-xml;
        }

        my $buffer = Buf.new;
        given archive-write($buffer, format => 'zip') -> $archive {
            for @parts -> (:key($path), :value($content)) {
                $archive.write($path, $content.encode('utf-8'));
            }
            $archive.close;
        }
        $buffer
    }

    #| Save directly to a file path.
    method save(IO() $path --> Nil) {
        $path.spurt(self.to-blob);
    }
}
