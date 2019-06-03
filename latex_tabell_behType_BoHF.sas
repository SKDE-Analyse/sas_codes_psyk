latex_tabell_behType_boHF(inndata=phvtsb1517, opptak=1, navn_opptak=Finnmark, innb=innbyggere_1517);

proc format;

value Beh_type
1='DPS/somatisk'
2='Rusenhet, HN'
3='Regional enh.'
4='Utenfor HN'
5='Privat';

/*Bosatte i angitt opptaksområde*/

/*TSB*/

/*Velger aktuell sektor og populasjon*/
data tsb1517_&navn_opptak;
set &inndata;
where sektor=1 and BoHF=&opptak;
run;

/*Grupperer sammen dag/poli-opphold og innleggelser til pasientdager og institusjonsopphold, og aggregerer.*/
%DagAktivitet(inndata=tsb1517_&navn_opptak, utdata=tsb1517_DA);
%aggreger_psyk_DA(inndata=tsb1517_DA, utdata=tsb1517_agg, agg_var=alle);

/*Lager ny variabel til tabell: Beh_type (DPS, rusenhet, privat etc.)*/
/*Resten av stegene i makroen er de samme som i latex_tabell_boHF.*/
data tsb1517_agg_BehHF;
set tsb1517_agg_BehHF;
where Type_beh not in (99,.);

if Type_beh in (8,9) then Beh_type=5;	/*Private*/
else if Type_beh = 7 then Beh_type=4;	/*Utenfor HN*/
else if Type_beh=6 then Beh_type=3;	/*Reg. enhet*/
else if Type_beh=5 then Beh_type=2;	/*Off. rusenhet*/
else if Type_beh in (1,4) then Beh_type=1;	/*DPS/somatisk*/

format Beh_type Beh_type.;

run;

proc sql;
create table tsb1517_Beh_type as
select distinct Beh_type, SUM(inn) as tot_inn, SUM(poli) as tot_poli
from tsb1517_agg_BehHF
group by Beh_type;
quit; run;

data tsb1517_Beh_type;
set tsb1517_Beh_type;

snitt_inn=tot_inn/3;
snitt_poli= tot_poli/3;

sum_inn+snitt_inn;
sum_poli+snitt_poli;

sektor=1;

run;

proc sql;
create table tsb1517_Beh_type2 as
select distinct sektor, Beh_type, tot_inn, tot_poli, snitt_inn, snitt_poli, max(sum_inn) as sum_inn, max(sum_poli) as sum_poli
from tsb1517_Beh_type
group by sektor;
quit; run;

data tsb1517_Beh_type3;
set tsb1517_Beh_type2;

andel_inn=snitt_inn/sum_inn;
andel_poli=snitt_poli/sum_poli;

BoHF=&opptak;

run;

/*PHV*/

data phv1517_&navn_opptak;
set &inndata;
where sektor=2 and BoHF=&opptak;
run;

%DagAktivitet(inndata=phv1517_&navn_opptak, utdata=phv1517_DA);
%aggreger_psyk_DA(inndata=phv1517_DA, utdata=phv1517_agg, agg_var=alle);

data phv1517_agg_BehHF;
set phv1517_agg_BehHF;
where Type_beh not in (99,.);

if Type_beh in (8,9) then Beh_type=5;	/*Private*/
else if Type_beh = 7 then Beh_type=4;	/*Utenfor HN*/
else if Type_beh=6 then Beh_type=3;	/*Reg. enhet*/
else if Type_beh=5 then Beh_type=2;	/*Off. rusenhet*/
else if Type_beh in (1,4) then Beh_type=1;	/*DPS/somatisk*/

format Beh_type Beh_type.;

run;

proc sql;
create table phv1517_Beh_type as
select distinct Beh_type, SUM(inn) as tot_inn, SUM(poli) as tot_poli
from phv1517_agg_BehHF
group by Beh_type;
quit; run;

data phv1517_Beh_type;
set phv1517_Beh_type;

snitt_inn=tot_inn/3;
snitt_poli= tot_poli/3;

sum_inn+snitt_inn;
sum_poli+snitt_poli;

sektor=2;

run;

proc sql;
create table phv1517_Beh_type2 as
select distinct sektor, Beh_type, tot_inn, tot_poli, snitt_inn, snitt_poli, max(sum_inn) as sum_inn, max(sum_poli) as sum_poli
from phv1517_Beh_type
group by sektor;
quit; run;

data phv1517_Beh_type3;
set phv1517_Beh_type2;

andel_inn=snitt_inn/sum_inn;
andel_poli=snitt_poli/sum_poli;

BoHF=&opptak;

run;

data tsbphv1517_&navn_opptak.2;
set phv1517_Beh_type3 tsb1517_Beh_type3;

format sektor sektor.;

run;

data inn_&navn_opptak.1517;
set &innb;
where BoHF=&opptak;
run;

proc sql;
create table inn_&navn_opptak.1517BoHF as
select distinct BoHF, sum(innbyggere) as tot_innbyggere
from inn_&navn_opptak.1517
group by BoHF;
run;
quit;

data inn_&navn_opptak.1517BoHF_sn;
set inn_&navn_opptak.1517BoHF;
snitt_innbyggere=tot_innbyggere/3;
run;

data TSBPHV1517_&navn_opptak._I2;
merge TSBPHV1517_&navn_opptak.2 inn_&navn_opptak.1517BoHF_sn;
by BoHF;

sum_inn_I=10000*sum_inn/snitt_innbyggere;
sum_poli_I=10000*sum_poli/snitt_innbyggere;

snitt_inn_I=10000*snitt_inn/snitt_innbyggere;
snitt_poli_I=10000*snitt_poli/snitt_innbyggere;

run;

ods tagsets.tablesonlylatex tagset=event1
file="\\hn.helsenord.no\RHF\SKDE\Analyse\Prosjekter\2019_Psyk_HN\latex\&navn_opptak._TSBPHV_1517_INSTOPPH2.tex" (notop nobot) style=journal;

title "Bosatte i &navn_opptak";
PROC TABULATE
DATA=TSBPHV1517_&navn_opptak._I2;
	VAR andel_inn andel_poli snitt_inn snitt_poli snitt_inn_I snitt_poli_I;
	CLASS Beh_type /	ORDER=UNFORMATTED MISSING;
	CLASS sektor /	ORDER=UNFORMATTED MISSING;
	TABLE 
	/* Row Dimension */
	Beh_type={label=''},
	/* Column Dimension */
	sektor={label=''} *(
	snitt_inn={label='Antall'}*Sum={label=''}*{f=nlnum8.0}  
	snitt_inn_I={label='Rate'}*Sum={label=''}*{f=nlnum8.0}  
	andel_inn={label='Andel'}*Sum={label=''}*{f=nlpct8.1} 
/*	snitt_poli={label='Pasientdager'}*Sum={label=''} */
/*	snitt_poli_I={label='pr. 10 000'}*Sum={label=''} */
/*	andel_poli={label='Andel'}*Sum={label=''}*/
	);
RUN;
TITLE;
ods tagsets.tablesonlylatex close;

ods tagsets.tablesonlylatex tagset=event1
file="\\hn.helsenord.no\RHF\SKDE\Analyse\Prosjekter\2019_Psyk_HN\latex\&navn_opptak._TSBPHV_1517_PASDAGER2.tex" (notop nobot) style=journal;

title "Bosatte i &navn_opptak";
PROC TABULATE
DATA=TSBPHV1517_&navn_opptak._I2;
	VAR andel_inn andel_poli snitt_inn snitt_poli snitt_inn_I snitt_poli_I;
	CLASS Beh_type /	ORDER=UNFORMATTED MISSING;
	CLASS sektor /	ORDER=UNFORMATTED MISSING;
	TABLE 
	/* Row Dimension */
	Beh_type={label=''},
	/* Column Dimension */
	sektor={label=''} *(
/*	snitt_inn={label='Innleggelser'}*Sum={label=''} */
/*	snitt_inn_I={label='pr. 10 000'}*Sum={label=''} */
/*	andel_inn={label='Andel'}*Sum={label=''} */
	snitt_poli={label='Antall'}*Sum={label=''}*{f=nlnum8.0}  
	snitt_poli_I={label='Rate'}*Sum={label=''}*{f=nlnum8.0}  
	andel_poli={label='Andel'}*Sum={label=''}*{f=nlpct8.1} 
	);
RUN;
TITLE;
ods tagsets.tablesonlylatex close;


proc datasets nolist;
delete tsb1517: phv1517: inn_:;
run;



%mend;