-- заполнение OLAP из OLTP
/*ПРЕЖДЕ ЧЕМ ЗАПУСКАТЬ ЭТОТ ФАЙЛ, ЗАПУСТИТЕ СКРИПТ postgres fdw*/
insert into DimSubject(subject_id, subject_name)
select su.subj_id,
su.subject_name
from subjects su
on conflict (subject_id) do nothing;

insert into DimDepartment(department_id, department_name)
select d.dep_id,
d.department_name
from departments d
on conflict (department_id) do nothing;

insert into DimInstrument(instrument_id, instrument_name, department_key)
select i.instr_id,
i.instrument_name,
D.department_key
from instruments i
join DimDepartment D on (D.department_id = i.dep_id)
on conflict (instrument_id) do nothing;

insert into DimTeacher (teacher_id,	teacher_name, instrument_key, subject_key)
select t.teacher_id,
t.teacher_name,
I.instrument_key,
S.subject_key
from teachers t
join DimInstrument I on (I.instrument_id = t.instr_id)
join DimSubject S on (S.subject_id = t.subj_id)
on conflict (teacher_id) do nothing;

update DimStudent ds --если у ученика сменился инструмент/отделение, то SCD type 2 - новая запись
set date_to = current_date,
isCurrent = false
from students s
join DimInstrument di on (di.instrument_id = s.instr_id)
join DimDepartment dd on (dd.department_id = s.dep_id)
where s.stud_id = ds.student_id and
	  isCurrent = TRUE and 
row(
	ds.instrument_key, 
	ds.department_key
  ) is distinct from 
  row( 
	di.instrument_key, 
	dd.department_key
  );

update DimStudent ds --если у ученика сменилась фамилия/имя, то мы просто меняем их, без новй записи
set student_name = s.stud_name,
    student_surname = s.stud_surname
from students s
where ds.student_id = s.stud_id
  and ds.isCurrent = TRUE
  and (
      ds.student_name is distinct from s.stud_name
      or
      ds.student_surname is distinct from s.stud_surname
  );
  

update DimStudent ds -- если ученик ушел, мы удалили его из csv и oltp, то мы помечаем его false
set isCurrent = false,
    date_to = current_date
where ds.isCurrent = true
  and not exists (
      select 1
      from students s
      where s.stud_id = ds.student_id
  );
  
-- добавляем студента, которого еще нет в olap
insert into DimStudent (student_id, student_name, student_surname, enroll_date, department_key, instrument_key, date_from, date_to, isCurrent)
select s.stud_id,
s.stud_name,
s.stud_surname,
s.enroll_date,
D.department_key,
I.instrument_key,
CURRENT_DATE,
'9999-12-01', 
TRUE
from students s
join DimInstrument I on (I.instrument_id = s.instr_id)
join DimDepartment D on (D.department_id = s.dep_id)
where not exists (
    select *
    from DimStudent ds
    where ds.student_id = s.stud_id
);

-- добавляем студента, у которго новая запись (SCD)
insert into DimStudent (student_id, student_name, student_surname, enroll_date, department_key, instrument_key, date_from, date_to, isCurrent)
select s.stud_id,
s.stud_name,
s.stud_surname,
s.enroll_date,
D.department_key,
I.instrument_key,
current_date, 
'9999-12-01', 
TRUE
from students s
join DimInstrument I on (I.instrument_id = s.instr_id)
join DimDepartment D on (D.department_id = s.dep_id)
where exists (
    select *
    from DimStudent ds
    where ds.student_id = s.stud_id
      and ds.isCurrent = FALSE
      and ds.date_to = current_date
) and not exists (
    select *
    from DimStudent cur
    where cur.student_id = s.stud_id
      and cur.isCurrent = TRUE
);


insert into BridgeTable(student_key, teacher_key, subject_key)
select ds.student_key,
dt.teacher_key,
dsu.subject_key
from student_teacher st
join DimStudent ds on (ds.student_id = st.stud_id) and (ds.isCurrent = true)
join DimTeacher dt on (dt.teacher_id = st.teacher_id)
join DimSubject dsu on (dsu.subject_id = st.subj_id)
on conflict (student_key, teacher_key, subject_key) do nothing;

insert into FactGrade (bridge_key, semestr, grade) 
select bt.bridge_key,
g.semestr,
g.grade
from grades g
join DimSubject dsu on (dsu.subject_id = g.subj_id)
join DimStudent ds on (ds.student_id = g.stud_id) and (ds.isCurrent = true)
join BridgeTable bt on (bt.student_key = ds.student_key) and (bt.subject_key = dsu.subject_key)
on conflict (bridge_key, semestr) do update
set grade = excluded.grade
where FactGrade.grade is distinct from excluded.grade;

insert into FactPerformance (student_key, semestr, average)
select ds.student_key,
g.semestr,
round(avg(g.grade), 2)
from grades g
join DimStudent ds on (ds.student_id = g.stud_id) and (ds.isCurrent = true)
group by ds.student_key, g.semestr
on conflict (student_key, semestr) do update
set average = excluded.average
where FactPerformance.average is distinct from excluded.average;