--
-- Test if the table exists and has the right format
--
BEGIN;

SELECT plan(3);

SELECT has_schema('public'::name);

SELECT has_table('public'::name, 'ddl_history'::name);

SELECT columns_are(
       'public'::name,
       'ddl_history'::name,
       ARRAY['id', 'objoid', 'objsubid', 'ddl_date', 'username', 'ddl_tag', 'object_name', 'otype', 'ddl_command', 'trg_name', 'txid']);

SELECT finish();

ROLLBACK;
