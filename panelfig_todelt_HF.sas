%macro panelfig_todelt_HF(aar1=2015, aar2=2016, aar3=2017, del1=, del2=, tot=, var=, label1=, label2=, xlabel=, figtittel=);

proc format;

Value BoHF_ny
1='Finnmark'
2='UNN'
3='Nordland'
4='Helgeland'
5='Utenfor HN';

/*Beregner innbyggertall p� ny boHF variabel*/

data innbyggere_1517;
set innbygg.innb_2004_2017_bydel_allebyer;
where aar in (2015, 2016, 2017);
%boomraaderPsyk;
run;

proc sql;
create table innbygg_boHF as
select distinct aar, boHF, sum(innbyggere) as innb
from innbyggere_1517
group by aar, boHF;
quit;
run;

data innbygg_boHF2;
set innbygg_boHF;
where boHF ne .;

if boHF gt 4 then boHF_ny=5;
else boHF_ny=boHF;

format boHF_ny boHF_ny.;

run;

proc sql;
create table innbygg_boHF_ny as
select distinct aar, boHF_ny, sum(innb) as innb_ny
from innbygg_boHF2
group by aar, boHF_ny;
quit;
run;


/*DEL 1*/

/*Grupperer til pasientdager og institusjonsopphold, aggregerer.*/
%DagAktivitet(inndata=&del1, utdata=&del1._DA);
%aggreger_psyk_DA(inndata=&del1._DA, utdata=agg1, agg_var=alle, ut_boHF=1, ut_BehHF=0, ut_boDPS=0);

/*Lager ny boHF variabel, grupperer alle boHF i s�r til ett boHF.*/
data agg1_boHF2;
set agg1_boHF;
where boHF ne .;

if boHF gt 4 then boHF_ny=5;
else boHF_ny=boHF;

format boHF_ny boHF_ny.;

var=&var;

run;

/*aggregerer p� ny boHF variabel*/
proc sql;
create table agg1_boHF_ny as
select distinct aar, boHF_ny, sum(var) as var_ny
from agg1_boHF2
group by aar, boHF_ny;
quit;
run;


/*Setter sammen datasett med aggregerte tall og innbyggertall og beregner ujustert rate.*/
proc sort data=agg1_boHF_ny;
by aar boHF_ny;
quit;

proc sort data=innbygg_boHF_ny;
by aar boHF_ny;
quit;

data agg1_boHF_rate;
merge agg1_boHF_ny innbygg_boHF_ny;
by aar boHF_ny;

var_rate=10000*var_ny/innb_ny;

run;

/*DEL 2*/

/*Grupperer til pasientdager og institusjonsopphold, aggregerer.*/
%DagAktivitet(inndata=&del2, utdata=&del2._DA);
%aggreger_psyk_DA(inndata=&del2._DA, utdata=agg2, agg_var=alle, ut_boHF=1, ut_BehHF=0, ut_boDPS=0);

/*Lager ny boHF variabel, grupperer alle boHF i s�r til ett boHF.*/
data agg2_boHF2;
set agg2_boHF;
where boHF ne .;

if boHF gt 4 then boHF_ny=5;
else boHF_ny=boHF;

format boHF_ny boHF_ny.;

var=&var;

run;

/*aggregerer p� ny boHF variabel*/
proc sql;
create table agg2_boHF_ny as
select distinct aar, boHF_ny, sum(var) as var_ny
from agg2_boHF2
group by aar, boHF_ny;
quit;
run;

/*Setter sammen datasett med aggregerte tall og innbyggertall og beregner ujustert rate.*/
proc sort data=agg2_boHF_ny;
by aar boHF_ny;
quit;

proc sort data=innbygg_boHF_ny;
by aar boHF_ny;
quit;

data agg2_boHF_rate;
merge agg2_boHF_ny innbygg_boHF_ny;
by aar boHF_ny;

var_rate=10000*var_ny/innb_ny;

run;

/*ALLE*/

/*Grupperer til pasientdager og institusjonsopphold, agg3regerer.*/
%DagAktivitet(inndata=&tot, utdata=&tot._DA);
%aggreger_psyk_DA(inndata=&tot._DA, utdata=agg3, agg_var=alle, ut_boHF=1, ut_BehHF=0, ut_boDPS=0);

/*Lager ny boHF variabel, grupperer alle boHF i s�r til ett boHF.*/
data agg3_boHF2;
set agg3_boHF;
where boHF ne .;

if boHF gt 4 then boHF_ny=5;
else boHF_ny=boHF;

format boHF_ny boHF_ny.;

var=&var;

run;

/*aggregerer p� ny boHF variabel*/
proc sql;
create table agg3_boHF_ny as
select distinct aar, boHF_ny, sum(var) as var_ny
from agg3_boHF2
group by aar, boHF_ny;
quit;
run;

/*Setter sammen datasett med aggregerte tall og innbyggertall og beregner ujustert rate.*/
proc sort data=agg3_boHF_ny;
by aar boHF_ny;
quit;

proc sort data=innbygg_boHF_ny;
by aar boHF_ny;
quit;

data agg3_boHF_rate;
merge agg3_boHF_ny innbygg_boHF_ny;
by aar boHF_ny;

var_rate=10000*var_ny/innb_ny;

run;

%macro trans_hf(yr=,innfil=);
data yr&yr(keep=aar var_rate BoHF_ny);
  set &innfil;
  where aar=&yr;
  rename rate&yr=var_rate;
run;
%mend;


/* total */
%trans_hf(yr=&aar1, innfil=agg3_boHF_rate);
%trans_hf(yr=&aar2, innfil=agg3_boHF_rate);
%trans_hf(yr=&aar3, innfil=agg3_boHF_rate);
data tot_hf;
  set yr&aar1 yr&aar2 yr&aar3;
  *  where bohf <> 8888;
run;
proc sort data=tot_hf;  by aar bohf_ny; run;


/* del 1 */
%trans_hf(yr=&aar1, innfil=agg1_boHF_rate);
%trans_hf(yr=&aar2, innfil=agg1_boHF_rate);
%trans_hf(yr=&aar3, innfil=agg1_boHF_rate);
data del1_hf;
  set yr&aar1 yr&aar2 yr&aar3;
   * where bohf <> 8888;
run;
proc sort data=del1_hf;  by aar bohf_ny; run;


/* del 2 */
%trans_hf(yr=&aar1, innfil=agg2_boHF_rate);
%trans_hf(yr=&aar2, innfil=agg2_boHF_rate);
%trans_hf(yr=&aar3, innfil=agg2_boHF_rate);
data del2_hf;
  set yr&aar1 yr&aar2 yr&aar3;
   * where bohf <> 8888;
run;
proc sort data=del2_hf;  by aar bohf_ny; run;

data hf_&figtittel;
  merge tot_hf   (rename=(var_rate=RV_rate_tot))
        del1_hf  (rename=(var_rate=RV_rate_del1))
		del2_hf   (rename=(var_rate=RV_rate_del2));
  by aar bohf_ny;
where boHF_ny le 4;
run;


/*FIGURER*/

%let mappe=Panelfigurer\png\;

ODS Graphics ON /reset=All imagename="&figtittel._HF_panel" imagefmt=png border=off;
ODS Listing Image_dpi=300 GPATH="&bildelagring.&mappe";

proc sgpanel data=hf_&figtittel noautolegend sganno=&anno pad=(Bottom=5%);
PANELBY bohf_ny / columns=4 rows=1 novarname spacing=2 HEADERATTRS=(Color=black Family=Arial Size=8) noheaderborder;
vbarparm category=aar response=RV_rate_tot / outlineattrs=(thickness=1 color=bgr) fillattrs=(color=CX568BBF) missing name="rate 2" legendlabel="&label2";
vbarparm category=aar response=RV_rate_del1 / outlineattrs=(thickness=1 color=bgr) fillattrs=(color=CX95BDE6) missing name="rate 1" legendlabel="&label1";
/*series x=aar y=Norge_rate_tot /lineattrs=(color=black pattern=1 thickness=2) name="norge" legendlabel="Norge";*/
keylegend "rate 1" "rate 2"/ noborder position=bottom;
colaxis fitpolicy=thin display=(nolabel) valueattrs=(size=8);
rowaxis label="&xlabel" valueattrs=(size=8) labelattrs=(size=8)  ;
RUN; 

ods listing close;

%let mappe=Panelfigurer\pdf\;

ODS Graphics ON /reset=All imagename="&figtittel._HF_panel" imagefmt=pdf border=off;
ODS Listing Image_dpi=300 GPATH="&bildelagring.&mappe";

proc sgpanel data=hf_&figtittel noautolegend sganno=&anno pad=(Bottom=5%);
PANELBY bohf_ny / columns=4 rows=1 novarname spacing=2 HEADERATTRS=(Color=black Family=Arial Size=8) noheaderborder;
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
