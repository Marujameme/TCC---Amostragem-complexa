%include "C:\disciplinas\Tecnicas_amostragem2\CNEFE\macros_undersized_oversized.sas";
PROC IMPORT DATAFILE="C:\disciplinas\Tecnicas_amostragem2\CNEFE\Agregados_por_setores_basico_BR.xlsx"
OUT=agregados_setores_BR
DBMS=XLSX
REPLACE;
GETNAMES=YES;
RUN;
   /* Caminho do Prof. Alan */

%let UF=AC;
%let COD=12;

%let MUN=1200013;
%let SETOR=120001305000001;

%include "/export/viya/homes/202023583@aluno.unb.br/TCC2/macros_undersized_oversized.sas";

/* Para leitura */ 
libname tcc2 "/export/viya/homes/202023583@aluno.unb.br/TCC2";

data agregados_setores_BR;
    set tcc2.agregados_setores_BR;
run; /* Caminho do André */

data agregados_setores_BR;set agregados_setores_BR;
if v0001>0;
run;

%macro UF(UF=,COD=,mb=,lb=,MUN=9999999,SETOR=999999999999999,where=);
/*
proc mapimport datafile="C:\disciplinas\Tecnicas_amostragem2\CNEFE\&UF._setores_CD2022.shp" 
out=SC_&UF;
run;
/* Caminho do Prof. Alan */
proc mapimport datafile="/export/viya/homes/202023583@aluno.unb.br/TCC2/Shapefiles/&UF._setores_CD2022.shp" 
out=SC_&UF;
run; /* Caminho do André */
/*
proc mapimport datafile="C:\disciplinas\Tecnicas_amostragem2\CNEFE\&UF._Municipios_2023.shp" 
out=mun_&cod;
run;  /* Caminho do prof. Alan*/
proc mapimport datafile="/export/viya/homes/202023583@aluno.unb.br/TCC2/Shapefiles/&UF._Municipios_2023.shp" 
out=mun_&cod;
run; /* Caminho do André */




/*** Computing Proportion ***/
proc freq data=agregados_setores_BR noprint;
tables CD_MUN /out=pop_mun(rename=count=pop_mun);
weight v0001;
where CD_UF=&cod;
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

DATA agregados_setores_&cod;SET agregados_setores_BR(WHERE=(CD_UF=&cod) 
rename=CD_SETOR=CD_SETORn);
CD_SETOR=trim(left(put(CD_SETORn, BEST15.)));
RUN;

proc means data=agregados_setores_&cod sum;
var v0001;
run;

proc means data=agregados_setores_&cod sum;
var v0002;
run;

proc freq data=Agregados_setores_&cod;
tables NM_MUN;
run;

/**** sample ***/
proc means data=agregados_setores_&cod noprint nway;
var v0002;
output out=tamanho_amostra(drop=_type_ rename=_freq_=tot_dom) mean=Lb;
run;

data tamanho_amostra;set tamanho_amostra;
z=1.96;
erro=0.020;
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
proc print data=tamanho_amostra noobs;
var a m_b l_b;
run;

/*** Total ***/
proc means data=Agregados_setores_&cod noprint nway;
var v0002 v0001;
output out=freq_sc_dom(drop=_type_ rename=_freq_=tot_sc)
sum(v0002)=tot_dom sum(v0001)=tot_pop;
run;

data tamanho_amostra;merge tamanho_amostra freq_sc_dom;run;

/*-----   Como a fórmula necessita do tamanho 
          da amostra selecionada não posso checar under 
          nessa etapa
-----   */
/*
proc freq data=Agregados_setores_&cod noprint;
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
*/
data a;
cd_mun="&mun";
num_set=2;
run;
proc gmap data=a map=mun_&cod all;
id cd_mun;
choro num_set /nolegend;
run;
quit;

proc freq data=Agregados_setores_&cod noprint;
tables CD_MUN*NM_MUN /out=freq_mun_sc(rename=(count=tot_sc) drop=percent);
run;
data freq_mun_sc;if _n_=1 then set Tamanho_amostra(keep=a m_b l_b);
merge freq_mun_sc Pop_mun(keep=CD_MUN pop_mun);by CD_MUN;
run;
proc sort data=Freq_mun_sc;by CD_MUN;run;
data Freq_mun_sc2;merge Freq_mun_sc(in=a) Freq_mun_sc(keep=CD_MUN 
NM_MUN rename=CD_MUN=CD_MUN);by CD_MUN;if a;
run;
data Freq_mun_sc2;if _n_=1 then set tamanho_amostra;set Freq_mun_sc2;run;

proc sql noprint;select sum(v0001) into:M0 from Agregados_setores_&cod;quit;
%put &M0;

proc sql;select a into:a from tamanho_amostra;quit;
%put "a=" &a;
%oversized(data=Freq_mun_sc2,size=&a,tot_size=pop_mun,oversized=strata,M0=&M0);
proc freq data=Freq_mun_sc2;
tables strata;
run;

proc freq data=Freq_mun_sc2 noprint;
tables strata*_ah_ /out=tamanho_amostrah(drop=count percent);
run;
proc sort data=Freq_mun_sc2;by strata CD_MUN;run;
proc surveyselect data=Freq_mun_sc2 sampsize=tamanho_amostrah(rename=_ah_=_nsize_)
seed=3 out=amostra_mun method=pps;
size pop_mun;
strata strata;
run;

title "Sum of Weights 1st stage";
proc means data=Amostra_mun sum ndec=2;
var pop_mun;
weight SamplingWeight;
run;
%put &M0;

/*** Segundo Estagio ***/

proc sql;
create table agregados_setores_&cod._2 as
select b.*, a.SamplingWeight as SamplingWeight1, a.m_b, 
a.tot_pop, a.l_b from amostra_mun a
left join agregados_setores_&cod b
on a.CD_MUN = b.CD_MUN;
quit;

title ' Sum of Weights 1st stage';
proc means data=agregados_setores_&cod._2 sum ndec=2;
var v0001;
weight SamplingWeight1;
run;

/**tabela com total de setores censitários**/
proc freq data=agregados_setores_&cod noprint;
tables CD_MUN*NM_MUN /out=freq_nm_mun_sc(rename=(count=tot_sc) drop=percent);
run;
/** Verificando se o mb bate com a média dos m amostrados**/
proc sort data=amostra_mun;by CD_MUN;run;
proc sort data=freq_nm_mun_sc;by CD_MUN;run;
proc sql noprint;
select sum(tot_sc) into: tot_mia from freq_nm_mun_sc /** total de setores censitários do municipio "a" **/
where CD_MUN in (select CD_MUN from amostra_mun);
quit;
%put &tot_mia; /** total de setores censitários nos "a" municipios selecionados **/
data amostra_mun;merge amostra_mun(in=a) freq_nm_mun_sc;
by CD_MUN;if a; 
mi=round(a*m_b*tot_sc/&tot_mia); /** fórmula do mi**/
if tot_sc<mi then undersized=1;else undersized=0;
run; 

proc means data=amostra_mun mean;
var mi; /** tem que bater o mb essa média **/
run;

data a;
CD_SETOR="&setor";
num_set=2;
run;
proc gmap data=a map=SC_&UF all;
id CD_SETOR;
choro num_set;
run;
quit;
proc gmap data=a map=SC_&UF(where=(CD_MUN="&mun")) all;
id CD_SETOR;
choro num_set;
run;
quit;

proc freq data = Agregados_setores_&cod._2 noprint;
tables SITUACAO / out=Prop_mun_situacao(rename=(count = freq_setor_situacao percent=pct_situacao));
by CD_MUN;
run;

proc freq data = Agregados_setores_&cod._2 noprint;
tables CD_MUN * SITUACAO / out=Pop_mun_situacao(drop=percent rename=count=pop_mun_situacao);
weight v0001;
run;

proc sort data=amostra_mun;by CD_MUN;run;
proc sort data=Agregados_setores_&cod._2;by CD_MUN;run;
data Agregados_setores_&cod._2;
merge Agregados_setores_&cod._2 amostra_mun(keep= CD_MUN mi l_b);
by CD_MUN;
run;

proc sort data=Agregados_setores_&cod._2;
by CD_MUN SITUACAO;
run;
 
data Agregados_setores_&cod._2;
merge Agregados_setores_&cod._2 Pop_mun_situacao Prop_mun_situacao;
by CD_MUN SITUACAO;
&where;
*if 40.90<=pct_situacao<=40.91 then pct_situacao=40.8;
m_ih = round((mi*pct_situacao)/100);
if m_ih<1 then m_ih=1; 
run;
proc freq data=Agregados_setores_&cod._2 noprint;
tables CD_MUN*SITUACAO*pct_situacao*mi*m_ih /out=count_m_bh(drop=count percent);
run;
proc print data=count_m_bh noobs;run;

title 'Sum of Weights 1st stage';
proc means data=Agregados_setores_&cod._2 sum;var v0001;weight SamplingWeight1;run;

title ' ';
%oversized(data=Agregados_setores_&cod._2,size=m_ih,tot_size=v0001,
oversized=strata,strata=CD_MUN SITUACAO,M0=pop_mun_situacao);
proc freq data=Agregados_setores_&cod._2;
tables CD_MUN*strata;
run;

proc freq data=Agregados_setores_&cod._2;
tables CD_MUN * SITUACAO;
run;

proc freq data=Agregados_setores_&cod._2 noprint;
tables CD_MUN*SITUACAO*strata*_ah_ /out=tamanho_amostrah(drop=percent);
run;
proc sort data=Agregados_setores_&cod._2;by CD_MUN SITUACAO strata;run;
proc surveyselect data=Agregados_setores_&cod._2 sampsize=tamanho_amostrah(rename=_ah_=_nsize_)
seed=3 out=amostra_mun_sc_sys method=pps;
size v0001;
strata CD_MUN SITUACAO strata;
run;
data amostra_mun_sc_sys;set amostra_mun_sc_sys(rename=SamplingWeight=SamplingWeight2);
peso_mun_sc = SamplingWeight1 * SamplingWeight2;
run;

title "Sum of Weights 2nd stage";
proc means data=amostra_mun_sc_sys sum ndec=2;
var v0001;
weight peso_mun_sc;
run;
%put &M0;

/* talvez aqui */

proc sort data=amostra_mun_sc_sys;by CD_MUN CD_SETOR;run;
proc sort data=Agregados_setores_&cod._2;by CD_MUN CD_SETOR;run;
proc means data=amostra_mun_sc_sys noprint nway;
class CD_MUN SITUACAO;
var v0002;
output out=soma_pia (drop=_type_ _freq_) sum=tot_pia;
run;

proc sort data=amostra_mun_sc_sys;by CD_MUN SITUACAO;run;
proc sort data=soma_pia;by CD_MUN SITUACAO;run;
data amostra_mun_sc_sys; merge amostra_mun_sc_sys soma_pia;
by CD_MUN SITUACAO;
l_ihj=round(m_ih*l_b*v0002/tot_pia);
if l_ihj<1 then l_ihj=1;
v0001_dom=v0001/v0002;
peso3=v0001/(l_ihj*v0001_dom);
peso3d=v0002/l_ihj;
CD_SETOR=trim(left(CD_SETOR));
run;

proc means data=amostra_mun_sc_sys mean;
var l_ihj;
run;

data amostra_mun_sc_sys; set amostra_mun_sc_sys;
if v0002<l_ihj then undersized=1;else undersized=0;
run;
proc freq data=amostra_mun_sc_sys;tables undersized;run;



/*** simulando CNEFE 3 estagio *****/

data cnefe_&UF._mun_sc;set amostra_mun_sc_sys;
do i=1 to v0002;
output;
end;
run;
proc sort data=cnefe_&UF._mun_sc;by CD_MUN SITUACAO strata CD_SETOR;run;
proc sort data=amostra_mun_sc_sys;by CD_MUN SITUACAO strata CD_SETOR;run;
proc surveyselect data=cnefe_&UF._mun_sc
sampsize=amostra_mun_sc_sys(rename=l_ihj=_nsize_)
seed=3 out=amostra_mun_sys_sc_dom;
strata CD_MUN SITUACAO strata CD_SETOR;
run;

data amostra_mun_sys_sc_dom;set amostra_mun_sys_sc_dom;
peso_final=peso_mun_sc*SamplingWeight;
v0001_dom=V0001/v0002;
run;

title "Sum of Weights 3rd stage";
proc means data=amostra_mun_sys_sc_dom sum ndec=2;
var v0001_dom;
weight peso_final;
run;
%put &M0;

title 'Municípios Selecionados na Amostra';
proc gmap data=amostra_mun map=mun_&cod all;
id cd_mun;
choro cd_mun;
run;
quit;
%mend UF;

/* ACRE */
%UF(UF=AC,COD=12,MUN=1200013,SETOR=120001305000001);

/* ALAGOAS */
%UF(UF=AL,COD=27,MUN=2706802,SETOR=270680200000001,where=);
 
/* RIO DE JANEIRO */
%UF(UF=RJ,COD=33,MUN=3300456,SETOR=330045600000001);
 
/* PARAN� */
%UF(UF=PR,COD=41,MUN=4101507,SETOR=410150700000001);

%let UF=AC;
%let COD=12;

%let MUN=1200013;
%let SETOR=120001305000001;


