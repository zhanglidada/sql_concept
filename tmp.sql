/*** 建表操作 ***/
create table student(sid int, name char(100), login char(100), age int, gpa float);
+-------+--------+------------+------+------+
| sid   | name   | login      | age  | gpa  |
+-------+--------+------------+------+------+
| 53666 | Kanye  | Kayne@cs   |   39 |  4.0 |
| 53688 | Bieber | jbieber@cs |   22 |  3.9 |
| 53655 | Tupac  | shakur@cs  |   26 |  3.5 |
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


/***           aggregates             ***/
-- aggregate functions can only be used in the select output list.
select count(login) as cnt from student where login like '%@cs';

select count(*) as cnt from student where login like '%@cs';

select count(1) as cnt from student where login like '%@cs';


/***           multiple aggregates      ***/
-- get the number of students and their avg gpa that has a "@cs" login
select avg(gpa), count(sid) from student where login like '%@cs';

/***           distinct aggregates      ***/
select count(distinct login) from student where login like '%@cs';


/***           group by       ***/
select avg(gpa), e.cid from enrolled as e, student as s
  where e.sid = s.sid
  group by e.cid;

-- non-aggregated values in select output clause must appear in group by clause
-- s.name为非聚集，且没有在分组中
select avg(gpa), e.cid, s.name from enrolled as e, student as s
  where e.sid = s.sid
  group by e.cid;

-- 修改如下,group by 含有多个属性时，即按照属性组合的唯一性进行分析
select avg(gpa), e.cid, s.name from enrolled as e, student as s
  where e.sid = s.sid
  group by e.cid, s.name;


/***           having          ***/
-- filters results based on aggregation computation could not used in where clause
select avg(s.gpa) as avg_gpa, e.cid from enrolled as e, student as s
  where s.sid = e.sid
  and avg_gpa > 3.9
  group by e.cid;

-- 修改，使用having计算 aggregate结果
select avg(s.gpa) as avg_gpa, e.cid from enrolled as e, student as s
  where s.sid = e.sid
  group by e.cid
  having avg_gpa > 3.9;


/*** string operations  ***/
-- like is used fo string matching, '%' matches any substring and '_' matches any one character
select * from enrolled as e where e.cid like '15-%';

select * from student as s where s.login like '%@c_';

-- mysql 下标从1开始
select substring(name, 1, 5) as abbrv_name from student where sid = 53688;

select * from student as s where upper(s.name) like 'KAN%';



-- sql 92
select name from student where login = lower(name) || '@cs';

-- mysql
select name from student where login = lower(name) || '@cs';



/*** time opertions  ***/
--mysql
select datediff(date('2018-08-29'), date('2018-01-01')) as days;



/*** 输出重定向  ***/
-- 1.需要将数据重定向到表中时，可以在创建表的同时插入数据
create table CourseIds(select distinct cid from enrolled);

-- 2.也可以将数据插入已经存在的表中
insert into CourseIds(select distinct cid from enrolled);

-- order by <column*> [asc|desc]
select sid from enrolled where cid = '15-721' order by grade desc,sid asc;

-- limit <count> [offset]
-- 限制结果集元组个数为10
select sid, name from student where login like '%@cs' limit 10;

-- 限制结果集元组个数为20, 且从第10个开始
select sid, name from student where login like '%@cs' limit 20 offset 10;

/*** 嵌套查询  ***/
-- 此时的
select name from student where sid in (select sid from enrolled);

-- get the names of student in '15-445'
select name from student where sid in (select sid from enrolled where cid = '15-445');

-- 使用any匹配子查询中任意结果
select name from student where sid = any(
  select sid from enrolled where cid = '15-445'
);

-- 使用嵌套子查询
select (select s.name from student as s where s.sid = e.sid) as sname
  from enrolled as each
  where cid = '15-445';

-- find student revord whih the highest id that is enrolled in at least one course
-- 有问题，因为存在aggregation function和非aggragation function
select max(e.sid), s.name from enrolled as e, student as s where e.sid = s.sid;

-- 修改版本1
select sid, name from student where sid in (
  select max(sid) from enrolled
);

-- 修改版本2, 但是mysql暂时不支持内层查询的limit
select sid, name from student where sid in (
  -- 内层查询课程注册信息，降序排列且限制为一个
  select sid from enrolled order by sid desc limit 1
);


-- find all courses that has no students enrolled in it
select * from course as c where not exists(
  -- 内层查询可以调用外层查询使用的表信息，查询课程注册表中有哪些课程被注册
  select * from enrolled as e where c.cid = e.cid
);

-- 可以实现同样的效果,修改版1
select c.cid, c.name from course as c where c.cid not in(
  -- 查找所有被注册课程的cid
  select e.cid from enrolled as e where c.cid = e.cid
);

-- 可以实现同样的效果,修改版2
select c.cid, c.name from course as c where c.cid not in(
  -- 查找所有被注册课程的cid
  select distinct(e.cid) from enrolled as e
);



/*** windows functions ***/
--1. Aggregation function

--2. Special windows function
-- 分析函数，生成一个排序列
select *, row_number() over() as row_num from enrolled;

-- 根据cid分区
select cid, sid, row_number() over(partition by cid) from enrolled order by cid;

-- 结果同第一个一样
select *, row_number() over(order by cid) from enrolled order by cid;



-- find the student with the highest grade for each course
select * from (select *, rank() over (partition by cid order by grade asc) as grade_rank from enrolled) 
as ranking where ranking.grade_rank = 1;


/***     common table expressions   ***/
-- provides a way to write auxiliary statements for use in a large query(just like a temp table for one query)

-- simple use of it
with ctename as (select 1)
select * from ctename;

-- you can bind output columns to names before the 'as' keyword
with ctename (col1, col2) as (
  select 1, 2
)
select col1 + col2 from ctename; 


-- find student record with the highest id that is enrolled in at least one course

-- get a temp view and can only used in this clause
with cteSource (maxId) as (
  -- find the max sid in enrolled table
  select max(sid) from enrolled
)
-- use student table and the temp view
select name from student, cteSource where student.sid = cteSource.maxId;

-- print the sequence of number from 1 to 10, 使用了递归的cte
with recursive cteSource(counter) as (
  (
    select 1  -- 初始查询，形成cte结构的基本结果集，即锚成员
  )
  union all
  (
    select counter + 1 from cteSource  -- 递归成员,引用了cte名称
    where counter < 10  -- 中止条件
  ) 
)
select * from cteSource;  -- 使用cte查询


