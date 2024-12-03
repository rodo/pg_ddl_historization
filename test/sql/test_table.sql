--
-- Test if the tables exists and have the right format
--
BEGIN;

SELECT plan(8);

SELECT has_schema('public'::name);

SELECT has_table('public'::name, 'ddl_history'::name);

SELECT has_table('public'::name, 'ddl_history_schema'::name);

SELECT columns_are(
       'public'::name,
       'ddl_history'::name,
       ARRAY['id', 'ddl_date', 'objoid', 'objsubid',  'username', 'ddl_tag', 'object_name', 'otype', 'ddl_command', 'trg_name', 'txid']);

SELECT has_table('public'::name, 'ddl_history_column'::name);

SELECT columns_are(
       'public'::name,
       'ddl_history_column'::name,
       ARRAY['attrelid', 'attnum', 'tablename', 'columnname', 'creation_time', 'create_by']);

SELECT has_view('public'::name, 'ddl_history_comment'::name);

-- by default there is only one schema
SELECT results_eq(
    'SELECT count(*) FROM ddl_history_schema ',
    'SELECT CAST(1 as bigint)'
);


SELECT finish();

ROLLBACK;
