/*** 建表操作 ***/
create table student(sid int, name char(100), login char(100), age int, gpa float);
+-------+--------+------------+------+------+
| sid   | name   | login      | age  | gpa  |
+-------+--------+------------+------+------+
| 53655 | Tupac  | shakur@cs  |   26 |  3.5 |
| 53666 | Kanye  | Kayne@cs   |   39 |    4 |
| 53688 | Bieber | jbieber@cs |   22 |  3.9 |
+-------+--------+------------+------+------+


create table enrolled(sid int, cid char(100), grade char(2));
+-------+--------+-------+
| sid   | cid    | grade |
+-------+--------+-------+
| 53655 | 15-445 | B     |
| 53666 | 15-445 | C     |
| 53666 | 15-721 | C     |
| 53688 | 15-721 | A     |
| 53688 | 15-826 | B     |
+-------+--------+-------+


create table course(cid char(100), name char(100));
+--------+------------------------------+
| cid    | name                         |
+--------+------------------------------+
| 15-445 | Database Systems             |
| 15-721 | Advanced Systems             |
| 15-823 | Advanced Topics in Databases |
| 15-826 | Data Mining                  |
+--------+------------------------------+


/*** string operations  ***/
-- sql 92
select name from student where login = lower(name) || '@cs';

-- mysql
select name from student where login = lower(name) || '@cs';



/*** time opertions  ***/
--mysql
select datediff(date('2018-08-29'), date('2018-01-01')) as days;



/*** 输出重定向  ***/
-- 1.对于需要被插入的表，可以不必事先创建，在数据重定向时创建即可
create table CourseIds(select distinct cid from enrolled);

-- 2.也可以将数据插入已经存在的表中
insert into CourseIds(select distinct cid from enrolled);


-- 按属性对select结果排序
select sid, grade from enrolled where cid = '15-721' order by grade;

select sid from enrolled where cid = '15-721' order by grade desc,sid asc;

-- limit <count> [offset] 使用
select sid, name from student where login like '%@cs' limit 10;

select sid, name from student where login like '%@cs' limit 20 offset 10;

/*** 嵌套查询  ***/
select name from student where sid in (select sid from enrolled);

-- get the names of student in '15-445'
select name from student where sid in (select sid from enrolled where cid = '15-445');


-- find student revord whih the highest id that is enrolled in at least one course
-- 有问题
select max(e.sid), s.name from enrolled as e, student as s where e.sid = s.sid;

-- 修改版本1
select sid, name from student where sid in (
  select max(sid) from enrolled
);

-- 修改版本2, 但是mysql暂时不支持内层查询的limit
select sid, name from student where sid in (
 select sid from enrolled order by sid desc limit 1
);


-- find all courses that has no students enrolled in it
select * from course where not exists(
  -- 内层查询可以调用外层查询使用的表信息
  select * from enrolled where course.cid = enrolled.cid
);


/*** windows functions ***/
--1. Aggregation function

--2. Special windows function
-- 分析函数，生成一个排序列
select *, row_number() over() as row_num from enrolled;

-- 根据cid分组并排序
select cid, sid, row_number() over(partition by cid) from enrolled order by cid;

-- find the student with the highest grade for each course
select * from (
  select *, rank() over
    (partition by cid order by grade asc) 
  as rank from enrolled) 
as ranking where ranking.rank = 1;