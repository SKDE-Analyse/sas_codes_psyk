%macro latex_tabell_liten(inndata=&innds, utdata=, opptak=1, dps=&dps_tab, opptak2=, navn_opptak=Finnmark, innb=&innbygg);

proc format;

value BehHF_type
1='Eget HF'
2='Annet HF, HN'
3='Off. utenfor HN'
4='Privat'
5='Avtalespesialist';

/*Bosatte i angitt opptaksområde*/

/*TSB*/

%if &dps=1 %then %do;
/*Velger aktuell sektor og populasjon*/
data tsb1517_&navn_opptak;
set &inndata;
where sektor=1 and BoHF=&opptak and BoDPS=&opptak2;
run;
%end;
%else %do;
/*Velger aktuell sektor og populasjon*/
data tsb1517_&navn_opptak;
set &inndata;
where sektor=1 and BoHF=&opptak;
run;
%end;

/*Grupperer sammen dag/poli-opphold og innleggelser til pasientdager og institusjonsopphold*/
%DagAktivitet(inndata=tsb1517_&navn_opptak, utdata=tsb1517_DA);
/*Aggregerer*/
%aggreger_psyk_DA(inndata=tsb1517_DA, utdata=tsb1517_agg, agg_var=alle);

/*Lager ny variabel til tabell: BehHF_type (eget, annet i HN, privat etc.)*/
data tsb1517_agg_BehHF;
set tsb1517_agg_BehHF;
where BehHF not in (99,.);

if BehHF = 27 then BehHF_type=4;
else if BehHF gt 4 then BehHF_type=3;
else do;
	if BehHF = &opptak then BehHF_type=1;
	else BehHF_type=2;
end;

format BehHF_type BehHF_type.;

run;

/*Aggregerer på nytt med ny variabel BehHF_type, finner sum for årene 15-17*/
proc sql;
create table tsb1517_BehHFType as
select distinct BehHF_type, SUM(inn) as tot_inn, SUM(inn_unik_aar_i) as tot_inn_u, SUM(poli) as tot_poli, SUM(poli_unik_aar_i) as tot_poli_u
from tsb1517_agg_BehHF
group by BehHF_type;
quit; run;

/*Finner snitt for årene 15-17. Summerer for å finne totalt antall inst.opph./pas.dager uansett behandlingssted (sum_inn og sum_poli).*/
data tsb1517_BehHFType;
set tsb1517_BehHFType;

snitt_inn=tot_inn/3;
snitt_poli= tot_poli/3;

sum_inn+snitt_inn;
sum_poli+snitt_poli;

snitt_inn_u=tot_inn_u/3;
snitt_poli_u= tot_poli_u/3;

sum_inn_u+snitt_inn_u;
sum_poli_u+snitt_poli_u;

sektor=1;

run;

/*Finner andel behandlet i eget HF/annet i HN, privat etc.*/
proc sql;
create table tsb1517_BehHFType2 as
select distinct sektor, BehHF_type, tot_inn, tot_poli, snitt_inn, snitt_poli, max(sum_inn) as sum_inn, max(sum_poli) as sum_poli, 
tot_inn_u, tot_poli_u, snitt_inn_u, snitt_poli_u, max(sum_inn_u) as sum_inn_u, max(sum_poli_u) as sum_poli_u
from tsb1517_BehHFType
group by sektor;
quit; run;

data tsb1517_BehHFType3;
set tsb1517_BehHFType2;

andel_inn=snitt_inn/sum_inn;
andel_poli=snitt_poli/sum_poli;

andel_inn_u=snitt_inn_u/sum_inn_u;
andel_poli_u=snitt_poli_u/sum_poli_u;

BoHF=&opptak;

run;

/*PHV*/
/*Alle stegene over gjentas for PHV.*/

%if &dps=1 %then %do;
/*Velger aktuell sektor og populasjon*/
data phv1517_&navn_opptak;
set &inndata;
where sektor=2 and BoHF=&opptak and BoDPS=&opptak2;
run;
%end;
%else %do;
/*Velger aktuell sektor og populasjon*/
data phv1517_&navn_opptak;
set &inndata;
where sektor=2 and BoHF=&opptak;
run;
%end;

%DagAktivitet(inndata=phv1517_&navn_opptak, utdata=phv1517_DA);
%aggreger_psyk_DA(inndata=phv1517_DA, utdata=phv1517_agg, agg_var=alle);

data phv1517_agg_BehHF;
set phv1517_agg_BehHF;
where BehHF not in (99,.);

if BehHF = 27 then BehHF_type=4;
else if BehHF gt 4 then BehHF_type=3;
else do;
	if BehHF = &opptak then BehHF_type=1;
	else BehHF_type=2;
end;

format BehHF_type BehHF_type.;

run;


/*Tar inn avtalespesialister i PHV-data*/


%if &dps=1 %then %do;
/*Velger aktuell sektor og populasjon*/
data phv1517_&navn_opptak._AS;
set &inndata;
where sektor=4 and BoHF=&opptak and BoDPS=&opptak2;
run;
%end;
%else %do;
/*Velger aktuell sektor og populasjon*/
data phv1517_&navn_opptak._AS;
set &inndata;
where sektor=4 and BoHF=&opptak;
run;
%end;

%DagAktivitet(inndata=phv1517_&navn_opptak._AS, utdata=phv1517_AS_DA);
%aggreger_psyk_DA(inndata=phv1517_AS_DA, utdata=phv1517_AS_agg, agg_var=alle);

data phv1517_AS_agg_BehHF;
set phv1517_AS_agg_BehHF;

BehHF_type=5;

format BehHF_type BehHF_type.;

run;

data phv1517_alle_agg_BehHF;
set phv1517_agg_BehHF phv1517_AS_agg_BehHF;
run;

proc sql;
create table phv1517_BehHFType as
select distinct BehHF_type, SUM(inn) as tot_inn, SUM(inn_unik_aar_i) as tot_inn_u, SUM(poli) as tot_poli, SUM(poli_unik_aar_i) as tot_poli_u
from phv1517_alle_agg_BehHF
group by BehHF_type;
quit; run;

data phv1517_BehHFType;
set phv1517_BehHFType;

snitt_inn=tot_inn/3;
snitt_poli= tot_poli/3;

sum_inn+snitt_inn;
sum_poli+snitt_poli;

snitt_inn_u=tot_inn_u/3;
snitt_poli_u= tot_poli_u/3;

sum_inn_u+snitt_inn_u;
sum_poli_u+snitt_poli_u;

sektor=2;

run;

proc sql;
create table phv1517_BehHFType2 as
select distinct sektor, BehHF_type, tot_inn, tot_poli, snitt_inn, snitt_poli, max(sum_inn) as sum_inn, max(sum_poli) as sum_poli, 
tot_inn_u, tot_poli_u, snitt_inn_u, snitt_poli_u, max(sum_inn_u) as sum_inn_u, max(sum_poli_u) as sum_poli_u
from phv1517_BehHFType
group by sektor;
quit; run;

data phv1517_BehHFType3;
set phv1517_BehHFType2;

andel_inn=snitt_inn/sum_inn;
andel_poli=snitt_poli/sum_poli;

andel_inn_u=snitt_inn_u/sum_inn_u;
andel_poli_u=snitt_poli_u/sum_poli_u;

BoHF=&opptak;

run;

data tsbphv1517_&navn_opptak;
set phv1517_BehHFType3 tsb1517_BehHFType3;

format sektor sektor.;

run;

/*Finner innbyggertall for aktuelt BoHF*/

%if &dps=1 %then %do;
/*Velger aktuell sektor og populasjon*/
data inn_&navn_opptak.1517;
set &innb;
where BoHF=&opptak and BoDPS=&opptak2;
run;
%end;
%else %do;
data inn_&navn_opptak.1517;
set &innb;
where BoHF=&opptak;
run;
%end;



proc sql;
create table inn_&navn_opptak.1517BoHF as
select distinct BoHF, sum(innbyggere) as tot_innbyggere
from inn_&navn_opptak.1517
group by BoHF;
run;
quit;

/*Beregner snitt for 15-17*/
data inn_&navn_opptak.1517BoHF_sn;
set inn_&navn_opptak.1517BoHF;
snitt_innbyggere=tot_innbyggere/3;
run;

/*Beregner snittrater for 15-17 (per 10 000 innbyggere). Ujusterte rater.*/
data &utdata;
merge TSBPHV1517_&navn_opptak. inn_&navn_opptak.1517BoHF_sn;
by BoHF;

sum_inn_I=10000*sum_inn/snitt_innbyggere;
sum_poli_I=10000*sum_poli/snitt_innbyggere;

snitt_inn_I=10000*snitt_inn/snitt_innbyggere;
snitt_poli_I=10000*snitt_poli/snitt_innbyggere;

sum_inn_u_I=10000*sum_inn_u/snitt_innbyggere;
sum_poli_u_I=10000*sum_poli_u/snitt_innbyggere;

snitt_inn_u_I=10000*snitt_inn_u/snitt_innbyggere;
snitt_poli_u_I=10000*snitt_poli_u/snitt_innbyggere;

run;

proc datasets nolist;
delete tsb1517: phv1517: inn_:;
run;

%mend latex_tabell_liten;