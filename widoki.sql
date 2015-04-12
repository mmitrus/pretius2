
--widok PER_PROJEKT
CREATE VIEW PER_PROJEKT AS
SELECT k.nazwa "Nazwa klienta", p.nazwa "Nazwa projektu", sum(cp.czas) "Iloœæ godzin w miesi¹cu", to_char(cp.DATA,'YYYY\MM') "Miesi¹c z rokiem"
FROM czas_pracy cp, 
      zadanie z,
      projekt p,
      klient k
WHERE cp.zadanie_id = z.ID
AND z.projekt_id = p.ID 
AND p.klient_id = k.ID 
GROUP BY k.nazwa, p.nazwa, to_char(cp.DATA,'YYYY\MM')  
ORDER BY 4;

select *
from PER_PROJEKT;

--widok PER_OSOBA - ze wzgledu na brak informacji o okresie jaki ma prezentowac raport, domyslny okres  200 dni do przydu i do ty³u od dnia stworzenia widoku
DECLARE
v_data varchar2(256);
v_daty clob;
BEGIN

FOR K IN (WITH dane AS (
               select DISTINCT (zd.dzien) dzien
               from (select (SYSDATE-200) + rownum -1 DZIEN
                      from all_objects
                     where rownum <= 
                    (SYSDATE+200)-(SYSDATE-200)+1)  zd
               left outer join PER_OSOBA2 w2 on to_char(zd.dzien, 'YYYY-MM-DD')  = to_char(w2.data, 'YYYY-MM-DD') 
               group by osoba, zd.dzien, czas
               order by zd.dzien)
SELECT DZIEN
FROM dane) LOOP



v_data := 'NVL(SUM(CASE WHEN TO_CHAR(DATA, ''YYYY-MM-DD'')  = ''' || TO_CHAR(k.DZIEN, 'YYYY-MM-DD')  || ''' THEN CZAS ELSE NULL END),0) AS "'|| TO_CHAR(k.DZIEN, 'YYYY-MM-DD')  ||'" ';

v_daty := v_daty ||', '||v_data;

END LOOP;


execute immediate 
'create view PER_OSOBA as
SELECT OSOBA as "osoba" ' ||v_daty ||       
       ' FROM PER_OSOBA2 
       GROUP BY OSOBA';

END;

select *
from PER_OSOBA;


--widok PER_OSOBA2 - widok obejmue okres miedzy pierwszym a ostatnim wpisem w tabeli CZAS-PRACY
CREATE VIEW PER_OSOBA2 AS
WITH zdzien AS (SELECT (SELECT MIN(DATA)
FROM CZAS_PRACY) + ROWNUM -1 DZIEN 
  FROM all_objects 
 WHERE ROWNUM <=  
(SELECT MAX(DATA) 
FROM CZAS_PRACY)-(SELECT MIN(DATA) 
FROM CZAS_PRACY)+1)  
SELECT  p.imie||' '||p.nazwisko Osoba,NVL(SUM(CZAS),0) CZAS ,ZD.DZIEN 
FROM  zdzien zd 
LEFT OUTER JOIN (czas_pracy cp  
LEFT OUTER JOIN  pracownik p ON p.ID = cp.pracownik_id )ON  to_char(cp.DATA, 'YYYY-MM-DD') = to_char(zd.dzien, 'YYYY-MM-DD') 
GROUP BY p.imie||' '||p.nazwisko , ZD.DZIEN 
ORDER BY ZD.DZIEN; 

select *
from PER_OSOBA2;

--zapytanie budujce zapytanie raportu per osoba - ze wzgledu na brak informacji o okresie jaki ma prezentowac raport, domyslny okres to bierzacy miesiac
WITH dane AS (SELECT DISTINCT DZIEN FROM PER_OSOBA2 WHERE dzien > (SELECT add_months(last_day(SYSDATE),-1)
FROM dual) AND dzien <(SELECT  last_day(SYSDATE)+1 
FROM dual)) 
SELECT 'SELECT OSOBA,' || 
       LISTAGG('NVL(SUM(CASE WHEN TO_CHAR(DZIEN, ''YYYY-MM-DD'')  = ''' || TO_CHAR(DZIEN, 'YYYY-MM-DD')  || ''' THEN CZAS ELSE NULL END),0) AS "'|| TO_CHAR(DZIEN, 'YYYY-MM-DD')  ||'"', ',') WITHIN GROUP (ORDER BY DZIEN) ||
       ' FROM PER_OSOBA2  
       WHERE OSOBA !='' ''
       GROUP BY OSOBA'
FROM dane;



-- inna wersja widoku PER_OSOBA
create view PER_OSOBA3 as
SELECT  p.imie||' '||p.nazwisko Osoba,NVL(CZAS,0) CZAS , cp.data
FROM  czas_pracy cp 
 join  pracownik p on p.id = cp.pracownik_id;
 
 select *
from PER_OSOBA3;
   --zapytanie budujce zapytanie raportu per osoba -w parametrach daty rozpoczecia i zakonczenia
WITH dane AS (
               select DISTINCT (zd.dzien) dzien
               from (select (&startDT) + rownum -1 DZIEN
                      from all_objects
                     where rownum <= 
                    (&stopDT)-(&startDT)+1)  zd
               left outer join PER_OSOBA3 w2 on to_char(zd.dzien, 'YYYY-MM-DD')  = to_char(w2.data, 'YYYY-MM-DD') 
               group by osoba, zd.dzien, czas
               order by zd.dzien)
SELECT 'SELECT OSOBA,' ||
       LISTAGG('NVL(SUM(CASE WHEN TO_CHAR(DATA, ''YYYY-MM-DD'')  = ''' || TO_CHAR(DZIEN, 'YYYY-MM-DD')  || ''' THEN CZAS ELSE NULL END),0) AS "'|| TO_CHAR(DZIEN, 'YYYY-MM-DD')  ||'"', ',') WITHIN GROUP (ORDER BY dzien) ||
       ' FROM PER_OSOBA3 
       WHERE OSOBA !='' ''
       GROUP BY OSOBA'
FROM dane;

