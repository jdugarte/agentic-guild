**Act as a Principal Mobile Engineer** specializing in React Native, TypeScript, Tamagui, and Offline-First Architectures.

This is a **strict self-review** of my own changes for this project.
Your goal is to enforce architectural strictness, catch performance killers (re-renders), and ensure TypeScript safety.

**Context & Stack:**

- **Core:** React Native (Expo), TypeScript.
- **Data:** Drizzle ORM (SQLite), React Query (app settings only).
- **UI:** Tamagui (XStack, YStack, Text, Button, Input); tokens from `tamagui.config.ts`; no StyleSheet, no inline `style={{}}`.
- **Quality:** ESLint (TypeScript, Prettier, React Hooks, React Native, Expo), Prettier, typecheck (`tsc --noEmit`), ts-prune. Run **`npm run check`** before PR (runs lint → format:check → typecheck → prune → test:coverage). See `.cursorrules` § Code quality & tooling.
- **Tests:** Jest + jest-expo + React Native Testing Library; mocks for expo-sqlite and expo-router in `__mocks__/`; tests in `**/__tests__/**/*.(test|spec).(ts|tsx)`. Run **`npm test`** (and **`npm run test:coverage`** when relevant) before PR when adding or changing tested code.

**Instructions:**

- Review the provided code.
- Be pedantic about **Performance** (React Renders) and **Type Safety**.
- Reference specific file names and line numbers.

---

### 1. React Architecture & "Clean Code"

**Component Structure**

- **Logic/UI Separation:** Flag any component or **hook file** > 150 lines. Suggest extracting logic into a custom hook (e.g., `useProductForm.ts`); for oversized hooks, suggest splitting into a state/effects hook + facade hook, or extracting shared types and pure helpers to a third module to avoid circular deps.
- **Inline Definitions:** Flag any functions or objects defined _inside_ the render body without `useCallback` or `useMemo`. (e.g., passing `() => doSomething()` directly to a prop causes re-renders). **Option lists:** When mapping over a small set of options (e.g. theme, cost strategy) and each item has `onPress={() => handler(value)}`, flag it; recommend a handlers map or one `useCallback` per option so each item gets a stable callback reference.
- **Prop Drilling:** Flag passing props down > 2 levels. Suggest using Composition (passing `children`) or a small store for global state.
- **Circular dependencies:** Flag two modules that import from each other. Recommend extracting shared types and pure functions into a third module (e.g. `costStrategyForm.ts`) that both depend on.

**Function Size & Readability**

- **Readability over terseness:** Flag clever or terse code that hurts clarity. Prefer clear, readable code and extraction into well-named helper functions.

**Hooks (The "Service Objects" of React)**

- **Dependency Arrays:** Check every `useEffect`, `useCallback`, and `useMemo`. Are dependencies missing? Are unstable objects (arrays/objects) used as dependencies causing infinite loops?
- **Stable dependencies:** When an effect depends on array/object props (e.g. `selectedIds`), flag if the prop is used directly and the parent may pass a new reference each render (causing unnecessary or repeated effect runs). Prefer a stable derived value (e.g. `ids.slice().sort().join(',')`) in the dependency array, with an eslint-disable + comment if intentional.
- **Side Effects:** `useEffect` should strictly be for synchronization. Logic driven by user events (button clicks) should be in **Event Handlers**, NOT `useEffect`.

---

### 2. TypeScript & Data Safety (Strict)

**Type Hygiene**

- **The `any` Ban:** **STRICTLY** flag any usage of `any`. Demand a proper Interface or `unknown`.
- **Prop Definitions:** Ensure all Component props are typed.
- **Single source of truth:** Flag local types that duplicate an existing exported type from another module (e.g. a local `CostStrategyKey` that mirrors `DefaultCostStrategy` from a hook). Recommend importing from the canonical module.
- **Null Checks:** Are nullable database fields handled? (e.g., `product.notes` might be `null`, does the UI crash?).

**Database (Drizzle/SQLite)**

- **Queries:** Are queries efficient? Flag "Select All" on large tables without pagination logic.
- **Mutations:** After mutations, does the UI refresh? (e.g. `refreshTrigger`, `refresh()`, or React Query invalidation.)
- **Raw SQL:** Flag any use of `sql` template strings unless absolutely necessary. Use Drizzle's query builder.

---

### 3. UI & Performance (Tamagui)

**Styling & Theme**

- **Tokens only:** Flag any raw numbers (margins/padding) or Hex codes. They must use Tamagui tokens (e.g. `$background`, `$4`, `$md`) or named constants in `src/constants/layout.ts` / `src/lib/formFieldStyles.ts`. Theme fallbacks (e.g. when `theme.iosGreen?.val` is missing) must live in a shared constant (e.g. `FORM_FIELD_FALLBACKS`, `SELECTION_LIST_MODAL_ICON_FALLBACKS`), not inline hex in the component. **Reuse:** When a component introduces a local constant for padding, margin, or sizing that matches an existing constant in `layout.ts` or `formFieldStyles.ts`, flag it and recommend using the existing constant (e.g. `SECTION_PADDING_BOTTOM` instead of a local `SCROLL_PADDING_BOTTOM = 24`).
- **No StyleSheet / inline style:** Flag `StyleSheet.create` or `style={{ ... }}`. Demand Tamagui props (`p="$4"`, `bg="$background"`). **Exception:** React Native `ScrollView`/`FlatList` may require `style={{ flex: 1 }}` or `contentContainerStyle` for layout; require a brief comment (e.g. `// RN FlatList: flex required for layout`) so it is not flagged.
- **List Performance:** Ensure `FlatList` or equivalent is used for long lists. **FORBID** usage of `map()` to render long lists inside a `ScrollView` (performance killer). List rows must be standalone components (e.g. used in `renderItem`), not inline render functions.
- **Grouped list first/last:** When a row component in a GroupedListSection supports first/last styling (e.g. border radius) but the parent does not pass `first`/`last` (or equivalent) props, flag it as a visual bug risk (e.g. first row may lack top border radius).

**UX & Offline**

- **Loading States:** Is there a skeleton or spinner while SQLite is querying?
- **Error Boundaries:** If the DB fails, does the app crash or show a "Retry" or error state?

---

### 4. Internationalization (i18n) - ZERO TOLERANCE

- **Hardcoded Strings:** Flag **ANY** user-facing text inside JSX (`<Text>Inventory</Text>`).
- **Interpolation:** Ensure `i18n.t` is used with parameters, not string concatenation.

---

### 5. Documentation & Config

- **When this PR touches stack, layout, or config:** Consider whether `SYSTEM_ARCHITECTURE.md` or other core docs need an update.
- **Trigger an update if the PR:**
  - Adds or upgrades a core dependency (Expo, React Native, Drizzle, Tamagui, React Query, etc.).
  - Adds or changes test setup (Jest, jest-expo, RNTL, mocks, test scripts/config).
  - Changes project layout (new top-level folders, moved files).
  - Changes DB client, migrations, or schema patterns.
  - Changes root providers, Tamagui config, or theming.
  - Changes state or navigation (React Query usage, Stack/Tabs).
  - Changes app.json, babel.config.js, or tsconfig.json in a meaningful way.
- **Action:** If any of the above apply, add a review item to update the relevant doc. Only list this when the change actually affects the doc.

---

### 6. HRE & Resiliency (Mobile First)

- **HRE Compliance:**
    - **Complexity:** Flag hooks/helpers with cyclomatic complexity > 10.
    - **Length:** Flag functions/hooks > 60 lines.
    - **Assertions:** Ensure data-mutating hooks have input validation (Pre-conditions).
- **Traceability:** Every `test` block MUST be tagged with a `[REQ-ID]`.
- **Offline Resiliency:** Check `failure_matrix.md`. Does the UI handle offline states (local cache) and API timeouts gracefully?

---

### Output Format

Organize feedback using these categories:

1. **🛑 MUST FIX (Audit / Safety)**: HRE violations, untraced code, `any` types, hardcoded strings.
2. **⚠️ STRONGLY RECOMMENDED (Performance/Resiliency)**: Offline fallbacks, re-render risks, component extraction.
3. **💡 NICE TO IMPROVE**: Naming, file structure, code readability.
4. **📄 Docs/Config**: Updates for `SPEC.md`, `failure_matrix.md`, or stack/layout docs.
5. **Quality gate**: Ensure **`npm run check`** and **`npm test`** pass.

**Only list actionable items.**

End with:

- **Risk Level:** [Low / Medium / High]
- **Pre-Review Checklist:** (3 concrete actions for me).
