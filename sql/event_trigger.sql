--
-- Automatically start the historization at the end of install.
--
SELECT @extschema@.log_ddl_start();

INSERT INTO @extschema@.ddl_history_schema (schema_name) VALUES ('public');
