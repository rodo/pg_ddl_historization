CREATE UNIQUE INDEX ddl_pkey on ddl (id);
ALTER TABLE ddl add PRIMARY KEY USING INDEX ddl_pkey;
