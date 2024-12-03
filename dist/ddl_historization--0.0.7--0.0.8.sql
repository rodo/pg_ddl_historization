CREATE TABLE IF NOT EXISTS ddl_history_schema (
  schema_name text primary key,
  added_on    timestamptz default current_timestamp,      -- when the event occured
  added_by    text default current_user
);

INSERT INTO @extschema@.ddl_history_schema (schema_name) VALUES ('public');
