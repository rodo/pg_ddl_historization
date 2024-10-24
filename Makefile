.PHONY : all build flush clean install test

FILES = function.sql event_trigger.sql table.sql

TESTFILES = test_function.sql test_event_trigger.sql test_table.sql

EXTENSION = ddl_historization

EXTVERSION = 0.3

DATA = ddl_historization--$(EXTVERSION).sql

PGTLEOUT = pgtle.$(EXTENSION)-$(EXTVERSION).sql

PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)

# edit this value if you want to deploy by hand
SCHEMA = @extschema@

include $(PGXS)

all: $(FILES) $(TESTFILES)

clean:
	rm -f $(FILES) $(TESTFILES) $(DATA)
	rm -f $(PGTLEOUT)

%.sql:	%.in
	sed -e 's/_SCHEMA_/$(SCHEMA)/' $< > $@

test:
	pg_prove $(TESTFILES)

flush:
	psql -f clean/drop_event_trigger.sql
	psql -f clean/drop_function.sql
	psql -f clean/drop_table.sql
	psql -f table.sql
	psql -f function.sql
	psql -f event_trigger.sql

pgtle: build
	sed -e 's/_EXTVERSION_/$(EXTVERSION)/' pgtle_header.in > $(PGTLEOUT)
	cat $(DATA) >>  $(PGTLEOUT)
	cat pgtle_footer.in >> $(PGTLEOUT)


build: $(FILES)
	cat table.sql > $(DATA)
	cat function.sql >> $(DATA)
	cat event_trigger.sql >> $(DATA)

install: build
