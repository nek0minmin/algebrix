---
name: brutal-reviewer-and-epic-planner
description: >-
  Brutally reviews code, UI/UX, and architecture for Algebrix, and converts project requirements,
  assignments, or feature requests into structured Epics with User Stories (with acceptance criteria)
  and actionable atomic engineering tasks.
---

# Brutal Reviewer & Agile Epic Planner Skill

This skill operates in two synchronized modes:
1. **Brutal Auditor**: Rigorously and unapologetically critiques pull requests, screen implementations, state providers, and animations against educational efficacy, design tokens, responsive layout, and testing invariants.
2. **Agile Architect**: Decomposes high-level assignments, fuzzy user requests, or new game modes into structured **Epics**, **User Stories** (with Gherkin Acceptance Criteria), and **Atomic Engineering Tasks**.

---

## Part 1: The 7-Pillar Brutal Review Rubric

When reviewing any feature or code change in Algebrix, grade each of the 7 pillars as **PASS**, **WARN**, or **FAIL**:

```
+-------------------------------------------------------------------------------+
|                             7-PILLAR REVIEW MATRIX                            |
+---+----------------------------+----------------------------------------------+
| 1 | Pedagogical Efficacy       | Does it build mental models or enable guess? |
| 2 | Tactile UI/UX Polish       | Are animations springy, purposeful & fluid?  |
| 3 | Atomix Brand Fidelity      | Exact color tokens, Nunito fonts, Xy mascot? |
| 4 | Flutter Clean Architecture | Proper Provider separation & no leaked state?|
| 5 | Test Rigor & Pump Safety   | Zero pumpAndSettle timeouts & 100% passes?   |
| 6 | Offline & API Resilience   | Graceful degradation when network drops?     |
| 7 | Zero-Overflow Responsiveness| 320px screen check with no yellow stripes?   |
+---+----------------------------+----------------------------------------------+
```

### Review Checklist & Inspection Points

1. **Pedagogical Efficacy & Scaffolding**:
   - Is there a post-solve reasoning check?
   - Are visual metaphors accurate to the math domain?
   - Are distractors pedagogically meaningful (e.g., inverse operations, common misconception values)?

2. **Tactile UI/UX & Micro-Animations**:
   - Do interactive objects give immediate visual feedback on hover/drag?
   - Is spring physics applied (`Curves.easeOutBack`, `Curves.elasticOut`)?
   - Are touch targets at least 48x48dp?

3. **Atomix Brand Fidelity**:
   - Are `AppColors` used instead of hardcoded hex values or generic Flutter colors?
   - Are constructor parameters correct (`PrimaryButton(label:)`, `SecondaryPageAppBar(supportingText:)`, `RootPageHeader(subtitle:)`)?
   - Is Xy mascot showing appropriate emotional state?

4. **Flutter Architecture & State Management**:
   - Are business logic, math evaluations, and API calls isolated inside services and providers?
   - Is `notifyListeners()` called only when state actually transitions?
   - Are collections exposed as `List.unmodifiable(...)`?

5. **Test Rigor & Pump Safety**:
   - Are infinite repeating animations guarded with `!WidgetsBinding.instance.runtimeType.toString().contains('Test')`?
   - Does `flutter test` pass with 0 failures across all test suites?

6. **Offline & API Resilience**:
   - Is there a local fallback engine if HTTP GET / POST fails or times out?
   - Does the UI display connection status badges gracefully?

7. **Zero-Overflow Responsiveness**:
   - Are formula expressions wrapped in `FittedBox`?
   - Are row labels wrapped in `Flexible` with `TextOverflow.ellipsis`?

---

## Part 2: Agile Epic, User Story & Task Decomposition Framework

When given a new assignment, feature request, or problem statement, convert it into this standardized hierarchy:

### Format Template

```markdown
# Epic [ID]: [Epic Title]
**Target Objective**: [Clear 1-2 sentence statement of educational and engineering goal]
**Target Module**: `lib/screens/[module]` | `lib/core/providers/[module]` | `lib/services/[module]`

---

## User Story [ID].1: [Story Title]
**As a** [learner / student / user],  
**I want to** [action / interaction],  
**So that** [educational benefit / mental model reinforcement].

### Acceptance Criteria (Gherkin Format):
- **Scenario 1: [Scenario Name]**
  - **Given** [initial state / screen context]
  - **When** [user performs action / interaction]
  - **Then** [expected UI state / feedback / animation]
- **Scenario 2: [Edge / Failure Case]**
  - **Given** [error state / offline context]
  - **When** [user triggers operation]
  - **Then** [fallback mechanism activates / graceful notice displayed]

### Engineering Tasks:
- [ ] `Task [ID].1.1`: [Domain / Model / Service implementation]
- [ ] `Task [ID].1.2`: [State Provider management and logic]
- [ ] `Task [ID].1.3`: [Interactive Widget & animation UI construction]
- [ ] `Task [ID].1.4`: [Unit and Widget test suite creation with pump verification]
```

---

## Part 3: Example Output Reference (Root Finder Feature)

```markdown
# Epic 03: Interactive Quadratic Root Finder Arena
**Target Objective**: Implement visual quadratic factoring and parabola vertex tracking where learners drag binomial factors to reveal roots on a coordinate plane.

## User Story 03.1: Binomial Factor Drag-and-Drop
**As a** high school algebra learner,  
**I want to** drag candidate root factors `(x - r1)` onto the factorization slots,  
**So that** I understand that the roots of $ax^2 + bx + c = 0$ occur where the factors equal zero.

### Acceptance Criteria:
- **Scenario: Valid Factor Placement**
  - **Given** equation $x^2 - 5x + 6 = 0$ is presented
  - **When** user drags `(x - 2)` and `(x - 3)` into the factor slots
  - **Then** the parabola curve animates through $(2,0)$ and $(3,0)$ with a celebratory +30 XP pop-up.

### Engineering Tasks:
- [ ] `Task 03.1.1`: Add quadratic problem generator in `math_api_service.dart`.
- [ ] `Task 03.1.2`: Create `RootFinderProvider` managing parabola points and factor slots.
- [ ] `Task 03.1.3`: Build `RootFinderScreen` with `CustomPainter` coordinate plane and draggable factor cards.
- [ ] `Task 03.1.4`: Write `root_finder_test.dart` asserting factor validation and coordinate graph rendering.
```
