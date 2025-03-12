use ${datapath}\final_data, replace

********************************************************************************
* event study set-up
********************************************************************************

xtset plantnum year

gen wind_3 = 1 if F3_taxhike == 1 | F2_taxhike == 1 | F1_taxhike == 1 |  L0_taxhike == 1 | L1_taxhike == 1 |  L2_taxhike == 1   |  L3_taxhike == 1    

gen wind_4 = 1 if F4_taxhike == 1 | F3_taxhike == 1 | F2_taxhike == 1 | F1_taxhike == 1 |  L0_taxhike == 1 | L1_taxhike == 1 |  L2_taxhike == 1   |  L3_taxhike == 1   |  L4_taxhike == 1  

* reference period
replace F1_taxhike = 0
gen F1_bintaxhike = 0
gen F1_bin3taxhike = 0

global x_lbt_hike   c.F2_taxhike c.F1_taxhike  c.L0_taxhike c.L1_taxhike L2_taxhike 

global x_lbt_hike4   c.F4_taxhike c.F3_taxhike c.F2_taxhike c.F1_taxhike  c.L0_taxhike c.L1_taxhike L2_taxhike c.L3_taxhike c.L4_taxhike 

global x_lbt_hikebin   c.F4_bintaxhike c.F3_bintaxhike c.F2_bintaxhike c.F1_bintaxhike  c.L0_bintaxhike c.L1_bintaxhike L2_bintaxhike c.L3_bintaxhike c.L4_bintaxhike 

global x_lbt_hikebin3    c.F3_bin3taxhike c.F2_bin3taxhike c.F1_bin3taxhike  c.L0_bin3taxhike c.L1_bin3taxhike L2_bin3taxhike c.L3_bin3taxhike  

********************************************************************************
* Figure 3: Event Study: Investment Revision Effect after a Tax Hike
********************************************************************************

* Panel A: TW FEs

local var x_lbt_hike 
* settings
local fe plantnum year
eststo clear
* Downward revision
local depvar down_dummy 
reghdfe `depvar' $`var'   , a(`fe') vce(cl ao_gem_2017 ) 
estimates store dd

* Log Ratio
local depvar logdiff  
reghdfe `depvar' $`var'   , a(`fe') vce(cl ao_gem_2017 ) // N = 32,933
estimates store ld

coefplot (dd , offset(-0.05)  m(O)  ) (ld , offset(0.05)  m(S)  ) , vert drop(_cons) omitted levels(95 90) recast(con) yline(0) ///
	rename(F4_taxhike=t-4 F3_taxhike=t-3 F3_taxchange=t-3 F2_taxhike=t-2 F2_taxchange=t-2 F1_taxhike=t-1 F1_taxchange=t-1 L0_taxhike=t0 L0_taxchange=t0 L1_taxhike=t1 L1_taxchange=t1 L2_taxhike=t2 L2_taxchange=t2 L3_taxhike=t3 L3_taxchange=t3 L4_taxhike=t4 ///
	F4_bintaxhike=t-4 F4_bin3taxhike=t-4 F3_bintaxhike=t-3 F3_bin3taxhike=t-3 F2_bintaxhike=t-2 F2_bin3taxhike=t-2 F1_bintaxhike=t-1 F1_bin3taxhike=t-1 L0_bintaxhike=t0 L0_bin3taxhike=t0 L1_bintaxhike=t1 L1_bin3taxhike=t1 L2_bintaxhike=t2 L2_bin3taxhike=t2 L3_bintaxhike=t3 L3_bin3taxhike=t3 L4_bintaxhike=t4 L4_bin3taxhike=t4 ) ytitle("Estimated Effect Relative to Period t = -1") legend(order(3 "Downward Revision" 6 "Log Revision Ratio")) ylabel(-0.075(0.025)0.075, format(%4.3f))
graph export "${outputpath}\fig_3_a.pdf", replace 

* Panel B: Full FEs

local var x_lbt_hike 
* settings
local fe plantnum year_X_industry year_X_state   
eststo clear
* Downward revision
local depvar down_dummy 
reghdfe `depvar' $`var'   , a(`fe') vce(cl ao_gem_2017 ) 
estimates store dd

* Log Ratio
local depvar logdiff  
reghdfe `depvar' $`var'   , a(`fe') vce(cl ao_gem_2017 ) 
estimates store ld

coefplot (dd , offset(-0.05)  m(O)  ) (ld , offset(0.05)  m(S)  ) , vert drop(_cons) omitted levels(95 90) recast(con) yline(0) ///
	rename(F4_taxhike=t-4 F3_taxhike=t-3 F3_taxchange=t-3 F2_taxhike=t-2 F2_taxchange=t-2 F1_taxhike=t-1 F1_taxchange=t-1 L0_taxhike=t0 L0_taxchange=t0 L1_taxhike=t1 L1_taxchange=t1 L2_taxhike=t2 L2_taxchange=t2 L3_taxhike=t3 L3_taxchange=t3 L4_taxhike=t4 ///
	F4_bintaxhike=t-4 F4_bin3taxhike=t-4 F3_bintaxhike=t-3 F3_bin3taxhike=t-3 F2_bintaxhike=t-2 F2_bin3taxhike=t-2 F1_bintaxhike=t-1 F1_bin3taxhike=t-1 L0_bintaxhike=t0 L0_bin3taxhike=t0 L1_bintaxhike=t1 L1_bin3taxhike=t1 L2_bintaxhike=t2 L2_bin3taxhike=t2 L3_bintaxhike=t3 L3_bin3taxhike=t3 L4_bintaxhike=t4 L4_bin3taxhike=t4 ) ytitle("Estimated Effect Relative to Period t = -1") legend(order(3 "Downward Revision" 6 "Log Revision Ratio")) ylabel(-0.075(0.025)0.075, format(%4.3f))
graph export "${outputpath}\fig_3_b.pdf", replace 

********************************************************************************
* Figure C.1: Long Event Study: Effect of Tax Hike on Investment Plans, Realizations, and Revisions
* Panel A: Downward Revision and Log Revision Ratio
********************************************************************************

local var x_lbt_hike4 
* settings
local fe plantnum year
eststo clear
* Downward revision
local depvar down_dummy 
reghdfe `depvar' $`var'   if drop_around4 != 1 , a(`fe') vce(cl ao_gem_2017 ) 
estimates store dd

* Log Ratio
local depvar logdiff  
reghdfe `depvar' $`var'  if drop_around4 != 1  , a(`fe') vce(cl ao_gem_2017 ) 
estimates store ld

coefplot (dd , offset(-0.05)  m(O)  ) (ld , offset(0.05)  m(S)  ) , vert drop(_cons) omitted levels(95 90) recast(con) yline(0) ///
	rename(F4_taxhike=t-4 F3_taxhike=t-3 F3_taxchange=t-3 F2_taxhike=t-2 F2_taxchange=t-2 F1_taxhike=t-1 F1_taxchange=t-1 L0_taxhike=t0 L0_taxchange=t0 L1_taxhike=t1 L1_taxchange=t1 L2_taxhike=t2 L2_taxchange=t2 L3_taxhike=t3 L3_taxchange=t3 L4_taxhike=t4 ///
	F4_bintaxhike=t-4 F4_bin3taxhike=t-4 F3_bintaxhike=t-3 F3_bin3taxhike=t-3 F2_bintaxhike=t-2 F2_bin3taxhike=t-2 F1_bintaxhike=t-1 F1_bin3taxhike=t-1 L0_bintaxhike=t0 L0_bin3taxhike=t0 L1_bintaxhike=t1 L1_bin3taxhike=t1 L2_bintaxhike=t2 L2_bin3taxhike=t2 L3_bintaxhike=t3 L3_bin3taxhike=t3 L4_bintaxhike=t4 L4_bin3taxhike=t4 ) ytitle("Estimated Effect Relative to Period t = -1") legend(order(3 "Downward Revision" 6 "Log Revision Ratio")) ylabel(-0.15(0.02)0.09, format(%3.2f)) 
graph export "${outputpath}\fig_c1_a.pdf", replace 

********************************************************************************
* Figure C.3: Event Study: Expenditures and revenues of municipalities
********************************************************************************

* Panel A: Indicator

foreach var in x_lbt_hike  {
	
* settings
local fe plantnum year_X_industry year_X_state  

eststo clear
* Downward revision
local depvar hh_rev_incr 
reghdfe `depvar' $`var'  , a(`fe') vce(cl ao_gem_2017 ) 
estimates store dd

* Log Ratio
local depvar hh_exp_incr  
reghdfe `depvar' $`var' , a(`fe') vce(cl ao_gem_2017 )
estimates store ld

coefplot (dd , offset(-0.05)  m(O)  ) (ld , offset(0.05)  m(S)  ) , vert drop(_cons) omitted levels(95 90) recast(con) yline(0) ///
	rename(F3_taxhike=t-3 F3_taxchange=t-3 F2_taxhike=t-2 F2_taxchange=t-2 F1_taxhike=t-1 F1_taxchange=t-1 L0_taxhike=t0 L0_taxchange=t0 L1_taxhike=t1 L1_taxchange=t1 L2_taxhike=t2 L2_taxchange=t2 L3_taxhike=t3 L3_taxchange=t3 ) ytitle("Estimated Effect Relative to Period t = -1") legend(order(3 "Revenue Increase" 6 "Spending Increase")) ylabel(-0.2(0.05)0.2, format(%3.2f))
graph export "${outputpath}\fig_c3_a.pdf", replace 
}

* Panel B: Logarithm

foreach var in x_lbt_hike  {
* settings
local fe plantnum year_X_industry year_X_state  
eststo clear
* Downward revision
local depvar log_hhrev 
reghdfe `depvar' $`var'  , a(`fe') vce(cl ao_gem_2017 ) 
estimates store dd

* Log Ratio
local depvar log_hhexp  
reghdfe `depvar' $`var' , a(`fe') vce(cl ao_gem_2017 )
estimates store ld

coefplot (dd , offset(-0.05)  m(O)  ) (ld , offset(0.05)  m(S)  ) , vert drop(_cons) omitted levels(95 90) recast(con) yline(0) ///
	rename(F3_taxhike=t-3 F3_taxchange=t-3 F2_taxhike=t-2 F2_taxchange=t-2 F1_taxhike=t-1 F1_taxchange=t-1 L0_taxhike=t0 L0_taxchange=t0 L1_taxhike=t1 L1_taxchange=t1 L2_taxhike=t2 L2_taxchange=t2 L3_taxhike=t3 L3_taxchange=t3 ) ytitle("Estimated Effect Relative to Period t = -1") legend(order(3 "Log Revenues" 6 "Log Spending")) ylabel(-0.05(0.01)0.05, format(%3.2f))
graph export "${outputpath}\fig_c3_b.pdf", replace 
}


********************************************************************************
* Figure C.4: Investment Revisions after a Tax Hike: Permutation Test
********************************************************************************	

cap drop n  b_perm1 b_perm2 draw hike_perm cdf1 cdf2
gen n = _n
gen b_perm1 = .
gen b_perm2 = .
gen draw = .
gen hike_perm = .

set seed 1
* muni-year level
forv t = 1/2000 {
	qui replace draw = runiform()
	qui bysort ao_gem_2017 year: replace draw = draw[1]
	qui replace hike_perm = 0 if draw > 0.074 & draw != .
	qui replace hike_perm = 1 if draw <= 0.074 & draw != .

	qui reghdfe down_dummy hike_perm	,absorb(plantnum year_X_industry year_X_state)
	qui replace b_perm1 = _b[hike_perm] if n == `t'
	
	qui reghdfe logdiff hike_perm	,absorb(plantnum year_X_industry year_X_state)
	qui replace b_perm2 = _b[hike_perm] if n == `t'
	_dots `t' 0
}

cumul b_perm1 , gen(cdf1)
cumul b_perm2 , gen(cdf2)

reghdfe down_dummy taxhike	,absorb(plantnum year_X_industry year_X_state)
local b_real = _b[taxhike]
gen share_out1 = 0 if b_perm1 != .
replace share_out1 = 1 if  b_perm1 >= `b_real' &  b_perm1 != . 
tab share_out1 // 0.05%
tw scatter cdf1 b_perm1 , xline(`b_real') xlabel(-0.04(0.01)0.04) ms(Oh) color(navy) xtitle("Placebo Treatment Coefficient") ytitle("Cumulative Distribution Function")
graph export "${outputpath}\fig_c4_a.pdf", replace


reghdfe logdiff taxhike	,absorb(plantnum year_X_industry year_X_state)
local b_real = _b[taxhike]
gen share_out2 = 0 if b_perm2 != .
replace share_out2 = 1 if  b_perm2 <= `b_real' &  b_perm2 != . 
tab share_out2 // 1.15%
tw scatter cdf2 b_perm2 , xline(`b_real') xlabel(-0.05(0.01)0.05) ms(Oh) color(navy) xtitle("Placebo Treatment Coefficient") ytitle("Cumulative Distribution Function")
graph export "${outputpath}\fig_c4_b.pdf", replace 


********************************************************************************
* Build sample for heterogenous treatment effects
********************************************************************************

* tag year of hike
gen taxhike_year = year if taxhike == 1

* generate variables with year of x'th tax hike
xtset plantnum year

egen tot_hike = total(taxhike) ,by(plantnum)

egen first_h = min(taxhike_year) ,by(plantnum)
egen second_h = min(taxhike_year) if taxhike_year != first_h ,by(plantnum)
egen third_h = min(taxhike_year) if taxhike_year != first_h & taxhike_year != second_h ,by(plantnum)
egen forth_h = min(taxhike_year) if taxhike_year != first_h & taxhike_year != second_h & taxhike_year != third_h ,by(plantnum)
egen fifth_h = min(taxhike_year) if taxhike_year != first_h & taxhike_year != second_h & taxhike_year != third_h & taxhike_year != forth_h ,by(plantnum)
egen sixth_h = min(taxhike_year) if taxhike_year != first_h & taxhike_year != second_h & taxhike_year != third_h & taxhike_year != forth_h  & taxhike_year != fifth_h ,by(plantnum)
egen seventh_h = min(taxhike_year) if taxhike_year != first_h & taxhike_year != second_h & taxhike_year != third_h & taxhike_year != forth_h  & taxhike_year != fifth_h  & taxhike_year != sixth_h ,by(plantnum)

egen f_h = max(first_h) ,by(plantnum)
egen s_h = max(second_h) ,by(plantnum)
egen t_h = max(third_h) ,by(plantnum)
egen fo_h = max(forth_h) ,by(plantnum)
egen fi_h = max(fifth_h) ,by(plantnum)
egen si_h = max(sixth_h) ,by(plantnum)
egen se_h = max(seventh_h) ,by(plantnum)

bys plantnum: gen f_s_h = (f_h + s_h) / 2
bys plantnum: gen s_t_h = (s_h + t_h) / 2
bys plantnum: gen t_f_h = (t_h + fo_h) / 2
bys plantnum: gen f_f_h = (fo_h + fi_h) / 2
bys plantnum: gen f_si_h = (fi_h + si_h) / 2
bys plantnum: gen s_s_h = (si_h + se_h) / 2


bys plantnum: gen t_group =  first_h if year<=f_s_h
bys plantnum: replace t_group =  second_h if year>f_s_h & year <= s_t_h & f_s_h != .
bys plantnum: replace t_group =  third_h if year>s_t_h & year <= t_f_h & s_t_h != .
bys plantnum: replace t_group =  forth_h if year>t_f_h & year <= f_f_h & t_f_h != .
bys plantnum: replace t_group =  fifth_h if year>f_f_h & year <= f_si_h & f_f_h != .
bys plantnum: replace t_group =  sixth_h if year>f_si_h & year <= s_s_h & f_si_h != .
bys plantnum: replace t_group =  seventh_h if year > s_s_h & s_s_h != .

replace t_group = 0 if t_group == .

xtset plantnum year

* new firm id
egen firm_hike_id = group(plantnum t_group)

********************************************************************************
* Figure C.2: Investment Reivion Effect after a Tax Hike: Alternative Estimators
********************************************************************************

* Preparation for Sun and Abraham Estimator
gen t_group_het = t_group
replace t_group_het = . if t_group_het == 0 

gen never_group = (t_group_het == .)

gen ry = year - t_group_het

forvalues k = 18(-1)2 {
     gen g_`k' = ry == -`k'
}
forvalues k = 0/18 {
     gen g`k' = ry == `k'
}

gen g_1 = 0

did_imputation down_dummy plantnum year t_group_het , fe(plantnum year) h(0/2)  pre(2)  autosample 
matrix C = e(b)
mata st_matrix("A",sqrt(diagonal(st_matrix("e(V)"))))
matrix C = C \ A'
matrix list C
matrix b = C'
matrix r = J(5,2,.)
matrix r[1,1] = b[5,1]
matrix r[2,1] = b[4,1]
matrix r[3,1] = b[1,1]
matrix r[4,1] = b[2,1]
matrix r[5,1] = b[3,1]
matrix r[1,2] = b[5,2]
matrix r[2,2] = b[4,2]
matrix r[3,2] = b[1,2]
matrix r[4,2] = b[2,2]
matrix r[5,2] = b[3,2]

svmat r

eventstudyinteract down_dummy  g_2 g_1 g0-g2 , cohort(t_group_het) control_cohort(never_group) absorb(i.plantnum  i.year)
matrix M = e(b_iw)
mata st_matrix("N",sqrt(diagonal(st_matrix("e(V_iw)"))))
matrix M = M \ N'
matrix list M
matrix s = M'
svmat s

did_imputation logdiff plantnum year t_group_het , fe(plantnum year) h(0/2)  pre(2)  autosample 
matrix C = e(b)
mata st_matrix("A",sqrt(diagonal(st_matrix("e(V)"))))
matrix C = C \ A'
matrix list C
matrix b = C'
matrix t = J(5,2,.)
matrix t[1,1] = b[5,1]
matrix t[2,1] = b[4,1]
matrix t[3,1] = b[1,1]
matrix t[4,1] = b[2,1]
matrix t[5,1] = b[3,1]
matrix t[1,2] = b[5,2]
matrix t[2,2] = b[4,2]
matrix t[3,2] = b[1,2]
matrix t[4,2] = b[2,2]
matrix t[5,2] = b[3,2]

svmat t

eventstudyinteract logdiff  g_2 g_1 g0-g2 , cohort(t_group_het) control_cohort(never_group) absorb(i.plantnum  i.year)
matrix M = e(b_iw)
mata st_matrix("N",sqrt(diagonal(st_matrix("e(V_iw)"))))
matrix M = M \ N'
matrix list M
matrix u = M'
svmat u

gen t = _n - 3

gen t_left = t - 0.12
gen t_right = t + 0.12
gen t_sleft = t - 0.04
gen t_sright = t + 0.04

gen lb_r = r1 - 1.96*t2
gen ub_r = r1 + 1.96*t2

gen lb_s = s1 - 1.96*s2
gen ub_s = s1 + 1.96*s2

gen lb_t = t1 - 1.96*t2
gen ub_t = t1 + 1.96*t2

gen lb_u = u1 - 1.96*u2
gen ub_u = u1 + 1.96*u2

tw (rcap lb_r ub_r t_left, color(navy)) (scatter r1 t_left, color(navy)) (line r1 t_left, color(navy)) (rcap lb_s ub_s t_sleft, color(navy)) (scatter s1 t_sleft, color(navy)) (line s1 t_sleft, color(navy) lp(dash)) (rcap lb_t ub_t t_sright, color(maroon)) (scatter t1 t_sright, color(maroon) ms(S)) (line t1 t_sright, color(maroon)) (rcap lb_u ub_u t_right, color(maroon)) (scatter u1 t_right, color(maroon) ms(S)) (line u1 t_right, color(maroon) lp(dash)) if t < 3 , ylabel(-0.075(0.025)0.075, format(%4.3f)) legend(order(3 "Downward Revision - Borusyak et al." 6 "Downward Revision - Sun and Abraham" 9 "Log Revision Ratio - Borusyak et al." 12 "Log Revision Ratio - Sun and Abraham") cols(1))  yline(0) ytitle("Average Effect") xlabel(-2 "t-2" -1 "t-1" 0 "t0" 1 "t1" 2 "t2")
graph export "${outputpath}\fig_c2.pdf", replace 

********************************************************************************
* Figure 4: Effect of Tax Hike on Investment Plans, Realizations, and Revisions
********************************************************************************

local win wind_3
local outer   (`win' == 1 | t_group == 0)

eststo a : reghdfe l_e_i $x_lbt_hikebin3   if   logdiff != .  & drop_around3 != 1 & `outer'   , absorb(firm_hike_id  year)  vce(cluster ao_gem_2017) 
eststo b : reghdfe l_r_i  $x_lbt_hikebin3   if   logdiff != .  & drop_around3 != 1 & `outer'   , absorb(firm_hike_id year) vce(cluster ao_gem_2017) 
eststo c : reghdfe logdiff  $x_lbt_hikebin3   if  logdiff != . & drop_around3 != 1 & `outer' , absorb(firm_hike_id year  ) vce(cluster ao_gem_2017) // N = 19,822

* reduction of sample size (compared to baseline event study in Figure 3) 
dis (32933 - e(N) ) / 32933 // 40%

coefplot (a, keep(*taxhike*) drop(F3* L3*) offset(-0.1) color(dkgreen) ciopts(color(dkgreen dkgreen)) lp(shortdash)) ///
(b, keep(*taxhike*) drop(F3* L3*) offset(+0.1) color(orange) ciopts(color(orange orange)) lp(longdash) m(S)) ///
(c, keep(*taxhike*) drop(F3* L3*) offset(0) color(maroon) ciopts(color(maroon maroon)) m(S)),  vert drop(_cons) omitted levels(95 90) recast(con) yline(0) ytitle("Estimated Effect Relative to Period t = -1")   ylabel(-0.10(0.025)0.07, format(%4.3f)) rename(F4_bin3taxhike=t-4 F3_bin3taxhike=t-3 F3_taxchange=t-3 F2_bin3taxhike=t-2 F2_taxchange=t-2 F1_bin3taxhike=t-1 F1_taxchange=t-1 L0_bin3taxhike=t0 L0_taxchange=t0 L1_bin3taxhike=t1 L1_taxchange=t1 L2_bin3taxhike=t2 L2_taxchange=t2 L3_bin3taxhike=t3 L3_taxchange=t3 L4_bin3taxhike=t4 )   legend(order(3 "Log Planned Investment" 6 "Log Realized Investment" 9 "Log Revision Ratio")) 
graph export "${outputpath}\fig_4.pdf", replace 

********************************************************************************
* Figure C.1: Long Event Study: Effect of Tax Hike on Investment Plans, Realizations, and Revisions
* Panel B: Log Planned and Realized Investment
********************************************************************************

local win wind_4
local outer   (`win' == 1 | t_group == 0)

eststo a : reghdfe l_e_i $x_lbt_hikebin   if   logdiff != .   & drop_around4 != 1 & `outer'  , absorb(firm_hike_id  year) vce(cluster ao_gem_2017) // 18,049 ; N = 32,933
eststo b : reghdfe l_r_i  $x_lbt_hikebin   if   logdiff != .   & drop_around4 != 1 & `outer'   , absorb(firm_hike_id year)   vce(cluster ao_gem_2017)

coefplot (a, keep(*taxhike*) offset(-0.1) color(dkgreen) ciopts(color(dkgreen dkgreen)) lp(shortdash)) ///
(b, keep(*taxhike*) offset(+0.1) color(orange) ciopts(color(orange orange)) lp(longdash) m(S)) ///
,  vert drop(_cons) omitted levels(95 90) recast(con) yline(0) ytitle("Estimated Effect Relative to Period t = -1")   ylabel(-0.15(0.02)0.09, format(%3.2f)) rename(F4_bintaxhike=t-4 F3_bintaxhike=t-3 F3_taxchange=t-3 F2_bintaxhike=t-2 F2_taxchange=t-2 F1_bintaxhike=t-1 F1_taxchange=t-1 L0_bintaxhike=t0 L0_taxchange=t0 L1_bintaxhike=t1 L1_taxchange=t1 L2_bintaxhike=t2 L2_taxchange=t2 L3_bintaxhike=t3 L3_taxchange=t3 L4_bintaxhike=t4 )   legend(order(3 "Log Planned Investment" 6 "Log Realized Investment")) 
graph export "${outputpath}\fig_c1_b.pdf", replace 
