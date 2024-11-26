--
-- Warning,this test works only on empty ddl_history table
--

BEGIN;

SELECT plan(6);

TRUNCATE ddl_history;

-- 2
CREATE TABLE foobar (id int);

SELECT results_eq(
    'SELECT count(*) FROM ddl_history',
    'SELECT CAST(1 as bigint)'
);

-- 3
ALTER TABLE foobar ADD COLUMN toto int;
ALTER TABLE foobar ADD COLUMN tata text;

SELECT results_eq(
    'SELECT count(*) FROM ddl_history',
    'SELECT CAST(3 as bigint)'
);


-- 2 rows generated
ALTER TABLE foobar DROP COLUMN toto;

SELECT results_eq(
    'SELECT count(*) FROM ddl_history',
    'SELECT CAST(5 as bigint)'
);


-- 3
CREATE INDEX ON foobar (tata);
CREATE INDEX filax ON foobar (id, tata);
DROP INDEX filax;

--
COMMENT ON TABLE foobar IS 'this is a comment';
COMMENT ON COLUMN foobar.id IS 'this is a column comment';

--

SELECT results_eq(
    'SELECT count(*) FROM ddl_history',
    'SELECT CAST(10 as bigint)'
);
--
-- Table with a primaru key
--
CREATE TABLE inte_fifoo (id int PRIMARY KEY);

-- 1 row for the table and one for the index
SELECT results_eq(
    'SELECT count(*) FROM ddl_history',
    'SELECT CAST(12 as bigint)'
);

--
-- Table that references another one
--
CREATE TABLE inte_ref (id int PRIMARY KEY REFERENCES inte_fifoo (id) );

-- 1 row for the table and one for the index
SELECT results_eq(
    'SELECT count(*) FROM ddl_history',
    'SELECT CAST(15 as bigint)'
);



ROLLBACK;
