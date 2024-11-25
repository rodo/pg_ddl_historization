--
-- Create a new table to collect the new columns
--
CREATE TABLE IF NOT EXISTS ddl_history_column (
  attrelid      oid,
  tablename     name,
  columnname    name,
  creation_time timestamp with time zone DEFAULT current_timestamp,
  create_by     text DEFAULT current_user
);
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

     IF tg_tag = 'CREATE TABLE' AND r.object_type = 'table' THEN
       INSERT INTO @extschema@.ddl_history_column (attrelid, tablename, columnname)
       SELECT attrelid, r.object_identity, attname FROM pg_attribute
       WHERE attnum > 0 AND attrelid = r.objid;
     END IF;

  END LOOP;
END;
$$ LANGUAGE plpgsql;
