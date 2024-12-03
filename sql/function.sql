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
