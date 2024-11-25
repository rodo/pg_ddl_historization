--
-- Test if the table exists and has the right format
--
BEGIN;

SELECT plan(6);

SELECT has_schema('public'::name);

SELECT has_table('public'::name, 'ddl_history'::name);

SELECT columns_are(
       'public'::name,
       'ddl_history'::name,
       ARRAY['id', 'ddl_date', 'objoid', 'objsubid',  'username', 'ddl_tag', 'object_name', 'otype', 'ddl_command', 'trg_name', 'txid']);

SELECT has_table('public'::name, 'ddl_history_column'::name);

SELECT columns_are(
       'public'::name,
       'ddl_history_column'::name,
       ARRAY['oid', 'tablename', 'columnname', 'creation_time', 'create_by']);

SELECT has_view('public'::name, 'ddl_history_comment'::name);

SELECT finish();

ROLLBACK;
