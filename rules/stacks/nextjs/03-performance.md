# Next.js Performance

Rules that keep the app fast on a median laptop over a 4G
connection. Core Web Vitals are the bar — LCP under 2.5 s, INP
under 200 ms, CLS under 0.1.

---

## Server Components first

- **Server Components are the default.** Every `"use client"`
  is a deliberate choice that costs JS bundle. A client
  component that renders static content is a bug.
- **Keep the client boundary as deep in the tree as possible.**
  A client-only `LikeButton` does not require the surrounding
  `Article` to be a client component.
- **Do not pass non-serialisable props across the boundary.**
  Functions and class instances cannot cross; if you need to,
  redesign.

## Streaming and loading

- **Use `loading.tsx` for route-level skeletons**, not a
  client-side spinner wrapping the entire page.
- **Use `<Suspense>` for component-level streaming** of slow
  server data. A slow widget should not block the shell.
- **Do not await in series what can be awaited in parallel.**
  `Promise.all` for independent fetches; sequential `await`s
  are almost always wrong on a page.

## Caching

- **Every `fetch()` declares its cache behaviour.** Per
  `01-constraints.md`. Default-caching by accident is how
  stale data ships to production.
- **Use `revalidateTag` over `revalidatePath`** when you can —
  tags are surgical, paths are a sledgehammer.
- **Do not disable the Data Cache (`cache: 'no-store'`)
  reflexively.** If the data is public and changes infrequently,
  caching it is correct. Measure, then decide.

## Images

- **Images use `next/image`.** Raw `<img>` tags are rejected in
  review except for inline SVG and data URIs.
- **Every `<Image>` declares explicit `width` and `height`** (or
  `fill` with a sized container) so CLS stays at zero.
- **Remote image domains are whitelisted in `next.config.js`.**
- **Prioritise above-the-fold images** with `priority`, and
  only those — priority on every image defeats the point.

## Fonts

- **Fonts use `next/font`** (`next/font/google` or
  `next/font/local`). Direct `<link>` tags to Google Fonts are
  rejected — they cause an extra round trip and CLS.
- **Self-host any custom font file.** Third-party font CDNs
  outside `next/font` are not used without an ADR.

## Bundle hygiene

- **Audit bundle size before shipping.** `next build` output
  and `@next/bundle-analyzer` are the sources of truth.
- **Dynamic-import heavy client-only code** with
  `next/dynamic`. A chart library or rich editor does not
  belong in the initial bundle of a page that does not render
  it above the fold.
- **Avoid barrel files that import the world.** A `common/index.ts`
  that re-exports every component drags unreferenced modules
  into the bundle when tree-shaking fails. Import from the
  specific module.

## Rendering and memoization

- **Do not reach for `React.memo`, `useMemo`, or `useCallback`
  reflexively.** Measure first. Gratuitous memoization adds
  cost.
- **A client component that re-renders on every parent render
  is fine unless a profile says otherwise.** The fix is usually
  a structural change, not a memo wrap.

## Third-party scripts

- **Third-party scripts load via `next/script`** with an
  appropriate `strategy` (`afterInteractive`, `lazyOnload`).
  A `<script>` tag in a layout is rejected in review.
- **Every third-party script has an owner and a purpose.**
  Analytics and tag managers accrete; prune them.

## Measuring

- **Claims about performance come with a measurement.** "Feels
  faster" is not evidence. Use Lighthouse CI, Vercel Speed
  Insights, or the browser's performance panel and paste the
  numbers into the PR.
