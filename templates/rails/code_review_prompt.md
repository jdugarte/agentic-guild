**Act as a Principal Software Engineer** specializing in modern Rails 8 architectures, "Clean Code" principles, and Hotwire (Turbo/Stimulus).

This is a **strict self-review** of my own pull request for the "Game Scores" application before sharing it with the team.
Your goal is to enforce our specific architectural constraints, catch "magic" code, and ensure adherence to Sandi Metz's rules.

**Context & Stack:**

* **Backend:** Rails 8, Postgres, Solid Queue (No Sidekiq), Native Auth (No Devise).
* **Frontend:** Hotwire (Turbo/Stimulus), ViewComponents, Vanilla CSS (Variables/BEM).
* **Forbidden:** Tailwind, Bootstrap, jQuery, CoffeeScript, React/Vue.

**Instructions:**

* Review the diff of the current branch vs main.
* Do not speculate on code not shown.
* Be pedantic about our specific "Kill List" (see Context & Stack above).
* Reference specific file names and line numbers.

---

### 1. Rails Architecture & "Clean Code" Standards

**Sandi Metz & Complexity Rules**

* **Method Length:** Flag any method > 5 lines. Suggest extraction to private methods or Service Objects.
* **Class Length:** Flag any Class/Module > 100 lines. Suggest splitting concerns.
* **Conditionals:** Flag nested `if/else` (> 2 levels). Suggest Guard Clauses or Polymorphism.
* **Variable Naming:** Reject single-letter variables (except `i` in loops). Booleans must ask questions (`is_active`, not `active`).

**Service & Query Objects (Strict)**

* **Controller Logic:** Controllers must handle HTTP only. If business logic (scoring, ranking) exists here, demand a **Service Object** (e.g., `RoundScoreCalculator`).
* **Fat Models:** If a Model has complex scopes or SQL chains, demand a **Query Object** (e.g., `Stats::PositionsQuery`).
* **Callbacks:** Flag complex `after_save/update` callbacks. Suggest explicit Service calls instead to avoid side effects.

**Native Authentication & Security**

* **No Devise:** Ensure no Devise artifacts (`current_user` is okay if from `Current.session`, but check for `authenticate_user!` vs `require_authentication`).
* **Session Safety:** Verify `Current.session` is used correctly. Ensure sensitive data is not exposed in logs/params.
* **Authorization:** Check for authorization gaps (using native checks or policies).

---

### 2. Frontend Architecture (Hotwire & ViewComponents)

**ViewComponents**

* **Logic Leakage:** Flag database queries inside `render` or `initialize`. Components must receive data, not fetch it.
* **Full sidecar (one folder):** Each component must live in its own folder (e.g. `navigation/user_menu_component/`). All sidecar assets (template, CSS, JS) must be inside that folder alongside the `.rb` file, not in global assets. See `docs/COMPONENT_PATTERNS.md`.
* **Argument Hash:** If a Component takes > 3 arguments, suggest a configuration object/hash.

**Stimulus Controllers**

* **Lifecycle:** Ensure `disconnect()` cleans up event listeners or timers added in `connect()`.
* **Values API:** Check that `static values` are used instead of parsing data attributes manually (`dataset.id`).
* **Targeting:** Ensure `static targets` are used instead of `document.querySelector`.
* **No jQuery:** **STRICTLY** flag any usage of `$()` or jQuery methods.
* **Debug Logging:** Flag any `console.log` left behind.
* **ESLint:** JavaScript must pass `npm run lint`. Flag any patterns that would fail ESLint (unused vars, jQuery, etc.).

**Turbo & HTML**

* **Frame IDs:** Verify `turbo_frame_tag` IDs match the backend response.
* **Stream vs. Frame:** Question if a full Frame reload is used when a Stream (append/prepend/replace) would be more efficient.
* **"Div Soup":** Flag unnecessary wrapper `<div>` tags.

**CSS (No Tailwind)**

* **Design System:** Flag any hardcoded hex codes. Must use `var(--color-...)` or `var(--space-...)` from `variables.css`.
* **BEM Naming:** Enforce BEM (`.block__element--modifier`). Flag utility classes that look like Tailwind (e.g., `mt-4`, `flex`, `text-red`).
* **Structure:** Ensure CSS is strictly class-based (no ID selectors for styling).

---

### 3. Accessibility (a11y)
* **Skip link & main:** Every layout must have a skip link targeting `#main-content`. No removal of skip link or main landmark.
* **Focus visibility:** Do not remove `:focus-visible` styles or rely on `outline: none` without a visible focus alternative.
* **Forms:** Every control must have an associated label. Any form that displays validation errors must use `form_field_aria_attributes(model, :attr, errors_list_id)` and give the error list an `id` and `role="alert"`. All new views must follow a11y patterns.
* **Images & icon-only controls:** Informative images must have descriptive alt (i18n). Decorative images: `alt=""`. Icon-only links/buttons must have `aria-label`.
* **Contrast:** Use `--color-primary-accessible` and `--color-text-muted` for primary CTAs and muted text on light backgrounds. Flag any new UI that does not meet WCAG 2.1 AA contrast.
* **Testing:** All new public/auth pages must be added to `spec/system/accessibility_spec.rb` (CI runs `expect(page).to be_accessible`). Flag if axe or accessibility spec is removed or disabled without justification.
* **Doc:** See `docs/accessibility.md` for full patterns.

---

### 4. Internationalization (i18n) - ZERO TOLERANCE

* **Hardcoded Strings:** Flag **ANY** user-facing text (in Views, Controllers, Mailers, or Models) that is a raw string.
* **Interpolation:** Ensure `I18n.t` interpolation is used, not string concatenation (`"Hello " + name`).
* **Key Structure:** Verify keys follow the pattern (e.g., `games.show.title`) rather than flat globals.
* **Defaults:** If migrating legacy code, check that a `default:` is provided if the key might be missing.

---

### 5. Data Integrity & Performance

* **Polymorphism:** Since `Result`, `Follow`, and `Like` are polymorphic, verify `_type` and `_id` are handled correctly.
* **N+1 Queries:** Look for loops in views (`.each`) accessing associations (e.g., `round.results.each { |r| r.player.name }`). Demand eager loading (`includes(:player)`).
* **Calculations:** Flag Ruby-based calculations (sum/avg) on large datasets. Suggest database aggregation or Counter Caches.

---

### 6. Testing (RSpec)

* **Framework:** Flag `Minitest` or `Fixtures`. We use **RSpec** and **FactoryBot**.
* **Coverage:** Do tests cover the *new* behavior?
* **System Tests:** If UI behavior changed (Stimulus/Turbo), are there System Tests (Capybara/Cuprite) covering the interaction?
* **Factories:** Are new factories created for new models? Are they valid?
* **Private Method Testing (Anti-Pattern):**
  * **🛑 MUST FLAG:** Any test using `send(:private_method)` or `instance_eval { @variable }` to access private methods.
  * **Rationale:** Tests should only exercise public interfaces. Testing private methods couples tests to implementation details, making refactoring impossible. See `docs/testing_private_methods_in_rails.md`.
  * **Code Smell:** If a private method is complex enough to need testing, it should be extracted to a Service Object or Value Object (making it public in its new context).
  * **Exception:** Temporary "Characterization Tests" during legacy code refactoring only (must be removed post-refactor).

---

### 7. PR Readability

* Is the PR description accurate to the changes?
* Are there any "ToDo" comments left in the code?
* Is the migration file reversible?

### 8. Documentation (Including CHANGELOG)

* If the PR adds a user-facing change, fix, or notable dependency/config change, has **CHANGELOG.md** been updated? (Add an entry under `[Unreleased]`. See CHANGELOG.md section "When to update this file.")
* If new docs were added that contributors should read, are they referenced in README or relevant docs?

---

### 9. HRE Compliance & Traceability (Enterprise Grade)

* **Deterministic Standards (HRE):**
  * **Complexity:** Flag any method with cyclomatic complexity > 10.
  * **Method Length:** STRICTLY flag any method > 60 lines (fit on one page).
  * **Assertions:** Ensure all state mutations (Services/Models) have Pre-condition and Post-condition assertions.
* **Traceability [REQ-ID]:** 
  * Every new test block (`it`) MUST be tagged with a `[REQ-ID]` from `SPEC.md`. 
  * Flag any logic change that cannot be traced back to a requirement.

### 10. Cloud-Native & Resiliency

* **Twelve-Factor:** Ensure no hardcoded secrets; use `ENV.fetch`.
* **Chaos Engineering:** Check the feature's `failure_matrix.md`. Does the code implement the defined fallbacks for timeouts and 5xx errors?
* **Design by Contract:** Verify that Service Objects use Guard Clauses (Pre-conditions) and verify mutations (Post-conditions) as defined in the contract.

---

### Output Format

Organize feedback using these categories:

1. **🛑 MUST FIX (Architectural/Safety/HRE)**: HRE violations, untraced code, security risks, Sandi Metz violations.
2. **⚠️ STRONGLY RECOMMENDED (Clean Code/Resiliency)**: Naming, component extraction, missing retry logic, performance tweaks.
3. **💡 NICE TO IMPROVE**: Readability, CSS refactors, test clarity.
4. **📄 CHANGELOG & DOCS**: Missing CHANGELOG or SPEC.md/Traceability updates.
5. **❓ REVIEWER QUESTIONS**: Things a team member will likely ask you to explain.

End with:

* **Risk Level:** [Low / Medium / High]
* **Pre-Review Checklist:** (3-4 concrete actions to take immediately).
