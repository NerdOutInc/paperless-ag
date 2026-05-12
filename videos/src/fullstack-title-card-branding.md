# Fullstack AG Title Card Branding

Use the HTML template as the source of truth for Fullstack AG title cards:

```text
videos/src/fullstack-title-card-template.html
```

The template includes the canvas size, background image, font loading, text
positions, typography, and placeholder title/subtitle. It is intentionally kept
next to its dependencies so the relative paths already work:

```text
videos/src/fullstack-ag-title-card-background-3600x2160.png
videos/src/fonts/manrope-latin-variable.woff2
videos/src/fonts/inter-latin-variable.woff2
```

Do not copy CSS values into this markdown file. If the card styling changes,
update the HTML template only so these instructions do not go stale.

## Workflow

1. Copy `videos/src/fullstack-title-card-template.html` for the episode.
2. Replace the placeholder title and subtitle in the copied HTML.
3. Render the copied HTML to a `3600x2160` PNG.
4. Show the still PNG for approval before re-rendering a full screencast.

Keep the episode text in the central clear area between the logo/wordmark and
the orange line. The background PNG already includes the green gradient,
topographic texture, wheat/field-row decoration, Fullstack AG logo treatment,
and orange line, so do not rebuild those pieces or use the old generic skill
title-card assets.

## Editing Notes

- Preserve the template's existing fonts, weights, scale, and positioning unless
  the request is specifically a visual redesign.
- For wording or line-break changes, edit only the text and requested line
  breaks whenever possible.
- Compare against an accepted card from the same series before changing the
  video.
- For Episode 05-style titles, keep `on DigitalOcean` together on the second
  line when requested.

Accepted Episode 05 reference:

```text
videos/05-how-to-install-on-digital-ocean-build/cards/intro-how-to-install-on-digital-ocean.png
```
