--
-- Warning,this test works only on empty ddl_history table
--

BEGIN;

SELECT plan(1);

TRUNCATE ddl_history;

--
CREATE EXTENSION pg_trgm;

SELECT results_eq(
    'SELECT count(*) > 0 FROM ddl_history WHERE ddl_command LIKE ''CREATE EXTENSION pg_trgm%'' ',
    'SELECT true',
    'There is one row in ddl_history for extension'
);


ROLLBACK;
