%macro fjerne_dupl_dogn(inndata=, utdata=);

/*Splitter i to datasett: døgn og ikke-dogn. */
data inn_dogn;
set &inndata;
where erdogn=1;
run;

data ikkedogn;
set &inndata;
where erdogn=0;
run;

/*Sorterer på pid, inndato og år.*/
proc sort data=inn_dogn;
by pid inndato aar;
quit;

data inn_dogn;
set inn_dogn;
by pid inndato aar;

/*I tilfeller der samme opphold er registrert i flere årganger (eks. både i 15 og 16) 
vil oppholdet som er registrert sist (siste år) få høyest inndatoteller*/
if first.inndato then unik_inndato=1;
if first.inndato then inndatoteller=0;
	inndatoteller+1;

run;

/*Tar bare med ett opphold for hver inndato. Velger det oppholdet som har 
høyest inndatoteller, dvs. det sist registrerte.*/
proc sql;
create table inn_dogn_dedup as
select distinct(inndato), *
from inn_dogn
group by pid, inndato
	having inndatoteller = max(inndatoteller);
quit;

/*Fjerner midlertidige variabler*/
data ut_dogn;
set inn_dogn_dedup;
drop unik_inndato inndatoteller;
run;

/*Setter sammen datasett med dogn-kontakter der duplikater er fjernet og 
datasett med ikkedogn-kontakter*/
data &utdata;
set ut_dogn ikkedogn;
run;

%mend;