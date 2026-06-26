CREATE EXTENSION postgres_fdw;

CREATE SERVER Music_School --название вашей OLTP-базы данных
FOREIGN DATA WRAPPER postgres_fdw
OPTIONS (
    host 'localhost',
    dbname 'Music_School', --название вашей OLTP-базы данных
    port '5432'
);

CREATE USER MAPPING FOR CURRENT_USER
SERVER oltp_server
OPTIONS (
    user 'postgres', --ваш юзер
    password '408008' -- ваш пароль
);

IMPORT FOREIGN SCHEMA public
LIMIT TO (
    students,
    teachers,
    subjects,
    grades,
    departments,
    instruments,
    student_teacher
)
FROM SERVER Music_School
INTO public;
