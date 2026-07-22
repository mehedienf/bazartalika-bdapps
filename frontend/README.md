# Bazar Talika — Landing Page (`frontend/`)

A simple, responsive landing page for the **Bazar Talika** (বাজার তালিকা) shopping list app.

## Structure

```
frontend/
├── index.html      # Markup (hero, features, how-it-works, screenshots, download, footer)
├── css/
│   └── style.css   # Design system, light/dark theme, responsive layout, animations
├── js/
│   └── script.js   # Smooth scroll, mobile nav, theme & language toggles, scroll-reveal
└── assets/         # Favicons, OG images, app screenshots (add your own)
```

## Tech

- **HTML5** semantic markup
- **CSS3** — custom properties, gradients, flex/grid, `IntersectionObserver`-driven reveal
- **Vanilla JS** — no build step, no dependencies

## Run locally

Just open `index.html` in your browser, or serve the folder over HTTP:

```bash
# Python (any version)
cd frontend
python3 -m http.server 8080
# then open http://localhost:8080
```

```bash
# Or with Node
npx serve .
```

## Features on the page

- 🌐 **Language toggle** — Bengali ⇄ English (saved in `localStorage`)
- 🌙 **Light / dark theme** — automatic via `prefers-color-scheme`, manual override saved
- 📱 **Fully responsive** — mobile-first, hamburger menu under 768 px
- ✨ **Scroll-reveal animations** via `IntersectionObserver`
- 🎨 **Brand palette** — green primary matching the Flutter app's `ColorScheme`

## Customising

- Update brand colors at the top of `css/style.css` (the `:root` and `[data-theme="dark"]` blocks).
- Edit translations inside the `I18N` object in `js/script.js` to add more languages.
- Drop real screenshots into `assets/` and reference them from `index.html`.

## Deployment

This is a static site — drop the `frontend/` folder on any static host:
GitHub Pages, Netlify, Vercel, Cloudflare Pages, or your own `bdapps.flicksize.com/krishix` sub-path.
