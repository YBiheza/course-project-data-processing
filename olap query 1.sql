select fp.semestr, -- показывает, какой средний балл получился в семестрах по отделениям (между учениками разных лет)
       dd.department_name,
       round(avg(fp.average)) as average
from FactPerformance fp
join DimStudent ds on ds.student_key = fp.student_key
join DimDepartment dd on dd.department_key = ds.department_key
where ds.isCurrent = true
group by fp.semestr,
         dd.department_name
order by fp.semestr;