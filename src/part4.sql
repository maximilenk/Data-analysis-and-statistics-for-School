-- create database metadata;

-- \c metadata;
-- ^for psql, otherwise create database manually

create table if not exists tablenamesomething (column1 varchar);
create table if not exists nottablename (column2 bigint);
create table if not exists notes(column3 numeric);

CREATE PROCEDURE drop_table(tname varchar) AS $$
DECLARE
row record;
BEGIN
FOR row IN
    SELECT table_name
    FROM information_schema.tables
    WHERE tables.table_schema=CURRENT_SCHEMA AND table_name ILIKE tname || '%'
LOOP
    EXECUTE 'DROP TABLE ' || quote_ident(row.table_name);
END LOOP;
END;
$$ LANGUAGE PLPGSQL;

CALL drop_table('table');

create or replace function write_() returns varchar as $$ select 'hello' $$ language sql;

create or replace function sum(one numeric, two numeric) returns numeric as $$ select $1 + $2 $$ language sql;

create or replace function parrot(word varchar) returns varchar as $$ select $1 $$ language sql;

CREATE PROCEDURE scalar_functions(OUT returned_functions int) AS $$
DECLARE 
row record;
row2 record;
string varchar;
cur_par varchar;
BEGIN
returned_functions := 0;
FOR row IN
    SELECT routines.routine_name
    FROM information_schema.routines
    WHERE routine_type = 'FUNCTION' AND routines.specific_schema=CURRENT_SCHEMA
    ORDER BY routines.routine_name
LOOP
    string := row.routine_name;
    cur_par = '';
    FOR row2 IN
        SELECT parameters.parameter_name
        FROM information_schema.routines
        RIGHT JOIN information_schema.parameters ON routines.specific_name=parameters.specific_name
        WHERE routine_type = 'FUNCTION' AND routines.specific_schema=CURRENT_SCHEMA AND routines.routine_name = string
        ORDER BY parameters.ordinal_position
    LOOP
        cur_par = row2.parameter_name;
        string := string || ' ' || cur_par;
    END LOOP;
IF cur_par != '' THEN raise notice '%', string;
    returned_functions = returned_functions + 1;
END IF;
END LOOP;
END;
$$ LANGUAGE PLPGSQL;
call scalar_functions(0);

CREATE PROCEDURE delete_triggers(OUT deleted_triggers int) AS $$
DECLARE
row record;
BEGIN
deleted_triggers := 0;
FOR row IN
    SELECT trigger_name, event_object_table
    FROM information_schema.triggers
LOOP
    EXECUTE 'DROP TRIGGER ' || quote_ident(row.trigger_name) || ' on ' || quote_ident(row.event_object_table);
    deleted_triggers := deleted_triggers + 1;
END LOOP;
END;
$$ LANGUAGE PLPGSQL; -- not finished

create function trg_fnc() RETURNS TRIGGER AS $$
BEGIN
raise notice 'inserted to nottablename';
return null;
end;
$$ language plpgsql;

create trigger trg_insert after insert on nottablename
for each row execute function trg_fnc();

CALL delete_triggers(0);

CREATE PROCEDURE has_string(string varchar) AS $$
DECLARE row record;
BEGIN
for row in
    SELECT routine_name, routine_type
    FROM information_schema.routines
    WHERE routine_name LIKE ('%' || string || '%') AND routines.specific_schema=CURRENT_SCHEMA
LOOP
    raise notice '% %', row.routine_name, row.routine_type;
END LOOP;
END;
$$ LANGUAGE PLPGSQL;

CALL has_string('parrot');