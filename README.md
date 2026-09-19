# AVIF encode notes (stdlib blog screenshots)

UI/DevTools screenshots for blog figures. Goal: replace hand-cranked
[Squoosh](https://squoosh.app) exports with a local, scriptable encode that
stays sharp enough for text and lands near the same file size.

## Control

Squoosh GUI, AVIF, **quality 70**, **effort 7**.

| source PNG | Squoosh q70 e7 |
|---|---:|
| `axe-heading-levels-dywc.png` (647 KB) | 70.4 KB |
| `axe-color-contrast-dywc-1.png` (753 KB) | 89.1 KB |
| `axe-color-contrast-dywc-2.png` (795 KB) | 90.7 KB |
| `axe-links-only-color-dywc-1.png` (776 KB) | 97.0 KB |

## Tools tried

| tool | notes |
|---|---|
| **`avifenc`** (libavif + libaom, Homebrew) | Best match. Same encoder family as Squoosh. Scriptable. **Winner.** |
| **`cavif`** (rav1e, `cargo install cavif`) | Worked, but larger files at comparable look. Default 10-bit inflated sizes; `--depth 8` still lost to avifenc here. |
| ImageMagick / ffmpeg | Fine for pipelines; less direct control than `avifenc` for stills. |
| Squoosh GUI | Good visual control; painful for batches (manual per file). |

## Grid (heading-levels shot)

Rough sizes for `axe-heading-levels-dywc.png` (Squoosh control = **70 399** bytes):

| recipe | bytes | vs Squoosh |
|---|---:|---:|
| avifenc q55 s3 **420** | 69 387 | −1.4% |
| avifenc q55 s1 444 | 72 773 | +3.4% |
| avifenc q60 s3 420 | 74 559 | +5.9% |
| avifenc q60 s1 444 | 78 885 | +12% |
| avifenc q65 s1 444 | 85 508 | +22% |
| avifenc q70 s1 444 | 92 369 | +31% |
| cavif q55 s1 d8 | 88 734 | +26% |
| cavif q60 s1 d8 | 94 389 | +34% |
| cavif q65 s1 rgb | 154 969 | +120% |

Notes:

- **Lower `avifenc` speed = more effort** (`-s 0` slowest … `-s 10` fastest).
- Squoosh **effort 7** ≈ avifenc **`-s 3`** (rule of thumb: speed ≈ 10 − effort).
- Squoosh quality 0–100 ≈ avifenc `-q`; cq-level ≈ `(100 − q) * 63 / 100` (q55 → 28).
- **`--yuv 444`** preserves chroma (slightly larger). **`420`** is enough for these shots.
- Extra AOM flags used: `end-usage=q`, `cq-level=…`, `tune=ssim`, `sharpness=2`.

## Chosen default

Visual check: **`avifenc-q55-s3-420` looks totally fine** on the heading-levels
screenshot (text, purple highlight, dark DevTools chrome).

Rolled out to all five sources:

| image | q55 s3 420 | vs Squoosh |
|---|---:|---:|
| heading-levels | 69.4 KB | −1.4% |
| color-contrast-1 | 87.8 KB | −1.5% |
| color-contrast-2 | 92.9 KB | +2.4% |
| links-only-color-1 | 94.9 KB | −2.2% |
| issue-categories | 54.8 KB | (no Squoosh control) |

~8–9× smaller than PNG.

### Command

```bash
avifenc -q 55 -s 3 --yuv 420 \
  -a end-usage=q -a cq-level=28 \
  -a tune=ssim -a sharpness=2 \
  input.png input.avif
```

Batch (same basename, `.png` → `.avif`):

```bash
./png-to-avif.sh *.png
# or
./png-to-avif.sh path/to/dir
```

See `png-to-avif.sh`.

## When to nudge

| if… | try… |
|---|---|
| text looks soft on a busy crop | `-q 60` or `--yuv 444` |
| still want smaller | `-q 50` (check 100% crops) |
| one-off max quality | `-q 65 -s 1 --yuv 444` |

## Layout in this folder

- `AGENTS.md` — short standing brief for agents (recipe + do/don't)
- `axe-*.png` — sources
- `*-squoosh-q70-e7.avif` — Squoosh controls
- `avifenc-*.avif`, `cavif-*.avif` — heading-levels parameter grid
- `batch/` — multi-image recipe comparison outputs
- `decoded/` — PNG decodes used for metric peeks (gitignored; regenerable)
- `png-to-avif.sh` — production batch helper
