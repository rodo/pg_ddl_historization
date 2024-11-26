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

  END LOOP;
END;
$$ LANGUAGE plpgsql;
