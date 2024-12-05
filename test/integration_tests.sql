--
-- Warning,this test works only on empty ddl_history table
--
BEGIN;

SELECT plan(10);

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

-- Simple CREATE TABLE
--
--    ddl_tag    |     object_name     | otype |            ddl_command
-- --------------+---------------------+-------+-----------------------------------
--  CREATE TABLE | public.carabignac   | table | CREATE TABLE carabignac (id int);
TRUNCATE ddl_history;
CREATE TABLE carabignac (id int);

SELECT results_eq('SELECT count(*) FROM ddl_history', 'SELECT CAST(1 as bigint)', 'CREATE TABLE generates 1 row');

--
-- Dropping a table generate 3 events
--
--    ddl_tag    |     object_name     | otype |            ddl_command
-- --------------+---------------------+-------+-----------------------------------
--  DROP TABLE   | public.carabignac   | table | DROP TABLE carabignac;
--  DROP TABLE   | public.carabignac   | type  | DROP TABLE carabignac;
--  DROP TABLE   | public.carabignac[] | type  | DROP TABLE carabignac;
--
TRUNCATE ddl_history;
DROP TABLE carabignac;

SELECT results_eq('SELECT count(*) FROM ddl_history', 'SELECT CAST(3 as bigint)', 'DROP TABLE generates 3 rows');

-- CREATE TABLE with SERIAL
--
--    ddl_tag    |       object_name        |  otype   |             ddl_command
-- --------------+--------------------------+----------+--------------------------------------
--  CREATE TABLE | public.carabignac_id_seq | sequence | CREATE TABLE carabignac (id serial);
--  CREATE TABLE | public.carabignac        | table    | CREATE TABLE carabignac (id serial);
--  CREATE TABLE | public.carabignac_id_seq | sequence | CREATE TABLE carabignac (id serial);

TRUNCATE ddl_history;
CREATE TABLE carabignac (id serial);

SELECT results_eq('SELECT count(*) FROM ddl_history', 'SELECT CAST(3 as bigint)', 'CREATE TABLE with serial generates 3 rows');

-- -- CREATE TABLE with GENERATED ALWAYS
--
--    ddl_tag    |    object_name     |  otype   |                ddl_command
-- --------------+--------------------+----------+--------------------------------------------
--  CREATE TABLE | public.tgen_id_seq | sequence | CREATE TABLE tgen (                       +
--               |                    |          |     id bigint GENERATED ALWAYS AS IDENTITY+
--               |                    |          | );
--  CREATE TABLE | public.tgen        | table    | CREATE TABLE tgen (                       +
--               |                    |          |     id bigint GENERATED ALWAYS AS IDENTITY+
--               |                    |          | );
--  CREATE TABLE | public.tgen_id_seq | sequence | CREATE TABLE tgen (                       +
--               |                    |          |     id bigint GENERATED ALWAYS AS IDENTITY+
--               |                    |          | );

TRUNCATE ddl_history;
CREATE TABLE tgen (id bigint GENERATED ALWAYS AS IDENTITY );

SELECT results_eq('SELECT count(*) FROM ddl_history', 'SELECT CAST(3 as bigint)', 'CREATE TABLE with serial generates 3 rows');
ROLLBACK;
