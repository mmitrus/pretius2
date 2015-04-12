CREATE OR REPLACE PROCEDURE sample_data IS
 
TYPE klient_list IS TABLE OF VARCHAR2 (100); 
v_klienci   klient_list := klient_list (); 
 
TYPE projekt_list IS TABLE OF VARCHAR2 (100);
v_projekty   projekt_list := projekt_list ();
 
TYPE zadanie_list IS TABLE OF VARCHAR2 (100);
v_zadania   zadanie_list := zadanie_list (); 
 
TYPE imie_list IS TABLE OF VARCHAR2 (100); 
v_imiona   imie_list := imie_list (); 
 
TYPE nazwisko_list IS TABLE OF VARCHAR2 (100); 
v_nazwiska   nazwisko_list := nazwisko_list ();

v_klient_ID INT;
v_projekt_ID INT; 
v_pass VARCHAR2(64); 
v_pracownik_Id INT; 
v_zadanie_Id INT; 
v_data DATE; 
v_typ_dnia INT :=1; 
BEGIN 
 

FOR ki IN 1..10 loop 
v_klienci.EXTEND; 
v_klienci (v_klienci.LAST) := 'Klient '||ki||' '||dbms_random.string('U', 5) ; 
END loop; 
 

FOR pi IN 1..30 loop 
v_projekty.EXTEND; 
v_projekty (v_projekty.LAST) := 'Projekt '||pi ||' '||dbms_random.string('U', 5) ; 
END loop; 
 

FOR zi IN 1..30 loop 
v_zadania.EXTEND; 
v_zadania (v_zadania.LAST) := 'Zadanie '||zi ||' '||dbms_random.string('U', 5) ; 
END loop; 
 
v_imiona.EXTEND(10); 
v_imiona(1) := 'Adam'; 
v_imiona(2) := 'Tomek';
v_imiona(3) := 'Anna';
v_imiona(4) := 'Ola';
v_imiona(5) := 'Michal';
v_imiona(6) := 'Magda';
v_imiona(7) := 'Karol';
v_imiona(8) := 'Olaf';
v_imiona(9) := 'Krysia';
v_imiona(10) := 'Bolek';


v_nazwiska.EXTEND(11);

v_nazwiska(1) := 'Nowak';
v_nazwiska(2) := 'Polak';
v_nazwiska(3) := 'Kowalski';
v_nazwiska(4) := 'Wiœniewski';
v_nazwiska(5) := 'D¹browski';
v_nazwiska(6) := 'Lewandowski';
v_nazwiska(7) := 'Wójcik';
v_nazwiska(8) := 'Kamiñski';
v_nazwiska(9) := 'Kowalczyk';
v_nazwiska(10) := 'Zieliñski';
v_nazwiska(11) := 'Koz³owski';



  FOR kli IN 1..5 loop
   
   INSERT INTO klient(nazwa) 
   VALUES ( v_klienci(dbms_random.VALUE(1,10)))    
   RETURNING ID INTO v_klient_ID; 
 
    FOR pro IN 1..3 loop 
     
     INSERT INTO projekt(nazwa, aktywny, startDT, klient_ID) 
     VALUES (v_projekty(dbms_random.VALUE(1,30)), round(DBMS_RANDOM.VALUE), SYSDATE - dbms_random.VALUE(1,300), v_klient_ID) 
     RETURNING ID INTO v_projekt_ID; 
     
     FOR zad IN 1..3 loop
         
        INSERT INTO zadanie(nazwa, aktywny, startDT, estymacja, projekt_ID) 
        VALUES (v_zadania(dbms_random.VALUE(1,30)), round(DBMS_RANDOM.VALUE), SYSDATE - dbms_random.VALUE(1,300), dbms_random.VALUE(1,300), v_projekt_ID); 
       
      END loop;
    END loop;  
  END loop; 
    
   FOR prac IN 1..15 loop
    
     SELECT dbms_random.string('U', 8)
     INTO v_pass 
     FROM dual; 
      
     
     INSERT INTO pracownik(imie, nazwisko, pesel, login, haslo) 
     VALUES (v_imiona(dbms_random.VALUE(1,10)), v_nazwiska(dbms_random.VALUE(1,11)) , round(dbms_random.VALUE(10000000000, 99999999999)), dbms_random.string('U', 5), DBMS_OBFUSCATION_TOOLKIT.md5 (input => UTL_RAW.cast_to_raw(v_pass)));
     
    END loop;

  FOR cp IN 1..30 loop
   
    WITH p1 AS (SELECT ID, dbms_random.VALUE
                FROM pracownik 
                ORDER BY 2) 
      SELECT ID  
      INTO v_pracownik_Id 
      FROM p1 
      WHERE ROWNUM =1; 
       
     WITH z1 AS (SELECT ID, dbms_random.VALUE 
                FROM zadanie 
                WHERE aktywny =1 
                ORDER BY 2) 
      SELECT ID  
      INTO v_zadanie_Id  
      FROM z1 
      WHERE ROWNUM =1;  
   
    while  v_typ_dnia <2 OR v_typ_dnia>6 loop  
     v_data := SYSDATE - dbms_random.VALUE(1,20); 
     SELECT to_char(v_data, 'd','NLS_DATE_LANGUAGE=POLISH') 
     INTO v_typ_dnia 
     FROM dual; 
    END loop;  
    
    INSERT INTO czas_pracy(czas, DATA, komentarz, zadanie_id, pracownik_id, insp, modp)
    VALUES(round(dbms_random.VALUE(1, 8)), v_data, dbms_random.string('U',20), v_zadanie_Id, v_pracownik_Id,v_pracownik_Id,v_pracownik_Id); 
     
    v_typ_dnia := 1;
   
   END loop; 
END; 