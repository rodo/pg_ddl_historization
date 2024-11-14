--
-- Automatically start the historization at the end of install.
--
SELECT @extschema@.log_ddl_start();
