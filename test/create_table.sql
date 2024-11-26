--
--
--

SET search_path=public,pgtap;

BEGIN;

SELECT plan(5);

TRUNCATE ddl_history;
TRUNCATE ddl_history_column;

--
CREATE TABLE foobar_ddl (id serial, label text);
CREATE TABLE second_table (varid int, varlabel text);

-- 4 rows, 2 for the 2 tables and 2 for the sequence
SELECT results_eq(
    'SELECT count(*) FROM ddl_history',
    'SELECT CAST(4 as bigint)',
    'We have 4 row in ddl_history');


SELECT results_eq(
    'SELECT count(*) FROM ddl_history_column',
    'SELECT CAST(4 as bigint)',
    'We have 4 rows in ddl_history_column');

SELECT results_eq(
    'SELECT tablename, columnname FROM ddl_history_column ORDER BY tablename,columnname',
    $$VALUES ('public.foobar_ddl'::name, 'id'::name),
             ('public.foobar_ddl'::name, 'label'::name),
             ('public.second_table'::name, 'varid'::name),
             ('public.second_table'::name, 'varlabel'::name)
$$);

--
-- Test that old data are cleaned after a drop
DROP TABLE second_table;

SELECT results_eq(
    'SELECT count(*) FROM ddl_history_column',
    'SELECT CAST(2 as bigint)',
    'We have 2 rows in ddl_history_column');

SELECT results_eq(
    'SELECT tablename, columnname FROM ddl_history_column ORDER BY tablename,columnname',
    $$VALUES ('public.foobar_ddl'::name, 'id'::name),
             ('public.foobar_ddl'::name, 'label'::name)
$$);


ROLLBACK;
