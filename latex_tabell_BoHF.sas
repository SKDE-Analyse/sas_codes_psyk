%macro latex_tabell_boHF(inndata=phvtsb1517, opptak=1, navn_opptak=Finnmark, innb=innbyggere_1517);

proc format;

value BehHF_type
1='Eget HF'
2='Annet HF, HN'
3='Off. utenfor HN'
4='Privat'
5='Avtalespesialist';

/*Bosatte i angitt opptaksområde*/

/*TSB*/

/*Velger aktuell sektor og populasjon*/
data tsb1517_&navn_opptak;
set &inndata;
where sektor=1 and BoHF=&opptak;
run;

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

data phv1517_&navn_opptak;
set &inndata;
where sektor=2 and BoHF=&opptak;
run;

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

data phv1517_&navn_opptak._AS;
set &inndata;
where sektor=4 and BoHF=&opptak;
run;

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

/*Beregner snitt for 15-17*/
data inn_&navn_opptak.1517BoHF_sn;
set inn_&navn_opptak.1517BoHF;
snitt_innbyggere=tot_innbyggere/3;
run;

/*Beregner snittrater for 15-17 (per 10 000 innbyggere). Ujusterte rater.*/
data TSBPHV1517_&navn_opptak._I;
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

/*Lager output-tabeller.*/

/*PHV og TSB SAMMEN, BARE PD/IO*/

ods tagsets.tablesonlylatex tagset=event1
file="\\hn.helsenord.no\RHF\SKDE\Analyse\Prosjekter\2019_Psyk_HN\latex\&navn_opptak._TSBPHV_1517_INSTOPPH.tex" (notop nobot) style=journal;

title "Bosatte i &navn_opptak, inst. opphold, TSB/PHV";
PROC TABULATE
DATA=TSBPHV1517_&navn_opptak._I;
	VAR andel_inn andel_poli snitt_inn snitt_poli snitt_inn_I snitt_poli_I;
	CLASS BehHF_type /	ORDER=UNFORMATTED MISSING;
	CLASS sektor /	ORDER=UNFORMATTED MISSING;
	TABLE 
	/* Row Dimension */
	BehHF_type={label=''},
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
file="\\hn.helsenord.no\RHF\SKDE\Analyse\Prosjekter\2019_Psyk_HN\latex\&navn_opptak._TSBPHV_1517_PASDAGER.tex" (notop nobot) style=journal;

title "Bosatte i &navn_opptak, pasientdager, TSB/PHV";
PROC TABULATE
DATA=TSBPHV1517_&navn_opptak._I;
	VAR andel_inn andel_poli snitt_inn snitt_poli snitt_inn_I snitt_poli_I;
	CLASS BehHF_type /	ORDER=UNFORMATTED MISSING;
	CLASS sektor /	ORDER=UNFORMATTED MISSING;
	TABLE 
	/* Row Dimension */
	BehHF_type={label=''},
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

/*PHV og TSB HVER FOR SEG, PD/IO og UNIKE PASIENTER*/

/*Institusjonsopphold*/

ods tagsets.tablesonlylatex tagset=event1
file="\\hn.helsenord.no\RHF\SKDE\Analyse\Prosjekter\2019_Psyk_HN\latex\&navn_opptak._TSB_1517_INSTOPPH.tex" (notop nobot) style=journal;

title "Bosatte i &navn_opptak, inst. opphold og pasienter, TSB";
PROC TABULATE
DATA=TSBPHV1517_&navn_opptak._I;
where sektor=1;
	VAR andel_inn andel_inn_u snitt_inn snitt_inn_u snitt_inn_I snitt_inn_u_I;
	CLASS BehHF_type /	ORDER=UNFORMATTED MISSING;
	TABLE 
	/* Row Dimension */
	BehHF_type={label=''},
	/* Column Dimension */
	snitt_inn={label='Inst.opph.'}*Sum={label=''}*{f=nlnum8.0}  
	snitt_inn_I={label='Rate'}*Sum={label=''}*{f=nlnum8.0}  
	andel_inn={label='Andel'}*Sum={label=''}*{f=nlpct8.1} 
	snitt_inn_u={label='Pasienter'}*Sum={label=''}*{f=nlnum8.0}  
	snitt_inn_u_I={label='Rate'}*Sum={label=''}*{f=nlnum8.0}  
	andel_inn_u={label='Andel'}*Sum={label=''}*{f=nlpct8.1} 
	;

RUN;
TITLE;
ods tagsets.tablesonlylatex close;

ods tagsets.tablesonlylatex tagset=event1
file="\\hn.helsenord.no\RHF\SKDE\Analyse\Prosjekter\2019_Psyk_HN\latex\&navn_opptak._PHV_1517_INSTOPPH.tex" (notop nobot) style=journal;

title "Bosatte i &navn_opptak, inst. opphold og pasienter, PHV";
PROC TABULATE
DATA=TSBPHV1517_&navn_opptak._I;
where sektor=2;
	VAR andel_inn andel_inn_u snitt_inn snitt_inn_u snitt_inn_I snitt_inn_u_I;
	CLASS BehHF_type /	ORDER=UNFORMATTED MISSING;
	TABLE 
	/* Row Dimension */
	BehHF_type={label=''},
	/* Column Dimension */
	snitt_inn={label='Inst.opph.'}*Sum={label=''}*{f=nlnum8.0}  
	snitt_inn_I={label='Rate'}*Sum={label=''}*{f=nlnum8.0}  
	andel_inn={label='Andel'}*Sum={label=''}*{f=nlpct8.1} 
	snitt_inn_u={label='Pasienter'}*Sum={label=''}*{f=nlnum8.0}  
	snitt_inn_u_I={label='Rate'}*Sum={label=''}*{f=nlnum8.0}  
	andel_inn_u={label='Andel'}*Sum={label=''}*{f=nlpct8.1} 
	;

RUN;
TITLE;
ods tagsets.tablesonlylatex close;

/*Pasientdager*/

ods tagsets.tablesonlylatex tagset=event1
file="\\hn.helsenord.no\RHF\SKDE\Analyse\Prosjekter\2019_Psyk_HN\latex\&navn_opptak._TSB_1517_PASDAGER.tex" (notop nobot) style=journal;

title "Bosatte i &navn_opptak, pasientdager og pasienter, TSB";
PROC TABULATE
DATA=TSBPHV1517_&navn_opptak._I;
where sektor=1;
	VAR andel_poli andel_poli_u snitt_poli snitt_poli_u snitt_poli_I snitt_poli_u_I;
	CLASS BehHF_type /	ORDER=UNFORMATTED MISSING;
	TABLE 
	/* Row Dimension */
	BehHF_type={label=''},
	/* Column Dimension */
	snitt_poli={label='Pas.dager'}*Sum={label=''}*{f=nlnum8.0}  
	snitt_poli_I={label='Rate'}*Sum={label=''}*{f=nlnum8.0}  
	andel_poli={label='Andel'}*Sum={label=''}*{f=nlpct8.1} 
	snitt_poli_u={label='Pasienter'}*Sum={label=''}*{f=nlnum8.0}  
	snitt_poli_u_I={label='Rate'}*Sum={label=''}*{f=nlnum8.0}  
	andel_poli_u={label='Andel'}*Sum={label=''}*{f=nlpct8.1} 
	;

RUN;
TITLE;
ods tagsets.tablesonlylatex close;

ods tagsets.tablesonlylatex tagset=event1
file="\\hn.helsenord.no\RHF\SKDE\Analyse\Prosjekter\2019_Psyk_HN\latex\&navn_opptak._PHV_1517_PASDAGER.tex" (notop nobot) style=journal;

title "Bosatte i &navn_opptak, pasientdager og pasienter, PHV";
PROC TABULATE
DATA=TSBPHV1517_&navn_opptak._I;
where sektor=2;
	VAR andel_poli andel_poli_u snitt_poli snitt_poli_u snitt_poli_I snitt_poli_u_I;
	CLASS BehHF_type /	ORDER=UNFORMATTED MISSING;
	TABLE 
	/* Row Dimension */
	BehHF_type={label=''},
	/* Column Dimension */
	snitt_poli={label='Pas.dager'}*Sum={label=''}*{f=nlnum8.0}  
	snitt_poli_I={label='Rate'}*Sum={label=''}*{f=nlnum8.0}  
	andel_poli={label='Andel'}*Sum={label=''}*{f=nlpct8.1} 
	snitt_poli_u={label='Pasienter'}*Sum={label=''}*{f=nlnum8.0}  
	snitt_poli_u_I={label='Rate'}*Sum={label=''}*{f=nlnum8.0}  
	andel_poli_u={label='Andel'}*Sum={label=''}*{f=nlpct8.1} 
	;

RUN;
TITLE;
ods tagsets.tablesonlylatex close;

proc datasets nolist;
delete tsb1517: phv1517: inn_:;
run;



%mend;