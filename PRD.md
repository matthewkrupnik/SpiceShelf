# Project Requirements Document: SpiceShelf

**App Name**: SpiceShelf
**Platform**: iOS 26.0+
**Target Device**: iPhone (Optimized for iPhone 17)
**Date**: 2026-01-16
**Status**: Active Development

## 1. Project Overview
SpiceShelf is a personal recipe management application designed for iOS. It allows culinary enthusiasts to organize their recipe collection in a single, accessible digital location. Users can manually input their own family recipes or import them directly from web URLs. The app emphasizes data privacy and synchronization across devices using iCloud (CloudKit).

## 2. User Scenarios

### User Story 1: Manage Recipe Collection (Priority: P1)
**Description**: As a user, I want to view a list of all my saved recipes so that I can quickly decide what to cook.
**Acceptance Scenarios**:
1. **Given** the app is launched, **When** data is loaded, **Then** a list of recipes is displayed with titles, photos (if available), and preparation times.
2. **Given** a recipe in the list, **When** I tap it, **Then** I see the full details (ingredients, instructions, photo).
3. **Given** a recipe, **When** I swipe to delete, **Then** the recipe is removed from the list and storage.

### User Story 2: Manual Recipe Entry (Priority: P1)
**Description**: As a user, I want to manually add or edit a recipe to save my personal creations.
**Acceptance Scenarios**:
1. **Given** the "Add" button, **When** tapped, **Then** a form appears to enter Title, Ingredients, Instructions, Prep Time, Servings, and optional Photo.
2. **Given** an existing recipe, **When** I edit details and save, **Then** the changes are reflected in the list immediately.

### User Story 3: Import from Web (Priority: P2)
**Description**: As a user, I want to paste a URL to automatically extract recipe details so I don't have to type them manually.
**Acceptance Scenarios**:
1. **Given** the Import view, **When** I paste a valid recipe URL and tap "Import", **Then** the app attempts to parse the site and pre-fill the recipe form (including photo and servings if available).
    *   *Note*: Currently implemented as a stub; requires full parser implementation.

### User Story 4: Adjust Portions & Scale (Priority: P2)
**Description**: As a user, I want to adjust the number of servings a recipe makes so that the ingredient quantities scale automatically for my needs.
**Acceptance Scenarios**:
1. **Given** a recipe detail view with a default serving size (e.g., 4), **When** I change the servings to 8, **Then** all ingredient quantities displayed are doubled.
2. **Given** a scaled recipe, **When** I reset or leave the view, **Then** the recipe reverts to its original stored serving size (or persists user preference if desired - strictly strictly display-only scaling for now unless "Edit" is chosen).

### User Story 5: Recipe Photos (Priority: P2)
**Description**: As a user, I want to see photos of my recipes to make the collection visually appealing and easier to identify.
**Acceptance Scenarios**:
1. **Given** the Add/Edit view, **When** I tap the photo placeholder, **Then** I can select an image from my Photo Library or take a new one.
2. **Given** a saved recipe with a photo, **When** I view the list, **Then** a thumbnail of the recipe is displayed.

## 3. Requirements

### Functional Requirements
- **FR-001**: System MUST allow users to Create, Read, Update, and Delete (CRUD) recipes.
- **FR-002**: System MUST persist recipe data to user's private iCloud database via CloudKit.
- **FR-003**: System MUST support complex data types for Ingredients (Name, Quantity, Unit) serialized securely.
- **FR-004**: System MUST provide a mechanism to parse recipe data from external URLs (Implementation Pending).
- **FR-005**: System MUST handle offline scenarios gracefully, syncing data when connectivity is restored (CloudKit default behavior).
- **FR-006**: System MUST allow users to specify a default number of servings (portions) for a recipe.
- **FR-007**: System MUST allow users to temporarily adjust the serving size in the detail view, automatically scaling the displayed ingredient quantities.
- **FR-008**: System MUST allow users to attach a photo to a recipe (from camera or library) and persist it to CloudKit.

### Non-Functional Requirements
- **NFR-001**: App MUST follow Apple's Human Interface Guidelines (HIG) using SwiftUI.
- **NFR-002**: App MUST require iOS 26.0 or later.
- **NFR-003**: Codebase MUST adhere to MVVM architecture pattern.
- **NFR-004**: Codebase MUST pass `SwiftLint` checks defined in `.swiftlint.yml`.

## 4. Key Entities

### Recipe
The core domain model.
- **id**: UUID
- **title**: String
- **instructions**: String
- **prepTime**: TimeInterval
- **servings**: Int (Default: 1)
- **ingredients**: [Ingredient]
- **imageAsset**: CKAsset? (Optional, holds the recipe image)

### Ingredient
Structured component of a recipe.
- **id**: UUID
- **name**: String
- **quantity**: Double
- **unit**: String

## 5. Technical Architecture

- **UI Framework**: SwiftUI
- **Architecture Pattern**: MVVM (Model-View-ViewModel)
- **Dependency Injection**: ServiceLocator pattern for swapping real/mock services.
- **Persistence**:
    - **Primary**: CloudKit (via `CloudKitService`).
    - **Secondary**: SwiftData (`Item.swift`) - *Currently present in boilerplate but not actively used for Recipe domain.*
- **Networking**: `RecipeParserService` (Abstraction for web scraping/parsing).

## 6. Known Issues / Future Work
- **Ingredient Parsing**: The `RecipeParserService` currently uses a naive string splitter to separate quantity, unit, and name from web imports. This can be brittle with complex ingredient strings (e.g., "1 (15 oz) can of beans"). Future work should implement Natural Language Processing (NLP) or a more robust regex strategy.
- **Image Import**: While manual photo upload is supported, the "Import from Web" feature currently does not fetch the recipe image from the URL. Future work should download and attach the image asset during parsing.
- **Performance**: Image loading in `RecipeListView` and `RecipeDetailView` occurs synchronously on the main thread when unwrapping `CKAsset` data. This should be refactored to use `AsyncImage` or background loading to prevent UI hitches with large libraries.
- **Portion Scaling**: Ingredient scaling is strictly linear. Culinary scaling logic could be improved to handle non-linear ingredients (e.g., salt, spices) more intelligently.