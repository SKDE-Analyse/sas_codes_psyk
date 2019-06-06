%macro ratefig_BoHF(inndata=, var=poli, utfil_navn=);

proc format;

Value BoHF_ny
1='Finnmark'
2='UNN'
3='Nordland'
4='Helgeland'
5='Utenfor HN';

/*Grupperer til pasientdager og institusjonsopphold, aggregerer.*/
%DagAktivitet(inndata=&inndata, utdata=&inndata._DA);
%aggreger_psyk_DA(inndata=&inndata._DA, utdata=agg, agg_var=alle, ut_boHF=1, ut_BehHF=0, ut_boDPS=0);

/*Summerer for årene 15-17*/
proc sql;
create table agg_boHF_tot as
select distinct boHF, sum(&var) as var_tot
from agg_boHF
group by boHF;
quit;
run;

/*Lager ny boHF variabel, grupperer alle boHF i sør til ett boHF.*/
data agg_boHF_snitt;
set agg_boHF_tot;
where boHF ne .;

var_snitt=var_tot/3;

if boHF gt 4 then boHF_ny=5;
else boHF_ny=boHF;

format boHF_ny boHF_ny.;

run;

/*Aggregerer på ny boHF variabel*/
proc sql;
create table agg_boHF_ny as
select distinct boHF_ny, sum(var_snitt) as var_snitt_ny
from agg_boHF_snitt
group by boHF_ny;
quit;
run;

/*Beregner innbyggertall på ny boHF variabel*/

data innbyggere_1517;
set innbygg.innb_2004_2017_bydel_allebyer;
where aar in (2015, 2016, 2017) and alder ge 18;
%boomraaderPsyk;
run;

proc sql;
create table innbygg_boHF_tot as
select distinct boHF, sum(innbyggere) as innb_tot
from innbyggere_1517
group by boHF;
quit;
run;

data innbygg_boHF_snitt;
set innbygg_boHF_tot;
where boHF ne .;

innb_snitt=innb_tot/3;

if boHF gt 4 then boHF_ny=5;
else boHF_ny=boHF;

format boHF_ny boHF_ny.;

run;

proc sql;
create table innbygg_boHF_ny as
select distinct boHF_ny, sum(innb_snitt) as innb_snitt_ny
from innbygg_boHF_snitt
group by boHF_ny;
quit;
run;


/*Setter sammen datasett med aggregerte tall og innbyggertall og beregner ujustert rate.*/
proc sort data=agg_boHF_ny;
by boHF_ny;
quit;

proc sort data=innbygg_boHF_ny;
by boHF_ny;
quit;

data agg_boHF_sn_I;
merge agg_boHF_ny innbygg_boHF_ny;
by boHF_ny;

var_rate=10000*var_snitt_ny/innb_snitt_ny;

run;

/*Lager figurer*/
%let mappe=Ratefigurer\png\;

ODS Graphics ON /reset=All imagename="&utfil_navn._HF" imagefmt=png border=off ;
ODS Listing Image_dpi=300 GPATH="&bildelagring.&mappe";
proc sgplot data=agg_boHF_sn_I noborder noautolegend sganno=anno pad=(Bottom=5%);

     hbarparm category=boHF_ny response=var_rate / fillattrs=(color=CX95BDE6) missing outlineattrs=(color=grey);  

 	     *yaxis min=24 display=(noticks noline) label='Opptaksområde' labelattrs=(size=8 weight=bold) type=discrete discreteorder=data valueattrs=(size=8);
	 yaxis display=(noticks noline) label='Bosatte i opptaksområdene' labelpos=top labelattrs=(size=8 weight=bold) type=discrete discreteorder=data valueattrs=(size=9);
     xaxis  offsetmin=0 offsetmax=0.02  valueattrs=(size=8) label="&xlabel" labelattrs=(size=8 weight=bold);
     Yaxistable &hoyretabell /Label location=inside labelpos=top position=right valueattrs=(size=9 family=arial) labelattrs=(size=9);
	 label &labeltabell;

format &formattabell;

run;Title; ods listing close;

%let mappe=Ratefigurer\pdf\;

ODS Graphics ON /reset=All imagename="&utfil_navn._HF" imagefmt=pdf border=off ;
ODS Listing Image_dpi=300 GPATH="&bildelagring.&mappe";
proc sgplot data=agg_boHF_sn_I noborder noautolegend sganno=anno pad=(Bottom=5%);

     hbarparm category=boHF_ny response=var_rate / fillattrs=(color=CX95BDE6) missing outlineattrs=(color=grey);  

 	     *yaxis min=24 display=(noticks noline) label='Opptaksområde' labelattrs=(size=8 weight=bold) type=discrete discreteorder=data valueattrs=(size=8);
	 yaxis display=(noticks noline) label='Bosatte i opptaksområdene' labelpos=top labelattrs=(size=8 weight=bold) type=discrete discreteorder=data valueattrs=(size=9);
     xaxis  offsetmin=0 offsetmax=0.02  valueattrs=(size=8) label="&xlabel" labelattrs=(size=8 weight=bold);
     Yaxistable &hoyretabell /Label location=inside labelpos=top position=right valueattrs=(size=9 family=arial) labelattrs=(size=9);
	 label &labeltabell;

format &formattabell;


run;Title; ods listing close;

%mend;
