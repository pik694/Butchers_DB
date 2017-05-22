
alter session set current_schema = pzelazko;

/* ERASING DB */

drop sequence employees_sequence;
drop sequence departments_sequence;

drop package global_variables;


alter table shifts drop constraint shifts_fk;

alter table departments drop constraint departments_fk;

alter table production drop constraint recipe_fk;
alter table production drop constraint shift_fk;

alter table workers_on_shifts drop constraint employee_fk;
alter table workers_on_shifts drop constraint workers_shift_fk;

drop table employees;
drop table ingredients;
drop table recipes;
drop table departments;
drop table shifts;
drop table ingredients_in_recipes;
drop table production;
drop table workers_on_shifts;

drop procedure employees_generator;
drop procedure ingredients_generator;
drop procedure recipes_generator;
drop procedure departments_generator;
drop procedure shifts_generator;
drop procedure workers_on_shifts_generator;
drop procedure production_generator;
drop procedure recipes_ingredients_generator


/* SEQUENCES */

create sequence DEPARTMENTS_SEQUENCE;
create sequence EMPLOYEES_SEQUENCE;

/* END SEQUENCES */



/* TABLES */

create table EMPLOYEES
(
	ID NUMBER not null
    primary key,
	NAME VARCHAR2(32) not null,
	SURNAME VARCHAR2(32) not null,
	PHONE VARCHAR2(16)
);

create table INGREDIENTS
(
	NAME VARCHAR2(256) not null
    primary key,
	PRICE_PER_UNIT NUMBER(6,2) not null
);


create table DEPARTMENTS
(
	ID NUMBER not null
		primary key,
	NAME VARCHAR2(32),
	MANAGER NUMBER
		constraint DEPARTMENTS_FK
			references EMPLOYEES on delete set null
);


create table RECIPES
(
	NAME VARCHAR2(32) not null
		primary key
);

create table SHIFTS
(
	DATE_OF_SHIFT DATE not null,
	DEPARTMENT NUMBER not null
		constraint SHIFTS_FK
			references DEPARTMENTS,
	COST NUMBER(6,2),
	constraint SHIFTS_PK
		primary key (DATE_OF_SHIFT, DEPARTMENT)
);


create table ingredients_in_recipes (
  recipe varchar2(32) not null
    constraint recipes_fk references recipes on delete cascade,
  ingredient varchar2(32) not null
    constraint ingredients_fk references ingredients on delete cascade,
  amount number(6,2)
);
alter table ingredients_in_recipes add constraint ingredient_unique unique (recipe, ingredient);

create table production (
  shift_date date not null,
  department number not null,
  recipe varchar2(32) not null
    constraint recipe_fk references recipes,
  amount number(6,2) not null
);
alter table production add constraint shift_fk foreign key (shift_date, department) references shifts(date_of_shift, department);
alter table production add constraint recipe_unique unique (shift_date, department, recipe);

create table workers_on_shifts (
  employee number not null
    constraint  employee_fk references employees,
  shift_date date not null,
  department number not null
);
alter table workers_on_shifts add constraint workers_shift_fk foreign key (shift_date, department) references shifts(date_of_shift, department);
alter table workers_on_shifts add constraint workers_shifts_unique unique (shift_date, employee);

/* END TABLES */

/* PROCEDURES */



/* END PROCEDURES */

/* TRIGGERS */

-- EMPLOYEES' TRIGGERS
create or replace trigger EMPLOYEES_AUTO_ID_TRIGGER
	before insert
	on EMPLOYEES
	for each row
  begin
    :new.id := employees_sequence.nextval;
  end;
/

-- INGREDIENTS' TRIGGERS
create or replace trigger ingredient_validation_trigger
  before insert or update
  on ingredients
  for each row
begin
    if :new.price_per_unit <= 0 then
      RAISE_APPLICATION_ERROR(-20000, 'Price cannot equal or be below 0');
    end if;
end;
/

create or replace trigger ingredient_price_changed
  after update of price_per_unit
  on ingredients
  for each row
begin
  dbms_output.put_line('Price of '|| :new.name  || ' has changed from ' || to_char(:old.price_per_unit) || ' to ' || to_char(:new.price_per_unit));
end;
/


-- DEPARTMENTS' TRIGGERS
create or replace trigger DEPARTMENTS_AUTO_ID_TRIGGER
	before insert
	on DEPARTMENTS
	for each row
begin
    :new.id := departments_sequence.nextval;
end;
/

-- RECIPES' TRIGGERS

-- SHIFTS' TRIGGERS
create or replace trigger SHIFTS_DATE_TRUNCATE_TRIGGER
	before insert or update
	on SHIFTS
	for each row
begin
    :new.date_of_shift := trunc(:new.date_of_shift);
  end;
/


-- INGREDIENTS IN RECIPES TRIGGERS
create or replace trigger recipes_trigger
  before insert or update
  on ingredients_in_recipes
  for each row
  begin
    if :new.amount <= 0 then
      RAISE_APPLICATION_ERROR(-20000, 'Amount cannot equal or be below 0');
    end if;
  end;
/

-- PRODUCTION TRIGGERS

create or replace trigger production_trigger
  before insert or update or delete
  on production
  for each row
  declare
    cost number(6,2);
begin
  if :new.amount <= 0 then
      RAISE_APPLICATION_ERROR(-20000, 'Amount cannot equal or be below 0');
  end if;
  select ingredients.price_per_unit * :new.amount into cost from ingredients where ingredients.name =
  case
    when inserting then

    when updating then
    when deleting then
    --TODO:
  end case;
end;

-- WORKERS ON SHIFTS TRIGGERS
create or replace trigger workers_shifts_trigger
  after insert or update or delete
  on workers_on_shifts
  for each row
  declare
    wage number(6,2);
  begin
    wage := 150;
    case
      when inserting then
        update shifts set cost = nvl(cost,0) + wage where department = :new.department and date_of_shift = :new.shift_date;
      when updating then
        update shifts set cost = nvl(cost,0) + wage where department = :new.department and date_of_shift = :new.shift_date;
        update shifts set cost = nvl(cost,0) - wage where department = :old.department and date_of_shift = :old.shift_date;
      when deleting then
        update shifts set cost = nvl(cost,0) - wage where department = :old.department and date_of_shift = :old.shift_date;
    end case;
  end;
/

/* END TRIGGERS */

/* GENERATORS */

CREATE or replace procedure employees_generator as
  type str_table is table of varchar2(256);
  names str_table;
  surnames str_table;
  phone_nr integer (10);
  random_name integer (10);
  random_surname integer (10);
  random_phone_number integer (10);
  begin
    names := str_table ('Adam', 'Adrian', 'Krzysztof', 'Daniel', 'Zdzislaw', 'Mariusz', 'Piotr', 'Paweł', 'Zbigniew', 'Władysław', 'Jan', 'Robert', 'Grzegorz', 'Fabian', 'Michał', 'Włodzimierz', 'Waldemar', 'Janusz', 'Edward', 'Mateusz');
    surnames := str_table ('Nowak', 'Kowalski', 'Wiśniewski', 'Wójcik', 'Kowalczyk', 'Woźniak', 'Lewandowski', 'Kamiński', 'Zieliński', 'Szymański', 'Dąbrowski', 'Jankowski', 'Kozłowski', 'Mazur', 'Wojciechowski', 'Krawczyk', 'Kwiatkowski');

    for i in 1..1000 loop
      random_name := dbms_random.value(1, names.count);
      random_surname := dbms_random.value(1, surnames.count);
      random_phone_number := dbms_random.value(500000000, 899999999);
      insert into employees values (null, names(random_name), surnames (random_surname), to_char(random_phone_number));
    end loop;
  dbms_output.put_line ('Added 1000 employees');
  end;
/

CREATE or replace procedure ingredients_generator as
  name varchar2(32);
  price decimal(6,2);

  begin
    for i in 1..128 loop
      name := dbms_random.string('u', 16);
      price := dbms_random.value (0, 999999) / 100;
      insert into ingredients (name, price_per_unit) values (name, price);
    end loop;
    dbms_output.put_line('Added 32 ingredients');
  end;
/

CREATE or replace procedure departments_generator as
    type str_table is table of varchar2(32);
    manager integer;
    names str_table;
  begin
    names := str_table ('A', 'B', 'C', 'D', 'E');
    for i in 1..names.count loop
      insert into departments (name, manager) values ( names (i), (select * from (select id from employees order by dbms_random.value) where rownum = 1));
    end loop;
    dbms_output.put_line('Added ' || to_char(names.count) || ' departments');
  end;
/

CREATE or replace procedure recipes_generator as
  type str_table is table of varchar2(32);
  meats str_table;
  kinds str_table;
  meat_nr integer;
  kind_nr integer;
  begin
    meats := str_table ('kielbasa', 'szynka', 'wedlina', 'galareta', 'pieczeń', 'kaszanka');
    kinds := str_table ('swojska', 'podwędzana', 'górnicza', 'jałowcowa', 'dymiona', 'z beczki', 'czarna', 'soczysta');
    for i in 1..128 loop
      meat_nr := dbms_random.value(1, meats.count);
      kind_nr := dbms_random.value(1, kinds.count);
      insert into recipes values (meats(meat_nr) || ' ' || kinds(kind_nr)|| ' ' || to_char(i));
    end loop;
    dbms_output.put_line('Added 128 recipes');
  end;
/


CREATE or replace procedure shifts_generator as
  begin
    for i in 1..100 loop
      insert into shifts (date_of_shift, department) values (
             (select to_date('1999-01-01','yyyy-mm-dd') + trunc(dbms_random.value(1,10000)) from dual),
             (select * from (select id from departments order by dbms_random.value) where rownum = 1));
    end loop;
  end;
/

create or replace procedure workers_on_shifts_generator as
  begin
    for i in 1..100 loop
        --TODO
    end loop;
  end;
/

create or replace procedure production_generator as
  begin
    for i in 1..5000 loop
      --TODO
    end loop;
  end;
/

create or replace procedure recipes_ingredients_generator as
  begin
    for i in 1...500 loop
      --TODO
    end loop;
  end;
/
/* END GENERATORS */


/* EXECUTE GENERATORS */

begin
  employees_generator();
  departments_generator();
  ingredients_generator();
  recipes_generator();
  shifts_generator();
  workers_on_shifts_generator();
  recipes_ingredients_generator();
  production_generator();
end;

commit;

/* CHECK RESULTS */

/*
select * from employees;
select d.id, d.name, e.name, e.surname from departments d join employees e on d.manager = e.id;
select * from ingredients;
select * from recipes;
select date_of_shift, departments.name as department from shifts join departments on shifts.department = departments.id;

select departments.name as dep_name, count (shifts.date_of_shift) as count
from shifts
  join departments on shifts.department = departments.id
group by departments.name
order by departments.name asc;
*/