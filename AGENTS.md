# AGENTS.md — avif-compare

Scratch pad + settled recipe for turning stdlib blog UI screenshots (PNG) into AVIF without Squoosh.

Full notes, size tables, and tool comparison: **`README.md`**.

## Default encode (do not reinvent)

```bash
./png-to-avif.sh path/to/image.png
# or a directory / cwd — writes same basename: foo.png → foo.avif
```

Recipe locked in the script:

- `avifenc` (Homebrew libavif + libaom)
- **`-q 55 -s 3 --yuv 420`**
- `-a end-usage=q -a cq-level=28 -a tune=ssim -a sharpness=2`

Chosen because it matched Squoosh **q70 / effort 7** on size (~±2%) and looked fine on text-heavy DevTools crops. Prefer this over cavif, ffmpeg, ImageMagick, or the Squoosh GUI for batch work.

## Overrides

| env | default | when |
|---|---|---|
| `QUALITY` | `55` | soft text → try `60` |
| `SPEED` | `3` | lower = slower / better compression |
| `YUV` | `420` | chroma-critical UI chrome → `444` |
| `-f` | off | overwrite existing `.avif` |

Example: `QUALITY=60 YUV=444 ./png-to-avif.sh -f shot.png`

## Do / don't

- **Do** keep output basename identical to the PNG (only change the extension).
- **Do** eyeball 100% crops of text if you change quality or chroma.
- **Don't** re-run the full encoder grid unless Mara asks — results live under `avifenc-*.avif`, `cavif-*.avif`, and `batch/`.
- **Don't** treat Squoosh as the production path; controls here are historical (`*-squoosh-q70-e7.avif`).
- **Don't** default to cavif for these shots (larger, no visual win in the grid).

## Layout

| path | what |
|---|---|
| `axe-*.png` | sources |
| `*-squoosh-q70-e7.avif` | Squoosh controls |
| `png-to-avif.sh` | production batch helper |
| `batch/` | multi-recipe comparison outputs |
| `decoded/` | PNG decodes from metric peeks (gitignored) |
