*************************************************************************************************
*** Summary Statistics on Home Ownership and Credit Constraints from EVS, used in Appendix A5 ***
*************************************************************************************************

/*
Data is from the German Income and Consumption Panel (Einkommens- und Verbrauchsstichprobe) 2018 
Data access can be applied for at the German Statistical Office https://www.forschungsdatenzentrum.de/
*/

clear all

*** Generate variables ***
gen has_apt = (EF584>0 | EF585>0)
gen has_house = (EF582>0 | EF583>0)
gen has_shouse = (EF582>0)

gen has_rapt = has_apt 
replace has_rapt = 0 if EF50==2 & EF585==1 & EF19==4   
gen has_rhouse = has_shouse
replace has_rhouse = 0 if EF50==2 & (EF582+EF583==1) & (EF19==1 | EF19==2 | EF19==3)
 
gen has_mort = (EF477>0 | EF478>0)
gen morinc_tot = (EF477 + EF478)/ EF62 

*** Summary Statistics for Table A.4 ***

* Share owned for investment purposes
sum has_rhouse [aw=EF107] if has_house==1
sum has_rapt [aw=EF107] if has_apt==1

* Share of properties with a mortgage
sum has_mort [aw=EF107] if has_house==1
sum has_mort [aw=EF107] if has_apt==1

* Average mortgage payments relative to net household income
sum morinc_tot [aw=EF107] if has_house==1
sum morinc_tot [aw=EF107] if has_apt==1


