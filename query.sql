--  DDL for View VIEW_DOST
--------------------------------------------------------

CREATE OR REPLACE FORCE VIEW "TERS"."VIEW_DOST" ("Сотрудник", "Дата", "Доступ кем предоставлен", "Кому предоставлен") AS 
  SELECT 
    p.FAM' 'p.NAME AS "Сотрудник",
    TO_CHAR(d.DATE_GRANTED,'YYYY-MM-DD HH:MM:SS') AS "Дата",
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM TEST_DEP dep 
            WHERE dep.id_d = p.id_d AND dep.CHIEF_DEP = d.GRANTED_BY
        ) THEN 'Начальник ' || 
             (SELECT FAM' 'NAME FROM TEST_PEOPLE WHERE ID_P = d.GRANTED_BY)
        ELSE (SELECT FAM' 'NAME FROM TEST_PEOPLE WHERE ID_P = d.GRANTED_BY)
    END AS "Доступ кем предоставлен",
    (SELECT FAM' 'NAME FROM TEST_PEOPLE WHERE ID_P = d.GRANTED_AT) as "Кому предоставлен"
FROM 
    TEST_PEOPLE p 
    INNER JOIN TEST_DOST d ON p.ID_P = d.ID_P;

CREATE OR REPLACE FORCE VIEW "TERS"."VIEW_DOST_ANIMALS" ("Ресурс", "Дата", "Доступ кем предоставлен", "Кому предоставлен") AS 
SELECT 
    a.NAME_A' 'a.TYPE AS "Ресурс",
    TO_CHAR(d.DATE_GRANTED,'YYYY-MM-DD HH:MM:SS') AS "Дата",
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM TEST_DEP dep 
            WHERE dep.id_d = p.id_d AND dep.CHIEF_DEP = d.GRANTED_BY
        ) THEN 'Начальник ' || 
             (SELECT FAM' 'NAME FROM TEST_PEOPLE WHERE ID_P = d.GRANTED_BY)
        ELSE (SELECT FAM' 'NAME FROM TEST_PEOPLE WHERE ID_P = d.GRANTED_BY)
    END AS "Доступ кем предоставлен",
    (SELECT FAM' 'NAME FROM TEST_PEOPLE WHERE ID_P = d.GRANTED_AT) as "Кому предоставлен"
FROM 
    TEST_PEOPLE p
    INNER JOIN TEST_DOST d ON a.ID_P = d.ID_P
    INNER JOIN TEST_ANIMALS a on a.id_p = p.id_p
    ;

3-----
Select distinct FAM' 'NAME "Сотрудник",
COUNT(GRANTED_BY) OVER (PARTITION BY GRANTED_BY) "Кол-во пред.доступов"
from TEST_PEOPLE p 
left join TEST_DOST d on p.id_p = d.id_p

4----
With t1 as (Select FAM,NAME,ID_D,
(Select NAME_DEP from TEST_PEOPLE p inner join TEST_DEP d
on p.id_d = d.id_d where GRANTED_AT = ID_P) "Какому отделу пред доступ" 
from TEST_DOST d left join TEST_PEOPLE p on 
d.id_p = p.id_p
where (Select ID_D from TEST_PEOPLE where GRANTED_AT = ID_P)!=ID_D)
Select "Какому отделу пред доступ" , count(*) "Кол-во" from t1
group by "Какому отделу пред доступ"

5-----
Select 
(Select FAM' 'NAME from TEST_PEOPLE where ID_P = GRANTED_AT) "Сотрудник"
 from TEST_PEOPLE p inner join 
TEST_DOST d on p.ID_P = d.GRANTED_AT
group by GRANTED_AT
having count(GRANTED_AT)>3

6 ----
Select FAM' 'NAME "Сотрудник",NAME_DEP from 
TEST_PEOPLE p inner join TEST_DEP d on p.ID_D = d.ID_D
where p.ID_P in (Select distinct ID_P from TEST_RESTRICT_ACCESS)

7--------
Select FAM' 'NAME "Сотрудник",
(Select FAM' 'NAME from TEST_PEOPLE where ID_P = CHIEF_DEP) "Начальник",
count(ID_P) OVER (PARTITION BY ID_P) as "Кол-во выданных доступов",
NAME_DEP from TEST_PEOPLE p 
inner join TEST_DEP d on p.ID_D = d.ID_D
left join TEST_DOST do on do.ID_P = p.ID_P
order by FAM,NAME


--пример добавления доступа 
-- Добавление доступа
DECLARE
    v_result NUMBER;
BEGIN
    v_result := test.change_dost(42,42,22,1);
    IF v_result = 1 THEN
        DBMS_OUTPUT.PUT_LINE('Доступ успешно добавлен');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Ошибка: ' || v_result);
    END IF;
END;