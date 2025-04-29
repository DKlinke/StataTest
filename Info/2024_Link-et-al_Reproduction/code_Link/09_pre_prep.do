********************************************************************************
* prepare Bundesbank data
********************************************************************************

* data since 2003
import delimited "${datapath}\effektivzinssatz_neugeschaeft_ab2003_BBK01.SUD939A.csv", varnames(1) encoding(UTF-8) rowrange(9) clear

replace bbk01sud939a = subinstr(bbk01sud939a,",",".",1)

destring bbk01sud939a , replace force

drop if bbk01sud939a == .

gen year = substr(v1,1,4)
gen month = substr(v1,6,7)
destring year, replace
destring month, replace

gen date_m = ym(year,month)
format date_m %tm

collapse bbk01sud939a , by(year)
rename bbk01sud939a effektivzins
save "${datapath}\effektivzinssatz_neugeschaeft.dta" , replace

* data since 1996
import delimited "${datapath}\festzinskredit_500kbis5mio_abnov19996_BBK01.SU0509.csv", varnames(1) encoding(UTF-8) rowrange(9) clear 

replace bbk01su0509 = subinstr(bbk01su0509,",",".",1)

destring bbk01su0509 , replace force

drop if bbk01su0509 == .

gen year = substr(v1,1,4)
gen month = substr(v1,6,7)
destring year, replace
destring month, replace

gen date_m = ym(year,month)
format date_m %tm

collapse bbk01su0509 , by(year)
rename bbk01su0509 festzinskredit
save "${datapath}\festzinskredit.dta" , replace

* data since 1948
import delimited "${datapath}\buba_diskontsatz_BBK01.SU0112.csv", varnames(1) encoding(UTF-8) rowrange(9) clear 

replace bbk01su0112 = subinstr(bbk01su0112,",",".",1)

destring bbk01su0112 , replace force

drop if bbk01su0112 == .

gen year = substr(v1,1,4)
gen month = substr(v1,6,7)
destring year, replace
destring month, replace

gen date_m = ym(year,month)
format date_m %tm

collapse bbk01su0112 , by(year)

rename bbk01su0112 diskontsatz
save "${datapath}\diskontsatz.dta" , replace

*** merge

use "${datapath}\effektivzinssatz_neugeschaeft.dta" , clear

merge 1:1 year using "${datapath}\festzinskredit.dta"
drop _merge
merge 1:1 year using "${datapath}\diskontsatz.dta"

sort year

gen diff03 = effektivzins - festzinskredit
egen max_diff03 = max(diff03)


gen zins = effektivzins
replace zins = festzinskredit + max_diff03 if year < 2003 & year > 1995

gen diff97 = zins - diskontsatz
egen mean_diff97 = mean(diff97)

replace zins = diskontsatz + mean_diff97 if year < 1996
label variable zins "Discount Factor"
keep zins year

export excel using "${datapath}\final_buba_zins.xlsx", firstrow(variables) replace

keep if year >= 1980

save "${datapath}\final_buba_zins.dta" , replace

********************************************************************************
* prepare local newspaper data
********************************************************************************

import delimited "${datapath}\gewerbe_erh.csv", encoding(UTF-8) clear


gen date_m = ym(year,month)
format date_m %tm

keep date_m count 

save "${datapath}\gewerbe_erh.dta", replace


import delimited "${datapath}\gewerbe_erh_broad.csv", encoding(UTF-8) clear

rename count count_broad

gen date_m = ym(year,month)
format date_m %tm

keep date_m count_broad 

merge 1:1 date_m using "${datapath}\gewerbe_erh.dta"

save "${datapath}\local_newspaper.dta", replace

********************************************************************************
* prepare wage data
********************************************************************************

import excel "${datapath}\Lange_Reihe_2_Quartal_2021.xlsx", sheet(" 1.1.2_D-Std-Vj-VÄ") cellrange(A7:BI160) firstrow clear

drop in  1

replace Jahr = Jahr[_n-1] if Jahr == .

gen quarter = substr(Quartal,1,1)

destring quarter, replace

gen yq = yq(Jahr,quarter)
format yq %tq

destring VerarbeitendesGewerbe , replace force

gen up = 8
gen year_r = Jahr - 0.5

drop if Jahr == 1995

save "${datapath}\union_wages.dta", replace

********************************************************************************
* prepare cpi data
********************************************************************************

import excel ${datapath}\cpi_ger.xls, sheet("FRED Graph") cellrange(A11:B72) firstrow clear

gen year = year(observation_date)
rename DEUCPIALLMINMEI cpi
drop observation_date

tsset year
gen lag_cpi = l.cpi
gen forw_cpi = f.cpi
save ${datapath}\cpi, replace

***
* run matlab code "lmps_zval.m"
* output of matlab code is "cbt_with_z_with_zins.xlsx"
***

********************************************************************************
* prepare investment shares based on matlab output
********************************************************************************

import excel "${datapath}\81000-0115_ausr.xlsx", sheet("81000-0115") cellrange(A9:B39) clear

rename A year
rename B inv_mach

save "${datapath}\inv_mach.dta" , replace

 
import excel "${datapath}\81000-0115_bauten.xlsx", sheet ("81000-0115") cellrange(A9:B39) clear

rename A year
rename B inv_construction


merge 1:1 year using "${datapath}\inv_mach.dta"

gen share_mach = inv_mach  / (inv_mach + inv_construction)
gen share_build =  inv_construction / (inv_mach + inv_construction)


keep share_mach share_build year
destring year , replace
drop if year == .
save "${datapath}\mb_shares.dta", replace

* oxford CBT Data and z-values
import excel "${datapath}\cbt_with_z_with_zins.xlsx" , sheet("Tabelle1") clear

rename Q z_mach5
rename R z_mach7
rename S z_mach9
rename T z_build5
rename U z_build7
rename V z_build9
rename W z_mach11
rename X z_build11

rename A year

keep year z_mach* z_build*

drop if year == 1979

* add 2018
input
2018  1 1 1 1 1 1 1 1
end

tsset year
forv r = 5(2)11 {

	replace z_mach`r' = l.z_mach`r' if year == 2018
	replace z_build`r' = l.z_build`r' if year == 2018
}

merge 1:1 year using ${datapath}\mb_shares , nogen

* fill values before 1991 with 1991 value (share of machinery and buildings)
gen t = share_mach if year == 1991
egen tm = max(t) 

replace share_mach = tm if year < 1991

drop t tm

gen t = share_build if year == 1991
egen tm = max(t) 

replace share_build = tm if year < 1991

drop t tm

* drop if missing
drop if z_mach5 == .

forv r = 5(2)11 {
	gen z_weighted`r' = (share_mach*z_mach`r') + (share_buil*z_build`r')
}

save "${datapath}\mb_shares_zvals.dta", replace
