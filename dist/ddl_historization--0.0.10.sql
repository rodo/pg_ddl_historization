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
  attrelid      oid PRIMARY KEY,
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
-- Log ddl changes on non DROP actions
--
--
CREATE OR REPLACE FUNCTION log_ddl()
  RETURNS event_trigger AS $$
DECLARE
  r RECORD;
  s TEXT;
BEGIN
  s := current_query();

  FOR r IN SELECT * FROM pg_event_trigger_ddl_commands()
  LOOP
     IF EXISTS (SELECT FROM @extschema@.ddl_history_schema WHERE schema_name = r.schema_name) THEN
       INSERT INTO @extschema@.ddl_history
       (ddl_date, objoid, objsubid, ddl_tag, object_name, ddl_command, otype, username, trg_name, txid)
       VALUES
       (statement_timestamp(), r.objid, r.objsubid, tg_tag, r.object_identity, s,
       r.object_type, current_user, 'command_end', txid_current() );
       --
       -- log columns for new table
       --
       IF tg_tag = 'CREATE TABLE' AND r.object_type = 'table' THEN
         INSERT INTO @extschema@.ddl_history_column (attrelid, tablename, columnname, attnum)
         SELECT attrelid, r.object_identity, attname, attnum FROM pg_attribute
         WHERE attnum > 0 AND attrelid = r.objid
         ON CONFLICT (tablename, columnname) DO NOTHING;
       END IF;
       --
       -- log new columns
       --
       IF tg_tag = 'ALTER TABLE' AND r.object_type = 'table' THEN
         INSERT INTO @extschema@.ddl_history_column (attrelid, tablename, columnname, attnum)
         SELECT attrelid, r.object_identity, attname, attnum FROM pg_attribute
         WHERE attnum > 0 AND NOT attisdropped AND attrelid = r.objid
         ON CONFLICT DO NOTHING;
       END IF;
     END IF;
  END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Log ddl changes on DROP actions
--
--
CREATE OR REPLACE FUNCTION log_ddl_drop()

  RETURNS event_trigger AS $$

DECLARE
  r RECORD;
  s TEXT;
BEGIN
  s := current_query();
  FOR r IN SELECT * FROM pg_event_trigger_dropped_objects()
  LOOP
     IF EXISTS (SELECT FROM @extschema@.ddl_history_schema WHERE schema_name = r.schema_name) THEN
       INSERT INTO @extschema@.ddl_history (ddl_date, objoid, objsubid, ddl_tag, object_name,
       ddl_command, otype, username, trg_name, txid )
       VALUES (statement_timestamp(), r.objid, r.objsubid, tg_tag, r.object_identity, s,
       r.object_type, current_user, 'sql_drop', txid_current() );
       --
       -- drop table
       --
       IF tg_tag = 'DROP TABLE' AND r.object_type = 'table' THEN
         DELETE FROM @extschema@.ddl_history_column WHERE tablename = r.object_identity;
       END IF;
       --
       -- alter table drop column
       --
       IF tg_tag = 'ALTER TABLE' AND r.object_type = 'table column' THEN
         DELETE FROM @extschema@.ddl_history_column WHERE attrelid = r.objid AND attnum=r.objsubid;
       END IF;
     END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;
--
--
--
CREATE OR REPLACE FUNCTION log_ddl_start()
  RETURNS void AS $funky$
DECLARE
  schemaname TEXT;
BEGIN

  EXECUTE format('
        CREATE EVENT TRIGGER log_ddl_info
        ON ddl_command_end
        EXECUTE FUNCTION @extschema@.log_ddl()');

  EXECUTE format('
        CREATE EVENT TRIGGER log_ddl_drop_info
        ON sql_drop
        EXECUTE FUNCTION @extschema@.log_ddl_drop()');

END;
$funky$ LANGUAGE plpgsql;
--
-- Stop to historize
--
CREATE OR REPLACE FUNCTION log_ddl_stop()
  RETURNS void AS $$
BEGIN
        EXECUTE format('DROP EVENT TRIGGER IF EXISTS log_ddl_info');
        EXECUTE format('DROP EVENT TRIGGER IF EXISTS log_ddl_drop_info');
END;
$$ LANGUAGE plpgsql;
--
-- When the extension is installed by a superuser the database owner needs rights
--
CREATE OR REPLACE FUNCTION log_ddl_auth()
  RETURNS void AS $funky$
DECLARE
  owner TEXT;
BEGIN

  EXECUTE 'SELECT u.usename FROM pg_database d join pg_user u on u.usesysid=d.datdba
WHERE datname = current_database() ' INTO owner;

  EXECUTE format('GRANT SELECT,INSERT ON ddl_history TO %I', owner);
  EXECUTE format('GRANT USAGE ON ddl_history_id_seq TO  %I', owner);

  EXECUTE format('GRANT SELECT,INSERT,DELETE ON ddl_history_column TO %I', owner);

  EXECUTE format('GRANT SELECT,INSERT ON ddl_history_schema TO %I', owner);
  EXECUTE format('GRANT USAGE ON ddl_history_schema_id_seq TO  %I', owner);

END;
$funky$ LANGUAGE plpgsql;
--
-- Automatically start the historization at the end of install.
--
SELECT @extschema@.log_ddl_start();

INSERT INTO @extschema@.ddl_history_schema (schema_name) VALUES ('public');


SELECT @extschema@.log_ddl_auth();
