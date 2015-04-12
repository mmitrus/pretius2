CREATE OR REPLACE PACKAGE Godziny_Pracy AS
 
FUNCTION dodaj_godziny(p_pracownikID pracownik.ID%TYPE, 
                       p_zadanieID zadanie.ID%TYPE, 
                       p_czas czas_pracy.czas%TYPE, 
                       p_komentarz czas_pracy.komentarz%TYPE, 
                       p_data czas_pracy.DATA%TYPE, 
                       p_insp czas_pracy.insp%TYPE, 
                       p_modp czas_pracy.modp%TYPE) 
                       RETURN VARCHAR2;
                       
FUNCTION modyfikuj_godziny(p_id czas_pracy.ID%TYPE, 
                           p_czas czas_pracy.czas%TYPE, 
                           p_komentarz czas_pracy.komentarz%TYPE, 
                           p_data czas_pracy.DATA%TYPE, 
                           p_modp czas_pracy.modp%TYPE) 
                           RETURN VARCHAR2; 
                           
FUNCTION go_add RETURN VARCHAR2; 
FUNCTION go_mod RETURN VARCHAR2;  
FUNCTION typ_dnia(p_data czas_pracy.DATA%TYPE) RETURN NUMBER;

END Godziny_Pracy;
/ 
 
CREATE OR REPLACE PACKAGE BODY Godziny_Pracy AS
------------------------------------------------------------------typ_dnia-------------------------------------------------------------------
FUNCTION typ_dnia(p_data czas_pracy.DATA%TYPE) 
RETURN NUMBER
IS
BEGIN

  IF TO_CHAR(p_data, 'D') <2 or TO_CHAR(p_data, 'D') >6 THEN
   RETURN 0;
  ELSE
   RETURN 1;
  END IF;
  
END typ_dnia;
/**************************************************************************************************************************************************/
------------------------------------------------------------------dodaj_godziny-------------------------------------------------------------------
  FUNCTION dodaj_godziny(p_pracownikID pracownik.ID%TYPE, 
                         p_zadanieID zadanie.ID%TYPE,  
                         p_czas czas_pracy.czas%TYPE,   
                         p_komentarz czas_pracy.komentarz%TYPE,  
                         p_data czas_pracy.DATA%TYPE,  
                         p_insp czas_pracy.insp%TYPE,  
                         p_modp czas_pracy.modp%TYPE) 
  RETURN VARCHAR2 IS 
  
  v_zadanie zadanie.nazwa%TYPE; 
  
  PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN 
  
    BEGIN
      SELECT nazwa
      INTO v_zadanie
      FROM zadanie
      WHERE ID = p_zadanieID;
    EXCEPTION WHEN NO_DATA_FOUND THEN 
      v_zadanie := NULL;
    END;
    
    IF typ_dnia(p_data) = 0 THEN
      RETURN 'Czas nie zosta³ dodany - wybrany dzieñ nie jest dniem roboczym';
    END IF;    

    BEGIN
      INSERT INTO czas_pracy(pracownik_ID, zadanie_ID, czas, komentarz, data, insp, modp)
      VALUES(p_pracownikID, p_zadanieID, p_czas, p_komentarz, p_data, p_insp, p_modp);
      COMMIT;
    EXCEPTION WHEN OTHERS THEN
      RETURN 'Czas nie zosta³ dodany do zadania '||v_zadanie;
    END;
    
    RETURN 'Do zadania '||v_zadanie ||' dodano przepracowany czas';
  
  END dodaj_godziny;
/**************************************************************************************************************************************************/

-----------------------------------------------------------------------------modyfikuj_godziny------------------------------------------------------
  FUNCTION modyfikuj_godziny(p_id czas_pracy.id%TYPE,
                             p_czas czas_pracy.czas%TYPE, 
                             p_komentarz czas_pracy.komentarz%TYPE, 
                             p_data czas_pracy.data%TYPE, 
                             p_modp czas_pracy.modp%TYPE) 
   RETURN VARCHAR2  IS
   PRAGMA AUTONOMOUS_TRANSACTION;
   BEGIN
   
      IF typ_dnia(p_data) = 0 THEN
        RETURN 'Czas nie zosta³ dodany - wybrany dzieñ nie jest dniem roboczym';
      END IF; 
   
      BEGIN
        UPDATE czas_pracy set czas      = p_czas,
                              komentarz = p_komentarz,
                              data      = p_data,
                              modp      = p_modp
        WHERE id = p_id;     
        COMMIT;
      EXCEPTION WHEN OTHERS THEN
        RETURN 'Wpis nie zosta³ zmodyfikowany';
      END;
      
      RETURN 'Zmodyfikowano wpis';
   
   END modyfikuj_godziny;
   
/**************************************************************************************************************************************************/

-----------------------------------------------------------------------------go_add------------------------------------------------------ 
/*********************************
    wywoadnie do testu
    
    select godziny_pracy.go_add
    from dual;
***********************************/    
   FUNCTION go_add 
   RETURN VARCHAR2 IS
   
   v_check VARCHAR2(256);
   v_losowy_pracownik NUMBER;
   v_losowe_zadanie NUMBER;
   v_losowy_czas NUMBER;
   v_losowa_data DATE;
   
   BEGIN
   --dodanie przepracowanego czasu
   
   SELECT ROUND(dbms_random.value(1,10)) num 
   INTO v_losowy_pracownik
   FROM dual; 
   
   SELECT ROUND(dbms_random.value(1,10)) num 
   INTO v_losowe_zadanie
   FROM dual; 
   
   SELECT ROUND(dbms_random.value(1,4)) num 
   INTO v_losowy_czas
   FROM dual; 
   
   IF v_losowy_czas > 5 THEN
    v_losowa_data := SYSDATE + v_losowy_czas;
   ELSE  
    v_losowa_data := SYSDATE - v_losowy_czas;
   END IF;
   
   v_check := dodaj_godziny(v_losowy_pracownik, v_losowe_zadanie, v_losowy_czas, 'testowy komentarz', v_losowa_data, v_losowy_pracownik, v_losowy_pracownik);
    

    RETURN v_check;
   
   END go_add;

/**************************************************************************************************************************************************/

-----------------------------------------------------------------------------go_mod------------------------------------------------------ 
/*********************************
    wywoadnie do testu
    
    select godziny_pracy.go_mod
    from dual;
***********************************/  
  FUNCTION go_mod 
   RETURN VARCHAR2 IS
   
   v_check VARCHAR2(256);
   v_losowy_id_czasu NUMBER;
   v_czas   NUMBER;
   v_komentarz VARCHAR2(2048) := NULL;
   v_data DATE;
   v_losowy_czas NUMBER;
   v_losowa_data DATE;
   v_losowy_pracownik NUMBER;
   v_zadanie_id  NUMBER;
   
   BEGIN
   --modyfikacja przepracowanego czasu
    WHILE  v_komentarz IS NULL LOOP
     SELECT ROUND(dbms_random.value(1,200)) num 
     INTO v_losowy_id_czasu
     FROM dual; 
     
     BEGIN
       SELECT czas, komentarz, data, zadanie_id
       into v_czas, v_komentarz, v_data, v_zadanie_id
       FROM czas_pracy
       WHERE id = v_losowy_id_czasu;
     EXCEPTION WHEN NO_DATA_FOUND THEN
      v_czas       := null;
      v_komentarz  := null;
      v_data       := null;
      v_zadanie_id := null;
     END;
   END LOOP;  
  
   SELECT ROUND(dbms_random.value(1,4)) num 
   INTO v_losowy_czas
   FROM dual; 
   
   SELECT ROUND(dbms_random.value(1,10)) num 
   INTO v_losowy_pracownik
   FROM dual; 
   
   IF v_losowy_czas > 5 THEN
    v_losowa_data := SYSDATE + v_losowy_czas;
   ELSE  
    v_losowa_data := SYSDATE - v_losowy_czas;
   END IF;
   
   v_check := modyfikuj_godziny(v_losowy_id_czasu, v_losowy_czas,'zmodyfikowany komentarz', v_losowa_data, v_losowy_pracownik);
   
    RETURN v_check;
   
   END go_mod;
   
END Godziny_Pracy;
/
