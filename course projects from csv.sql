--drop table if exists departments, ellectives, subjects, instruments, students, teachers, grades, student_teacher, stg_dep_instr, stg_electives, stg_teacher, stg_grades, stg_students;
-- creating tables for OLTP
create table if not exists departments (
	dep_id serial primary key,
	department_name varchar(20) unique not null
); 

create table if not exists ellectives (
	ellective_id serial primary key,
	ellective_name varchar(20) unique not null
);

create table if not exists subjects (
	subj_id serial primary key,
	subject_name varchar(25) unique not null
);

create table if not exists instruments (
	instr_id serial primary key,
	instrument_name varchar(20) unique not null,
	dep_id integer not null,
	foreign key (dep_id) references departments(dep_id)
);

create table if not exists students (
	stud_id serial primary key,
	stud_code varchar(7) unique,
	stud_name varchar(20) not null,
	stud_surname varchar(25) not null,
	date_of_birth date not null,
	enroll_date integer not null,
	dep_id integer not null,
	instr_id integer not null,
	ellective_id integer not null,
	foreign key (dep_id) references departments(dep_id),
	foreign key (instr_id) references instruments(instr_id),
	foreign key (ellective_id) references ellectives(ellective_id)
);

create table if not exists teachers (
	teacher_id serial primary key,
	teacher_name varchar(25) not null,
	instr_id integer not null,
	subj_id integer not null,
	unique (teacher_name, subj_id),
	foreign key (subj_id) references subjects(subj_id),
	foreign key (instr_id) references instruments(instr_id)
);

create table if not exists grades (
	stud_id integer not null,
	subj_id integer not null,
	semestr int not null,
	grade int not null,
	unique (stud_id, subj_id, semestr),
	primary key (stud_id, subj_id, semestr),
	foreign key (subj_id) references subjects(subj_id),
	foreign key (stud_id) references students(stud_id)
);

create table if not exists student_teacher (
	stud_id integer not null,
	teacher_id integer not null,
	subj_id integer not null,
	unique (stud_id, subj_id),  -- ученик и так может учить предмет только у одного учителя, поэтому такой unique
	primary key (stud_id, teacher_id, subj_id),
	foreign key (stud_id) references students(stud_id),
	foreign key (teacher_id) references teachers(teacher_id),
	foreign key (subj_id) references subjects(subj_id)
);


alter table grades
drop constraint grades_stud_id_fkey,
drop constraint grades_subj_id_fkey;

alter table grades
add constraint grades_stud_id_fkey
foreign key (stud_id) references students(stud_id) on delete cascade,

--данные ограничения необходимы, чтобы при удалении студента из БД (он отчислился), удалялись и все связанные с ним связи
add constraint grades_subj_id_fkey
foreign key (subj_id) references subjects(subj_id)
on delete cascade;

alter table student_teacher 
drop constraint student_teacher_stud_id_fkey,
drop constraint student_teacher_subj_id_fkey,
drop constraint student_teacher_teacher_id_fkey;

alter table student_teacher 
add constraint student_teacher_stud_id_fkey
foreign key (stud_id) references students(stud_id) on delete cascade,

add constraint student_teacher_subj_id_fkey
foreign key (subj_id) references subjects(subj_id) on delete cascade,

add constraint student_teacher_teacher_id_fkey
foreign key (teacher_id) references teachers(teacher_id) on delete cascade;
/*==========================tables are created===========================*/

/*==========================inserts into oltp============================*/
--fill in ellectives from csv

create table if not exists stg_electives (
    ellective_name VARCHAR(20)
);

TRUNCATE TABLE stg_electives; -- храним только актуальные данные (тут и ниже)

copy stg_electives
from 'C:\Comp Science Degree\DataProcessing\course project\ellectives.csv'
delimiter ','
csv header;

insert into ellectives (ellective_name)
select distinct ellective_name
from stg_electives
on conflict (ellective_name) do nothing;/*update
	set	ellective_name = excluded.ellective_name
	where ellectives.ellective_name is distinct from excluded.ellective_name;*/


--fill in departments and instruments from csv

create table if not exists stg_dep_instr (
	department_name varchar(20),
	instrument_name varchar(20)
);

TRUNCATE TABLE stg_dep_instr;

copy stg_dep_instr
from 'C:\Comp Science Degree\DataProcessing\course project\dep_instr.csv'
delimiter ','
csv header;

insert into departments(department_name)
select distinct department_name
from stg_dep_instr
on conflict (department_name) do nothing; /*update
set department_name = excluded.department_name
where departments.department_name is distinct from excluded.department_name;*/

insert into instruments(instrument_name, dep_id)
select s.instrument_name,
	d.dep_id
from stg_dep_instr s
join departments d on (d.department_name = s.department_name)
on conflict (instrument_name) do nothing;


--fill in teachers and subjects from csv

create table if not exists stg_teacher (
	teacher_name varchar(25),
	instrument_name varchar(20),
	subject_name varchar(25)
);

TRUNCATE TABLE stg_teacher;

copy stg_teacher
from 'C:\Comp Science Degree\DataProcessing\course project\teachers.csv'
delimiter ','
csv header;

insert into subjects(subject_name)
select distinct subject_name
from stg_teacher
on conflict (subject_name) do nothing; /*update
set subject_name = excluded.subject_name
where subjects.subject_name is distinct from excluded.subject_name;*/

insert into teachers(teacher_name, instr_id, subj_id) 
select s.teacher_name,
i.instr_id,
su.subj_id
from stg_teacher s
join instruments i on (s.instrument_name = i.instrument_name)
join subjects su on (s.subject_name = su.subject_name)
on conflict (teacher_name, subj_id) do nothing /*update
set teacher_name = excluded.teacher_name,
	subj_id = excluded.subj_id
where teachers.teacher_name is distinct from excluded.teacher_name or
      teachers.subj_id is distinct from excluded.subj_id*/;


--fill in students and student_teacher from csv

create table if not exists stg_students (
	student_code varchar(7),
	student_name varchar(20),
	student_surname varchar(20),
	birthday date,
	enroll_year integer,
	department_name varchar(20),
	instrument_name varchar(20),
	ellective_name varchar(20),
	teacher_name varchar(25),
	solfeggio_teacher varchar(25),
	literature_teacher varchar(25),
	choir_teacher varchar(25)
);

TRUNCATE TABLE stg_students;

copy stg_students
from 'C:\Comp Science Degree\DataProcessing\course project\students.csv'
delimiter ','
csv header;

insert into students(stud_code, stud_name, stud_surname, date_of_birth, enroll_date, dep_id, instr_id, ellective_id)
select s.student_code,
s.student_name, 
s.student_surname, 
s.birthday, 
s.enroll_year,
d.dep_id,
i.instr_id,
e.ellective_id
from stg_students s
join departments d on (s.department_name = d.department_name)
join instruments i on (s.instrument_name = i.instrument_name)
join ellectives e on (s.ellective_name = e.ellective_name)
on conflict (stud_code) do update -- если мы вставляем студента с таким же кодом, как уже есть,это перезапишет имеющуюся запись
set
	stud_name = excluded.stud_name,
	stud_surname = excluded.stud_surname,
	date_of_birth = excluded.date_of_birth,
	dep_id = excluded.dep_id,
	instr_id = excluded.instr_id,
	ellective_id = excluded.ellective_id
where
students.stud_name is distinct from excluded.stud_name or
students.stud_surname is distinct from excluded.stud_surname or
students.date_of_birth is distinct from excluded.date_of_birth or
students.dep_id is distinct from excluded.dep_id or
students.instr_id is distinct from excluded.instr_id or
students.ellective_id is distinct from excluded.ellective_id;


insert into student_teacher(stud_id, teacher_id, subj_id) 
select s.stud_id,
t.teacher_id,
su.subj_id
from stg_students st
--join students s on (st.student_name = s.stud_name) and (st.student_surname = s.stud_surname)
join students s on (st.student_code = s.stud_code)
join teachers t on (st.teacher_name = t.teacher_name)
join subjects su on (su.subject_name = 'Специальность') -- заполняем связки именно с учителем специальности
on conflict (stud_id, subj_id) do update -- если случится повтор связки ученик+предмет (значит, сменился учитель по специальности), то старая запись перезапишется
set
	stud_id = excluded.stud_id,
	teacher_id = excluded.teacher_id,
	subj_id = excluded.subj_id
where student_teacher.stud_id is distinct from excluded.stud_id or
student_teacher.teacher_id is distinct from excluded.teacher_id or
student_teacher.subj_id is distinct from excluded.subj_id;

insert into student_teacher(stud_id, teacher_id, subj_id)
select s.stud_id,
t.teacher_id,
su.subj_id
from stg_students st
--join students s on (st.student_name = s.stud_name) and (st.student_surname = s.stud_surname)
join students s on (st.student_code = s.stud_code)
join teachers t on (st.solfeggio_teacher = t.teacher_name)
join subjects su on (su.subject_name = 'Сольфеджио') -- связки с учителями сольфеджио
on conflict (stud_id, teacher_id, subj_id) do update -- если случится повтор связки ученик+предмет (значит, сменился учитель), то старая запись перезапишется
set
	stud_id = excluded.stud_id,
	teacher_id = excluded.teacher_id,
	subj_id = excluded.subj_id
where student_teacher.stud_id is distinct from excluded.stud_id or
	student_teacher.teacher_id is distinct from excluded.teacher_id or
	student_teacher.subj_id is distinct from excluded.subj_id;

insert into student_teacher(stud_id, teacher_id, subj_id) 
select s.stud_id,
t.teacher_id,
su.subj_id
from stg_students st
--join students s on (st.student_name = s.stud_name) and (st.student_surname = s.stud_surname)
join students s on (st.student_code = s.stud_code)
join teachers t on (st.choir_teacher = t.teacher_name)
join subjects su on (su.subject_name = 'Хор') -- связь с учителем хора
on conflict (stud_id, teacher_id, subj_id) do update -- если случится повтор связки ученик+предмет (значит, сменился учитель), то старая запись перезапишется
set
	stud_id = excluded.stud_id,
	teacher_id = excluded.teacher_id,
	subj_id = excluded.subj_id
where student_teacher.stud_id is distinct from excluded.stud_id or
	student_teacher.teacher_id is distinct from excluded.teacher_id or
	student_teacher.subj_id is distinct from excluded.subj_id;

insert into student_teacher(stud_id, teacher_id, subj_id) 
select s.stud_id,
t.teacher_id,
su.subj_id
from stg_students st
--join students s on (st.student_name = s.stud_name) and (st.student_surname = s.stud_surname)
join students s on (st.student_code = s.stud_code)
join teachers t on (st.literature_teacher = t.teacher_name)
join subjects su on (su.subject_name = 'Музыкальная литература') --связь с учителем муз.лит.
on conflict (stud_id, teacher_id, subj_id) do update -- -- если случится повтор связки ученик+предмет (значит, сменился учитель), то старая запись перезапишется
set
	stud_id = excluded.stud_id,
	teacher_id = excluded.teacher_id,
	subj_id = excluded.subj_id
where student_teacher.stud_id is distinct from excluded.stud_id or
	student_teacher.teacher_id is distinct from excluded.teacher_id or
	student_teacher.subj_id is distinct from excluded.subj_id;


--fill in grades from csv

create table if not exists stg_grades (
	student_code varchar(7),
	sem int,
	subject_name varchar(25),
	grade int
);

TRUNCATE TABLE stg_grades;

copy stg_grades
from 'C:\Comp Science Degree\DataProcessing\course project\grades.csv'
delimiter ','
csv header;

insert into grades(stud_id, subj_id, semestr, grade)
select st.stud_id,
su.subj_id,
s.sem,
s.grade
from stg_grades s
join students st on (s.student_code = st.stud_code)
join subjects su on (s.subject_name = su.subject_name)
on conflict (stud_id, subj_id, semestr) do update --если изменилась отметка (студент пересдал), то изменяем данные
set grade = excluded.grade
where grades.grade is distinct from excluded.grade;
/*on conflict (stud_id, subj_id, semestr) do update
set
	stud_id = excluded.stud_id,
	subj_id = excluded.subj_id,
	semestr = excluded.semestr
where grades.stud_id is distinct from excluded.stud_id or
	  grades.subj_id is distinct from excluded.subj_id or
	  grades.semestr is distinct from excluded.semestr;*/

delete from students s
where not exists (
    select *
    from stg_students st
    where st.student_code = s.stud_code
);