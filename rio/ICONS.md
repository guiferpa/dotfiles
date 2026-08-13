# Why the icons needed a `symbol-map`

The file icons `oil` draws were rendering noticeably smaller than the text
beside them. The fix was seven lines of `symbol-map` in `config.toml`, but the
reason it takes a font-level workaround — rather than a setting in `oil` — is
worth writing down, because the obvious fix is a trap this config had already
fallen into once.

Every number here was measured with `fontTools` against the actual `.ttf` files
in `~/Library/Fonts`, at Nerd Fonts 3.5.0. None of it is from memory.

## It was never an `oil` problem

`oil` has no icon size setting, and neither does Neovim. Neovim has no font
configuration at all — it draws through whatever the terminal renders with, so
the only thing in this repository that can affect glyph size is
`rio/config.toml`.

The icons themselves come from `mini.icons` (`nvim/lua/plugins/icons.lua`),
which emits Nerd Font codepoints. `oil` just prints a character. How big that
character comes out is entirely the font's decision.

## What the Mono build actually does

Nerd Fonts ships three builds of every family. They carry identical codepoint
coverage and differ only in how the patched-in icon glyphs are sized. Measured
on `JetBrainsMono`, using the folder icon `oil` puts on every directory
(`U+F0219`, `nf-md-folder`):

| Build   | Advance | Ink width | Ink height |
| ------- | ------: | --------: | ---------: |
| `Mono`  |     600 |       600 |        748 |
| Plain   |     600 |       668 |        832 |
| `Propo` |     668 |       668 |        832 |

Two things stand out, and the second one surprised me.

**The `Mono` build clamps ink to the cell.** Its icon is exactly 600 units
wide — the same as the advance, the same as a letter. The plain build's is 668.
To hit that 600 the glyph is scaled down, and since scaling is uniform, the
height falls with it: 748 against 832. That lost height is the entire complaint.

**The plain build does not use a two-cell advance.** I assumed it did before
measuring. It does not — advance stays 600, identical to `Mono` and to text.
The plain build simply lets the ink overflow its own advance box. Only `Propo`
changes the advance, and it makes it *proportional*, which is what would truly
break a terminal grid.

That distinction matters for the fix. Remapping a range to the plain build does
not desynchronise the terminal's column arithmetic, because the advance the
terminal reads is unchanged at 600. The glyph just paints slightly wider than
its own box.

## How much was being lost

Averaged over every glyph in each class that exists in both builds:

| Icon class       | Glyphs | `Mono` height | Plain height | Gain |
| ---------------- | -----: | ------------: | -----------: | ---: |
| Material Design  |  6 896 |     0.596 em  |    0.776 em  | +30% |
| Font Awesome     |  1 488 |     0.577 em  |    0.847 em  | +47% |
| Devicons         |    496 |     0.585 em  |    0.706 em  | +21% |
| Codicons         |    438 |     0.590 em  |    0.785 em  | +33% |
| Octicons         |    308 |     0.557 em  |    0.860 em  | +54% |
| Weather          |    228 |     0.507 em  |    0.785 em  | +55% |
| Seti-UI + Custom |    190 |     0.611 em  |    0.806 em  | +32% |
| Font Awesome Ext |    170 |     0.613 em  |    0.852 em  | +39% |
| Font Logos       |    130 |     0.592 em  |    0.915 em  | +55% |
| Pomicons         |     11 |     0.676 em  |    0.770 em  | +14% |

Material Design is the row that matters for `oil` — as the README's font
section records, 73% of the glyphs `mini.icons` uses live in that class.

The clearest way to state the problem is to compare against text rather than
against another build. A capital `M` in this font has 0.730 em of ink height,
in all three builds. So:

- in `Mono`, a Material Design icon is **0.596 em — 82% of cap height.** It
  reads as undersized, because it *is* smaller than the letters it sits next to.
- in the plain build it is **0.776 em — 106% of cap height.** Slightly larger
  than the capitals, which is what an icon is supposed to look like.

An icon shorter than the surrounding capitals is the entire perceptual bug.
"Too small" was exactly right.

## Why not just switch the whole family

Because it was tried, and it is why the config was on `Mono` in the first
place. The commit history and the old comment in `config.toml` both record the
same finding: the plain and `Propo` builds make icons overlap the next column
in `oil` and `lualine`.

The measurements say why. In the plain build, the fraction of glyphs whose ink
is wider than the 600-unit cell:

| Class            | Overflows cell |
| ---------------- | -------------: |
| Font Logos       |            99% |
| Font Awesome     |            94% |
| Octicons         |            94% |
| Material Design  |            91% |
| Seti-UI + Custom |            90% |
| Codicons         |            90% |

So switching `family` wholesale trades a real problem for a real problem. The
icons get their size back and start bleeding into whatever is drawn to their
right.

`symbol-map` is what makes it not a trade. `family` stays `Mono`, so every
character that carries meaning as text — letters, box drawing, block elements,
braille — keeps the `Mono` metrics and the grid stays honest. Only the ranges
that contain nothing but icons are redirected. The bleed still exists, but it
now happens exclusively where the next column is padding: `oil`'s `icon` column
emits a trailing space and the column join adds another, so there are two
spaces of slack to bleed into.

## Why Powerline is excluded

`U+E0A0`–`U+E0D7` is deliberately absent from the map, and it is the one
exclusion that is not obvious.

Measured, Powerline glyphs are **1.253 em** tall in `Mono` and **1.264 em** in
the plain build. A 1% difference, against 30% for Material Design. They are
already drawn well past full em height in both builds, because a `lualine`
separator has to meet its neighbours edge to edge with no seam — its geometry
is load-bearing, not decorative.

There is nothing to gain and a working status line to lose. Same reasoning for
IEC power (`U+23FB`–`U+23FE`), which sits inline with real text.

## Applying it

`install.sh` copies configs into `~/.config`, it does not symlink them
(`install.sh:248-256`). Editing this repository alone changes nothing in a
running terminal:

```sh
./install.sh
```

Then fully restart Rio. `config.toml` notes that font features have no
live-reload support; whether `symbol-map` specifically reloads was not
verified, and a restart settles it either way.

## If it ever needs tuning

1. Point the map at `JetBrainsMono Nerd Font Propo` instead — same ink as the
   plain build, but with a proportional advance. Different tradeoff, not a
   strictly better one.
2. Narrow the map to Material Design (`F0001`–`F1AF0`) alone. That is where
   nearly all of `oil`'s filetype icons come from, and it is the smallest
   change that fixes the visible complaint.
3. Delete the `symbol-map` block. Nothing else depends on it.

## Reproducing the measurements

```python
from fontTools.ttLib import TTFont
from fontTools.pens.boundsPen import BoundsPen

f = TTFont("~/Library/Fonts/JetBrainsMonoNerdFontMono-Regular.ttf")
gs, cmap = f.getGlyphSet(), f.getBestCmap()

pen = BoundsPen(gs)
gs[cmap[0xF0219]].draw(pen)
print(pen.bounds, f["head"].unitsPerEm)
```

Swap `Mono` for `JetBrainsMonoNerdFont-Regular.ttf` to compare. `hmtx[glyph]`
gives the advance; the bounding box gives the ink.
