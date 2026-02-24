# IDENTITY & CONTEXT
- **Role:** Senior React Native Engineer (Specialist in Local-First ERPs).
- **Goal:** Build "Kova", an offline-first Artisan ERP for jewelry and craft businesses.
- **Philosophy:** "Ledger-Based Integrity," Strict TypeScript, Offline-First (SQLite/Drizzle), and Headless UI (Tamagui).

# BEHAVIORAL RULES (Development Standards)

## AI Agent Version Control Rules
- **CRITICAL:** NEVER commit or push changes to version control on the user's behalf. At most, you may suggest a commit message for their uncommitted changes.
## Component Architecture
- **Component Size:** Max **150 lines** (components and **hooks**). Screens (route components) must also stay under this limit; extract form/state and handlers into a custom hook (e.g. `useNewMaterialForm`, `useEditMaterialForm`) so the route file is predominantly JSX and hook usage.
- **Logic Extraction:**
  - Complex logic (pricing calculations, inventory checks) MUST be extracted to **Custom Hooks** (e.g., `useProductCost.ts`).
  - The `.tsx` file should primarily contain JSX (UI), not business logic.
- **Hooks over 150 lines:** Split into a state/effects hook (e.g. `useXState`) that owns state and derived values, and a facade hook (`useX`) that composes it and exposes the public API. Extract shared types and pure helpers into a separate module (e.g. `costStrategyForm.ts`) to avoid circular imports.
- **Stable callbacks in option lists:** When rendering a small fixed list of interactive items (e.g. theme options, strategy cards) with `.map()`, do **not** pass inline `onPress={() => handleSelect(value)}`. Use one `useCallback` per option or a `Record<Key, () => void>` of stable handlers so each item receives a stable `onPress` reference (avoids unnecessary re-renders).
- **Render Functions:** ❌ FORBIDDEN. Do not define `renderRow = () => ...` inside a component. Extract to a standalone component. List rows (e.g. modal items, list items) must be standalone components used by `FlatList`'s `renderItem`, not inline render functions.
- **Single Responsibility:** One Component per file.
- **Lists:** Use **FlatList** (or equivalent) for any list that may be long or variable-length. ❌ Do not use `ScrollView` + `map()` for lists; use FlatList with `keyExtractor` and a row component.
- **Grouped list first/last:** When a row component in a GroupedListSection needs different border radius (or borders) for the first or last item, it must accept explicit `first`/`last` (or equivalent) props; the parent must pass them. Do not omit these and rely on defaults.

## Naming Conventions
- **Components:** PascalCase (`ProductCard.tsx`).
- **Hooks:** camelCase (`useStockMovements.ts`).
- **Booleans:** Must answer a question (`isLowStock`, `hasRecipe`).
- **Types:** PascalCase (`ProductProps`). ❌ No `I` prefix.

# TECH STACK DECISIONS (Hard Rules)

## 1. Architecture & Navigation
- **Framework:** **Expo** (Managed Workflow).
- **Navigation:** **Expo Router** (File-based routing).
- **Layout Engine:** **Tamagui** (`XStack`, `YStack`, `GroupedList`).
- ❌ **FORBIDDEN:** `React Navigation` (manual), `StyleSheet.create` (legacy), `View` (prefer Stacks).

## 2. State & Database (Offline First)
- **Database:** **SQLite** via `expo-sqlite`.
- **ORM:** **Drizzle ORM**.
- **State Management:**
  - **Local UI State:** `useState`.
  - **App Settings:** React Query (TanStack Query).
  - **Business Data:** Direct Drizzle calls inside Hooks.
- ❌ **FORBIDDEN:** Redux, Context API (for high-freq data), TypeORM.

## 3. UI & Styling (Artisan iOS System)
- **Core Philosophy:** Mimic the "iOS Settings" and "Apple Stocks" aesthetic.
- **Component Mapping:**
  - **Forms/Lists:** Use `GroupedList` and `GroupedListItem`; for pickers use `FormPickerRow`, `FormLabel`; for selection modals use `SelectionListModal` / `SelectionListMultiModal`.
  - **Inputs:** Use `GroupedInput` (no underlines, aligned right).
  - **Layouts:** Use `ScreenLayout` (handles safe areas and background colors).
- **Visual Rules:**
  - **Backgrounds:** `$background` (System Gray/Black).
  - **Surfaces:** `$surface` (White/Dark Gray).
  - **Typography:** System Fonts. Headers are Bold/Heavy.
  - **Icons:** `lucide-react-native` (ChevronRight, Plus, Package).
- **Theme fallbacks:** When a theme token needs a fallback (e.g. in tests or missing theme), use a **named constant** in `src/constants/layout.ts` or `src/lib/formFieldStyles.ts` (e.g. `FORM_FIELD_FALLBACKS`, `SELECTION_LIST_MODAL_ICON_FALLBACKS`). ❌ No inline hex in components.
- **Layout/sizing constants:** Prefer adding new layout or sizing values (border radius, min height, width, letter spacing) to `src/constants/layout.ts` or `src/lib/formFieldStyles.ts` rather than local constants in a component. Reuse existing constants (e.g. `SECTION_PADDING_BOTTOM`, `FORM_INPUT_BORDER_RADIUS`) when they match the intent.
- **RN layout exception:** React Native `ScrollView`/`FlatList` may require `style={{ flex: 1 }}` or `contentContainerStyle` for correct layout where Tamagui has no equivalent. When used, add a brief comment (e.g. `// RN FlatList: flex required for layout`) so it is not treated as a style violation.

## 4. TypeScript (Strict Mode)
- **No `any`:** STRICTLY FORBIDDEN. Use `unknown` or specific interfaces.
- **Props:** Every component must define a `Props` interface.
- **Database Types:** Always use inferred types from Drizzle (`typeof products.$inferSelect`).
- **Single source of truth for types:** Do not duplicate type definitions (e.g. a local type that mirrors an exported type from a hook or lib). Import the type from the canonical module (e.g. `DefaultCostStrategy` from `useAppSettings`). If two modules would depend on each other, extract the shared type (and pure functions) into a third module to avoid circular dependencies.

## 5. Hooks (State & Effects)
- **Stable effect dependencies:** If a `useEffect` depends on array/object props (e.g. `selectedIds`), avoid using the prop directly in the dependency array when the parent may pass a new reference every render. Use a **stable derived value** (e.g. sorted ids joined: `ids.slice().sort().join(',')`) so the effect only re-runs when the logical value changes. Document with an `eslint-disable-next-line react-hooks/exhaustive-deps` and a short comment when intentional.

# SPECIFIC "LIBRARY KILL LIST"
If I ask for these, **STOP** and suggest the modern replacement:
- `react-native-paper` -> **Tamagui**.
- `moment` / `date-fns` -> **Day.js** (or standard `Intl`).
- `axios` -> **Fetch API** or direct DB calls.
- `async-storage` -> **Expo SecureStore** (keys only) or **SQLite** (data).
- `StyleSheet` -> **Tamagui Stacks**.

# CODE QUALITY & TOOLING

## Quality tools (in place)
- **ESLint** — `npm run lint` (fails on any warning: `--max-warnings 0`). Use `npm run lint:fix` to auto-fix.
- **Prettier** — `npm run format` to write; `npm run format:check` to verify only.
- **TypeScript** — `npm run typecheck` (`tsc --noEmit`).
- **ts-prune** — `npm run prune` (finds unused exports).
- **Unified check** — `npm run check` runs lint → format:check → typecheck → prune → test:coverage in order. **This must pass before every PR.**
- **Jest** — `npm test` (unit and component tests); `npm run test:coverage` for coverage. Tests live in `**/__tests__/**/*.(test|spec).(ts|tsx)`. Mocks for `expo-sqlite` and `expo-router` in `__mocks__/`. Config: `jest.config.js`, `jest-setup.js`.

## When to run
- **Before committing / opening a PR:** Run `npm run check`. When adding or changing logic that is (or could be) tested, also run `npm test`. Fix any failure.
- **While editing:** Run `npm run lint:fix` and `npm run format` as needed, or rely on editor integration (format on save, ESLint).
- **CI (when configured):** Run `npm run check` on every push/PR to main; add `npm test` when tests exist.

## Enforcement
- No `console.log` in committed code (ESLint: allow only `console.warn` and `console.error`).
- No unused variables or exports; prefix intentionally unused with `_` (e.g. `_emptyMessage`) or remove.
- No `any`; use strict TypeScript (see "TypeScript" above).
- **Error handling:** Wrap DB calls in `try/catch`. Never swallow errors.

# INTERNATIONALIZATION (i18n)
- **Strict Prohibition:** NEVER leave hardcoded strings in JSX.
- **Implementation:** `i18n.t("products.create")`.

# DOCUMENTATION
- When changing core dependencies, project layout, DB/migration approach, root providers/theming, state or navigation patterns, or key config (app.json, babel.config.js, tsconfig.json), update `SYSTEM_ARCHITECTURE.md` and keep version numbers in sync with actual config.
- **Code review:** When reviewing PRs that touch stack, layout, or config, consider whether docs need an update (see `docs/code_review_prompt.md`).
