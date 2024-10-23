.PHONY : all flush test clean

FILES = function.sql event_trigger.sql table.sql test_function.sql test_event_trigger.sql test_table.sql

all : $(FILES)

clean :
	rm -f $(FILES)

%.sql :	%.in
	sed -e 's/_SCHEMA_/dba/' $< > $@

test :
	pg_prove test_*.sql

flush :
	psql -f clean/drop_event_trigger.sql
	psql -f clean/drop_function.sql
	psql -f clean/drop_table.sql
	psql -f table.sql
	psql -f function.sql
	psql -f event_trigger.sql
