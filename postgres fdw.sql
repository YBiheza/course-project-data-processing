CREATE EXTENSION postgres_fdw;

CREATE SERVER Music_School
FOREIGN DATA WRAPPER postgres_fdw
OPTIONS (
    host 'localhost',
    dbname 'Music_School',
    port '5432'
);

CREATE USER MAPPING FOR CURRENT_USER
SERVER oltp_server
OPTIONS (
    user 'postgres',
    password '408008'
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
FROM SERVER oltp_server
INTO public;
