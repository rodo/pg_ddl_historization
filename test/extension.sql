--
-- Warning,this test works only on empty ddl_history table
--

BEGIN;

SELECT plan(1);

TRUNCATE ddl_history;

--
CREATE EXTENSION pg_trgm;

SELECT results_eq(
    'SELECT count(*) FROM ddl_history WHERE ddl_tag=''CREATE EXTENSION'' ',
    'SELECT CAST(1 as bigint)'
);


ROLLBACK;
