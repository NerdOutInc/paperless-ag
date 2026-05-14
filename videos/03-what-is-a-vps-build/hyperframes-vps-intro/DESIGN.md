# Fullstack AG VPS Intro Design

## Style Prompt

Warm technical explainer for agricultural operators. The video should feel like
Fullstack AG: practical, direct, field-tested, and calm enough for a tutorial.
Use the live Fullstack AG site language as inspiration: dark hero sections,
cream content surfaces, sage field texture, burnt-orange emphasis, numbered
sections, terminal/system cards, and plain operator-focused copy. Avoid generic
cloud-computing visuals.

## Colors

- `#17120f` charcoal: dark hero canvas and terminal surfaces
- `#5f7358` sage: field background and infrastructure accents
- `#f5f1eb` cream: primary text and light panels
- `#d4622b` burnt orange: emphasis, section badges, progress lines
- `#3f2f27` chocolate: deep secondary panels

## Typography

- Manrope: headings, large labels, numbered marks
- Inter: supporting copy and UI labels
- JetBrains Mono: terminal commands, system labels, technical readouts

## Motion Rules

- Use slow contour drift and subtle grain for background life.
- Use `gsap.from()` entrances for every scene element.
- Use smooth push or blur crossfades between scenes; outgoing content stays
  visible when each transition begins.
- Keep motion deliberate and readable. This is a tutorial intro, not an ad.

## What NOT to Do

- Do not use neon blue/purple tech gradients.
- Do not use stock cloud icons as the main visual language.
- Do not make the slides feel like generic SaaS marketing.
- Do not add fake UI that implies a Droplet was created before the real demo.
- Do not overwrite the existing finished MP4; render a review candidate.
