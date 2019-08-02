%macro panelfig_todelt_DPS(aar1=2015, aar2=2016, aar3=2017, del1=, del2=, tot=, var=, label1=, label2=, xlabel=, figtittel=);

proc format;

value BoDPS_ny
1='Øst-Finnmark'
2='Midt-Finnmark'
3='Vest-Finnmark'
4='Nord-Troms'
5='Midt-Troms'
6='Tromsø'
7='Sør-Troms'
8='Ofoten'
9='Vesterålen'
10='Salten'
11='Lofoten'
12= "Mo i Rana"
13= "Mosjøen"
14= "Ytre Helgeland"
15= "Utenfor HN";

/*Beregner innbyggertall på ny BoDPS variabel*/

data innbyggere_1517;
set innbygg.innb_2004_2017_bydel_allebyer;
where aar in (2015, 2016, 2017) and alder ge 18;
%boomraaderPsyk;
run;

proc sql;
create table innbygg_BoDPS as
select distinct aar, BoDPS, sum(innbyggere) as innb
from innbyggere_1517
group by aar, BoDPS;
quit;
run;

data innbygg_BoDPS2;
set innbygg_BoDPS;
where BoDPS ne .;

if boDPS gt 14 then boDPS_ny=15;
else boDPS_ny=boDPS;

format BoDPS_ny BoDPS_ny.;

run;

proc sql;
create table innbygg_BoDPS_ny as
select distinct aar, BoDPS_ny, sum(innb) as innb_ny
from innbygg_BoDPS2
group by aar, BoDPS_ny;
quit;
run;


/*DEL 1*/

/*Grupperer til pasientdager og institusjonsopphold, aggregerer.*/
%aggreger_psyk_DA(inndata=&del1, utdata=agg1, agg_var=alle, ut_boHF=0, ut_BehHF=0, ut_boDPS=1);

/*Lager ny BoDPS variabel, grupperer alle BoDPS i sør til ett BoDPS.*/
data agg1_BoDPS2;
set agg1_BoDPS;
where BoDPS ne .;

if boDPS gt 14 then boDPS_ny=15;
else boDPS_ny=boDPS;

format BoDPS_ny BoDPS_ny.;

var=&var;

run;

/*aggregerer på ny BoDPS variabel*/
proc sql;
create table agg1_BoDPS_ny as
select distinct aar, BoDPS_ny, sum(var) as var_ny
from agg1_BoDPS2
group by aar, BoDPS_ny;
quit;
run;


/*Setter sammen datasett med aggregerte tall og innbyggertall og beregner ujustert rate.*/
proc sort data=agg1_BoDPS_ny;
by aar BoDPS_ny;
quit;

proc sort data=innbygg_BoDPS_ny;
by aar BoDPS_ny;
quit;

data agg1_BoDPS_rate;
merge agg1_BoDPS_ny innbygg_BoDPS_ny;
by aar BoDPS_ny;

var_rate=10000*var_ny/innb_ny;

run;

/*DEL 2*/

/*Grupperer til pasientdager og institusjonsopphold, aggregerer.*/
%aggreger_psyk_DA(inndata=&del2, utdata=agg2, agg_var=alle, ut_boHF=0, ut_BehHF=0, ut_boDPS=1);

/*Lager ny BoDPS variabel, grupperer alle BoDPS i sør til ett BoDPS.*/
data agg2_BoDPS2;
set agg2_BoDPS;
where BoDPS ne .;

if boDPS gt 14 then boDPS_ny=15;
else boDPS_ny=boDPS;

format BoDPS_ny BoDPS_ny.;

var=&var;

run;

/*aggregerer på ny BoDPS variabel*/
proc sql;
create table agg2_BoDPS_ny as
select distinct aar, BoDPS_ny, sum(var) as var_ny
from agg2_BoDPS2
group by aar, BoDPS_ny;
quit;
run;

/*Setter sammen datasett med aggregerte tall og innbyggertall og beregner ujustert rate.*/
proc sort data=agg2_BoDPS_ny;
by aar BoDPS_ny;
quit;

proc sort data=innbygg_BoDPS_ny;
by aar BoDPS_ny;
quit;

data agg2_BoDPS_rate;
merge agg2_BoDPS_ny innbygg_BoDPS_ny;
by aar BoDPS_ny;

var_rate=10000*var_ny/innb_ny;

run;

/*ALLE*/

/*Grupperer til pasientdager og institusjonsopphold, agg3regerer.*/
%aggreger_psyk_DA(inndata=&tot, utdata=agg3, agg_var=alle, ut_boHF=0, ut_BehHF=0, ut_boDPS=1);

/*Lager ny BoDPS variabel, grupperer alle BoDPS i sør til ett BoDPS.*/
data agg3_BoDPS2;
set agg3_BoDPS;
where BoDPS ne .;

if boDPS gt 14 then boDPS_ny=15;
else boDPS_ny=boDPS;

format BoDPS_ny BoDPS_ny.;

var=&var;

run;

/*aggregerer på ny BoDPS variabel*/
proc sql;
create table agg3_BoDPS_ny as
select distinct aar, BoDPS_ny, sum(var) as var_ny
from agg3_BoDPS2
group by aar, BoDPS_ny;
quit;
run;

/*Setter sammen datasett med aggregerte tall og innbyggertall og beregner ujustert rate.*/
proc sort data=agg3_BoDPS_ny;
by aar BoDPS_ny;
quit;

proc sort data=innbygg_BoDPS_ny;
by aar BoDPS_ny;
quit;

data agg3_BoDPS_rate;
merge agg3_BoDPS_ny innbygg_BoDPS_ny;
by aar BoDPS_ny;

var_rate=10000*var_ny/innb_ny;

run;

%macro trans_hf(yr=,innfil=);
data yr&yr(keep=aar var_rate BoDPS_ny);
  set &innfil;
  where aar=&yr;
  rename rate&yr=var_rate;
run;
%mend;


/* total */
%trans_hf(yr=&aar1, innfil=agg3_BoDPS_rate);
%trans_hf(yr=&aar2, innfil=agg3_BoDPS_rate);
%trans_hf(yr=&aar3, innfil=agg3_BoDPS_rate);
data tot_hf;
  set yr&aar1 yr&aar2 yr&aar3;
  *  where BoDPS <> 8888;
run;
proc sort data=tot_hf;  by aar BoDPS_ny; run;


/* del 1 */
%trans_hf(yr=&aar1, innfil=agg1_BoDPS_rate);
%trans_hf(yr=&aar2, innfil=agg1_BoDPS_rate);
%trans_hf(yr=&aar3, innfil=agg1_BoDPS_rate);
data del1_hf;
  set yr&aar1 yr&aar2 yr&aar3;
   * where BoDPS <> 8888;
run;
proc sort data=del1_hf;  by aar BoDPS_ny; run;


/* del 2 */
%trans_hf(yr=&aar1, innfil=agg2_BoDPS_rate);
%trans_hf(yr=&aar2, innfil=agg2_BoDPS_rate);
%trans_hf(yr=&aar3, innfil=agg2_BoDPS_rate);
data del2_hf;
  set yr&aar1 yr&aar2 yr&aar3;
   * where BoDPS <> 8888;
run;
proc sort data=del2_hf;  by aar BoDPS_ny; run;

data hf_&figtittel;
  merge tot_hf   (rename=(var_rate=RV_rate_tot))
        del1_hf  (rename=(var_rate=RV_rate_del1))
		del2_hf   (rename=(var_rate=RV_rate_del2));
  by aar BoDPS_ny;
where BoDPS_ny le 14;
run;


/*FIGURER*/

%let mappe=Panelfigurer\png\;

ODS Graphics ON /reset=All imagename="&figtittel._DPS_panel" imagefmt=png border=off;
ODS Listing Image_dpi=300 GPATH="&bildelagring.&mappe";

proc sgpanel data=hf_&figtittel noautolegend sganno=&anno pad=(Bottom=5%);
PANELBY BoDPS_ny / columns=7 rows=2 novarname spacing=2 HEADERATTRS=(Color=black Family=Arial Size=8) noheaderborder;
vbarparm category=aar response=RV_rate_tot / outlineattrs=(thickness=1 color=bgr) fillattrs=(color=CX568BBF) missing name="rate 2" legendlabel="&label2";
vbarparm category=aar response=RV_rate_del1 / outlineattrs=(thickness=1 color=bgr) fillattrs=(color=CX95BDE6) missing name="rate 1" legendlabel="&label1";
/*series x=aar y=Norge_rate_tot /lineattrs=(color=black pattern=1 thickness=2) name="norge" legendlabel="Norge";*/
keylegend "rate 1" "rate 2"/ noborder position=bottom;
colaxis fitpolicy=thin display=(nolabel) valueattrs=(size=8);
rowaxis label="&xlabel" valueattrs=(size=8) labelattrs=(size=8)  ;
RUN; 

ods listing close;

%let mappe=Panelfigurer\pdf\;

ODS Graphics ON /reset=All imagename="&figtittel._DPS_panel" imagefmt=pdf border=off;
ODS Listing Image_dpi=300 GPATH="&bildelagring.&mappe";

proc sgpanel data=hf_&figtittel noautolegend sganno=&anno pad=(Bottom=5%);
PANELBY BoDPS_ny / columns=7 rows=2 novarname spacing=2 HEADERATTRS=(Color=black Family=Arial Size=8) noheaderborder;
vbarparm category=aar response=RV_rate_tot / outlineattrs=(thickness=1 color=bgr) fillattrs=(color=CX568BBF) missing name="rate 2" legendlabel="&label2";
vbarparm category=aar response=RV_rate_del1 / outlineattrs=(thickness=1 color=bgr) fillattrs=(color=CX95BDE6) missing name="rate 1" legendlabel="&label1";
/*series x=aar y=Norge_rate_tot /lineattrs=(color=black pattern=1 thickness=2) name="norge" legendlabel="Norge";*/
keylegend "rate 1" "rate 2"/ noborder position=bottom;
colaxis fitpolicy=thin display=(nolabel) valueattrs=(size=8) ;
rowaxis label="&xlabel" valueattrs=(size=8) labelattrs=(size=8)  ;
RUN; 
ods listing close;


proc datasets nolist;
delete yr: del: innbygg_: agg:;
run;

%mend;
