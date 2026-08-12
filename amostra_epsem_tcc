%include "/export/viya/homes/202023583@aluno.unb.br/TCC2/macros_undersized_oversized.sas";

/* Para leitura */
libname tcc2 "/export/viya/homes/202023583@aluno.unb.br/TCC2";

data agregados_setores_BR;
    set tcc2.agregados_setores_BR;
run;


/*** Computing Proportion ***/
proc freq data=agregados_setores_BR noprint;
tables CD_MUN /out=pop_mun(rename=count=pop_mun);
weight v0001;
where CD_UF=12;
run;
data pop_mun;set pop_mun;
if pop_mun<50000 then small=1; else small=0;
run;
proc freq data=pop_mun;
tables small /out=pct_small;
run;
proc sql noprint;
select PERCENT/100 into:pct_small from pct_small;
quit;
%put &pct_small;

DATA agregados_setores_12;SET agregados_setores_BR(WHERE=(CD_UF=12) 
rename=CD_SETOR=CD_SETORn);
CD_SETOR=trim(left(put(CD_SETORn, BEST15.)));
RUN;

/**** sample ***/
proc means data=agregados_setores_12 noprint nway;
var v0002;
output out=tamanho_amostra(drop=_type_ rename=_freq_=tot_dom) mean=Lb;
run;

data tamanho_amostra;set tamanho_amostra;
z=1.96;
erro=0.025;
deff=2.5;
CV=sqrt(&pct_small*(1-&pct_small));
c=140000;
c1=600;
c2=12;
c3=10;
c0=0.3*c;
rho=(deff-1)/(Lb-1);
l_b=round(sqrt((c2/c3)*((1-rho)/rho)));
m_b=round((z**2*CV**2*(rho+((1-rho)/l_b)))/erro**2);
a=round((c-c0)/(c1+c2*m_b+c3*m_b*l_b));
amostra_final=a*m_b*l_b;
C_final=c0+c1*a+c2*a*m_b+c3*a*m_b*l_b;
run;

/*** Total ***/
proc means data=Agregados_setores_12 noprint nway;
var v0002 v0001;
output out=freq_sc_dom(drop=_type_ rename=_freq_=tot_sc)
sum(v0002)=tot_dom sum(v0001)=tot_pop;
run;

data tamanho_amostra;merge tamanho_amostra freq_sc_dom;run;

proc freq data=Agregados_setores_12 noprint;
tables CD_MUN*NM_MUN /out=freq_mun_sc(rename=(count=tot_sc) drop=percent);
run;
data freq_mun_sc;if _n_=1 then set Tamanho_amostra(keep=a m_b l_b);
merge freq_mun_sc Pop_mun(keep=CD_MUN pop_mun);by CD_MUN;
if tot_sc<m_b then undersized=1;else undersized=0;
run;
proc sort data=freq_mun_sc;by NM_MUN;run;
proc print data=freq_mun_sc noobs;
var CD_MUN NM_MUN pop_mun tot_sc;
sum pop_mun tot_sc;
run;

proc mapimport datafile='/export/viya/homes/202023583@aluno.unb.br/TCC2/Shapefiles/AC_Municipios_2023.shp' 
out=mun_12;
run;
data a;
cd_mun='999999';
num_set=2;
run;
proc gmap data=a map=mun_12 all;
id cd_mun;
choro num_set /nolegend;
run;
quit;

%annomac;
proc sort data=mun_12 out=c_mun_12;by cd_mun;run;
%centroid(c_mun_12,centroide_12,cd_mun);
proc iml;
use centroide_12;
read all var{x y} into COORD;
read all var{cd_mun};
d = distance(COORD, "L2");
d=d*111;
create dist from d;
append from d;
quit;

data dist;set dist;idi=_n_;run;
proc transpose data=dist out=dist;
by idi;var col:;
run;
quit;
data dist;retain idi idj d;set dist(rename=col1=d);
idj=input(substr(_NAME_,4),5.);
drop _name_;
if d=0 then delete;
run;
data centroide_12_1;set centroide_12(keep=cd_mun);idi=_n_;run;
proc sql;
create table dist as
select a.*,b.cd_mun from dist a left join centroide_12_1 b
on a.idi=b.idi;
create table dist as
select a.*,b.cd_mun as cd_mun1 from dist a left join centroide_12_1 b
on a.idj=b.idi
order by idi,d;
quit;

%let confile=vizinhos;
%let idvar=cd_mun;
proc sort data=mun_12 out=mymap2 nodupkey; by x y &idvar.;run;
data hashmap (keep=x y z &idvar.);
retain z;
set mymap2(where=(x NE . and y NE .));
by x y;
if first.x or first.y then z=1;
z=z+1;
run;
proc means data=hashmap noprint;
output out=maxz max(z)=mz; run;
/*put the maximum value of z into macro variable maxnb*/
data _null_;
set maxz;
call symputx("maxnb",mz);
run;
%put &maxnb;
proc sort data=mymap2; by &idvar.;run;
data nonb (keep=myid);
length x y z 8; format &idvar. $16.; /*use a format statement for character id
values*/
if _n_=1 then do;
/*this hash object holds a second copy of the entire map for comparison*/
declare hash fc(dataset: "hashmap");
fc.definekey("x","y","z");
fc.definedata("x","y","z","&idvar.");
fc.definedone();
call missing (x,y,z,&idvar.);
/*this hash object will hold the rook neighbors for each area: they have two
points in common*/
declare hash rook();
rook.definekey("&idvar.","myid");
rook.definedata("&idvar.","myid");
rook.definedone();
/*this hash object holds the queen neighbors for each area: they have a point
in common*/
declare hash queen();
queen.definekey("&idvar.","myid");
queen.definedata("&idvar.","myid");
queen.definedone();
end;
foundnb="N";
do until (last.myid);
set mymap2 (keep=&idvar. x y rename=(&idvar.=myid x=myx y=myy) where=(myx NE .
and myy NE .)) end=eof;
by myid;
do n=1 to &maxnb.; /*this is max number of points in common =max z*/
rc=fc.find(key:myx, key:myy, key:n);
if rc=0 and myid NE &idvar. then do;
nbrc=queen.check(key:&idvar, key:myid);
if nbrc=0 then do;
rc2=rook.add(key:&idvar, key:myid, data:&idvar, data:myid);
foundnb="Y";
end;
else rc1=queen.add(key:&idvar, key:myid, data:&idvar, data:myid);
end;
end;*do &maxnb.;
end;*end DOW loop;
if foundnb="N" then output nonb;
*if eof then rook.output(dataset:"&confile");
if eof then queen.output(dataset:"&confile");
run;
proc sort data=&confile.;by &idvar;run;
data dist;set &confile.;rename myid=&idvar.1;run;

proc sql;
create table dist as
select a.*,b.tot_sc
from dist a left join Freq_mun_sc b
on a.CD_MUN1=b.CD_MUN
order by CD_MUN,tot_sc;
quit;

%undersized(data=Freq_mun_sc,ID=CD_MUN,size=51,tot_size=tot_sc,
undersized=undersized,pop=pop_mun,neighbor=dist,shape=mun_12);

proc sort data=Freq_mun_sc;by CD_MUN;run;
data Freq_mun_sc2;merge Freq_mun_sc2(in=a) Freq_mun_sc(keep=CD_MUN 
NM_MUN rename=CD_MUN=CD_MUN2);by CD_MUN2;if a;
run;
data Freq_mun_sc2;if _n_=1 then set tamanho_amostra;set Freq_mun_sc2;run;

proc sql noprint;select sum(v0001) into:M0 from Agregados_setores_12;quit;
%put &M0;

%oversized(data=Freq_mun_sc2,ID=CD_MUN,size=14,tot_size=pop_mun,
oversized=strata,M0=&M0);

proc freq data=Freq_mun_sc2 noprint;
tables strata*_ah_ /out=tamanho_amostrah(drop=count percent);
run;
proc sort data=Freq_mun_sc2;by strata CD_MUN2;run;
proc surveyselect data=Freq_mun_sc2 sampsize=tamanho_amostrah(rename=_ah_=_nsize_)
seed=3 out=amostra_mun method=pps;
size pop_mun;
strata strata;
run;

proc means data=Amostra_mun sum ndec=2;
var pop_mun;
weight SamplingWeight;
run;
%put &M0;

/*** Segundo Estágio ***/

%macro jts;
data agregados_setores_12_2;set agregados_setores_12;run;
data _xj_;set _xj_;
call symput("group"||trim(left(_n_)),var);
call symput("cod"||trim(left(_n_)),value);
run;
%put &cod1 &group1;
proc sql noprint;select count(*) into:cnt_cod from _xj_;quit;
data agregados_setores_12_2;set agregados_setores_12_2;
%do i=1 %to &cnt_cod;
if cd_mun in (&&group&i) then cd_mun2="&&cod&i";
%end;
if cd_mun2='' then cd_mun2=cd_mun;
run;
%mend jts;
%jts;

proc sql;
create table agregados_setores_12_2 as
select b.*, a.SamplingWeight as SamplingWeight1, a.m_b, 
a.tot_pop, a.l_b from amostra_mun a
left join agregados_setores_12_2 b
on a.CD_MUN2 = b.CD_MUN2;
quit;

proc means data=agregados_setores_12_2 sum ndec=2;
var v0001;
weight SamplingWeight1;
run;

data agregados_setores_12_2; set agregados_setores_12_2;
if v0002<l_b then undersized=1;else undersized=0;
run;
proc freq data=agregados_setores_12_2;tables undersized;run;

proc mapimport datafile='/export/viya/homes/202023583@aluno.unb.br/TCC2/Shapefiles/AC_setores_CD2022.shp' 
out=SC_AC;
run;
data a;
CD_SETOR="120001305000001";
num_set=2;
run;
proc gmap data=a map=SC_AC all;
id CD_SETOR;
choro num_set;
run;
quit;
proc gmap data=a map=SC_AC(where=(CD_MUN="1200013")) all;
id CD_SETOR;
choro num_set;
run;
quit;

%annomac;
proc sort data=SC_AC out=c_SC_AC;by CD_SETOR;run;
%centroid(c_SC_AC,centroide_AC_SC,CD_SETOR);
proc iml;
use centroide_AC_SC;
read all var{x y} into COORD;
read all var{CD_SETOR};
d = distance(COORD, "L2");
d=d*111;
create dist_SC_km from d;
append from d;
quit;

data dist_SC_km;set dist_SC_km;idi=_n_;run;
proc transpose data=dist_SC_km out=dist_SC_km;
by idi;var col:;
run;
quit;
data dist_SC_km;retain idi idj d;set dist_SC_km(rename=col1=d);
idj=input(substr(_NAME_,4),5.);
drop _name_;
if d=0 then delete;
run;
data centroide_AC_SC1;set centroide_AC_SC(keep=CD_SETOR);idi=_n_;run;
proc sql;
create table dist_SC_km as
select a.*,b.CD_SETOR from dist_SC_km a left join centroide_AC_SC1 b
on a.idi=b.idi;
create table dist_SC_km as
select a.*,b.CD_SETOR as CD_SETOR1 from dist_SC_km a left join centroide_AC_SC1 b
on a.idj=b.idi
order by idi,d;
quit;
data dist_SC_km;set dist_SC_km;by CD_SETOR;
if first.CD_SETOR then seq=1;else seq+1;
run;
data dist_SC_km;set dist_SC_km(where=(seq<=10));run;

%let confile=vizinhos_SC;
%let idvar=CD_SETOR;
proc sort data=SC_AC out=mymap2 nodupkey; by x y &idvar.;run;
data hashmap (keep=x y z &idvar.);
retain z;
set mymap2(where=(x NE . and y NE .));
by x y;
if first.x or first.y then z=1;
z=z+1;
run;
proc means data=hashmap noprint;
output out=maxz max(z)=mz; run;
/*put the maximum value of z into macro variable maxnb*/
data _null_;
set maxz;
call symputx("maxnb",mz);
run;
%put &maxnb;
proc sort data=mymap2; by &idvar.;run;
data nonb (keep=myid);
length x y z 8; format &idvar. $16.; /*use a format statement for character id
values*/
if _n_=1 then do;
/*this hash object holds a second copy of the entire map for comparison*/
declare hash fc(dataset: "hashmap");
fc.definekey("x","y","z");
fc.definedata("x","y","z","&idvar.");
fc.definedone();
call missing (x,y,z,&idvar.);
/*this hash object will hold the rook neighbors for each area: they have two
points in common*/
declare hash rook();
rook.definekey("&idvar.","myid");
rook.definedata("&idvar.","myid");
rook.definedone();
/*this hash object holds the queen neighbors for each area: they have a point
in common*/
declare hash queen();
queen.definekey("&idvar.","myid");
queen.definedata("&idvar.","myid");
queen.definedone();
end;
foundnb="N";
do until (last.myid);
set mymap2 (keep=&idvar. x y rename=(&idvar.=myid x=myx y=myy) where=(myx NE .
and myy NE .)) end=eof;
by myid;
do n=1 to &maxnb.; /*this is max number of points in common =max z*/
rc=fc.find(key:myx, key:myy, key:n);
if rc=0 and myid NE &idvar. then do;
nbrc=queen.check(key:&idvar, key:myid);
if nbrc=0 then do;
rc2=rook.add(key:&idvar, key:myid, data:&idvar, data:myid);
foundnb="Y";
end;
else rc1=queen.add(key:&idvar, key:myid, data:&idvar, data:myid);
end;
end;*do &maxnb.;
end;*end DOW loop;
if foundnb="N" then output nonb;
*if eof then rook.output(dataset:"&confile");
if eof then queen.output(dataset:"&confile");
run;
proc sort data=&confile.;by &idvar;run;
data dist_SC;set &confile.(rename=myid=&idvar.1);
cd_mun2=substr(&idvar,1,7);
if substr(&idvar,1,7) ne substr(&idvar.1,1,7) then delete;
run;


/*proc contents data=Freq_mun_scjt out=name_cd_mun noprint;run;
proc sql noprint;
select NAME into:cd_mun_var from name_cd_mun
where NAME not in ("CD_MUN" "COL1");
quit;
%put &cd_mun_var;

data Freq_mun_sc2;set Freq_mun_sc2;
call symput('cdmunj'||trim(left(_n_)),CD_MUN2);
run;
%put &cdmunj1;
proc sql noprint;select count(*) into:nmunj from Freq_mun_sc2;quit;%put &nmunj;
%macro join_dist;
proc sql;drop table dist_SC;quit;
%do i=1 %to &nmunj;
proc sql;
create table Dist_sc_1 as
select * from dist_SC_
where cd_mun2="&&cdmunj&i" and substr(&idvar.1,1,7) in 
(select COL1 from Freq_mun_scjt where &cd_mun_var="&&cdmunj&i");
quit;
proc append base=dist_SC data=Dist_sc_1 force;run;
%end;
%mend join_dist;
%join_dist;*/

proc sql;
create table dist_SC as
select * from dist_SC
where CD_SETOR in (select CD_SETOR from Agregados_setores_12_2);
create table dist_SC as
select a.*,b.v0001,b.v0002
from dist_SC a left join Agregados_setores_12_2 b
on a.CD_SETOR1=b.CD_SETOR
order by CD_SETOR,v0002;
quit;
data dist_SC;set dist_SC;if v0002 ne .;run;

proc sql;
create table SC_not_cont as
select CD_SETOR from Agregados_setores_12_2
where CD_SETOR not in (select CD_SETOR from dist_SC);
create table dist_SC2 as
select CD_SETOR,CD_SETOR1 from Dist_sc_km
where CD_SETOR in (select CD_SETOR from SC_not_cont);
create table dist_SC2 as
select a.*,b.v0001,b.v0002
from dist_SC2 a left join Agregados_setores_12_2 b
on a.CD_SETOR1=b.CD_SETOR
order by CD_SETOR,v0002;
quit;
data dist_SC2;set dist_SC2;if v0002 ne .;run;
data dist_SC;set dist_SC dist_SC2;run;

%undersized(data=Agregados_setores_12_2,ID=CD_SETOR,size=11,tot_size=v0002,
undersized=undersized,pop=v0001,neighbor=dist_SC,shape=SC_AC);

proc sql;
create table Agregados_setores_12_22 as
select a.*,b.l_b,b.m_b,b.situacao,b.CD_MUN2,b.SamplingWeight1 from Agregados_setores_12_22 a 
left join Agregados_setores_12_2 b
on a.CD_SETOR2=b.CD_SETOR
order by CD_MUN2;
quit;
proc freq data = Agregados_setores_12_22 noprint;
tables SITUACAO / out=Prop_mun_situacao(rename=(count = freq_setor_situacao percent=pct_situacao));
by CD_MUN2;
run;

proc freq data = Agregados_setores_12_22 noprint;
tables CD_MUN2 * SITUACAO / out=Pop_mun_situacao(drop=percent rename=count=pop_mun_situacao);
weight v0001;
run;

proc sort data=Agregados_setores_12_22;
by CD_MUN2 SITUACAO;
run;

data Agregados_setores_12_22;
merge Agregados_setores_12_22 Pop_mun_situacao Prop_mun_situacao;
by CD_MUN2 SITUACAO;
m_b=13;
*if 40.90<=pct_situacao<=40.91 then pct_situacao=40.8;
m_bh = round((m_b*pct_situacao)/100);
if m_bh<1 then m_bh=1; 
run;

proc means data=Agregados_setores_12_2 sum;var v0001;weight SamplingWeight1;run;





data Agregados_setores_12_22;set Agregados_setores_12_22;
M0=pop_mun_situacao;
a=m_bh;
if v0001>M0/a then strata=1;else strata=2;
weight_PSU=M0/(m_bh*v0001);
run;


proc means data=Agregados_setores_12_22 noprint nway;
   var v0001;
   class CD_MUN2 strata;
   output out=_sum_pop_str_(drop=_type_ rename=(_freq_=_freq_str)) sum=_pop_str_;
run;

data _sum_pop_str1_;
   set _sum_pop_str_(where=(strata=1)
                     rename=(_freq_str=_freq_str1)
                     drop=_pop_str_);
run;

proc sort data=Agregados_setores_12_22;
   by CD_MUN2 strata;
run;

data Agregados_setores_12_22;
   merge Agregados_setores_12_22 _sum_pop_str1_;
   by CD_MUN2;
   if _freq_str1=. then _freq_str1=0;
run;

data Agregados_setores_12_22;
   merge Agregados_setores_12_22 _sum_pop_str_;
   by CD_MUN2 strata;

   if strata=1 then weight_PSU=1;
   if strata=2 then weight_PSU=_pop_str_/((m_bh-_freq_str1)*v0001);

   if v0001>(_pop_str_/(m_bh-_freq_str1)) then strata2=1;
   else strata2=2;

   if strata=1 then strata2=1;

   if strata2=1 then _ah_=_freq_str1;
   if strata2=2 then _ah_=m_bh-_freq_str1;
run;






















%oversized(data=Agregados_setores_12_22,ID=CD_SETOR2,size=m_bh,tot_size=v0001,
oversized=strata,strata=CD_MUN2 SITUACAO,M0=pop_mun_situacao);

proc freq data=Agregados_setores_12_22 noprint;
tables CD_MUN2*SITUACAO*strata*_ah_ /out=tamanho_amostrah(drop=count percent);
run;
proc sort data=Agregados_setores_12_22;by CD_MUN2 SITUACAO strata;run;
proc surveyselect data=Agregados_setores_12_22 sampsize=tamanho_amostrah(rename=_ah_=_nsize_)
seed=3 out=amostra_mun_sc_sys method=pps;
size v0001;
strata CD_MUN2 SITUACAO strata;
run;
data amostra_mun_sc_sys;set amostra_mun_sc_sys(rename=SamplingWeight=SamplingWeight2);
peso_mun_sc = SamplingWeight1 * SamplingWeight2;
run;

proc means data=amostra_mun_sc_sys sum ndec=2;
var v0001;
weight peso_mun_sc;
run;
%put &M0;

/*** simulando CNEFE 3 estagio *****/

data cnefe_ac_mun_sc;set amostra_mun_sc_sys;
do i=1 to v0002;
output;
end;
run;
proc sort data=cnefe_ac_mun_sc;by CD_MUN2 SITUACAO strata CD_SETOR2;run;
proc sort data=amostra_mun_sc_sys;by CD_MUN2 SITUACAO strata CD_SETOR2;run;
proc surveyselect data=cnefe_ac_mun_sc
sampsize=amostra_mun_sc_sys(rename=l_b=_nsize_)
seed=3 out=amostra_mun_sys_sc_dom;
strata CD_MUN2 SITUACAO strata CD_SETOR2;
run;

data amostra_mun_sys_sc_dom;set amostra_mun_sys_sc_dom;
peso_final=peso_mun_sc*SamplingWeight;
v0001_dom=V0001/v0002;
run;

proc means data=amostra_mun_sys_sc_dom sum ndec=2;
var v0001_dom;
weight peso_final;
run;
%put &M0;
