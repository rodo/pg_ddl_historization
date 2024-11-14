--
-- Warning,this test works only on empty ddl_history table
--

BEGIN;

SELECT plan(1);

TRUNCATE ddl_history;

-- 2
CREATE TABLE foobar (id int);
CREATE TABLE fifoo (id int);

-- 3
ALTER TABLE fifoo ADD COLUMN toto int;
ALTER TABLE fifoo ADD COLUMN tata text;

-- 2 rows generated
ALTER TABLE fifoo DROP COLUMN toto;

-- 3
CREATE INDEX ON fifoo (tata);
CREATE INDEX filax ON fifoo (id, tata);
DROP INDEX filax;

--
COMMENT ON TABLE foobar IS 'this is a comment';
COMMENT ON COLUMN foobar.id IS 'this is a column comment';


--

SELECT results_eq(
    'SELECT count(*) FROM ddl_history',
    'SELECT CAST(11 as bigint)'
);


ROLLBACK;
