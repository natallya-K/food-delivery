# Database Directory

This directory should contain the SQLite database file:
- `takeaway.db` (79.83 MB)

## Why is the database file missing?

The database file is not included in this repository because:
1. It's 79.83 MB, which exceeds GitHub's recommended 50 MB limit
2. Including large binary files in Git repositories can slow down cloning and increase storage costs

## How to get the database file?

Please obtain the `takeaway.db` file from your instructor or the original data source and place it in this directory before running the analysis.

## Directory Structure

```
database/
├── README.md (this file)
└── takeaway.db (place the database file here)
```

## Verification

You can verify the database is working correctly by running:
```bash
python scripts/explore_database.py
```

This will show you the database structure and sample data.
