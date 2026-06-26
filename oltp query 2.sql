select s.stud_name, --показывает все оценки студента за время учебы
       s.stud_surname,
       sub.subject_name,
       g.semestr,
       g.grade
from grades g
join students s on s.stud_id = g.stud_id
join subjects sub on sub.subj_id = g.subj_id
where s.stud_code = 'ST7' --любой код студента
order by g.semestr;
