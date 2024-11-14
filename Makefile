.PHONY : all build pgtle clean install test

FILES = $(wildcard sql/*.sql)

EXTENSION = ddl_historization

EXTVERSION   = $(shell grep -m 1 '[[:space:]]\{3\}"version":' META.json | \
	       sed -e 's/[[:space:]]*"version":[[:space:]]*"\([^"]*\)",\{0,1\}/\1/')

DATA = ddl_historization--$(EXTVERSION).sql

PGTLEOUT = pgtle.$(EXTENSION)-$(EXTVERSION).sql

PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)

# edit this value if you want to deploy by hand
SCHEMA = @extschema@

include $(PGXS)

all: $(DATA) pgtle

clean:
	rm -f $(DATA)
	rm -f $(PGTLEOUT)

$(EXTENSION)--$(EXTVERSION).sql: $(FILES)
	cat sql/table.sql > $@
	cat sql/function.sql >> $@
	cat sql/event_trigger.sql >> $@
	cat $@ > ddl_historization.sql

test:
	pg_prove -f test/sql/*.sql

pgtle: $(EXTENSION)--$(EXTVERSION).sql
	sed -e 's/_EXTVERSION_/$(EXTVERSION)/' pgtle_header.in > $(PGTLEOUT)
	cat $(EXTENSION)--$(EXTVERSION).sql >>  $(PGTLEOUT)
	cat pgtle_footer.in >> $(PGTLEOUT)

dist:
	git archive --format zip --prefix=$(EXTENSION)-$(EXTVERSION)/ -o $(EXTENSION)-$(EXTVERSION).zip HEAD
