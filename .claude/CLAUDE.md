# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

A monthly expense calculator: a single static page, `index.html`, with inline CSS and vanilla JS. There is no build step, package manager, linter or test suite. To run it, open `index.html` in a browser. The only external dependency is Google Fonts (Sarabun, IBM Plex Mono).

The UI text is in Thai (`lang="th"`), and currency is formatted as `฿` with `toLocaleString('th-TH')`. New UI strings should also be in Thai.

## Architecture

**Two "pages" in one document.** `#page-home` (the profile grid) and `#page-detail` (the editor for one profile) are toggled by `showPage()` through the `.active` class. Two modal overlays (`#modal` for a new profile, `#cat-modal` for a new category) and a `#toast` sit outside both pages.

**Persistence.** All data is a single JSON array in `localStorage` under the key `expense_profiles_v2`, held in memory as the global `profiles`. Shape:

```
{ id: 'p_<ts>', name, salary: number,
  categories: [{ id: 'cat_...', name, rows: [{ key, label, value }] }] }
```

If you change the shape, keep old stored data loading (for example, `renderProfile` falls back to `defaultCategories()` when `categories` is missing), or bump the key.

**The DOM is the source of truth while editing.** When a profile is opened, `renderProfile()` builds category blocks and rows from the stored object. After that, edits live only in the DOM:
- `calc()` re-reads every `.category-block` / `.num-input` on each input to update the summary and the result banner.
- `saveProfile()` writes back to `profiles` via `collectCategories()`, which scrapes the DOM, then calls `saveAll()`. Saving happens only when the save button is clicked. `goHome()` throws away unsaved edits.
- The home cards compute the remaining balance from the *stored* data (`calcRemain`), not from the DOM.

**Dynamic rows and categories.** `makeCategoryBlock()` and `makeRow()` build elements tagged with `data-cat-id` / `data-key`. A profile must keep at least 1 category and every category at least 1 row (enforced in `deleteCategory` / `delRow`). Number inputs are `type="text"` with `inputmode="decimal"`. `attachValidation()` restricts keystrokes to digits and one `.`, and triggers `calc()`.

**Escaping.** Any user text inserted through `innerHTML` or template strings must go through `escHtml()`.

## Known quirk

`renderProfile()` calls `attachValidation()` on the static `#salary` input every time a profile opens, so its listeners pile up (`calc()` runs once more for each profile opened). This is harmless but worth fixing if you touch that code.
