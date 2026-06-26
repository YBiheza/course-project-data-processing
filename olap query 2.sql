select ds.student_name, --топ-х лучших студентов по среднему баллу
       ds.student_surname,
       round(avg(fp.average)) as average
from FactPerformance fp
join DimStudent ds on ds.student_key = fp.student_key
where ds.isCurrent = true
group by ds.student_name,
         ds.student_surname
order by average desc
limit 10; --можно менять количество