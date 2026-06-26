--создание таблиц для OLAP
create table if not exists DimSubject (
	subject_key serial primary key,
	subject_id integer unique not null,
	subject_name varchar(25) not null
); 

create table if not exists DimDepartment (
	department_key serial primary key,
	department_id integer unique not null,
	department_name varchar(20) not null
);

create table if not exists DimInstrument (
	instrument_key serial primary key,
	instrument_id integer unique not null,
	instrument_name varchar(20) not null,
	department_key integer not null,
	foreign key (department_key) references DimDepartment(department_key)
);

create table if not exists DimTeacher (
	teacher_key serial primary key,
	teacher_id integer unique not null,
	teacher_name varchar(25) not null,
	instrument_key integer not null,
	subject_key integer not null,
	foreign key (instrument_key) references DimInstrument(instrument_key),
	foreign key (subject_key) references DimSubject(subject_key)	
);

create table if not exists DimStudent (
	student_key serial primary key,
	student_id integer not null,
	student_name varchar(20) not null,
	student_surname varchar(25) not null,
	enroll_date integer not null,
	department_key integer not null,
	instrument_key integer not null,
	date_from date not null,
	date_to date not null,
	isCurrent boolean not null,
	foreign key (instrument_key) references DimInstrument(instrument_key),
	foreign key (department_key) references DimDepartment(department_key)
);

create table if not exists BridgeTable (
	bridge_key serial primary key,
	student_key integer not null,
	teacher_key integer not null,
	subject_key integer not null,
	unique (student_key, teacher_key, subject_key),
	foreign key (subject_key) references DimSubject(subject_key),	
	foreign key (student_key) references DimStudent(student_key),	
	foreign key (teacher_key) references DimTeacher(teacher_key)
);

create table if not exists FactGrade (
	grade_key serial primary key,
	bridge_key integer not null,
	semestr integer not null,
	grade integer not null,
	unique (bridge_key, semestr),
	foreign key (bridge_key) references BridgeTable(bridge_key)
);

create table if not exists FactPerformance (
	record_key serial primary key,
	student_key integer not null,
	semestr integer not null,
	average real not null,
	unique (student_key, semestr),
	foreign key (student_key) references DimStudent(student_key)
);

/*====================Tables are created======================*/
