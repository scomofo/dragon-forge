# Browser Playtest

The browser build under `src/` is the live React/Vite slice. The Godot runtime has separate smoke paths.

## Commands

```powershell
npm test
npm run build
npm audit
npm run playtest:smoke
```

`npm run playtest:smoke` expects a production build in `dist/`. It uses an existing preview/dev server at `http://127.0.0.1:4173/dragon-forge/` when one is running, otherwise it starts `npm run preview`.

## Smoke Coverage

The smoke pass checks desktop `1440x900`, tablet `900x700`, and mobile `390x844`.

It verifies:

- title boot into the game
- Forge navigation
- keyboard movement in the Forge
- no horizontal overflow on Forge, Hatchery, Map, Shop, and Battles
- no browser page errors

Screenshots are written to `.playtest-artifacts/`, which is gitignored.

## Acceptable Warnings

Browser autoplay warnings before the first user gesture are acceptable during manual playtest. The preferred automated smoke result is no page errors after boot.
