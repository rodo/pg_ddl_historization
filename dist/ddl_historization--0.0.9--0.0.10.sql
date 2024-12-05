ALTER TABLE ddl_history_column ADD COLUMN id serial PRIMARY KEY;
--
--
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
  EXECUTE format('GRANT USAGE ON ddl_history_column_id_seq TO  %I', owner);

  EXECUTE format('GRANT SELECT,INSERT ON ddl_history_schema TO %I', owner);

END;
$funky$ LANGUAGE plpgsql;
--
--
--

SELECT log_ddl_auth();
