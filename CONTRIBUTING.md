# Contributing

## Data Rules

- Use official university sources for admission requirements and deadlines.
- Use public academic profile pages for professor links and citation counts.
- Prefer one row per program when deadlines differ by degree or intake.
- Keep university names consistent across all CSV and Excel files.
- Keep department names as written by the university where possible.
- Record `last_verified` every time data is updated.

## Formatting Rules

- Dates: `YYYY-MM-DD`
- Multiple documents: separate with semicolons
- Multiple research areas: separate with semicolons
- Missing values: leave blank instead of writing `N/A` unless necessary
- URLs: always store full links including `https://`

## Folder Naming

Use lowercase kebab-case for university folders.

Example:

```text
data/universities/university-of-helsinki/
```

## Pull Request Checklist

- Data is readable and consistent
- Dates use the correct format
- Links are complete URLs
- Citation counts were checked recently
- `last_verified` was updated
