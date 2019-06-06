%macro panelfig_alder_firedelt_HF(aar1=2015, aar2=2016, aar3=2017, ds_en=, ds_to=, ds_tre=, ds_fire=, aldr_gr1=, aldr_gr2=, aldr_gr3=, aldr_gr4=, var=);

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
where aar in (2015, 2016, 2017) and alder ge 18;
%boomraaderPsyk;
run;

%macro lag_innb_ds(dsinn=, aldr=);

proc sql;
create table innbygg_&dsinn._boHF as
select distinct aar, boHF, sum(innbyggere) as innb
from innbyggere_1517
where &aldr
group by aar, boHF;
quit;
run;

data innbygg_&dsinn._boHF2;
set innbygg_&dsinn._boHF;
where boHF ne .;

if boHF gt 4 then boHF_ny=5;
else boHF_ny=boHF;

format boHF_ny boHF_ny.;

run;

proc sql;
create table innbygg_&dsinn._boHF_ny as
select distinct aar, boHF_ny, sum(innb) as innb_ny
from innbygg_&dsinn._boHF2
group by aar, boHF_ny;
quit;
run;

%mend;

%lag_innb_ds(dsinn=&ds_en, aldr=&aldr_gr1);
%lag_innb_ds(dsinn=&ds_to, aldr=&aldr_gr2);
%lag_innb_ds(dsinn=&ds_tre, aldr=&aldr_gr3);
%lag_innb_ds(dsinn=&ds_fire, aldr=&aldr_gr4);


%macro lag_rater(dsinn=);

/*Grupperer til pasientdager og institusjonsopphold, aggregerer.*/
%DagAktivitet(inndata=&dsinn, utdata=&dsinn._DA);
%aggreger_psyk_DA(inndata=&dsinn._DA, utdata=agg_&dsinn, agg_var=alle, ut_boHF=1, ut_BehHF=0, ut_boDPS=0);

/*Lager ny boHF variabel, grupperer alle boHF i s�r til ett boHF.*/
data agg_&dsinn._boHF2;
set agg_&dsinn._boHF;
where boHF ne .;

if boHF gt 4 then boHF_ny=5;
else boHF_ny=boHF;

format boHF_ny boHF_ny.;

var=&var;

run;

/*aggregerer p� ny boHF variabel*/
proc sql;
create table agg_&dsinn._boHF_ny as
select distinct aar, boHF_ny, sum(var) as var_ny
from agg_&dsinn._boHF2
group by aar, boHF_ny;
quit;
run;


/*Setter sammen datasett med aggregerte tall og innbyggertall og beregner ujustert rate.*/
proc sort data=agg_&dsinn._boHF_ny;
by aar boHF_ny;
quit;

proc sort data=innbygg_&dsinn._boHF_ny;
by aar boHF_ny;
quit;

data agg_&dsinn._boHF_rate;
merge agg_&dsinn._boHF_ny innbygg_&dsinn._boHF_ny;
by aar boHF_ny;

var_rate=10000*var_ny/innb_ny;

run;

%mend;

%lag_rater(dsinn=&ds_en);
%lag_rater(dsinn=&ds_to);
%lag_rater(dsinn=&ds_tre);
%lag_rater(dsinn=&ds_fire);


%macro trans_hf(yr=,innfil=);
data yr&yr(keep=aar var_rate BoHF_ny);
  set &innfil;
  where aar=&yr;
  rename rate&yr=var_rate;
run;
%mend;


/* del 1 */
%trans_hf(yr=&aar1, innfil=agg_&ds_en._boHF_rate);
%trans_hf(yr=&aar2, innfil=agg_&ds_en._boHF_rate);
%trans_hf(yr=&aar3, innfil=agg_&ds_en._boHF_rate);
data del1_hf;
  set yr&aar1 yr&aar2 yr&aar3;
   * where bohf <> 8888;
   Alder="&aldr_str1";
run;
proc sort data=del1_hf;  by aar bohf_ny; run;


/* del 2 */
%trans_hf(yr=&aar1, innfil=agg_&ds_to._boHF_rate);
%trans_hf(yr=&aar2, innfil=agg_&ds_to._boHF_rate);
%trans_hf(yr=&aar3, innfil=agg_&ds_to._boHF_rate);
data del2_hf;
  set yr&aar1 yr&aar2 yr&aar3;
   * where bohf <> 8888;
   Alder="&aldr_str2";
run;
proc sort data=del2_hf;  by aar bohf_ny; run;

/* del 3 */
%trans_hf(yr=&aar1, innfil=agg_&ds_tre._boHF_rate);
%trans_hf(yr=&aar2, innfil=agg_&ds_tre._boHF_rate);
%trans_hf(yr=&aar3, innfil=agg_&ds_tre._boHF_rate);
data del3_hf;
  set yr&aar1 yr&aar2 yr&aar3;
   * where bohf <> 8888;
   Alder="&aldr_str3";
run;
proc sort data=del3_hf;  by aar bohf_ny; run;


/* del 4 */
%trans_hf(yr=&aar1, innfil=agg_&ds_fire._boHF_rate);
%trans_hf(yr=&aar2, innfil=agg_&ds_fire._boHF_rate);
%trans_hf(yr=&aar3, innfil=agg_&ds_fire._boHF_rate);
data del4_hf;
  set yr&aar1 yr&aar2 yr&aar3;
   * where bohf <> 8888;
   Alder="&aldr_str4";
run;
proc sort data=del4_hf;  by aar bohf_ny; run;

data hf_&figtittel;
set del1_hf del2_hf del3_hf del4_hf;
where boHF_ny le 4;
run;


/*FIGURER*/

%let mappe=Panelfigurer\png\;

ODS Graphics ON /reset=All imagename="&figtittel._HF_panel" imagefmt=png border=off;
ODS Listing Image_dpi=300 GPATH="&bildelagring.&mappe";

proc sgpanel data=hf_&figtittel noautolegend sganno=&anno pad=(Bottom=5%);
styleattrs datacolors=(CX568BBF CX95BDE6 black grey);
PANELBY bohf_ny / columns=4 rows=1 novarname spacing=2 HEADERATTRS=(Color=black Family=Arial Size=8) noheaderborder;
vbarparm category=aar response=var_rate / group=alder groupdisplay=cluster outlineattrs=(thickness=1 color=bgr) missing;
/*series x=aar y=Norge_rate_tot /lineattrs=(color=black pattern=1 thickness=2) name="norge" legendlabel="Norge";*/
keylegend / noborder position=bottom;
colaxis fitpolicy=thin display=(nolabel) valueattrs=(size=8);
rowaxis label="&xlabel" valueattrs=(size=8) labelattrs=(size=8)  ;
RUN; 

ods listing close;

%let mappe=Panelfigurer\pdf\;

ODS Graphics ON /reset=All imagename="&figtittel._HF_panel" imagefmt=pdf border=off;
ODS Listing Image_dpi=300 GPATH="&bildelagring.&mappe";

proc sgpanel data=hf_&figtittel noautolegend sganno=&anno pad=(Bottom=5%);
styleattrs datacolors=(CX568BBF CX95BDE6 black grey);
PANELBY bohf_ny / columns=4 rows=1 novarname spacing=2 HEADERATTRS=(Color=black Family=Arial Size=8) noheaderborder;
vbarparm category=aar response=var_rate / group=alder groupdisplay=cluster outlineattrs=(thickness=1 color=bgr) missing;
/*series x=aar y=Norge_rate_tot /lineattrs=(color=black pattern=1 thickness=2) name="norge" legendlabel="Norge";*/
keylegend / noborder position=bottom;
colaxis fitpolicy=thin display=(nolabel) valueattrs=(size=8) ;
rowaxis label="&xlabel" valueattrs=(size=8) labelattrs=(size=8)  ;
RUN; 
ods listing close;

/*
proc datasets nolist;
delete yr: del: innbygg_: agg:;
run;
*/
%mend;
