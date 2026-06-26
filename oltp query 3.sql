select s.stud_name, -- показывает, кто каким дополнительным занятеим занимается
	   s.stud_surname,
	   e.ellective_name
from students s
join ellectives e on (s.ellective_id = e.ellective_id)
order by stud_name