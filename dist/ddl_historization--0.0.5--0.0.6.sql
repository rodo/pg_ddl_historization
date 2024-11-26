--
-- Create a new table to collect the new columns
--
CREATE TABLE IF NOT EXISTS ddl_history_column (
  attrelid      oid NOT NULL,
  attnum        smallint NOT NULL,
  tablename     name NOT NULL,
  columnname    name NOT NULL,
  creation_time timestamp with time zone DEFAULT current_timestamp,
  create_by     text DEFAULT current_user
);

CREATE UNIQUE INDEX ON ddl_history_column (tablename, columnname);

--
-- Update the function to fill the table
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
     INSERT INTO @extschema@.ddl_history
     (ddl_date, objoid, objsubid, ddl_tag, object_name, ddl_command, otype, username, trg_name, txid)
     VALUES
     (statement_timestamp(), r.objid, r.objsubid, tg_tag, r.object_identity, s, r.object_type, current_user, 'command_end', txid_current() );
     --
     -- log columns for new tables
     --
     IF tg_tag = 'CREATE TABLE' AND r.object_type = 'table' THEN
       INSERT INTO @extschema@.ddl_history_column (attrelid, tablename, columnname, attnum)
       SELECT attrelid, r.object_identity, attname, attnum FROM pg_attribute
       WHERE attnum > 0 AND attrelid = r.objid;
     END IF;

     IF tg_tag = 'ALTER TABLE' AND r.object_type = 'table' THEN
       INSERT INTO @extschema@.ddl_history_column (attrelid, tablename, columnname, attnum)
       SELECT attrelid, r.object_identity, attname, attnum FROM pg_attribute
       WHERE attnum > 0 AND NOT attisdropped AND attrelid = r.objid
       ON CONFLICT DO NOTHING;
     END IF;

  END LOOP;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION log_ddl_drop()

  RETURNS event_trigger AS $$

DECLARE
  r RECORD;
  s TEXT;
BEGIN
  s := current_query();
  FOR r IN SELECT * FROM pg_event_trigger_dropped_objects()
    LOOP
      INSERT INTO @extschema@.ddl_history (ddl_date, objoid, objsubid, ddl_tag, object_name, ddl_command, otype, username, trg_name, txid )
      VALUES (statement_timestamp(), r.objid, r.objsubid, tg_tag, r.object_identity, s, r.object_type, current_user, 'sql_drop', txid_current() );
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
    END LOOP;
END;
$$ LANGUAGE plpgsql;
