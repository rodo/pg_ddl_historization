.PHONY : all dist pgtle clean install test

FILES = $(wildcard sql/*.sql)

EXTENSION = ddl_historization

EXTVERSION   = $(shell grep -m 1 '[[:space:]]\{3\}"version":' META.json | \
	       sed -e 's/[[:space:]]*"version":[[:space:]]*"\([^"]*\)",\{0,1\}/\1/')

DATA = dist/ddl_historization--$(EXTVERSION).sql dist/ddl_historization--*--$(EXTVERSION).sql

PGTLEOUT = dist/pgtle.$(EXTENSION)-$(EXTVERSION).sql

UNITTESTS = $(shell find test/sql/ -type f -name '*.in' | sed -e 's/in/sql/')

PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)

# edit this value if you want to deploy by hand
SCHEMA = @extschema@

_SCHEMA_ = public

include $(PGXS)

all: $(PGTLEOUT) ddl_historization.control $(UNITTESTS)

clean:
	rm -f $(PGTLEOUT) $(UNITTESTS)

dist/$(EXTENSION)--$(EXTVERSION).sql: $(FILES)
	cat sql/table.sql > $@
	cat sql/function.sql >> $@
	cat sql/event_trigger.sql >> $@
	cat $@ > dist/ddl_historization.sql

test/sql/%.sql: test/sql/%.in
	sed 's,_SCHEMA_,$(_SCHEMA_),g; ' $< > $@;

test:
	pg_prove -f test/sql/*.sql

$(PGTLEOUT): dist/$(EXTENSION)--$(EXTVERSION).sql pgtle_header.in pgtle_footer.in
	sed -e 's/_EXTVERSION_/$(EXTVERSION)/' pgtle_header.in > $(PGTLEOUT)
	cat dist/$(EXTENSION)--$(EXTVERSION).sql >> $(PGTLEOUT)
	cat pgtle_footer.in >> $(PGTLEOUT)

dist: $(PGTLEOUT)
	git archive --format zip --prefix=$(EXTENSION)-$(EXTVERSION)/ -o $(EXTENSION)-$(EXTVERSION).zip HEAD

ddl_historization.control: ddl_historization.control.in META.json
	sed 's,EXTVERSION,$(EXTVERSION),g; ' $< > $@;
