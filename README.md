# Finland Universities Repository

This repository is a free, GitHub-friendly database for tracking Finnish universities, application requirements, deadlines, and professor research profiles.

It is designed to help collect and maintain:

- required application documents
- program deadlines
- university application links
- department, faculty, or school names
- department names
- professor names and titles
- research areas
- ResearchGate profiles
- Google Scholar profiles
- citation counts and verification notes

## Repository Structure

```text
data/
  master/
    universities_overview.csv
    application_deadlines.csv
    required_documents.csv
    departments_master.csv
    professors_master.csv
  sources/
    admissions_sources.csv
    department_sources.csv
    professor_sources.csv
  universities/
    _template/
      university_info.csv
      deadlines.csv
      required_documents.csv
      departments.csv
      professors.csv
    aalto-university/
    hanken-school-of-economics/
    lut-university/
    tampere-university/
    university-of-eastern-finland/
    university-of-helsinki/
    university-of-jyvaskyla/
    university-of-oulu/
    university-of-turku/
    university-of-vaasa/
    abo-akademi-university/
excel/
  finland_universities_master.xlsx
  universities/
scripts/
  generate_excel.ps1
templates/
  university_profile_template.md
CONTRIBUTING.md
```

## How To Use

1. Start with the CSV files in `data/master/` for a country-wide view.
2. Use `data/universities/_template/` whenever you add another Finnish university.
3. Fill each university folder with:
   - `university_info.csv`
   - `deadlines.csv`
   - `required_documents.csv`
   - `departments.csv`
   - `professors.csv`
4. Keep the same records synchronized in the matching Excel workbook under `excel/universities/`.
5. If you update CSV files in bulk, rerun `scripts/generate_excel.ps1` to regenerate the `.xlsx` files.

## Current Coverage

- Admissions data: verified 2026 application guidance for the Finland university set in this repository.
- Required documents: university-level baseline requirements from official admissions pages. Programme-specific extras still need checking on each programme page.
- Departments: official academic-unit lists are tracked as faculties, schools, departments, or institutes depending on how each university is organized.
- Professor data: seeded with verified faculty examples and source tracking. This part is iterative because Google Scholar blocks automated retrieval and universities expose profile links inconsistently.

## Recommended Workflow

For each university:

1. Confirm the official English university name and city.
2. Record the official website and application portal.
3. Add degree level, intake, and program-specific deadlines.
4. List required documents exactly as requested by the university.
5. Add departments relevant to your target field.
6. Record professor names, titles, and research areas within those departments.
7. Add profile links for ResearchGate, Google Scholar, and the official university profile.
8. Record citation counts, citation source, h-index if available, and the last verification date.

## Notes

- CSV files open directly in Excel, Google Sheets, and LibreOffice.
- The `excel/` folder is intended for users who prefer `.xlsx` workbooks.
- Keep dates in `YYYY-MM-DD` format.
- Use official university pages for admission requirements and deadlines.
- Use official organization, faculty, or school pages for department lists.
- Use public academic profile pages for ResearchGate, Google Scholar, and citation data.
- When citation counts cannot be verified automatically, leave the value blank and keep the source page in `data/sources/professor_sources.csv`.

## Suggested Next Steps

- Fill the master sheets with real data for the first 5 to 10 Finnish universities.
- Review professor lists department by department.
- Standardize research area keywords for easier filtering.
- Recheck deadlines before every application cycle.
