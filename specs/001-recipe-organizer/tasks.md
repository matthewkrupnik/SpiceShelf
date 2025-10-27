# Tasks: Recipe Organizer

**Input**: Design documents from `/specs/001-recipe-organizer/`

## Phase 1: Setup

- [X] T001 Create the project structure in Xcode
- [X] T002 Configure CloudKit for the project
- [X] T003 Set up SwiftLint

---

## Phase 2: Foundational

- [X] T004 Create the `Recipe` model in `SpiceShelf/Models/Recipe.swift`
- [X] T005 Create a `CloudKitService` in `SpiceShelf/Services/CloudKitService.swift` to handle all CloudKit operations

---

## Phase 3: User Story 1 - Manually Add a Recipe (Priority: P1) 🎯 MVP

**Goal**: Allow users to manually add a new recipe.

**Independent Test**: A user can add a recipe, and it will appear in their recipe list.

### Tests for User Story 1

- [X] T010 [US1] Write unit tests for `AddRecipeViewModel` in `SpiceShelfTests/AddRecipeViewModelTests.swift`
- [X] T011 [US1] Write UI tests for the add recipe flow in `SpiceShelfUITests/AddRecipeTests.swift`

### Implementation for User Story 1

- [X] T006 [US1] Create `AddRecipeView` in `SpiceShelf/Views/AddRecipeView.swift`
- [X] T007 [US1] Create `AddRecipeViewModel` in `SpiceShelf/ViewModels/AddRecipeViewModel.swift`
- [X] T008 [US1] Implement the UI for adding a recipe in `AddRecipeView`
- [X] T009 [US1] Implement the logic for saving a recipe in `AddRecipeViewModel`

---

## Phase 4: User Story 2 - View a Recipe (Priority: P1)

**Goal**: Allow users to view the details of a recipe.

**Independent Test**: A user can tap on a recipe in the list and see its details.

### Tests for User Story 2

- [X] T019 [US2] Write unit tests for `RecipeListViewModel` in `SpiceShelfTests/RecipeListViewModelTests.swift`
- [X] T020 [US2] Write UI tests for the recipe list and detail view in `SpiceShelfUITests/RecipeViewTests.swift`

### Implementation for User Story 2

- [X] T012 [US2] Create `RecipeListView` in `SpiceShelf/Views/RecipeListView.swift` to display a list of recipes
- [X] T013 [US2] Create `RecipeListViewModel` in `SpiceShelf/ViewModels/RecipeListViewModel.swift`
- [X] T014 [US2] Create `RecipeDetailView` in `SpiceShelf/Views/RecipeDetailView.swift`
- [X] T015 [US2] Create `RecipeDetailViewModel` in `SpiceShelf/ViewModels/RecipeDetailViewModel.swift`
- [X] T016 [US2] Implement the UI for the recipe list in `RecipeListView`
- [X] T017 [US2] Implement the logic for fetching recipes in `RecipeListViewModel`
- [X] T018 [US2] Implement the UI for the recipe detail view in `RecipeDetailView`

---

## Phase 5: User Story 3 - Edit a Recipe (Priority: P2)

**Goal**: Allow users to edit an existing recipe.

**Independent Test**: A user can edit a recipe and the changes will be saved.

### Tests for User Story 3

- [X] T024 [US3] Write unit tests for the edit functionality in `SpiceShelfTests/EditRecipeTests.swift`
- [X] T025 [US3] Write UI tests for the edit recipe flow in `SpiceShelfUITests/EditRecipeTests.swift`

### Implementation for User Story 3

- [X] T021 [US3] Add an "Edit" button to `RecipeDetailView`
- [X] T022 [US3] Implement the logic for updating a recipe in `CloudKitService`
- [X] T023 [US3] Implement the edit functionality in `RecipeDetailViewModel`

---

## Phase 6: User Story 4 - Delete a Recipe (Priority: P2)

**Goal**: Allow users to delete a recipe.

**Independent Test**: A user can delete a recipe and it will be removed from the list.

### Tests for User Story 4

- [X] T029 [US4] Write unit tests for the delete functionality in `SpiceShelfTests/DeleteRecipeTests.swift`
- [X] T030 [US4] Write UI tests for the delete recipe flow in `SpiceShelfUITests/DeleteRecipeTests.swift`

### Implementation for User Story 4

- [X] T026 [US4] Add a "Delete" button to `RecipeDetailView`
- [X] T027 [US4] Implement the logic for deleting a recipe in `CloudKitService`
- [X] T028 [US4] Implement the delete functionality in `RecipeDetailViewModel`

---

## Phase 7: User Story 5 - Import a Recipe from a URL (Priority: P3)

**Goal**: Allow users to import a recipe from a website.

**Independent Test**: A user can enter a URL from a supported website and the recipe will be imported.

### Tests for User Story 5

- [X] T036 [US5] Write unit tests for `ImportRecipeViewModel` in `SpiceShelfTests/ImportRecipeViewModelTests.swift`
- [X] T037 [US5] Write unit tests for `RecipeParserService` in `SpiceShelfTests/RecipeParserServiceTests.swift`
- [X] T038 [US5] Write UI tests for the import recipe flow in `SpiceShelfUITests/ImportRecipeTests.swift`

### Implementation for User Story 5

- [X] T031 [US5] Create an `ImportRecipeView` in `SpiceShelf/Views/ImportRecipeView.swift`
- [X] T032 [US5] Create an `ImportRecipeViewModel` in `SpiceShelf/ViewModels/ImportRecipeViewModel.swift`
- [X] T033 [US5] Create a `RecipeParserService` in `SpiceShelf/Services/RecipeParserService.swift` to handle parsing recipes from websites
- [X] T034 [US5] Implement the UI for importing a recipe in `ImportRecipeView`
- [X] T035 [US5] Implement the logic for parsing and saving the imported recipe in `ImportRecipeViewModel`

---

## Phase 8: Polish & Cross-Cutting Concerns

- [X] T039 Review and refactor code
- [X] T040 Ensure all UI is consistent with Apple's HIG
- [X] T041 Perform performance testing and optimization
