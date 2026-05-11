# Fullstack AG Title Card Branding

Use this file when adding episode-specific title or subtitle text on top of:

```text
videos/src/fullstack-ag-title-card-background-3600x2160.png
```

That PNG already includes the green gradient background, topographic texture,
wheat/field-row decoration, Fullstack AG logo treatment, and orange line. Do
not use the old generic skill title-card assets for this project.

## Canvas

- Size: `3600x2160`
- Center x: `1800`
- Keep episode text in the central clear area between the logo and orange line.

## Fonts

These are copied from the `fullstack-ag-web` Next.js generated font assets:

- `fonts/manrope-latin-variable.woff2`
  - Website role: `font-heading`
  - Source text match: `Where Business-Minded Operators Get Their Edge`
  - Use for title text.
- `fonts/inter-latin-variable.woff2`
  - Website role: `font-sans`
  - Source text match: `Tools Tuesday: One AI tool, broken down...`
  - Use for subtitle text.

Both files are Latin variable WOFF2 subsets from `next/font/google`, which is
enough for the current English video titles.

## Episode Title Text

Recommended title style:

- Font: Manrope
- Weight: `700` / Bold
- Size: `168px`
- Color: `#FFFFFF`
- Letter spacing: `0`
- Line height: `1.1`
- Max width: `2400px`
- Alignment: centered
- Position: center at `x=1800`, `y=1059`

For Pillow-style rendering, center the visual text bounds at:

```text
title_center = (1800, 1059)
```

For browser/CSS rendering, use the same center coordinate with absolute
positioning:

```css
.episode-title {
  position: absolute;
  left: 1800px;
  top: 1059px;
  width: 2400px;
  transform: translate(-50%, -50%);
  color: #ffffff;
  font-family: "Manrope", system-ui, sans-serif;
  font-size: 168px;
  font-weight: 700;
  letter-spacing: 0;
  line-height: 1.1;
  text-align: center;
}
```

## Episode Subtitle Text

Recommended subtitle style:

- Font: Inter
- Weight: `400` / Regular
- Size: `72px`
- Color: `#F4EFE7`
- Letter spacing: `0`
- Line height: `1.35`
- Max width: `2500px`
- Alignment: centered
- Position: center at `x=1800`, `y=1220`

For Pillow-style rendering, center the visual text bounds at:

```text
subtitle_center = (1800, 1220)
```

For browser/CSS rendering:

```css
.episode-subtitle {
  position: absolute;
  left: 1800px;
  top: 1220px;
  width: 2500px;
  transform: translate(-50%, -50%);
  color: #f4efe7;
  font-family: "Inter", system-ui, sans-serif;
  font-size: 72px;
  font-weight: 400;
  letter-spacing: 0;
  line-height: 1.35;
  text-align: center;
}
```

## Useful Reference Values

- Logo/wordmark is already baked into the background.
- Orange line is already baked into the background.
- Original accepted Episode 01 text bounds were roughly:
  - Title: `x=926..2673`, `y=980..1138`
  - Subtitle: `x=926..2673`, `y=1182..1257`
- Keep text out of the lower orange-line area around `y=1780`.

## Font Loading Snippet

```css
@font-face {
  font-family: "Manrope";
  src: url("./fonts/manrope-latin-variable.woff2") format("woff2");
  font-weight: 200 800;
  font-style: normal;
}

@font-face {
  font-family: "Inter";
  src: url("./fonts/inter-latin-variable.woff2") format("woff2");
  font-weight: 100 900;
  font-style: normal;
}
```
