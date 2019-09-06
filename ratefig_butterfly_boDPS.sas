/* This macro makes a butterfly plot
Must run ratefig_boDPS macro first to get the rates of the 2 parts (for plotting) + total (for sorting) 
fil1  to the left of the origin
data1 the rate we want to plot (for example, poli for kontact dount, poli_unik_aar for patient count, tot, tot_unik_aar, etc)
fil2  to the right of the origin
data2 the rate we want to plot (for example, poli for kontact dount, poli_unik_aar for patient count, tot, tot_unik_aar, etc)
fil3  the total that we want to sort the figure by
data3 the rate we want to sort (for example, poli for kontact dount, poli_unik_aar for patient count, tot, tot_unik_aar, etc)
*/
%macro ratefig_butterfly_boDPS(fil1=, data1=, fil2=, data2=, fil3=, data3=, figtittel=);

proc sort data=&fil1; by bodps_ny; run;
proc sort data=&fil2; by bodps_ny; run;
proc sort data=&fil3; by bodps_ny; run;

data butterfly;
  merge &fil1  (rename=(&data1._rate=left_rate)  keep=boDPS_ny &data1._rate)
        &fil2  (rename=(&data2._rate=right_rate) keep=boDPS_ny &data2._rate)
        &fil3  (rename=(&data3._rate=tot_rate)   keep=boDPS_ny &data3._rate); 
  by boDPS_ny;
  left_rate=left_rate*(-1);
run;

proc sort data=butterfly;
  by descending tot_rate;
run;

proc format;
  picture positive low-<0='0000' 0<-high='0000';


%macro plot_butterfly(fmt=);

%let mappe_&fmt=&mappe.\&fmt\justrate;
ODS Graphics ON /reset=All imagename="&figtittel" imagefmt=&fmt border=off ;
ODS Listing Image_dpi=300 GPATH="&bildelagring.&mappe_&fmt";

proc sgplot data=butterfly noborder noautolegend sganno=anno pad=(Bottom=5%);
  where BoDPS_ny le 14;
  format left_rate right_rate positive.;

  hbarparm category=boDPS_ny response=left_rate  / fillattrs=graphdata1(color=CX568BBF) name="left"  legendlabel="&label1" missing outlineattrs=(color=grey);  
  hbarparm category=boDPS_ny response=right_rate / fillattrs=graphdata2(color=CX95BDE6) name="right" legendlabel="&label2" missing outlineattrs=(color=grey);
 
  keylegend "left" "right"; 
  xaxis values=(-100 to 500 by 50) grid offsetmin=0.02 offsetmax=0.02  valueattrs=(size=8) label="&xlabel" labelattrs=(size=8 weight=bold);
  yaxis display=(noticks noline) label='Bosatte i opptaksområdene' labelpos=top labelattrs=(size=8 weight=bold) type=discrete discreteorder=data valueattrs=(size=9);
run;

ods listing close;
%mend;

%plot_butterfly(fmt=png);
%plot_butterfly(fmt=pdf);

%mend;

