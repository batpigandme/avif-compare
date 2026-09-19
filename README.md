# avif-compare

Scratch pad from comparing local AVIF encoders against [Squoosh](https://squoosh.app) for text-heavy UI screenshots. Public only because it has no reason to be private.

## Attribution / tools used

| tool | link | used for |
|---|---|---|
| **Squoosh** | [squoosh.app](https://squoosh.app) · [source](https://github.com/GoogleChromeLabs/squoosh) | Control encodes (AVIF quality 70, effort 7). Apache-2.0. |
| **libavif** (`avifenc`) | [AOMediaCodec/libavif](https://github.com/AOMediaCodec/libavif) | Local production encode path. BSD-2-Clause. |
| **libaom** | [aomedia aom](https://aomedia.googlesource.com/aom/) | AV1 encoder behind Homebrew `avifenc` here. BSD-2-Clause + AOM patent license. |
| **cavif** | [kornelski/cavif](https://github.com/kornelski/cavif) | Alternative encoder (`cargo install cavif`). BSD-2-Clause. |
| **rav1e** | [xiph/rav1e](https://github.com/xiph/rav1e) | AV1 encoder under cavif. BSD-2-Clause. |
| **ImageMagick** | [imagemagick.org](https://imagemagick.org) | `identify` / decode / `compare` metric peeks. |
| **ffmpeg** | [ffmpeg.org](https://ffmpeg.org) | Available still-image path; not preferred over `avifenc` for these crops. |
| **Homebrew** | [brew.sh](https://brew.sh) | `brew install libavif` (pulls libaom). |

This repo’s own notes and `png-to-avif.sh` are [0BSD](./LICENSE). That does not change the licenses of the tools above.

Screenshots are UI captures for personal encode testing, not a claim on anyone else’s product branding beyond fair documentation use.

---

## Notes to self

**Job:** stop hand-cranking Squoosh for stdlib blog DevTools PNGs; keep text sharp; land near Squoosh q70/e7 size.

### Control

Squoosh GUI, AVIF, **quality 70**, **effort 7**.

| source PNG | Squoosh q70 e7 |
|---|---:|
| `axe-heading-levels-dywc.png` (647 KB) | 70.4 KB |
| `axe-color-contrast-dywc-1.png` (753 KB) | 89.1 KB |
| `axe-color-contrast-dywc-2.png` (795 KB) | 90.7 KB |
| `axe-links-only-color-dywc-1.png` (776 KB) | 97.0 KB |

### Tools tried

| tool | notes |
|---|---|
| **`avifenc`** (libavif + libaom, Homebrew) | Best match. Same encoder family as Squoosh. Scriptable. **Winner.** |
| **`cavif`** (rav1e) | Worked, but larger files at comparable look. Default 10-bit inflated sizes; `--depth 8` still lost to avifenc here. |
| ImageMagick / ffmpeg | Fine for pipelines; less direct control than `avifenc` for stills. |
| Squoosh GUI | Good visual control; painful for batches (manual per file). |

### Grid (heading-levels shot)

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

### Chosen default

Visual check: **`avifenc-q55-s3-420` looks totally fine** on the heading-levels screenshot (text, purple highlight, dark DevTools chrome).

```bash
./png-to-avif.sh path/to/image.png   # foo.png → foo.avif
# needs: brew install libavif
```

Recipe in the script: **`-q 55 -s 3 --yuv 420`** plus `-a end-usage=q -a cq-level=28 -a tune=ssim -a sharpness=2`.

Rolled out to all five sources:

| image | q55 s3 420 | vs Squoosh |
|---|---:|---:|
| heading-levels | 69.4 KB | −1.4% |
| color-contrast-1 | 87.8 KB | −1.5% |
| color-contrast-2 | 92.9 KB | +2.4% |
| links-only-color-1 | 94.9 KB | −2.2% |
| issue-categories | 54.8 KB | (no Squoosh control) |

~8–9× smaller than PNG.

One-liner equivalent:

```bash
avifenc -q 55 -s 3 --yuv 420 \
  -a end-usage=q -a cq-level=28 \
  -a tune=ssim -a sharpness=2 \
  input.png input.avif
```

### When to nudge

| if… | try… |
|---|---|
| text looks soft on a busy crop | `-q 60` or `--yuv 444` (env: `QUALITY=60` / `YUV=444`) |
| still want smaller | `-q 50` (check 100% crops) |
| one-off max quality | `-q 65 -s 1 --yuv 444` |
| overwrite existing `.avif` | `./png-to-avif.sh -f …` |

### Layout

| path | what |
|---|---|
| `png-to-avif.sh` | production batch helper (`foo.png` → `foo.avif`) |
| `AGENTS.md` | short standing brief for agents |
| `axe-*.png` | sources |
| `*-squoosh-q70-e7.avif` | Squoosh controls |
| `avifenc-*.avif`, `cavif-*.avif` | heading-levels parameter grid |
| `batch/` | multi-image recipe comparison outputs |
| `decoded/` | PNG decodes used for metric peeks (gitignored; regenerable) |

**Don’t** re-run the full encoder grid unless inputs change. **Don’t** default to cavif for these shots.
