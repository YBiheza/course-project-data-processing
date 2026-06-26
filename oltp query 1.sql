select t.teacher_name, --показывает, какие ученики есть у каждого преподавателя
       s.stud_name,
       s.stud_surname,
       sub.subject_name
from student_teacher st
join teachers t on t.teacher_id = st.teacher_id
join students s on s.stud_id = st.stud_id
join subjects sub on sub.subj_id = st.subj_id
order by t.teacher_name, s.stud_surname;