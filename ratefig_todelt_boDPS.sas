%macro ratefig_todelt_boDPS(fil1=, data1=, fil2=, data2=, figtittel=);
/*
Must run ratefig_BoDPS macro first:
one time for the entire column that we want to plot (for example, total)
one time for the left part of the column that we want to plot (for example, offentlig)

fil1 = the overall column we want to draw, for example total
data1= var or var2 depending on which information we want to make the figure on
fil2 = the left part of the column, for example offentlig, therefore the rest of the column is private
data2= var or var2
figtittel = output file name, used for sas dataset and png/pdf figure file name

EXAMPLE:
%ratefig_BoDPS(inndata=phv1517_PD, var=poli_unik_aar, var2=poli, utfil_navn=Pas_PD_PHV);
%ratefig_BoDPS(inndata=phv1517_PD, var=poli_off_unik_aar, var2=poli_off, utfil_navn=Pas_PD_PHV_off);

%let label1=Offentlig;
%let label2=Privat;
%Let xlabel=Antall pasientdager per 10 000 innbyggere, justert for kjønn og alder;

%ratefig_todelt_boDPS(fil1=Pas_PD_PHV,data1=var2,fil2=Pas_PD_PHV_off, data2=var2, figtittel=Pas_PD_PHV_todelt);
*/

proc sort data=&fil1;
  by boDPS_ny;
run;

proc sort data=&fil2;
  by boDPS_ny;
run;

data &figtittel;
merge &fil1(rename=(&data1._rate=rate_tot)) &fil2(keep=boDPS_ny &data2._rate rename=(&data2._rate=rate_del1));
by boDPS_ny;
min=min(&data1._rate_2015,&data1._rate_2016,&data1._rate_2017);
max=max(&data1._rate_2015,&data1._rate_2016,&data1._rate_2017);
run;
/*Lager figurer*/

proc sort data=&figtittel;
 by descending rate_tot;
run;

%let mappe_png=&mappe.\png\justrate;
ODS Graphics ON /reset=All imagename="&figtittel" imagefmt=png border=off ;
ODS Listing Image_dpi=300 GPATH="&bildelagring.&mappe_png";
proc sgplot data=&figtittel noborder noautolegend sganno=anno pad=(Bottom=5%);
where BoDPS_ny le 14;

     hbarparm category=boDPS_ny response=rate_tot / fillattrs=(color=CX568BBF) missing name="rate 2" legendlabel="&label2" outlineattrs=(color=grey);  
     hbarparm category=boDPS_ny response=rate_del1/ fillattrs=(color=CX95BDE6) missing name="rate 1" legendlabel="&label1" outlineattrs=(color=grey);  

     scatter x=&data1._rate_2017 y=BoDPS_ny / markerattrs=(symbol=circle       color=black size=9pt) name="y3" legendlabel="2017"; 
	 scatter x=&data1._rate_2016 y=BoDPS_ny / markerattrs=(symbol=circlefilled color=grey  size=7pt) name="y2" legendlabel="2016"; 
	 scatter x=&data1._rate_2015 y=boDPS_ny / markerattrs=(symbol=circlefilled color=black size=5pt) name="y1" legendlabel="2015";

     Highlow Y=BoDPS_ny low=Min high=Max / type=line name="hl2" lineattrs=(color=black thickness=1 pattern=1); 
     keylegend "y1" "y2" "y3" / across=3 position=bottom location=outside noborder valueattrs=(size=7pt);
     keylegend "rate 1" "rate 2" "rate 3"/ across=1 noborder position=bottomright location=inside;

 	     *yaxis min=24 display=(noticks noline) label='Opptaksområde' labelattrs=(size=8 weight=bold) type=discrete discreteorder=data valueattrs=(size=8);
	 yaxis display=(noticks noline) label='Bosatte i opptaksområdene' labelpos=top labelattrs=(size=8 weight=bold) type=discrete discreteorder=data valueattrs=(size=9);
     xaxis  offsetmin=0 offsetmax=0.02  valueattrs=(size=8) label="&xlabel" labelattrs=(size=8 weight=bold);
     *Yaxistable &hoyretabell /Label location=inside labelpos=top position=right valueattrs=(size=9 family=arial) labelattrs=(size=9);
	 label &labeltabell;

format &formattabell;

run;Title; ods listing close;

%let mappe_pdf=&mappe.\pdf\justrate;
ODS Graphics ON /reset=All imagename="&figtittel" imagefmt=pdf border=off ;
ODS Listing Image_dpi=300 GPATH="&bildelagring.&mappe_pdf";
proc sgplot data=&figtittel noborder noautolegend sganno=anno pad=(Bottom=5%);
where BoDPS_ny le 14;

     hbarparm category=boDPS_ny response=rate_tot / fillattrs=(color=CX568BBF) missing name="rate 2" legendlabel="&label2" outlineattrs=(color=grey);  
     hbarparm category=boDPS_ny response=rate_del1/ fillattrs=(color=CX95BDE6) missing name="rate 1" legendlabel="&label1" outlineattrs=(color=grey);  

     scatter x=&data1._rate_2017 y=BoDPS_ny / markerattrs=(symbol=circle       color=black size=9pt) name="y3" legendlabel="2017"; 
	 scatter x=&data1._rate_2016 y=BoDPS_ny / markerattrs=(symbol=circlefilled color=grey  size=7pt) name="y2" legendlabel="2016"; 
	 scatter x=&data1._rate_2015 y=boDPS_ny / markerattrs=(symbol=circlefilled color=black size=5pt) name="y1" legendlabel="2015";

     Highlow Y=BoDPS_ny low=Min high=Max / type=line name="hl2" lineattrs=(color=black thickness=1 pattern=1); 
     keylegend "y1" "y2" "y3" / across=3 position=bottom location=outside noborder valueattrs=(size=7pt);
     keylegend "rate 1" "rate 2" "rate 3"/ across=1 noborder position=bottomright location=inside;

 	     *yaxis min=24 display=(noticks noline) label='Opptaksområde' labelattrs=(size=8 weight=bold) type=discrete discreteorder=data valueattrs=(size=8);
	 yaxis display=(noticks noline) label='Bosatte i opptaksområdene' labelpos=top labelattrs=(size=8 weight=bold) type=discrete discreteorder=data valueattrs=(size=9);
     xaxis  offsetmin=0 offsetmax=0.02  valueattrs=(size=8) label="&xlabel" labelattrs=(size=8 weight=bold);
     *Yaxistable &hoyretabell /Label location=inside labelpos=top position=right valueattrs=(size=9 family=arial) labelattrs=(size=9);
	 label &labeltabell;

format &formattabell;

run;Title; ods listing close;
%mend;