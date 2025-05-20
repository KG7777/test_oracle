create or replace PACKAGE TEST AS 
 /* TODO enter package declarations (types, exceptions, methods etc) here */ 

function insert_people(p_fam varchar2,p_name varchar2,p_dep number) return number;

function delete_people(p_id_p number) return number;

function insert_animal(p_type varchar2,p_name varchar2,p_id_p number) return number;

function delete_animal(p_id_a number) return number;

function insert_dep(name_dep varchar2,chief_dep number default NULL) return number;

function delete_dep(p_id_d number) return number;

FUNCTION change_dost(p_id_p IN NUMBER,gr_by IN number,gr_at IN number,type in number) RETURN NUMBER;

FUNCTION change_restriction(p_id_p IN NUMBER,p_restrict_by IN NUMBER,p_restrict_at IN NUMBER,p_type IN NUMBER) RETURN NUMBER;

procedure rec_log_error(KOD NUMBER,EXCEPT_MESS VARCHAR2,ERR_LOCATION VARCHAR2);

procedure show_all_people;

procedure show_all_animals;

procedure show_one_animal(p_id_p number);

procedure show_one_people(p_id_p number);

END TEST;
