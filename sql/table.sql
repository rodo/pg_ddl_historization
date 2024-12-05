--
-- Create thre tables
--
-- ddl_history
-- ddl_history_column
-- ddl_history_schema
--
-- and one view
--
-- ddl_history_comment
--

CREATE TABLE IF NOT EXISTS ddl_history (
  id serial primary key,
  ddl_date    timestamptz,      -- when the event occured
  objoid      oid,              -- the oid of the object
  objsubid    oid,              -- the oid of the column
  username    text,             -- the role used by the ddl command
  ddl_tag     text,
  object_name text,
  otype       text,             -- the object type
  ddl_command text,             -- the original statement that triggered
  trg_name    text,
  txid        bigint            -- the transaction id
);

--
--
--
CREATE TABLE IF NOT EXISTS ddl_history_column (
  id            serial primary key,
  attrelid      oid not null,
  attnum        smallint NOT NULL,
  tablename     name NOT NULL,
  columnname    name NOT NULL,
  creation_time timestamp with time zone DEFAULT current_timestamp,
  create_by     text DEFAULT current_user
);

CREATE UNIQUE INDEX ON ddl_history_column (tablename, columnname);
--
--
--
CREATE TABLE IF NOT EXISTS ddl_history_schema (
  schema_name text primary key,
  added_on    timestamptz default current_timestamp,      -- when the event occured
  added_by    text default current_user
);

--
-- View dedicated to consult the comment on all objects
--
CREATE OR REPLACE VIEW ddl_history_comment AS
SELECT
  h.id,
  h.objoid,
  h.ddl_date,
  h.username,
  h.object_name,
  h.otype,
  h.trg_name,
  d.description
  FROM ddl_history h
  JOIN pg_catalog.pg_description d ON d.objoid=h.objoid
  WHERE ddl_tag = 'COMMENT'
;

GRANT INSERT,SELECT ON ddl_history TO PUBLIC;
GRANT USAGE ON ddl_history_id_seq TO PUBLIC;
