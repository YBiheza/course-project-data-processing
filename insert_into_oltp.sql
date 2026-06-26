/*==========================inserts into oltp============================*/
/*ПЕРЕД ЗАПУСКОМ СОГЛАСНО КОММЕНТАРИЯМ ВСТАВЬТЕ АБСОЛЮТНЫЕ ПУТИ К ФАЙЛАМ .CSV*/


--fill in ellectives from csv

create table if not exists stg_electives (
    ellective_name VARCHAR(20)
);

TRUNCATE TABLE stg_electives; -- храним только актуальные данные (тут и ниже)

copy stg_electives
from 'C:\Comp Science Degree\DataProcessing\course project\ellectives.csv' --пропишите абсолютный путь к .csv файлу ellectives.csv
delimiter ','
csv header;

insert into ellectives (ellective_name)
select distinct ellective_name
from stg_electives
on conflict (ellective_name) do nothing;


--fill in departments and instruments from csv

create table if not exists stg_dep_instr (
	department_name varchar(20),
	instrument_name varchar(20)
);

TRUNCATE TABLE stg_dep_instr;

copy stg_dep_instr
from 'C:\Comp Science Degree\DataProcessing\course project\dep_instr.csv' --пропишите абсолютный путь к .csv файлу dep_instr.csv
delimiter ','
csv header;

insert into departments(department_name)
select distinct department_name
from stg_dep_instr
on conflict (department_name) do nothing;

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
from 'C:\Comp Science Degree\DataProcessing\course project\teachers.csv'  --пропишите абсолютный путь к .csv файлу teachers.csv
delimiter ','
csv header;

insert into subjects(subject_name)
select distinct subject_name
from stg_teacher
on conflict (subject_name) do nothing; 

insert into teachers(teacher_name, instr_id, subj_id) 
select s.teacher_name,
i.instr_id,
su.subj_id
from stg_teacher s
join instruments i on (s.instrument_name = i.instrument_name)
join subjects su on (s.subject_name = su.subject_name)
on conflict (teacher_name, subj_id) do nothing;


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
from 'C:\Comp Science Degree\DataProcessing\course project\students.csv' --пропишите абсолютный путь к .csv файлу students.csv
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
from 'C:\Comp Science Degree\DataProcessing\course project\grades.csv' --пропишите абсолютный путь к .csv файлу grades.csv
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


delete from students s -- удаление студентов, отчислившихся из муз.школы
where not exists (
    select *
    from stg_students st
    where st.student_code = s.stud_code
);