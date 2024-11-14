--
--
--
ALTER TABLE @extschema@.ddl_history
ADD COLUMN objsubid oid;
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
     INSERT INTO @extschema@.ddl_history
     (ddl_date, objoid, objsubid, ddl_tag, object_name, ddl_command, otype, username, trg_name, txid)
     VALUES
     (statement_timestamp(), r.objid, r.objsubid, tg_tag, r.object_identity, s, r.object_type, current_user, 'command_end', txid_current() );

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

    END LOOP;
END;
$$ LANGUAGE plpgsql;
