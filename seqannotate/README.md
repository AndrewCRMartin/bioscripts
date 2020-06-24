seqannotate
===========

(c) 2020 UCL, Prof. Andrew C.R. Martin
--------------------------------------

`seqannotate` is a simple program to generate annotation of a sequence
with coloured bars to indicate features. `seqannotate` doesn't
actually require a sequence - it can simply take a sequence length
instead and just draw a bar to represent the sequence.


Input
-----

The program requires a control file specifying the sequence and annotations.

The minimal content of the file is:

`SEQUENCE file.faa` - a FASTA file containing the sequence

--or--

`SEQLEN length` - the length of the sequence

If only that is supplied, the sequence will be displayed either as the
one-letter code or as a coloured bar.

`BREAK breaklength` - specifies the number of amino acids per line,
i.e. where to break a line [Default: 100]

`WIDTH percentwidth` - specify the percentage width of the image used
for `breakliength` amino acids [Default: 80]

`COLOUR|COLOR #colour [start stop]` - specifies the colour of the
sequence bar or amino acids. The colour is specified as an RGB
hexadecimal number (e.g. `FF0000` for bright red).

`SPLIT [splitsize]` - specified that the sequence (or sequence bar)
should contain a space every `splitsize` characters [Default: no
splitting, 10 if given without a parameter]

`TICK tickspacing` - place a tick mark and residue number every
`tickspacing` residues

`SFONT fontname size` - font used for the sequence [Default: Helvetica 12]

`AFONT fontname size` - font used for the annotations [Default: Helvetica 10]

`TFONT fontname size` - font used for the tick marks [Default: Helvetica 8]



`ANNOTATION start stop #colour [text [pos [#colour]]]` - an annotation bar
running from residue `start` to residue `stop`. `colour` is specified
as an RGB hexadecimal number (e.g. `FF0000` for bright red). `text`
must be in inverted commas if it contains spaces. `pos` is one of:

- `oleft` - outside the bar to the left
- `left` - inside the bar to the left
- `centre` or `center` - inside the bar, centred
- `right - inside the bar to the right
- `oright` - outside the bar to the right

[Default is `oright`]


Example
-------

```
SEQLEN 240
BREAK 60
ANNOTATION 1 100 #0000AA
ANNOTATION 90 120 #00FF00 "1ABC 1 61"
ANNOTATION 121 240 #330000 Missing centre #FFFFFF
```

Ouput will be of the form

```
============================================================
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb

============================================================
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
                             ggggggggggggggggggggggggggggggg 1ABC 1 61


============================================================
rrrrrrrrrrrrrrrrrrrrrrrrrr Missing rrrrrrrrrrrrrrrrrrrrrrrrr
```

(where '=' represents the sequence bar, 'b' a blue bar, 'g' a green
bar and 'r' a red bar).
