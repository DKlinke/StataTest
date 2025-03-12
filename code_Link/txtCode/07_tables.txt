********************************************************************************
* Tables
********************************************************************************

use ${datapath}\final_data, replace

xtset plantnum year

********************************************************************************
* Table 1: Tax Hikes across Municipalities and Firms: Summary Statistics
********************************************************************************

mat M = J(9,7,.)

* municipality level

preserve
duplicates drop ao_gem_2017 year ,force

sum taxchange if inrange(year,1980,1984) & taxhike == 1
mat M[1,1] = r(N)
mat M[1,2] = round(r(mean),0.01)
mat M[1,3] = round(r(sd),0.01)

sum taxchange if inrange(year,1985,1989) & taxhike == 1 
mat M[2,1] = r(N)
mat M[2,2] = round(r(mean),0.01)
mat M[2,3] = round(r(sd),0.01)

sum taxchange if inrange(year,1990,1994) & taxhike == 1
mat M[3,1] = r(N)
mat M[3,2] = round(r(mean),0.01)
mat M[3,3] = round(r(sd),0.01)

sum taxchange if inrange(year,1995,1999) & taxhike == 1
mat M[4,1] = r(N)
mat M[4,2] = round(r(mean),0.01)
mat M[4,3] = round(r(sd),0.01)

sum taxchange if inrange(year,2000,2004) & taxhike == 1
mat M[5,1] = r(N)
mat M[5,2] = round(r(mean),0.01)
mat M[5,3] = round(r(sd),0.01)

sum taxchange if inrange(year,2005,2009) & taxhike == 1
mat M[6,1] = r(N)
mat M[6,2] = round(r(mean),0.01)
mat M[6,3] = round(r(sd),0.01)

sum taxchange if inrange(year,2010,2014) & taxhike == 1
mat M[7,1] = r(N)
mat M[7,2] = round(r(mean),0.01)
mat M[7,3] = round(r(sd),0.01)

sum taxchange if inrange(year,2015,2018) & taxhike == 1
mat M[8,1] = r(N)
mat M[8,2] = round(r(mean),0.01)
mat M[8,3] = round(r(sd),0.01)

sum taxchange if  taxhike == 1
mat M[9,1] = r(N)
mat M[9,2] = round(r(mean),0.01)
mat M[9,3] = round(r(sd),0.01)

restore

* hike obs

sum down_dummy if inrange(year,1980,1984) & taxhike == 1
mat M[1,4] = r(N)
mat M[1,5] = round(r(mean),0.01)

sum down_dummy if inrange(year,1985,1989) & taxhike == 1
mat M[2,4] = r(N)
mat M[2,5] = round(r(mean),0.01)

sum down_dummy if inrange(year,1990,1994) & taxhike == 1
mat M[3,4] = r(N)
mat M[3,5] = round(r(mean),0.01)

sum down_dummy if inrange(year,1995,1999) & taxhike == 1
mat M[4,4] = r(N)
mat M[4,5] = round(r(mean),0.01)

sum down_dummy if inrange(year,2000,2004) & taxhike == 1
mat M[5,4] = r(N)
mat M[5,5] = round(r(mean),0.01)

sum down_dummy if inrange(year,2005,2009) & taxhike == 1
mat M[6,4] = r(N)
mat M[6,5] = round(r(mean),0.01)

sum down_dummy if inrange(year,2010,2014) & taxhike == 1
mat M[7,4] = r(N)
mat M[7,5] = round(r(mean),0.01)

sum down_dummy if inrange(year,2015,2018) & taxhike == 1
mat M[8,4] = r(N)
mat M[8,5] = round(r(mean),0.01)

sum down_dummy if taxhike == 1
mat M[9,4] = r(N)
mat M[9,5] = round(r(mean),0.01)

* no hike obs

sum down_dummy if inrange(year,1980,1984) & taxhike == 0
mat M[1,6] = r(N)
mat M[1,7] = round(r(mean),0.01)

sum down_dummy if inrange(year,1985,1989) & taxhike == 0
mat M[2,6] = r(N)
mat M[2,7] = round(r(mean),0.01)

sum down_dummy if inrange(year,1990,1994) & taxhike == 0
mat M[3,6] = r(N)
mat M[3,7] = round(r(mean),0.01)

sum down_dummy if inrange(year,1995,1999) & taxhike == 0
mat M[4,6] = r(N)
mat M[4,7] = round(r(mean),0.01)

sum down_dummy if inrange(year,2000,2004) & taxhike == 0
mat M[5,6] = r(N)
mat M[5,7] = round(r(mean),0.01)

sum down_dummy if inrange(year,2005,2009) & taxhike == 0
mat M[6,6] = r(N)
mat M[6,7] = round(r(mean),0.01)

sum down_dummy if inrange(year,2010,2014) & taxhike == 0
mat M[7,6] = r(N)
mat M[7,7] = round(r(mean),0.01)

sum down_dummy if inrange(year,2015,2018) & taxhike == 0
mat M[8,6] = r(N)
mat M[8,7] = round(r(mean),0.01)

sum down_dummy if taxhike == 0 
mat M[9,6] = r(N)
mat M[9,7] = round(r(mean),0.01)


mat colnames M =  "N" "Mean" "SD"  "N" "Mean"  "N" "Mean"    
mat rownames M = "1980-1984" "1985-1989" "1990-1994" "1995-1999" "2000-2004" "2005-2009" "2010-2014" "2015-2018" "Full Sample"

mat list M

esttab matrix(M) using "${outputpath}\tab_1_variation_IT_firms_hike" , ///
	replace booktabs mlabel(none) label

********************************************************************************
* Table 2: Difference-in-Differences: Investment Revisions after a Tax Hike
********************************************************************************


foreach depvar in  down_dummy  logdiff   {
    foreach tax in taxhike taxchange  {
		eststo clear
		
		eststo: reghdfe `depvar' `tax' `cond'  , noabs vce(cl ao_gem_2017 ) 
		estadd local y "-"
		estadd local f "-"
		estadd local ys "-"
		estadd local yi "-"

		eststo: reghdfe `depvar' `tax' `cond' , absorb(year ) vce(cl ao_gem_2017 ) 
		estadd local y "$\checkmark$"
		estadd local f "-"
		estadd local ys "-"
		estadd local yi "-"

		eststo: reghdfe `depvar' `tax' `cond' , absorb(plantnum ) vce(cl ao_gem_2017 ) 
		estadd local y "-"
		estadd local f "$\checkmark$"
		estadd local ys "-"
		estadd local yi "-"

		eststo: reghdfe `depvar' `tax' `cond', absorb(year plantnum) vce(cl ao_gem_2017 ) 
		estadd local y "$\checkmark$"
		estadd local f "$\checkmark$"
		estadd local ys "-"
		estadd local yi "-"

		eststo: reghdfe `depvar' `tax' `cond', absorb(plantnum year_X_industry year_X_state) vce(cl ao_gem_2017 ) 
		estadd local y "-"
		estadd local f "$\checkmark$"
		estadd local ys "$\checkmark$"
		estadd local yi "$\checkmark$"

		esttab , se star(* 0.10 ** 0.05 *** 0.01) cells(b(star fmt(3)) se(par fmt(3)))
		esttab using "${outputpath}\tab_2_baseline_reg_`depvar'_`tax'", replace  booktabs  se label scalar("N Observations" "y Year FE" "f Firm FE" "ys Year X State FE" "yi Year X Industry FE" ) nomtitles nodep collabels(none) noabbrev  star(* 0.10 ** 0.05 *** 0.01)  cells(b(star fmt(3)) se(par fmt(3))) 
	}
}



********************************************************************************
* Table 3: Investment Revisions after a Tax Hike: Effective Tax Rates
********************************************************************************

* Panel A
eststo clear
eststo: reghdfe logdiff tax_eff_change7 , absorb(plantnum year_X_industry year_X_state) vce(cl ao_gem_2017 ) 
estadd local y "-"
estadd local f "$\checkmark$"
estadd local ys "$\checkmark$"
estadd local yi "$\checkmark$"

eststo: reghdfe logdiff tax_firm_com_eff_change7 , absorb(plantnum year_X_industry year_X_state) vce(cl ao_gem_2017 ) 
estadd local y "-"
estadd local f "$\checkmark$"
estadd local ys "$\checkmark$"
estadd local yi "$\checkmark$"

eststo: reghdfe logdiff tax_eff_change11 , absorb(plantnum year_X_industry year_X_state) vce(cl ao_gem_2017 ) 
estadd local y "-"
estadd local f "$\checkmark$"
estadd local ys "$\checkmark$"
estadd local yi "$\checkmark$"

eststo: reghdfe logdiff tax_firm_com_eff_change11 , absorb(plantnum year_X_industry year_X_state) vce(cl ao_gem_2017 ) 
estadd local y "-"
estadd local f "$\checkmark$"
estadd local ys "$\checkmark$"
estadd local yi "$\checkmark$"


esttab , se star(* 0.10 ** 0.05 *** 0.01) cells(b(star fmt(3)) se(par fmt(3)))
esttab using "${outputpath}\tab_3_baseline_reg_rob_eff", replace  booktabs  se label scalar("N Observations" "y Year FE" "f Firm FE" "ys Year X State FE" "yi Year X Industry FE" ) nomtitles nodep collabels(none) noabbrev  star(* 0.10 ** 0.05 *** 0.01)  cells(b(star fmt(3)) se(par fmt(3))) 

* Panel B
eststo clear
eststo: reghdfe logdiff tax_eff_change7_c , absorb(plantnum year_X_industry year_X_state) vce(cl ao_gem_2017 ) 
estadd local y "-"
estadd local f "$\checkmark$"
estadd local ys "$\checkmark$"
estadd local yi "$\checkmark$"

eststo: reghdfe logdiff tax_firm_com_eff_change7_c , absorb(plantnum year_X_industry year_X_state) vce(cl ao_gem_2017 ) 
estadd local y "-"
estadd local f "$\checkmark$"
estadd local ys "$\checkmark$"
estadd local yi "$\checkmark$"

eststo: reghdfe logdiff tax_eff_change11_c , absorb(plantnum year_X_industry year_X_state) vce(cl ao_gem_2017 ) 
estadd local y "-"
estadd local f "$\checkmark$"
estadd local ys "$\checkmark$"
estadd local yi "$\checkmark$"

eststo: reghdfe logdiff tax_firm_com_eff_change11_c , absorb(plantnum year_X_industry year_X_state) vce(cl ao_gem_2017 ) 
estadd local y "-"
estadd local f "$\checkmark$"
estadd local ys "$\checkmark$"
estadd local yi "$\checkmark$"


esttab , se star(* 0.10 ** 0.05 *** 0.01) cells(b(star fmt(3)) se(par fmt(3)))
esttab using "${outputpath}\tab_3_baseline_reg_rob_usercost", replace  booktabs  se label scalar("N Observations" "y Year FE" "f Firm FE" "ys Year X State FE" "yi Year X Industry FE" ) nomtitles nodep collabels(none) noabbrev  star(* 0.10 ** 0.05 *** 0.01)  cells(b(star fmt(3)) se(par fmt(3))) 



********************************************************************************
* Table 4: Summmary of Estimated (Semi-)Elasticities
********************************************************************************

eststo clear
eststo: reghdfe logdiff taxchange, absorb(plantnum year_X_industry year_X_state) vce(cl ao_gem_2017 ) 
estadd local y "-"
estadd local f "$\checkmark$"
estadd local ys "$\checkmark$"
estadd local yi "$\checkmark$"

eststo: reghdfe logdiff log_net, absorb(plantnum year_X_industry year_X_state) vce(cl ao_gem_2017 ) 
estadd local y "-"
estadd local f "$\checkmark$"
estadd local ys "$\checkmark$"
estadd local yi "$\checkmark$"

eststo: reghdfe logdiff tax_firm_com_eff_change11 , absorb(plantnum year_X_industry year_X_state) vce(cl ao_gem_2017 ) 
estadd local y "-"
estadd local f "$\checkmark$"
estadd local ys "$\checkmark$"
estadd local yi "$\checkmark$"

eststo: reghdfe logdiff tax_firm_com_eff_change11_c , absorb(plantnum year_X_industry year_X_state) vce(cl ao_gem_2017 ) 
estadd local y "-"
estadd local f "$\checkmark$"
estadd local ys "$\checkmark$"
estadd local yi "$\checkmark$"

* I/K (second column)
dis _b[tax_firm_com_eff_change11_c] * 10
dis _se[tax_firm_com_eff_change11_c] * 10

esttab , se star(* 0.10 ** 0.05 *** 0.01) cells(b(star fmt(3)) se(par fmt(3)))
esttab using "${outputpath}\tab_4_summary_estimates_lit", replace  booktabs  se label scalar("N Observations" "y Year FE" "f Firm FE" "ys Year X State FE" "yi Year X Industry FE" ) nomtitles nodep collabels(none) noabbrev  star(* 0.10 ** 0.05 *** 0.01)  cells(b(star fmt(3)) se(par fmt(3))) 

********************************************************************************
* Table B.1: Distribution of Firms in the IVS by Industry and Size
********************************************************************************
use ${datapath}\linked_it_gemeindedaten_prepared, replace


gen wz08_2dig = floor(sector_wz08/1000)
tostring wz08_2dig ,gen(wz08_2dig_s)
*replace wz08_2dig_s = "11-12" if wz08_2dig_s == "11" | wz08_2dig_s == "12"
*replace wz08_2dig_s = "11-12" if wz08_2dig_s == "11" | wz08_2dig_s == "12" 
 tab wz08_2dig if year == 2018
 
gen wz08_double_buchs = ""
replace wz08_double_buchs = "B" if wz08_2dig >= 5 & wz08_2dig <= 9
 replace wz08_double_buchs = "CA" if wz08_2dig >= 10 & wz08_2dig <= 12
 replace wz08_double_buchs = "CB" if wz08_2dig >= 13 & wz08_2dig <= 15
 replace wz08_double_buchs = "CC" if wz08_2dig >= 16 & wz08_2dig <= 18
 replace wz08_double_buchs = "CD" if wz08_2dig == 19
 replace wz08_double_buchs = "CE" if wz08_2dig == 20
 replace wz08_double_buchs = "CF" if wz08_2dig == 21
 replace wz08_double_buchs = "CG" if wz08_2dig == 22 | wz08_2dig == 23
 replace wz08_double_buchs = "CH" if wz08_2dig == 24 | wz08_2dig == 25
 replace wz08_double_buchs = "CI" if wz08_2dig == 26
 replace wz08_double_buchs = "CJ" if wz08_2dig == 27
 replace wz08_double_buchs = "CK" if wz08_2dig == 28
 replace wz08_double_buchs = "CL" if wz08_2dig == 29 | wz08_2dig == 30
 replace wz08_double_buchs = "CM" if wz08_2dig >= 31 & wz08_2dig <= 33

 tab wz08_double_buchs if year == 2018 //1009
 drop if  wz08_double_buchs == "B"
 
gen f_size = "small" if besch_lj < 50 & besch_lj != .
replace f_size = "middle" if besch_lj >= 50 & besch_lj < 250 & besch_lj != .
replace f_size = "large" if besch_lj >= 250 & besch_lj != .

mat M = J(14,4,.)

tab f_size if f_size != "" & wz08_double_buchs != "" & year  == 2018
mat M[14,4] = r(N) / r(N) * 100
scalar all = r(N)

local r = 1
foreach sec in  CA CB CC CD CE CF CG CH CI CJ CK CL CM {
	tab f_size if f_size == "small" & wz08_double_buchs == "`sec'" & year  == 2018
	
	mat M[`r',1] = round(r(N) / all,0.001)*100
	if r(N) < 4 {
	mat M[`r',1] = . 
	}
	tab f_size if f_size == "middle" & wz08_double_buchs == "`sec'" & year  == 2018
	mat M[`r',2] = round(r(N) / all,0.001)*100
	if r(N) < 4 {
	mat M[`r',2] = . 
	}
	tab f_size if f_size == "large" & wz08_double_buchs == "`sec'" & year  == 2018
	mat M[`r',3] = round(r(N) / all,0.001)*100
	if r(N) < 4 {
	mat M[`r',3] = . 
	}
	tab f_size if f_size != "" & wz08_double_buchs == "`sec'" & year  == 2018

	mat M[`r',4] = round(r(N) / all,0.001)*100
	local r = `r' + 1
}
	tab f_size if f_size == "small" & wz08_double_buchs != "" & year  == 2018
	mat M[`r',1] = round(r(N) / all,0.001)*100
	
	tab f_size if f_size == "middle" & wz08_double_buchs != "" & year  == 2018
	mat M[`r',2] = round(r(N) / all,0.001)*100
	
	tab f_size if f_size == "large" & wz08_double_buchs != "" & year  == 2018
	mat M[`r',3] = round(r(N) / all,0.001)*100

mat list M


mat colnames M = "Small" "Middle"  "Large" "Total"
mat rownames M =  "CA" "CB" "CC" "CD" "CE" "CF" "CG" "CH" "CI" "CJ" "CK" "CL" "CM" "Total"

mat list M ,format(%3.1f)

svmat2 M, names(col) rnames(sector) 

keep Small Middle Large Total sector

drop if sector == ""

order sector

export excel using "${outputpath}\tab_b1_represent_it.xlsx", firstrow(variables) replace


********************************************************************************
* Table B.2: Summary Statistics of Firms in the Sample
********************************************************************************

use ${datapath}\final_data, replace

xtset plantnum year

mat M = J(4,4,.)

local r = 1
foreach var in besch_lj rev_k reali_inv_k obs_f {

	sum `var' , d
	mat M[`r',1] = round(r(p10),1)
	mat M[`r',2] = round(r(p50),1)
	mat M[`r',3] = round(r(p90),1)
	mat M[`r',4] = round(r(mean),1)

	local r = `r' + 1
}
	
	
mat list M
mat rownames M = "Employees" "Revenues" "Investment" "Observations per Firm"
mat colnames M = "p10" "p50" "p90" "mean"
mat list M

esttab matrix(M) using "${outputpath}\tab_b2_firm_sum_stat" , ///
	replace booktabs mlabel(none) label
	
********************************************************************************
* Table B.3: Balance Statistics of Firms in the Treatment and Control Group
********************************************************************************

mat M = J(5,3,.)

* mean
local r = 1
foreach var in besch_lj rev_k reali_inv_k down_dummy logdiff {


	sum `var' if F1_taxhike == 1 & taxhike == 0 , d
	mat M[`r',1] = round(r(mean),0.01)
	sum `var' if F1_taxhike == 0 & taxhike == 0 , d
	mat M[`r',2] = round(r(mean),0.01)
	ttest `var' if taxhike != 1 , by(F1_taxhike)
	mat M[`r',3] = round(r(p),0.0001)

	local r = `r' + 1
}
	
	
mat list M
mat rownames M = "Employees" "Revenues" "Investment" "Donward Revision" "Log Revision Ratio"
mat colnames M = "Treated" "Control" "p-value" 

mat list M

esttab matrix(M) using "${outputpath}\tab_b3_balance_test" , ///
	replace booktabs mlabel(none) label
	
	
********************************************************************************
* Table B.4: Information Content of Investment Plans for Realized Investment
********************************************************************************


gen sample_horse = 1
eststo: reghdfe l_r_i l_e_i l.l_r_i  if taxhike== 0 , absorb(plantnum) vce(cluster plantnum)
replace sample_horse = . if e(sample) != 1

eststo clear

eststo: reghdfe l_r_i l_e_i if taxhike== 0 & sample_horse == 1, noabs vce(cluster plantnum)
estadd local r2w = "-"
estadd local r2t = string(round(e(r2),0.01), "%9.2f")

eststo: reghdfe l_r_i l_e_i l.l_r_i if taxhike== 0 & sample_horse == 1 , noabs vce(cluster plantnum)
estadd local r2w = "-"
estadd local r2t = string(round(e(r2),0.01), "%9.2f")

eststo: reghdfe l_r_i l_e_i if taxhike== 0 & sample_horse == 1 , absorb(plantnum) vce(cluster plantnum)
estadd local r2w = string(round(e(r2_within),0.01), "%9.2f")
estadd local r2t = string(round(e(r2),0.01), "%9.2f")

eststo: reghdfe l_r_i l_e_i l.l_r_i if taxhike== 0 & sample_horse == 1 , absorb(plantnum) vce(cluster plantnum)
estadd local r2w = string(round(e(r2_within),0.01), "%9.2f")
estadd local r2t = string(round(e(r2),0.01), "%9.2f")

esttab , scalar("r2t R^2" "r2w R^2 (within)") label
esttab using "${outputpath}\tab_b4_plans_quality", replace label booktabs  se  scalar("r2 R^2" "r2w R^2 (within)") nomtitles noabbrev  star(* 0.10 ** 0.05 *** 0.01) cells(b(star fmt(3)) se(par fmt(3)) r(par fmt(2))) 
	
	
	
********************************************************************************
* Table C.1: Robustness: Baseline Estimates Excl. Reunification Period
********************************************************************************


foreach depvar in down_dummy  logdiff   {
    foreach tax in taxhike taxchange  {
		local cond if year < 1990 | year > 1998
		eststo clear
		
		eststo: reghdfe `depvar' `tax' `cond'  , noabs vce(cl ao_gem_2017 ) 
		estadd local y "-"
		estadd local f "-"
		estadd local ys "-"
		estadd local yi "-"

		eststo: reghdfe `depvar' `tax' `cond' , absorb(year ) vce(cl ao_gem_2017 ) 
		estadd local y "$\checkmark$"
		estadd local f "-"
		estadd local ys "-"
		estadd local yi "-"

		eststo: reghdfe `depvar' `tax' `cond' , absorb(plantnum ) vce(cl ao_gem_2017 ) 
		estadd local y "-"
		estadd local f "$\checkmark$"
		estadd local ys "-"
		estadd local yi "-"

		eststo: reghdfe `depvar' `tax' `cond', absorb(year plantnum) vce(cl ao_gem_2017 ) 
		estadd local y "$\checkmark$"
		estadd local f "$\checkmark$"
		estadd local ys "-"
		estadd local yi "-"

		eststo: reghdfe `depvar' `tax' `cond', absorb(plantnum year_X_industry year_X_state) vce(cl ao_gem_2017 ) 
		estadd local y "-"
		estadd local f "$\checkmark$"
		estadd local ys "$\checkmark$"
		estadd local yi "$\checkmark$"



		esttab , se star(* 0.10 ** 0.05 *** 0.01) cells(b(star fmt(3)) se(par fmt(3)))
		esttab using "${outputpath}\tab_c1_baseline_reg_`depvar'_`tax'_reunf", replace  booktabs  se label scalar("N Observations" "y Year FE" "f Firm FE" "ys Year X State FE" "yi Year X Industry FE" ) nomtitles nodep collabels(none) noabbrev  star(* 0.10 ** 0.05 *** 0.01)  cells(b(star fmt(3)) se(par fmt(3))) 
	}
}



********************************************************************************
* Table C.2: Treatment Effect Heterogeneity: State Dependence
********************************************************************************

* Panel A
eststo clear

foreach depvar in down_dummy logdiff {
	foreach treat in taxhike taxchange {

		eststo: reghdfe `depvar' c.`treat'#i.rec  , absorb(year plantnum) vce(cl ao_gem_2017 ) 

		test _b[c.`treat'#1.rec] = _b[c.`treat'#0.rec]

		estadd local y "$\checkmark$"
		estadd local f "$\checkmark$"
		estadd local ys "-"
		estadd local yi "-"
		estadd local ttest = round(r(p),0.001)

		eststo: reghdfe `depvar' c.`treat'#i.rec , absorb(plantnum year_X_industry year_X_state) vce(cl ao_gem_2017 ) 

		test _b[c.`treat'#1.rec] = _b[c.`treat'#0.rec]
		
		estadd local y "-"
		estadd local f "$\checkmark$"
		estadd local ys "$\checkmark$"
		estadd local yi "$\checkmark$"
		estadd local ttest = round(r(p),0.001)


	} 
}
esttab ,se star(* 0.10 ** 0.05 *** 0.01)

esttab using "${outputpath}\tab_c2_hetero_reg_recession_all", replace  booktabs  se label scalar("N Observations" "y Year FE" "f Firm FE" "ys Year X State FE" "yi Year X Industry FE" "ttest P-Value Test") nomtitles nodep noabbrev collabels(none)  star(* 0.10 ** 0.05 *** 0.01) cells(b(star fmt(3)) se(par fmt(3))) interaction(" $\times$ ")

* Panel B
eststo clear

foreach depvar in down_dummy logdiff {
	foreach treat in taxhike taxchange {
		
		eststo: reghdfe `depvar'  c.`treat'#i.rec_y  , absorb(year plantnum) vce(cl ao_gem_2017 ) 

		test _b[c.`treat'#1.rec_y] = _b[c.`treat'#0.rec_y]

		estadd local y "$\checkmark$"
		estadd local f "$\checkmark$"
		estadd local ys "-"
		estadd local yi "-"
		estadd local ttest = round(r(p),0.001)

		eststo: reghdfe `depvar'  c.`treat'#i.rec_y , absorb(plantnum year_X_industry year_X_state) vce(cl ao_gem_2017 ) 

		test _b[c.`treat'#1.rec_y] = _b[c.`treat'#0.rec_y]
		estadd local y "-"
		estadd local f "$\checkmark$"
		estadd local ys "$\checkmark$"
		estadd local yi "$\checkmark$"
		estadd local ttest = round(r(p),0.001)
	}
} 
esttab ,se star(* 0.10 ** 0.05 *** 0.01)

esttab using "${outputpath}\tab_c2_hetero_reg_recession_all_y", replace booktabs  se label scalar("N Observations" "y Year FE" "f Firm FE" "ys Year X State FE" "yi Year X Industry FE" "ttest P-Value Test")  nomtitles nodep noabbrev collabels(none)  star(* 0.10 ** 0.05 *** 0.01) cells(b(star fmt(3)) se(par fmt(3))) mgroups("Downward Revision" "Log Inv. Revision", pattern(1 0 0 0 1 0 0 0) prefix(\multicolumn{@span}{c}{)suffix(}) span erepeat(\cmidrule(lr){@span}))

********************************************************************************
* Table C.3: Difference-in-Differences: Investment Revisions after a Tax Hike
********************************************************************************

local depvar logdiff   
local tax log_net

eststo clear

eststo: reghdfe `depvar' `tax' `cond'  , noabs vce(cl ao_gem_2017 ) 
estadd local y "-"
estadd local f "-"
estadd local ys "-"
estadd local yi "-"

eststo: reghdfe `depvar' `tax' `cond' , absorb(year ) vce(cl ao_gem_2017 ) 
estadd local y "$\checkmark$"
estadd local f "-"
estadd local ys "-"
estadd local yi "-"

eststo: reghdfe `depvar' `tax' `cond' , absorb(plantnum ) vce(cl ao_gem_2017 ) 
estadd local y "-"
estadd local f "$\checkmark$"
estadd local ys "-"
estadd local yi "-"

eststo: reghdfe `depvar' `tax' `cond', absorb(year plantnum) vce(cl ao_gem_2017 ) 
estadd local y "$\checkmark$"
estadd local f "$\checkmark$"
estadd local ys "-"
estadd local yi "-"

eststo: reghdfe `depvar' `tax' `cond', absorb(plantnum year_X_industry year_X_state) vce(cl ao_gem_2017 ) 
estadd local y "-"
estadd local f "$\checkmark$"
estadd local ys "$\checkmark$"
estadd local yi "$\checkmark$"

esttab , se star(* 0.10 ** 0.05 *** 0.01) cells(b(star fmt(3)) se(par fmt(3)))
esttab using "${outputpath}\tab_c3_baseline_reg_`depvar'_`tax'", replace  booktabs  se label scalar("N Observations" "y Year FE" "f Firm FE" "ys Year X State FE" "yi Year X Industry FE" ) nomtitles nodep collabels(none) noabbrev  star(* 0.10 ** 0.05 *** 0.01)  cells(b(star fmt(3)) se(par fmt(3))) 

********************************************************************************
* Table C.4: Treatment Effect Heterogeneity: Volatility of Revenue Growth (high_sd_gr_rev)
* Table C.8: Treatment Effect Heterogeneity: Firm Size and Settlement Structure (large_emp; land)
* Table C.9: Treatment Effect Heterogeneity: Tax Hike Dynamics(many_hikes; hike_5noyears)
********************************************************************************

local n = 1

foreach interact in   high_sd_gr_rev large_emp land many_hikes hike_5noyears     {

	eststo clear

	foreach depvar in down_dummy logdiff {
		
		foreach treat in taxhike taxchange {

		eststo: reghdfe `depvar'  c.`treat'#i.`interact'  /*`interact'*/ , absorb(year plantnum) vce(cl ao_gem_2017) 

		test _b[c.`treat'#0.`interact'] = _b[c.`treat'#1.`interact']

		estadd local y "$\checkmark$"
		estadd local f "$\checkmark$"
		estadd local ys "-"
		estadd local yi "-"
		estadd local ttest = round(r(p),0.001)

		eststo: reghdfe `depvar'  c.`treat'#i.`interact'  /*`interact'*/ , absorb(plantnum year_X_industry year_X_state) vce(cl ao_gem_2017) 

		test _b[c.`treat'#0.`interact'] = _b[c.`treat'#1.`interact']

		estadd local y "-"
		estadd local f "$\checkmark$"
		estadd local ys "$\checkmark$"
		estadd local yi "$\checkmark$"
		estadd local ttest = round(r(p),0.001)

		}
	}
	
	if `n' == 1 {
		local tab c4
	}
	
	if `n' == 2 | `n' == 3 {
		local tab c8
	}
	
	if `n' == 4 | `n' == 5 {
		local tab c9
	}
	
	esttab ,se star(* 0.10 ** 0.05 *** 0.01)
	esttab using "${outputpath}\tab_`tab'_hetero_reg_all_`interact'", replace label booktabs  se  scalar("N Observations" "y Year FE" "f Firm FE" "ys Year X State FE" "yi Year X Industry FE" "ttest P-Value Test") nomtitles nodep noabbrev collabels(none) star(* 0.10 ** 0.05 *** 0.01) cells(b(star fmt(3)) se(par fmt(3))) mgroups("Downward Revision" "Log Revision Ratio", pattern(1 0 0 0 1 0 0 0) prefix(\multicolumn{@span}{c}{)suffix(}) span erepeat(\cmidrule(lr){@span}))
	local n = `n' + 1
}

********************************************************************************
* Table C.5: Treatment Effect Heterogeneity: Current Revenue Growth I
* Table C.7: Treatment Effect Heterogeneity: Financial Constraints
********************************************************************************

local n = 1
foreach interact in umsatzdropf fin_p {

	eststo clear
	foreach depvar in down_dummy logdiff {
		foreach treat in taxhike taxchange {

			eststo: reghdfe `depvar' c.`treat'#i.rec#i.`interact'   `interact' , absorb(year plantnum) vce(cl ao_gem_2017 ) 

			test _b[c.`treat'#1.rec#0.`interact'] = _b[c.`treat'#1.rec#1.`interact']

			estadd local y "$\checkmark$"
			estadd local f "$\checkmark$"
			estadd local ys "-"
			estadd local yi "-"
			estadd local ttest = round(r(p),0.001)

			eststo: reghdfe `depvar'   c.`treat'#i.rec#i.`interact'   `interact' , absorb(plantnum year_X_industry year_X_state) vce(cl ao_gem_2017 ) 
			
			test _b[c.`treat'#1.rec#0.`interact'] = _b[c.`treat'#1.rec#1.`interact']

			estadd local y "-"
			estadd local f "$\checkmark$"
			estadd local ys "$\checkmark$"
			estadd local yi "$\checkmark$"
			estadd local ttest = round(r(p),0.001)

		}
	}

		
	if `n' == 1 {
		local tab c5
	}

			
	if `n' == 2 {
		local tab c7
	}
		
	esttab ,se star(* 0.10 ** 0.05 *** 0.01)
	esttab using "${outputpath}\tab_`tab'_hetero_reg_rec_all_`interact'", replace label booktabs  se  scalar("N Observations" "y Year FE" "f Firm FE" "ys Year X State FE" "yi Year X Industry FE" "ttest P-Value Test") nomtitles nodep noabbrev collabels(none) star(* 0.10 ** 0.05 *** 0.01) cells(b(star fmt(3)) se(par fmt(3))) mgroups("Downward Revision" "Log Inv. Revision", pattern(1 0 0 0 1 0 0 0) prefix(\multicolumn{@span}{c}{)suffix(}) span erepeat(\cmidrule(lr){@span}))
	local n = `n' + 1
}

********************************************************************************
* Table C.6: Treatment Effect Heterogeneity: Current Revenue Growth II
********************************************************************************

local inter umsatzdropf  
local depvar down_dummy
local treat taxhike

eststo clear

eststo: reghdfe `depvar'  c.`treat'#i.rec#i.`inter'  `inter'  , absorb(year) vce(cl ao_gem_2017 )
estadd local y "$\checkmark$"
estadd local f "-"
estadd local ys "-"
estadd local yi "-"
estadd local sam "-"

eststo: reghdfe `depvar' c.`treat'#i.rec#i.`inter'  `inter'  , absorb(year plantnum) vce(cl ao_gem_2017 )
estadd local y "$\checkmark$"
estadd local f "$\checkmark$"
estadd local ys "-"
estadd local yi "-"
estadd local sam "-"

eststo: reghdfe `depvar'  c.`treat'#i.rec#i.`inter'  `inter' , absorb(plantnum year_X_industry year_X_state) vce(cl ao_gem_2017 )
estadd local y "-"
estadd local f "$\checkmark$"
estadd local ys "$\checkmark$"
estadd local yi "$\checkmark$"
estadd local sam "-"


eststo: reghdfe `depvar'  c.`treat'#i.rec#i.`inter'  `inter' if emp_change >= -0.05 & emp_change != .  , absorb(year plantnum) vce(cl ao_gem_2017 )
estadd local y "$\checkmark$"
estadd local f "$\checkmark$"
estadd local ys "-"
estadd local yi "-"
estadd local sam "Yes, < 5%"

eststo: reghdfe `depvar'  c.`treat'#i.rec#i.`inter'  `inter' if emp_change >= -0.05 & emp_change != . , absorb(plantnum year_X_industry year_X_state) vce(cl ao_gem_2017 )
estadd local y "-"
estadd local f "$\checkmark$"
estadd local ys "$\checkmark$"
estadd local yi "$\checkmark$"
estadd local sam "Yes, < 5%"

esttab , star(* 0.10 ** 0.05 *** 0.01)

esttab using "${outputpath}\tab_c6_hetero_reg_rec_rev_`depvar'_`treat'_`inter'", replace  booktabs  se rename(taxhike "Tax Hike" taxchange "Tax Increase" _cons "Constant") scalar("N Observations" "y Year FE" "f Firm FE" "ys Year X State FE" "yi Year X Industry FE" "sam Exclude Labor Drop") nomtitles noabbrev title("Difference-in-Differences: Investment Revisions after a Tax Hike")  star(* 0.10 ** 0.05 *** 0.01) cells(b(star fmt(3)) se(par fmt(3)))
