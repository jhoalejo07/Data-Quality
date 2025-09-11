# Data-Quality
This repository provides dynamic SQL scripts for checking data quality dimensions in SQL Server. The approach leverages metadata tables (INFORMATION_SCHEMA, sys.*) to build flexible queries that can be applied across schemas and adapted to other RDBMS.  Data quality dimensions are based on frameworks like DAMA DMBOK, ISO 8000, and ISO/IEC 25012.

# 📊 Data Quality Dimensions Covered
# 1. Completeness

Definition: Data is complete when mandatory fields are populated.

Check: Scan all IS_NULLABLE = 'NO' columns and count rows with NULL values.

Metadata used: INFORMATION_SCHEMA.COLUMNS

# 2. Uniqueness

Definition: Records should be represented only once according to primary keys or unique constraints.

Check: Identify PRIMARY KEY or UNIQUE constraints and validate no duplicates exist.

Metadata used: INFORMATION_SCHEMA.TABLE_CONSTRAINTS, CONSTRAINT_COLUMN_USAGE

# 3. Validity

Definition: Data conforms to defined formats, rules, or domains.

Generic rules implemented:

IDs > 0

Dates not before 1900 or unrealistically far in the future

Numeric values ≥ 0

Strings not empty or whitespace only

Metadata used: INFORMATION_SCHEMA.COLUMNS

# 4. Consistency

Definition: Data should not contradict itself across tables.

Check: For each foreign key, verify that child values exist in parent/master tables.

Metadata used: INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS

# 🚀 Usage

Clone this repository or copy the scripts into your SQL Server environment.

Adjust the schema name (@SchemaName) in each script if needed.

Run the scripts to create views that summarize data quality issues:

DQ_NullCountsView → Null violations (Completeness)

DQ_DistinctCountView → Duplicate violations (Uniqueness)

DQ_InvalidData → Invalid values (Validity)

DQ_InconsistentRows → FK mismatches (Consistency)

Query the views to review potential data quality problems.

# 📂 Example
-- Run completeness check
SELECT * FROM DQ_NullCountsView;

-- Run uniqueness check
SELECT * FROM DQ_DistinctCountView;

-- Run validity check
SELECT * FROM DQ_InvalidData;

-- Run consistency check
SELECT * FROM DQ_InconsistentRows;


If no rows are returned → ✅ Data passed that quality check.

# 🛠️ Extending the Framework

Add business-specific rules (e.g., code lists, domain values).

Integrate results into ETL pipelines for automated validation.

Connect to BI dashboards (Power BI, Tableau) for monitoring.

# 📖 References

DAMA DMBOK: Data Management Body of Knowledge

ISO/IEC 25012: Data Quality Model

ISO 8000: Data Quality Standard

✍️ Maintained by: Jhohan Arias
💡 Contributions welcome! Submit an issue or PR if you’d like to add more checks.
