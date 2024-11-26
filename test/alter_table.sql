--
--
--

SET search_path=public,pgtap;

BEGIN;

SELECT plan(7);

TRUNCATE ddl_history;
TRUNCATE ddl_history_column;

--
CREATE TABLE alter_table (id int, label text);

-- One action, so 1 row
SELECT results_eq(
    'SELECT count(*) FROM ddl_history',
    'SELECT CAST(1 as bigint)',
    'We have 1 row in ddl_history');

-- 1 table with 2 columns, so 2 rows
SELECT results_eq(
    'SELECT count(*) FROM ddl_history_column',
    'SELECT CAST(2 as bigint)',
    'We have 2 rows in ddl_history_column');

SELECT results_eq(
    'SELECT tablename, columnname FROM ddl_history_column ORDER BY tablename,columnname',
    $$VALUES ('public.alter_table'::name, 'id'::name),
             ('public.alter_table'::name, 'label'::name)
$$);

--
-- Add a column with alter table
--
ALTER TABLE alter_table ADD COLUMN xc date;

SELECT results_eq(
    'SELECT count(*) FROM ddl_history_column',
    'SELECT CAST(3 as bigint)',
    'We have 3 rows in ddl_history_column');

SELECT results_eq(
    'SELECT tablename, columnname FROM ddl_history_column ORDER BY tablename,columnname',
    $$VALUES ('public.alter_table'::name, 'id'::name),
             ('public.alter_table'::name, 'label'::name),
             ('public.alter_table'::name, 'xc'::name)
$$);

--
-- Remove a column
--
ALTER TABLE alter_table DROP COLUMN xc;

SELECT results_eq(
    'SELECT count(*) FROM ddl_history_column',
    'SELECT CAST(2 as bigint)',
    'We have 2 rows in ddl_history_column');

SELECT results_eq(
    'SELECT tablename, columnname FROM ddl_history_column ORDER BY tablename,columnname',
    $$VALUES ('public.alter_table'::name, 'id'::name),
             ('public.alter_table'::name, 'label'::name)
$$);



--
-- What happen on other ALTER TABLE with no column
ALTER TABLE alter_table ENABLE ROW LEVEL SECURITY;

ROLLBACK;
