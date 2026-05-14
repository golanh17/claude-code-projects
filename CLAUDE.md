# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository overview

A collection of self-contained browser games. Each game is a **single HTML file** with all CSS and JavaScript inline — no build tools, no dependencies, no server required. Open any file directly in a browser.

## Running the games

```powershell
# Open a game in the default browser (Windows)
Start-Process "shooter.html"
Start-Process "tictactoe.html"
```

There is no build step, no package manager, and no test suite. "Does it work?" means opening the file in a browser and playing it.

## Git workflow

Commit frequently with descriptive messages and push to GitHub after every meaningful change:

```powershell
git add <file>
git commit -m "short description of what changed and why"
git push
```

Remote: `https://github.com/golanh17/claude-code-projects`

## Architecture conventions

All games follow the same single-file structure. New games should follow the same pattern.

### Shooter (`shooter.html`) — section layout inside `<script>`

1. **CONSTANTS & CONFIG** — `CANVAS_W/H`, `PALETTE` (shared color tokens), `STATES` enum
2. **INPUT HANDLER** — `Input` singleton: keyboard state map + mouse coords/click, `consumeClick()` / `consumeKey()` for one-frame flags
3. **ENTITY CLASSES** — `Bullet`, `Particle`, `ParticleSystem`, `Enemy` (single class parameterized by `ENEMY_DEFS`), `Player`
4. **LEVEL CONFIG** — `ENEMY_DEFS` (4 types), `LEVELS` (5 levels × 2 waves), `WaveManager` singleton, `spawnEnemyAtEdge()`
5. **RENDERER** — pure draw functions only (`drawBackground`, `drawPlayer`, `drawEnemy`, `drawBullet`, `drawParticles`, `drawHUD`, `drawCursor`, `drawMenu`, `drawLevelTransition`, `drawGameOver`)
6. **GAME STATE MACHINE** — `Game` singleton with `setState()`, `startGame()`, `advanceWave()`, `updateHighScore()`
7. **GAME LOOP** — canvas init, `Input.init()`, `requestAnimationFrame` loop with capped delta time (`dt = min(Δms/1000, 0.05)`)

### Rendering rules

- All sprites are drawn with `ctx.fillRect` only — no `arc`, no image files.
- `ctx.imageSmoothingEnabled = false` is set at startup.
- Round all entity positions with `Math.round()` before drawing to avoid sub-pixel blur.
- Use `ctx.save()` / `ctx.translate()` / `ctx.rotate()` / `ctx.restore()` for rotated sprites (gun, rusher enemy).
- Always reset `ctx.globalAlpha = 1` after drawing particles.

### Game loop pattern

```js
// player.update() returns a new Bullet when firing, null otherwise
const newBullet = player.update(dt, Input);
if (newBullet) { bullets.push(newBullet); particles.spawnMuzzleFlash(...); }
```

State transitions are checked at the end of the PLAYING case: `!player.alive → GAME_OVER`, `WaveManager.waveDone → advanceWave()`.

### High score persistence

`localStorage.getItem/setItem('sectorZeroHigh')` — loaded once on page init, written on game over.

### Color palette

All colors are defined in `PALETTE` at the top. Add new colors there; never use raw hex strings inside draw functions.
