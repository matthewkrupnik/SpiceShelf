# Data Model: Recipe Organizer

## Recipe

Represents a single recipe.

### Fields

- **id**: `UUID` (Primary Key) - A unique identifier for the recipe.
- **title**: `String` - The title of the recipe.
- **ingredients**: `[String]` - A list of ingredients for the recipe.
- **instructions**: `[String]` - A list of instructions for the recipe.
- **sourceURL**: `String` (Optional) - The URL of the website where the recipe was imported from.

### Validation Rules

- `title` must not be empty.
- `ingredients` must not be empty.
- `instructions` must not be empty.
