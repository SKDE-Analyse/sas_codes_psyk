%macro ratefig_BoDPS(inndata=, var=poli, var2=poli_unik_aar, utfil_navn=);

proc format;

value BoDPS_ny
1='Øst-Finnmark'
2='Midt-Finnmark'
3='Vest-Finnmark'
4='Nord-Troms'
5='Midt-Troms'
6='Tromsø og omegn'
7='Sør-Troms'
8='Ofoten'
9='Vesterålen'
10='Salten (inkl Tysfjord)'
11='Lofoten'
12= "Mo i Rana"
13= "Mosjøen"
14= "Ytre Helgeland"
15= "Utenfor HN";

/*Grupperer til pasientdager og institusjonsopphold, aggregerer.*/
%DagAktivitet(inndata=&inndata, utdata=&inndata._DA);
%aggreger_psyk_DA(inndata=&inndata._DA, utdata=agg, agg_var=alle, ut_boHF=0, ut_BehHF=0, ut_boDPS=1);

/*Summerer for årene 15-17*/
proc sql;
create table agg_boDPS_tot as
select distinct boDPS, sum(&var) as var_tot, sum(&var2) as var2_tot
from agg_boDPS
group by boDPS;
quit;
run;

%macro aarsrate(ds=, yr=);

data &ds._&yr;
set &ds.;
where aar=&yr;
run;

proc sql;
create table &ds._tot_&yr as
select distinct boDPS, sum(&var) as var_tot_&yr
from &ds._&yr
group by boDPS;
quit;
run;

%mend;

%aarsrate(ds=agg_boDPS, yr=2015);
%aarsrate(ds=agg_boDPS, yr=2016);
%aarsrate(ds=agg_boDPS, yr=2017);

data agg_boDPS_tot2;
merge agg_boDPS_tot agg_boDPS_tot_2015 agg_boDPS_tot_2016 agg_boDPS_tot_2017;
by boDPS;
run;

/*Lager ny boDPS variabel, grupperer alle boDPS i sør til ett boDPS.*/
data agg_boDPS_snitt;
set agg_boDPS_tot2;
where boDPS ne .;

var_snitt=var_tot/3;
var2_snitt=var2_tot/3;

if boDPS gt 14 then boDPS_ny=15;
else boDPS_ny=boDPS;

format boDPS_ny boDPS_ny.;

run;

/*Aggregerer på ny boDPS variabel*/
proc sql;
create table agg_boDPS_ny as
select distinct boDPS_ny, sum(var_snitt) as var_snitt_ny, sum(var2_snitt) as var2_snitt_ny, 
sum(var_tot_2015) as var_tot_2015_ny, sum(var_tot_2016) as var_tot_2016_ny, sum(var_tot_2017) as var_tot_2017_ny
from agg_boDPS_snitt
group by boDPS_ny;
quit;
run;

/*Beregner innbyggertall på ny boDPS variabel*/

data innbyggere_1517;
set innbygg.innb_2004_2017_bydel_allebyer;
where aar in (2015, 2016, 2017) and alder ge 18;
%boomraaderPsyk;
run;

proc sql;
create table innbygg_boDPS_tot as
select distinct boDPS, sum(innbyggere) as innb_tot
from innbyggere_1517
group by boDPS;
quit;
run;


%macro aarsrate_innb(ds=, yr=);

data innbygg_boDPS_&yr;
set &ds.;
where aar=&yr;
run;

proc sql;
create table innbygg_boDPS_tot_&yr as
select distinct boDPS, sum(innbyggere) as innb_tot_&yr
from innbygg_boDPS_&yr
group by boDPS;
quit;
run;

%mend;

%aarsrate_innb(ds=innbyggere_1517, yr=2015);
%aarsrate_innb(ds=innbyggere_1517, yr=2016);
%aarsrate_innb(ds=innbyggere_1517, yr=2017);

data innbygg_boDPS_tot2;
merge innbygg_boDPS_tot innbygg_boDPS_tot_2015 innbygg_boDPS_tot_2016 innbygg_boDPS_tot_2017;
by boDPS;
run;

data innbygg_boDPS_snitt;
set innbygg_boDPS_tot2;
where boDPS ne .;

innb_snitt=innb_tot/3;

if boDPS gt 14 then boDPS_ny=15;
else boDPS_ny=boDPS;

format boDPS_ny boDPS_ny.;

run;

proc sql;
create table innbygg_boDPS_ny as
select distinct boDPS_ny, sum(innb_snitt) as innb_snitt_ny,
sum(innb_tot_2015) as innb_tot_2015_ny, sum(innb_tot_2016) as innb_tot_2016_ny, sum(innb_tot_2017) as innb_tot_2017_ny
from innbygg_boDPS_snitt
group by boDPS_ny;
quit;
run;


/*Setter sammen datasett med aggregerte tall og innbyggertall og beregner ujustert rate.*/
proc sort data=agg_boDPS_ny;
by boDPS_ny;
quit;

proc sort data=innbygg_boDPS_ny;
by boDPS_ny;
quit;

data agg_boDPS_sn_I;
merge agg_boDPS_ny innbygg_boDPS_ny;
by boDPS_ny;

/*Snittrate plottevariabel*/
var_rate=10000*var_snitt_ny/innb_snitt_ny;
var2_rate=10000*var2_snitt_ny/innb_snitt_ny;

/*Snittrate ekstravariabel (for bruk i tabell)*/
var_var2=var_rate/var2_rate;
var2_var=var2_rate/var_rate;

/*Snittrater plottevariabel pr år*/
var_rate_2015=10000*var_tot_2015_ny/innb_tot_2015_ny;
var_rate_2016=10000*var_tot_2016_ny/innb_tot_2016_ny;
var_rate_2017=10000*var_tot_2017_ny/innb_tot_2017_ny;

max=var_rate_2015;
if var_rate_2016 gt max then max=var_rate_2016;
if var_rate_2017 gt max then max=var_rate_2017;

min=var_rate_2015;
if var_rate_2016 lt min then min=var_rate_2016;
if var_rate_2017 lt min then min=var_rate_2017;

run;

/*Lager figurer*/
%let mappe=Ratefigurer\png\;

ODS Graphics ON /reset=All imagename="&utfil_navn._DPS" imagefmt=png border=off ;
ODS Listing Image_dpi=300 GPATH="&bildelagring.&mappe";
proc sgplot data=agg_boDPS_sn_I noborder noautolegend sganno=anno pad=(Bottom=5%);
where BoDPS_ny le 14;

     hbarparm category=boDPS_ny response=var_rate / fillattrs=(color=CX95BDE6) missing outlineattrs=(color=grey);  

     scatter x=var_rate_2017 y=BoDPS_ny / markerattrs=(symbol=circle       color=black size=9pt) name="y3" legendlabel="2017"; 
	scatter x=var_rate_2016 y=BoDPS_ny / markerattrs=(symbol=circlefilled color=grey  size=7pt) name="y2" legendlabel="2016"; 
	scatter x=var_rate_2015 y=boDPS_ny / markerattrs=(symbol=circlefilled color=black size=5pt) name="y1" legendlabel="2015";
     Highlow Y=BoDPS_ny low=Min high=Max / type=line name="hl2" lineattrs=(color=black thickness=1 pattern=1); 
     keylegend "y1" "y2" "y3" / across=1 position=bottomright location=inside noborder valueattrs=(size=7pt);

 	     *yaxis min=24 display=(noticks noline) label='Opptaksområde' labelattrs=(size=8 weight=bold) type=discrete discreteorder=data valueattrs=(size=8);
	 yaxis display=(noticks noline) label='Bosatte i opptaksområdene' labelpos=top labelattrs=(size=8 weight=bold) type=discrete discreteorder=data valueattrs=(size=9);
     xaxis  offsetmin=0 offsetmax=0.02  valueattrs=(size=8) label="&xlabel" labelattrs=(size=8 weight=bold);
     Yaxistable &hoyretabell /Label location=inside labelpos=top position=right valueattrs=(size=9 family=arial) labelattrs=(size=9);
	 label &labeltabell;

format &formattabell;

run;Title; ods listing close;

%let mappe=Ratefigurer\pdf\;

ODS Graphics ON /reset=All imagename="&utfil_navn._DPS" imagefmt=pdf border=off ;
ODS Listing Image_dpi=300 GPATH="&bildelagring.&mappe";
proc sgplot data=agg_boDPS_sn_I noborder noautolegend sganno=anno pad=(Bottom=5%);
where BoDPS_ny le 14;

     hbarparm category=boDPS_ny response=var_rate / fillattrs=(color=CX95BDE6) missing outlineattrs=(color=grey); 

     scatter x=var_rate_2017 y=BoDPS_ny / markerattrs=(symbol=circle       color=black size=9pt) name="y3" legendlabel="2017"; 
	scatter x=var_rate_2016 y=BoDPS_ny / markerattrs=(symbol=circlefilled color=grey  size=7pt) name="y2" legendlabel="2016"; 
	scatter x=var_rate_2015 y=boDPS_ny / markerattrs=(symbol=circlefilled color=black size=5pt) name="y1" legendlabel="2015";
     Highlow Y=BoDPS_ny low=Min high=Max / type=line name="hl2" lineattrs=(color=black thickness=1 pattern=1); 
     keylegend "y1" "y2" "y3" / across=1 position=bottomright location=inside noborder valueattrs=(size=7pt);
 

 	     *yaxis min=24 display=(noticks noline) label='Opptaksområde' labelattrs=(size=8 weight=bold) type=discrete discreteorder=data valueattrs=(size=8);
	 yaxis display=(noticks noline) label='Bosatte i opptaksområdene' labelpos=top labelattrs=(size=8 weight=bold) type=discrete discreteorder=data valueattrs=(size=9);
     xaxis  offsetmin=0 offsetmax=0.02  valueattrs=(size=8) label="&xlabel" labelattrs=(size=8 weight=bold);
      Yaxistable &hoyretabell /Label location=inside labelpos=top position=right valueattrs=(size=9 family=arial) labelattrs=(size=9);
	 label &labeltabell;

format &formattabell;

run;Title; ods listing close;

%mend;