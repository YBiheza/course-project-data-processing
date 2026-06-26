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
