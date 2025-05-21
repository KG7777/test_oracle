
create or replace PACKAGE BODY TEST AS

-- Вспомогательная функция для обработки общих ошибок
FUNCTION handle_common_errors(
    p_error_msg IN VARCHAR2,
    p_module IN VARCHAR2
) RETURN NUMBER AS
    v_result VARCHAR2(500);
BEGIN
    -- Специальная обработка для различных ошибок
    IF SQLCODE = -2291 THEN
        v_result := 'Нарушение ссылочной целостности: ' || p_error_msg;
    ELSIF SQLCODE = -1400 THEN
        v_result := 'Обязательное поле не заполнено: ' || p_error_msg;
    ELSIF SQLCODE = -2292 THEN
        v_result := 'Нарушение ограничения при удалении: ' || p_error_msg;
    ELSE
        v_result := 'Неизвестная ошибка ('  SQLCODE  '): ' || p_error_msg;
    END IF;

    -- Логирование ошибки
    rec_log_error(SQLCODE, v_result, p_module);
    ROLLBACK;
    RETURN SQLCODE;
END handle_common_errors;

--4. Добавление сотрудника 
FUNCTION insert_people(
    p_fam IN VARCHAR2,
    p_name IN VARCHAR2,
    p_dep IN NUMBER
) RETURN NUMBER AS
    v_new_id NUMBER;
    v_error_msg VARCHAR2(400);
    v_result VARCHAR2(500);
BEGIN
    -- Вставка данных 
    INSERT INTO TEST_PEOPLE (
        FAM,
        NAME,
        ID_D
    ) VALUES (
        p_fam, 
        p_name,
        p_dep
    )
    RETURNING ID_P INTO v_new_id;

    COMMIT;
    RETURN v_new_id;

EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        v_result := 'Duplicate value error: '||SUBSTR(SQLERRM,1,100);
        rec_log_error(SQLCODE, v_result, 'TEST.INSERT_PEOPLE');
        ROLLBACK;
        RETURN -1;

    WHEN VALUE_ERROR THEN  -- ORA-06502
        v_result := 'Type conversion error: '||SQLERRM;
        rec_log_error(-6502, v_result, 'TEST.INSERT_PEOPLE');
        ROLLBACK;
        RETURN -6502;

    WHEN INVALID_NUMBER THEN  -- ORA-01722
        v_result := 'Invalid number: '||SQLERRM;
        rec_log_error(-1722, v_result, 'TEST.INSERT_PEOPLE');
        ROLLBACK;
        RETURN -1722;

    WHEN OTHERS THEN
        v_error_msg := SQLERRM;

       RETURN handle_common_errors(v_error_msg, 'TEST.INSERT_PEOPLE');

        -- Логирование с выводом в том числе в DBMS_OUTPUT для отладки
        --DBMS_OUTPUT.PUT_LINE('DEBUG LOG: '||v_result);
        rec_log_error(SQLCODE, v_result, 'TEST.INSERT_PEOPLE');
        ROLLBACK;
        RETURN SQLCODE;
END insert_people;

--4. Удаление сотрудника
FUNCTION delete_people(
    p_id_p IN NUMBER
) RETURN NUMBER AS
    v_rows_deleted NUMBER;
    v_error_msg VARCHAR2(400);
    v_result VARCHAR2(500);
BEGIN
    -- Удаление записи
    DELETE FROM TEST_PEOPLE 
    WHERE ID_P = p_id_p;

    -- Получаем количество удаленных строк
    v_rows_deleted := SQL%ROWCOUNT;

    -- Если ни одна строка не была удалена
    IF v_rows_deleted = 0 THEN
        v_result := 'Запись с ID '  p_id_p  ' не найдена';
        rec_log_error(0, v_result, 'TEST.DELETE_PEOPLE');
        RETURN 0;  -- Возвращаем 0, если запись не найдена
    END IF;

    COMMIT;
    RETURN v_rows_deleted;  -- Возвращаем количество удаленных строк

EXCEPTION
    WHEN OTHERS THEN
        v_error_msg := SQLERRM;
        RETURN handle_common_errors(v_error_msg, 'TEST.DELETE_PEOPLE');

END delete_people;

--5. Добавление ресурса
FUNCTION insert_animal(
    p_type IN VARCHAR2,
    p_name IN VARCHAR2,
    p_id_p IN NUMBER
) RETURN NUMBER AS
    v_new_id NUMBER;
    v_error_msg VARCHAR2(400);
    v_result VARCHAR2(500);
BEGIN
    -- Вставка данных 
    INSERT INTO TEST_ANIMALS (
        TYPE,
        NAME_A,
        ID_P
    ) VALUES (
        p_type,
        p_name,
        p_id_p
    )
    RETURNING ID_A INTO v_new_id;

    COMMIT;
    RETURN v_new_id;

EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        v_result := 'Ошибка: дублирование ';
        rec_log_error(SQLCODE, v_result, 'TEST.INSERT_ANIMAL');
        ROLLBACK;
        RETURN -1;

    WHEN VALUE_ERROR THEN  -- ORA-06502
        v_result := 'Ошибка типа данных: ' || SUBSTR(SQLERRM, 1, 100);
        rec_log_error(-6502, v_result, 'TEST.INSERT_ANIMAL');
        ROLLBACK;
        RETURN -6502;

WHEN INVALID_NUMBER THEN  -- ORA-01722
        v_result := 'Некорректный числовой формат: ' || SUBSTR(SQLERRM, 1, 100);

rec_log_error(-1722, v_result, 'TEST.INSERT_ANIMAL');
        ROLLBACK;
        RETURN -1722;

    WHEN OTHERS THEN
        v_error_msg := SQLERRM;

        RETURN handle_common_errors(v_error_msg, 'TEST.INSERT_ANIMAL');
END insert_animal;

--5. Удаление ресурса
function delete_animal(
     p_id_a IN NUMBER
) RETURN NUMBER AS
    v_rows_deleted NUMBER;
    v_error_msg VARCHAR2(400);
    v_result VARCHAR2(500);
BEGIN
    -- Удаление записи
    DELETE FROM TEST_ANIMALS 
    WHERE ID_A = p_id_a;

    -- Получаем количество удаленных строк
    v_rows_deleted := SQL%ROWCOUNT;

    -- Если ни одна строка не была удалена 
    IF v_rows_deleted = 0 THEN
        v_result := 'Запись с ID '  p_id_a  ' не найдена';
        rec_log_error(0, v_result, 'TEST.DELETE_PEOPLE');
        RETURN 0;  -- Возвращаем 0, если запись не найдена
    END IF;

    COMMIT;
    RETURN v_rows_deleted;  -- Возвращаем количество удаленных строк

EXCEPTION
    WHEN OTHERS THEN
        v_error_msg := SQLERRM;
       RETURN handle_common_errors(v_error_msg, 'TEST.DELETE_PEOPLE');
  END delete_animal;

--добавление отдела
  function insert_dep(name_dep varchar2,chief_dep number default NULL) return number AS
    v_new_id NUMBER;
    v_error_msg VARCHAR2(400);
    v_result VARCHAR2(500);
BEGIN
    -- Вставка данных 
    INSERT INTO TEST_DEP (
        NAME_DEP,
        CHIEF_DEP
    ) VALUES (
        name_dep,
        chief_dep
    )
    RETURNING ID_D INTO v_new_id;

    COMMIT;
    RETURN v_new_id;

EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        v_result := 'Ошибка: дублирование записи ';
        rec_log_error(SQLCODE, v_result, 'TEST.INSERT_DEP');
        ROLLBACK;
        RETURN -1;

    WHEN VALUE_ERROR THEN  -- ORA-06502
        v_result := 'Ошибка типа данных: ' || SUBSTR(SQLERRM, 1, 100);
        rec_log_error(-6502, v_result, 'TEST.INSERT_ANIMAL');
        ROLLBACK;
        RETURN -6502;

    WHEN INVALID_NUMBER THEN  -- ORA-01722
        v_result := 'Некорректный числовой формат: ' || SUBSTR(SQLERRM, 1, 100);
        rec_log_error(-1722, v_result, 'TEST.INSERT_DEP');
        ROLLBACK;
        RETURN -1722;

    WHEN OTHERS THEN
        v_error_msg := SQLERRM;

        RETURN handle_common_errors(v_error_msg, 'TEST.INSERT_DEP');
  END insert_dep;

--удаление отдела
 function delete_dep(
     p_id_d IN NUMBER
) RETURN NUMBER AS
    v_rows_deleted NUMBER;
    v_error_msg VARCHAR2(400);
    v_result VARCHAR2(500);
BEGIN
    -- Удаление записи
    DELETE FROM TEST_DEP
    WHERE ID_D = p_id_d;

    -- Получаем количество удаленных строк
    v_rows_deleted := SQL%ROWCOUNT;

    -- Если ни одна строка не была удалена 
    IF v_rows_deleted = 0 THEN
        v_result := 'Запись с ID '  p_id_d  ' не найдена';
        rec_log_error(0, v_result, 'TEST.DELETE_DEP');
        RETURN 0;  -- Возвращаем 0, если запись не найдена
    END IF;

    COMMIT;
    RETURN v_rows_deleted;  -- Возвращаем количество удаленных строк

EXCEPTION
    WHEN OTHERS THEN
        v_error_msg := SQLERRM;
       RETURN handle_common_errors(v_error_msg, 'TEST.DELETE_DEP');
  END delete_dep;

  --4. Получение списка
  procedure show_all_people as
  begin
  for pe in (Select fam,name,nvl(name_dep,'Без отдела') name_dep,
              CASE 
                WHEN a.id_a IS NOT NULL THEN a.type  ' '  a.name_a
                ELSE 'Нет животного'
            END AS animal_info from 
    test_people p  LEFT JOIN test_dep d on p.id_d = d.id_d left join TEST_ANIMALS a on
    p.id_p = a.id_a) loop

    DBMS_OUTPUT.PUT_LINE(pe.fam' 'pe.name' 'pe.name_dep' 'pe.animal_info);
    end loop;

  end show_all_people;

  --4. Получение детальной информации по одному
  procedure show_one_people(p_id_p number) as

begin
  for pe in (Select fam,name,nvl(name_dep,'Без отдела') name_dep,
              CASE 
                WHEN a.id_a IS NOT NULL THEN a.type  ' '  a.name_a
                ELSE 'Нет животного'
            END AS animal_info from 
    test_people p  LEFT JOIN test_dep d on p.id_d = d.id_d left join TEST_ANIMALS a on
    p.id_p = a.id_a
    where id_p = p_id_p) loop

    DBMS_OUTPUT.PUT_LINE(pe.fam' 'pe.name' 'pe.name_dep' 'pe.animal_info);
    end loop;

  end show_one_people;

  --5. Получение списка
  procedure show_all_animals as
  begin
  for pe in (Select TYPE,NAME_A,FAM,NAME from TEST_ANIMALS a left join TEST_PEOPLE p on a.id_p = p.id_p) loop

    DBMS_OUTPUT.PUT_LINE(pe.type' 'pe.name_a' 'pe.fam' 'pe.name);
    end loop;

  end show_all_animals;

  --5. Получение детальной информации по одному
  procedure show_one_animal(p_id_p number) as
  begin
  for pe in (Select CASE 
                WHEN a.id_p = p_id_p THEN a.type  ' '  a.name_a
                ELSE 'Нет животного'
            END AS animal_info,FAM,NAME from TEST_PEOPLE p left join TEST_ANIMALS a on a.id_p = p.id_p
  where p.id_p = p_id_p) loop

    DBMS_OUTPUT.PUT_LINE(pe.fam' 'pe.name' 'pe.animal_info);
    end loop;

  end show_one_animal;
--6 8  и 9 механизм предоставления доступа и удаления доступа 
FUNCTION change_dost(
    p_id_p IN NUMBER,
    gr_by IN NUMBER,
    gr_at IN NUMBER,
    type IN NUMBER
) RETURN NUMBER AS
    v_error_msg VARCHAR2(400);
    v_result VARCHAR2(500);
    v_rows_affected NUMBER;
    chief NUMBER;
    access_granted_by NUMBER;
    is_chief NUMBER := 0;
    has_restriction NUMBER := 0;
BEGIN
    -- Проверка валидности типа операции
    IF type NOT IN (0, 1) THEN
        v_result := 'Неподдерживаемый тип операции: ' || type;
        rec_log_error(-20001, v_result, 'TEST.CHANGE_DOST');
        RETURN -20001;
    END IF;

    -- Проверяем, является ли gr_by начальником для p_id_p
    BEGIN
        SELECT 1 INTO is_chief 
        FROM TEST_DEP d 
        JOIN TEST_PEOPLE p ON d.id_d = p.id_d 
        WHERE d.CHIEF_DEP = gr_by AND p.id_p = p_id_p;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            is_chief := 0;
    END;

    -- Операция добавления доступа (type = 1)
    IF type = 1 THEN
        -- Новая проверка: доступ может предоставлять только начальник или сам человек (для себя)
        IF is_chief = 0 AND gr_by != p_id_p THEN
            v_result := 'Доступ может предоставлять только начальник отдела или сам человек';
            rec_log_error(-20003, v_result, 'TEST.CHANGE_DOST');
            RETURN -20003;
        END IF;

        -- Проверка ограничений доступа (если не начальник)
        IF is_chief = 0 THEN
            BEGIN
                -- Проверка запрета на доступ
                SELECT 1 INTO has_restriction
                FROM TEST_RESTRICT_ACCESS 
                WHERE id_p = p_id_p AND (restrict_at = -1 OR restrict_at = gr_by OR restrict_at = gr_at);

                v_result := 'Доступ запрещен настройками сотрудника';
                rec_log_error(-20002, v_result, 'TEST.CHANGE_DOST');
                RETURN -20002;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    NULL; -- Ограничений нет
            END;
        END IF;

        BEGIN
            INSERT INTO TEST_DOST (
                ID_P,
                GRANTED_BY,
                GRANTED_AT,
                DATE_GRANTED
            ) VALUES (
                p_id_p,
                gr_by,
                gr_at,
                SYSDATE
            );

            COMMIT;
            RETURN 1;

        EXCEPTION
            WHEN DUP_VAL_ON_INDEX THEN
                v_result := 'Ошибка: дублирование записи';
                rec_log_error(SQLCODE, v_result, 'TEST.CHANGE_DOST');
                ROLLBACK;
                RETURN -1;
            WHEN OTHERS THEN
                v_error_msg := SQLERRM;
                RETURN handle_common_errors(v_error_msg, 'TEST.CHANGE_DOST');
        END;

-- Операция удаления доступа (type = 0)
    ELSIF type = 0 THEN
        BEGIN
            -- Получаем информацию о том, кто предоставил доступ
            BEGIN
                SELECT d.CHIEF_DEP, dost.GRANTED_BY 
                INTO chief, access_granted_by
                FROM TEST_DEP d 
                JOIN TEST_PEOPLE p ON d.id_d = p.id_d 
                JOIN TEST_DOST dost ON dost.id_p = p.id_p
                WHERE p.id_p = p_id_p AND dost.GRANTED_AT = gr_at;

                -- Проверка прав на удаление
                -- 1.Если gr_by - начальник отдела > разрешено
                  IF gr_by = chief THEN
                      NULL;  -- Начальник может удалять любой доступ
                  -- 2. Если gr_by - не начальник и не тот, кто выдал доступ, и не сам сотрудник > запрещено
                  ELSIF gr_by != access_granted_by AND gr_by != p_id_p THEN
                      v_result := 'Удалить доступ может только начальник (ID: '  chief  '), выдавший (ID: '  access_granted_by  ') или сам сотрудник';
                      rec_log_error(-20004, v_result, 'TEST.CHANGE_DOST');
                      RETURN -20004;
                  END IF;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    NULL; -- Если нет данных, продолжаем
            END;

            -- Удаление доступа
            DELETE FROM TEST_DOST
            WHERE ID_P = p_id_p AND GRANTED_AT = gr_at;

            v_rows_affected := SQL%ROWCOUNT;

            IF v_rows_affected = 0 THEN
                v_result := 'Ограничение не найдено';
                rec_log_error(0, v_result, 'TEST.CHANGE_DOST');
                RETURN 0;
            END IF;

            COMMIT;
            RETURN 1;

        EXCEPTION
            WHEN OTHERS THEN
                v_error_msg := SQLERRM;
                RETURN handle_common_errors(v_error_msg, 'TEST.CHANGE_DOST');
        END;
    END IF;
END change_dost;

--7. Запрет на предоставление доступа

FUNCTION change_restriction(
    p_id_p IN NUMBER,        -- Кому устанавливалось ограничение (сотрудник)
    p_restrict_by IN NUMBER, -- Кто выполняет операцию
    p_restrict_at IN NUMBER, -- Кому запрещался доступ (-1=всем, или ID сотрудника)
    p_type IN NUMBER         -- 1=добавить, 0=удалить
) RETURN NUMBER AS
    v_error_msg VARCHAR2(400);
    v_result VARCHAR2(500);
    v_rows_affected NUMBER;
    is_chief NUMBER := 0;
    same_department NUMBER := 0;
    restriction_creator NUMBER;
BEGIN
    -- Проверка валидности типа операции
    IF p_type NOT IN (0, 1) THEN
        v_result := 'Неподдерживаемый тип операции: ' || p_type;
        rec_log_error(-20001, v_result, 'TEST.change_restriction');
        RETURN -20001;
    END IF;

    -- Для операции добавления
    IF p_type = 1 THEN
        -- Проверка специального ограничения (полный запрет)
        IF p_restrict_at = -1 AND p_restrict_by != p_id_p THEN
            v_result := 'Полный запрет доступа (RESTRICT_AT=-1) может быть установлен только для себя';
            rec_log_error(-20003, v_result, 'TEST.change_restriction');
            RETURN -20003;
        END IF;

        -- Проверяем, является ли restrict_by начальником для id_p
        BEGIN
            SELECT 1 INTO is_chief 
            FROM TEST_DEP d 
            JOIN TEST_PEOPLE p ON d.id_d = p.id_d 
            WHERE d.CHIEF_DEP = p_restrict_by AND p.id_p = p_id_p;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                is_chief := 0;
        END;

        -- Если это начальник, проверяем что restrict_at тоже из его отдела (кроме случая restrict_at=-1)
        IF is_chief = 1 AND p_restrict_at != -1 and p_restrict_by != p_id_p THEN            BEGIN
                SELECT 1 INTO same_department
                FROM TEST_PEOPLE p1
                JOIN TEST_PEOPLE p2 ON p1.id_d = p2.id_d
                WHERE p1.id_p = p_restrict_at  -- Кому запрещаем
                AND p2.id_p = p_id_p;          -- Кому устанавливаем ограничение

EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    v_result := 'Начальник может запрещать доступ только сотрудникам своего отдела';
                    rec_log_error(-20005, v_result, 'TEST.change_restriction');
                    RETURN -20005;
            END;
        END IF;

        -- Проверка прав (для добавления)
        IF is_chief = 0 AND p_restrict_by != p_id_p THEN
            v_result := 'Операция может выполняться только самим сотрудником или его начальником';
            rec_log_error(-20004, v_result, 'TEST.change_restriction');
            RETURN -20004;
        END IF;

        -- Вставка ограничения
        BEGIN
            INSERT INTO TEST_RESTRICT_ACCESS (
                ID_P,          -- Кому устанавливается ограничение
                RESTRICT_BY,   -- Кто установил ограничение
                RESTRICT_AT,   -- Кому запрещен доступ
                DATE_RESTRICT
            ) VALUES (
                p_id_p,
                p_restrict_by,
                p_restrict_at,
                SYSDATE
            );

            v_rows_affected := SQL%ROWCOUNT;
            COMMIT;
            RETURN 1;

        EXCEPTION
            WHEN DUP_VAL_ON_INDEX THEN
                v_result := 'Ошибка: такое ограничение уже существует';
                rec_log_error(SQLCODE, v_result, 'TEST.change_restriction');
                ROLLBACK;
                RETURN -1;

            WHEN OTHERS THEN
                v_error_msg := SQLERRM;
                RETURN handle_common_errors(v_error_msg, 'TEST.change_restriction');
        END;

    -- Для операции удаления
    ELSIF p_type = 0 THEN
        -- Получаем кто создал ограничение
        BEGIN
            SELECT RESTRICT_BY INTO restriction_creator
            FROM TEST_RESTRICT_ACCESS
            WHERE ID_P = p_id_p 
            AND RESTRICT_AT = p_restrict_at;

            -- Проверяем права на удаление:
            -- 1. Удаляет тот, кто создал ограничение
            -- 2. Или начальник отдела сотрудника
            -- 3. Или сам сотрудник (если ограничение на него)

            -- Проверяем является ли исполнитель начальником
            BEGIN
                SELECT 1 INTO is_chief 
                FROM TEST_DEP d 
                JOIN TEST_PEOPLE p ON d.id_d = p.id_d 
                WHERE d.CHIEF_DEP = p_restrict_by AND p.id_p = p_id_p;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    is_chief := 0;
            END;

            -- Если не создатель, не начальник и не сам сотрудник
            IF restriction_creator != p_restrict_by AND is_chief = 0 AND p_restrict_by != p_id_p THEN
                v_result := 'Удалить ограничение может только создатель, начальник или сам сотрудник';
                rec_log_error(-20006, v_result, 'TEST.change_restriction');
                RETURN -20006;
            END IF;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_result := 'Ограничение не найдено для удаления';
                rec_log_error(0, v_result, 'TEST.change_restriction');
                RETURN 0;
        END;

        -- Удаление ограничения
        BEGIN
            DELETE FROM TEST_RESTRICT_ACCESS
            WHERE ID_P = p_id_p 
            AND RESTRICT_AT = p_restrict_at;

            v_rows_affected := SQL%ROWCOUNT;

            IF v_rows_affected = 0 THEN
                v_result := 'Ограничение не найдено для удаления';
                rec_log_error(0, v_result, 'TEST.change_restriction');
                RETURN 0;
            END IF;

            COMMIT;
            RETURN 1;

        EXCEPTION
            WHEN OTHERS THEN
                v_error_msg := SQLERRM;
                RETURN handle_common_errors(v_error_msg, 'TEST.change_restriction');
        END;
    END IF;
END change_restriction;


--ведение логов ошибочных
procedure rec_log_error(KOD NUMBER,EXCEPT_MESS VARCHAR2,ERR_LOCATION VARCHAR2) AS
  BEGIN
    -- TODO: Implementation required for procedure TEST.rec_log_error
    INSERT
      INTO TEST_LOG_ERROR
        (
          DATA,
          KOD,
          EXCEPT_MESS,
          ERR_LOCATION,
          LOGIN
        )
        VALUES
        (
          sysdate,
          KOD,
          EXCEPT_MESS,
          ERR_LOCATION,
          user
        );
    commit;
  END rec_log_error;



END TEST;