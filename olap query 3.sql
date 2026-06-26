select dt.teacher_name, -- можно увидеть, по каким преподавателям самый высокий средний балл
       round(avg(fg.grade)) as average
from FactGrade fg
join BridgeTable b on b.bridge_key = fg.bridge_key
join DimTeacher dt on dt.teacher_key = b.teacher_key
group by dt.teacher_name
order by average desc
limit 5; --можно менять количество