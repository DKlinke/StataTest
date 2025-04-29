********************************************************************************
* Figures
********************************************************************************

use ${datapath}\final_data, replace

********************************************************************************
* Figure 2: Relationship between Planned and Realized Investment 
********************************************************************************

gen sample_horse = 1
eststo: reghdfe l_r_i l_e_i l.l_r_i  if taxhike== 0 , absorb(plantnum) vce(cluster plantnum)
replace sample_horse = . if e(sample) != 1

binscatter l_r_i l_e_i if taxhike == 0 &  sample_horse == 1 , n(100)  ms(Oh)   xtitle(log(Planned Investment)) ytitle(log(Realized Investment)) xlabel(10(2)20) ylabel(10(2)20)
graph export "${outputpath}\fig_2.pdf", replace 

********************************************************************************
* Figure 5: Investment Revisions after a Tax Hike: State Dependence
********************************************************************************

* Coefplot Recession Split
eststo clear

eststo estdown_dummy_1: reghdfe down_dummy c.taxhike#i.rec , absorb(plantnum year_X_industry year_X_state) vce(cl ao_gem_2017 ) 
eststo estdown_dummy_2: reghdfe down_dummy c.taxhike#i.rec_y , absorb(plantnum year_X_industry year_X_state) vce(cl ao_gem_2017 ) 

eststo estdown_dummy_3: reghdfe down_dummy c.taxchange#i.rec , absorb(plantnum year_X_industry year_X_state) vce(cl ao_gem_2017 ) 
eststo estdown_dummy_4: reghdfe down_dummy c.taxchange#i.rec_y , absorb(plantnum year_X_industry year_X_state) vce(cl ao_gem_2017 ) 

eststo estlogdiff_1: reghdfe logdiff c.taxhike#i.rec , absorb(plantnum year_X_industry year_X_state) vce(cl ao_gem_2017 ) 
eststo estlogdiff_2: reghdfe logdiff c.taxhike#i.rec_y , absorb(plantnum year_X_industry year_X_state) vce(cl ao_gem_2017 ) 

eststo estlogdiff_3: reghdfe logdiff c.taxchange#i.rec , absorb(plantnum year_X_industry year_X_state) vce(cl ao_gem_2017 ) 
eststo estlogdiff_4: reghdfe logdiff c.taxchange#i.rec_y , absorb(plantnum year_X_industry year_X_state) vce(cl ao_gem_2017 ) 

coefplot (estdown_dummy_1, offset(0) color(navy) nokey) (estdown_dummy_2, offset(0) color(navy) nokey) (estdown_dummy_3, offset(0) color(navy) nokey) (estdown_dummy_4, offset(0) color(navy) nokey)  , bylabel("{bf: Downward Revision}") ciopts(lcolor(navy)) legend(off) level(90) ///
|| (estlogdiff_1, offset(0) mcolor(maroon) ciopts(color(maroon)) nokey) (estlogdiff_2, offset(0)mcolor(maroon) ciopts(color(maroon)) nokey) (estlogdiff_3, offset(0) mcolor(maroon) ciopts(color(maroon)) nokey) (estlogdiff_4, offset(0) mcolor(maroon) ciopts(color(maroon)) nokey) , bylabel("{bf: Log Revision Ratio}")  ///
|| , drop(_cons) byopts(xrescale) baselevels  xlabel(-0.1(0.05)0.1 , labsize(small)) ylabel(,labsize(small)) xline(0)  ///
coeflabels(0.rec#c.taxhike = "No Recession" 1.rec#c.taxhike = "Recession" 0.rec_y#c.taxhike = "No Recession" 1.rec_y#c.taxhike = "Recession" 0.rec#c.taxchange = "No Recession" 1.rec#c.taxchange = "Recession" 0.rec_y#c.taxchange = "No Recession" 1.rec_y#c.taxchange = "Recession", labsize(small)) ///
headings(0.rec#c.taxhike = "{bf: A: Broad Recession Definition  }" ///
0.rec_y#c.taxhike = "{bf: B: Narrow Recession Definition}" ///
0.rec#c.taxchange = "{bf: A: Broad Recession Definition  }" ///
0.rec_y#c.taxchange = "{bf: B: Narrow Recession Definition}", labsize(small)) ///
groups(0.rec#c.taxhike 1.rec_y#c.taxhike = "{bf: Tax Hike Indicator}" ///
	0.rec#c.taxchange 1.rec_y#c.taxchange = "{bf: Tax Hike}", angle(90) labsize(small) gap(2) ) ///
grid(none) legend(off) level(90) norecycle
graph export "${outputpath}\fig_5.pdf", replace 

********************************************************************************
* Figure 6: Testing for Further Heterogeneity
********************************************************************************

eststo clear

eststo estdown_dummy_1: reghdfe down_dummy c.taxhike#i.large_emp , absorb(plantnum year_X_industry year_X_state) vce(cl ao_gem_2017 ) 
eststo estdown_dummy_2: reghdfe down_dummy c.taxhike#i.land , absorb(plantnum year_X_industry year_X_state) vce(cl ao_gem_2017 ) 
eststo estdown_dummy_3: reghdfe down_dummy c.taxhike#i.many_hikes , absorb(plantnum year_X_industry year_X_state) vce(cl ao_gem_2017 ) 
eststo estdown_dummy_4: reghdfe down_dummy c.taxhike#i.hike_5noyears , absorb(plantnum year_X_industry year_X_state) vce(cl ao_gem_2017 ) 
eststo estdown_dummy_6: reghdfe down_dummy c.taxchange#i.large_emp , absorb(plantnum year_X_industry year_X_state) vce(cl ao_gem_2017 ) 
eststo estdown_dummy_7: reghdfe down_dummy c.taxchange#i.land , absorb(plantnum year_X_industry year_X_state) vce(cl ao_gem_2017 ) 
eststo estdown_dummy_8: reghdfe down_dummy c.taxchange#i.many_hikes , absorb(plantnum year_X_industry year_X_state) vce(cl ao_gem_2017 ) 
eststo estdown_dummy_9: reghdfe down_dummy c.taxchange#i.hike_5noyears , absorb(plantnum year_X_industry year_X_state) vce(cl ao_gem_2017 ) 

eststo estlogdiff_1: reghdfe logdiff c.taxhike#i.large_emp , absorb(plantnum year_X_industry year_X_state) vce(cl ao_gem_2017 ) 
eststo estlogdiff_2: reghdfe logdiff c.taxhike#i.land , absorb(plantnum year_X_industry year_X_state) vce(cl ao_gem_2017 ) 
eststo estlogdiff_3: reghdfe logdiff c.taxhike#i.many_hikes , absorb(plantnum year_X_industry year_X_state) vce(cl ao_gem_2017 ) 
eststo estlogdiff_4: reghdfe logdiff c.taxhike#i.hike_5noyears , absorb(plantnum year_X_industry year_X_state) vce(cl ao_gem_2017 ) 
eststo estlogdiff_6: reghdfe logdiff c.taxchange#i.large_emp , absorb(plantnum year_X_industry year_X_state) vce(cl ao_gem_2017 ) 
eststo estlogdiff_7: reghdfe logdiff c.taxchange#i.land , absorb(plantnum year_X_industry year_X_state) vce(cl ao_gem_2017 ) 
eststo estlogdiff_8: reghdfe logdiff c.taxchange#i.many_hikes , absorb(plantnum year_X_industry year_X_state) vce(cl ao_gem_2017 ) 
eststo estlogdiff_9: reghdfe logdiff c.taxchange#i.hike_5noyears , absorb(plantnum year_X_industry year_X_state) vce(cl ao_gem_2017 ) 

coefplot (estdown_dummy_1, offset(0) color(navy) nokey) (estdown_dummy_2, offset(0) color(navy) nokey) (estdown_dummy_3, offset(0) color(navy) nokey) (estdown_dummy_4, offset(0) color(navy) nokey)  (estdown_dummy_6, offset(0) color(navy) nokey) (estdown_dummy_7, offset(0) color(navy) nokey) (estdown_dummy_8, offset(0) color(navy) nokey) (estdown_dummy_9, offset(0) color(navy) nokey)  , bylabel("{bf: Downward Revision}") ciopts(lcolor(navy)) legend(off) level(90) ///
|| (estlogdiff_1, offset(0) mcolor(maroon) ciopts(color(maroon)) nokey) (estlogdiff_2, offset(0) mcolor(maroon) ciopts(color(maroon)) nokey) (estlogdiff_3, offset(0) mcolor(maroon) ciopts(color(maroon)) nokey) (estlogdiff_4, offset(0) mcolor(maroon) ciopts(color(maroon)) nokey)  (estlogdiff_6, offset(0) mcolor(maroon) ciopts(color(maroon)) nokey) (estlogdiff_7, offset(0) mcolor(maroon) ciopts(color(maroon)) nokey) (estlogdiff_8, offset(0) mcolor(maroon) ciopts(color(maroon)) nokey) (estlogdiff_9, offset(0) mcolor(maroon) ciopts(color(maroon)) nokey)  , bylabel("{bf: Log Revision Ratio}")  ///
|| , drop(_cons) byopts(xrescale) baselevels  xlabel(-0.1(0.05)0.1 , labsize(vsmall)) ylabel(,labsize(vsmall)) xline(0)  ///
coeflabels(0.large_emp#c.taxhike = "Small Firms" 1.large_emp#c.taxhike = "Large Firms" 0.land#c.taxhike = "Urban Area" 1.land#c.taxhike = "Rural Area" 0.many_hikes#c.taxhike = "Few Tax Hikes" 1.many_hikes#c.taxhike = "Many Tax Hikes" 0.hike_5noyears#c.taxhike = "At least 1 Hike in Last 5 Years" 1.hike_5noyears#c.taxhike = "No Hike in Last 5 Years"  0.large_emp#c.taxchange = "Small Firms" 1.large_emp#c.taxchange = "Large Firms" 0.land#c.taxchange = "Urban Area" 1.land#c.taxchange = "Rural Area" 0.many_hikes#c.taxchange = "Few Tax Hikes" 1.many_hikes#c.taxchange = "Many Tax Hikes" 0.hike_5noyears#c.taxchange = "At least 1 Hike in Last 5 Years" 1.hike_5noyears#c.taxchange = "No Hike in Last 5 Years" , labsize(vsmall)) ///
headings(0.large_emp#c.taxhike = "{bf: A: Firm Size                                                          }" ///
0.land#c.taxhike = "{bf: B: Settlement Structure                                       }" ///
0.many_hikes#c.taxhike = "{bf: C: Frequency of Tax Hikes                                  }" ///
0.hike_5noyears#c.taxhike = "{bf: D: Occurence of a Tax Hike in the Last 5 Years}" ///
0.large_emp#c.taxchange = "{bf: A: Firm Size                                                          }" ///
0.land#c.taxchange = "{bf: B: Settlement Structure                                       }" ///
0.many_hikes#c.taxchange = "{bf: C: Frequency of Tax Hikes                                  }" ///
0.hike_5noyears#c.taxchange = "{bf: D: Occurence of a Tax Hike in the Last 5 Years}" ///
, labsize(vsmall) ) ///
groups(0.large_emp#c.taxhike 1.hike_5noyears#c.taxhike = "{bf: Tax Hike Indicator}" ///
	0.large_emp#c.taxchange 1.hike_5noyears#c.taxchange = "{bf: Tax Hike}", angle(90) labsize(vsmall) gap(2) ) ///
grid(none) legend(off) msize(small) level(90) norecycle
graph export "${outputpath}\fig_6.pdf", replace

********************************************************************************
* Figure B.5: Distribution of Firms by Number of Employees
********************************************************************************

* Panel A: Linear Scale
hist be_winz , xtitle("Number of Employees (winzorized)") lw(0) color("navy") xline(264)
graph export "${graphs}\fig_b5_a.pdf", replace 

* Panel B: Log Scale
hist ln_emp  , xlabel( 3.912 "50"  5.576 "p50=264"   6.908 "1000" 8.517 "5000" ) xtitle("Number of Employees (log scale)") lw(0) color("navy")
graph export "${outputpath}\fig_b5_b.pdf", replace 

********************************************************************************
* Figure B.6: Time-Series of Investment Plans and Realizations
********************************************************************************
* year for recession shades
gen year_r = year - 0.5

preserve

gen up = 15

* generate log investment levels
gen l_e = ln(expec_inv)
gen l_i = ln(reali_inv)
keep if l_e !=. & l_i != . & logdiff != .
collapse l_e l_i year_r up (sem) se_e = l_e se_i = l_i, by(year)
gen ub_e = l_e + invnormal(0.975)*se_e
gen lb_e = l_e - invnormal(0.975)*se_e
gen ub_i = l_i + invnormal(0.975)*se_i
gen lb_i = l_i - invnormal(0.975)*se_i

tw (area up year if year_r >= 1973.5 & year_r <= 1975.5 , lw(0) fcolor(black) fi(*.2)) ///
 (area up year_r if year_r >= 1979.5 & year_r <= 1982.5 , lw(0) fcolor(black) fi(*.2)) ///
 (area up year_r if  year_r >= 1991.5 & year_r <= 1993.5 , lw(0) fcolor(black) fi(*.2)) ///
 (area up year_r if year_r >= 2000.5 & year_r <= 2003.5 , lw(0) fcolor(black) fi(*.2) ) ///
 (area up year_r if year_r >= 2007.5 & year_r <= 2009.5  , lw(0) fcolor(black) fi(*.2)) ///
 (line l_e year, color(navy) lp(dash)) (rarea lb_e ub_e year, color(navy%20) lw(0)) ///
  (line l_i year, color(navy)) (rarea lb_i ub_i year, color(navy%50) lw(0)) ///
 , ytitle("Log Investment")  ylab(13(0.5)15,format(%3.1f)) xlab(1980(5)2020)  xtitle("") xsize(16) ysize(9) legend(order(6 "Log Planned Investment"  8 "Log Realized Investment"))
graph export "${outputpath}\fig_b6.pdf", replace 
restore

********************************************************************************
* Figure B.7: Time-Series of Investment Revisions
********************************************************************************

* Inv Revisions
preserve

gen up = 1

collapse down_dummy logdiff year_r up rec (sem) se_dd = down_dummy se_ld = logdiff , by(year)
gen ub = down_dummy + invnormal(0.975)*se_dd
gen lb = down_dummy - invnormal(0.975)*se_dd
gen ub2 = logdiff + 2*se_ld
gen lb2 = logdiff - 2*se_ld
drop if year < 1970
tw (area up year if year_r >= 1973.5 & year_r <= 1975.5 , lw(0) fcolor(black) fi(*.2)) ///
 (area up year_r if year_r >= 1979.5 & year_r <= 1982.5 , lw(0) fcolor(black) fi(*.2)) ///
 (area up year_r if  year_r >= 1991.5 & year_r <= 1993.5 , lw(0) fcolor(black) fi(*.2)) ///
 (area up year_r if year_r >= 2000.5 & year_r <= 2003.5 , lw(0) fcolor(black) fi(*.2) ) ///
 (area up year_r if year_r >= 2007.5 & year_r <= 2009.5  , lw(0) fcolor(black) fi(*.2)) ///
(line down_dummy year, color(navy)) (rarea lb ub year, color(navy%20) lw(0)) (line logdiff year, yaxis(2) color(maroon) lp (longdash)) (rarea lb2 ub2 year, color(maroon%20) lw(0) yaxis(2)) , ytitle("Downward Revision") ytitle("Log Revision Ratio" ,axis(2)) ylab(,format(%3.1f) axis(2)) ylab(,format(%3.1f)) xlab(1980(5)2020) legend(order(6 "Downward Revision"  8 "Log Revision Ratio")) xtitle("") xsize(16) ysize(9)
graph export "${outputpath}\fig_b7.pdf", replace 
restore

********************************************************************************
* Figure B.8: Time-Series of Share of Large Revenue Drops
********************************************************************************

xtset plantnum year

preserve

gen up = 1

collapse rec up year_r umsatzdropf (sem) se_rev = umsatzdropf  , by(year)
gen ub = umsatzdropf + invnormal(0.975)*se_rev
gen lb = umsatzdropf - invnormal(0.975)*se_rev

tw (area up year if year_r >= 1973.5 & year_r <= 1975.5 , lw(0) fcolor(black) fi(*.2)) ///
 (area up year_r if year_r >= 1979.5 & year_r <= 1982.5 , lw(0) fcolor(black) fi(*.2)) ///
 (area up year_r if  year_r >= 1991.5 & year_r <= 1993.5 , lw(0) fcolor(black) fi(*.2)) ///
 (area up year_r if year_r >= 2000.5 & year_r <= 2003.5 , lw(0) fcolor(black) fi(*.2) ) ///
 (area up year_r if year_r >= 2007.5 & year_r <= 2009.5  , lw(0) fcolor(black) fi(*.2)) ///
 (line umsatzdropf year, color(navy)) (rarea lb ub year, color(navy%20) lw(0)) , ytitle("Share of Firms with more than 10% Decline in Revenues")  ylab(,format(%3.1f)) xlab(1980(5)2020) legend(off) xtitle("") xsize(16) ysize(9)
graph export "${outputpath}\fig_b8.pdf", replace 
restore

********************************************************************************
* Figure B.9: Distribution of the Log Revision Ratio
********************************************************************************

hist logdiff , color(navy) lw(0) xlabel(-3(1)3) xtitle("Log Revision Ratio")
graph export "${outputpath}\fig_b9.pdf", replace 

********************************************************************************
* Figure C.6: Obstacles to Investment by Firm Size
********************************************************************************

* Panel A
binscatter fin_p log_avg_emp , by(rec)  ylabel(0(0.05)0.4) ytitle("Share of firms reporting strongly hampered" "investment due to financing situation") xtitle("Log Employment") legend(order(1 "No Recession" 2 "Recession"))
graph export "${outputpath}\fig_c6_a.pdf", replace 

* Panel B
binscatter prof_p log_avg_emp , by(rec) ylabel(0(0.05)0.4) ytitle("Share of firms reporting strongly hampered" "investment due to earnings situation") xtitle("Log Employment") legend(order(1 "No Recession" 2 "Recession"))
graph export "${outputpath}\fig_c6_b.pdf", replace 

********************************************************************************
* Figure E.3: 
********************************************************************************

* upper-left
tw  (scatter tax_eff_change7 taxchange  ,msiz(*.5) color(navy%50) mlw(0) )  , ytitle("Effective Tax Hike") ylabel(0(0.5)2)
graph export "${outputpath}\fig_e3_a.png", replace

* upper-right
tw  (scatter tax_eff_change11 taxchange  ,msiz(*.5) color(navy%50) mlw(0) )  , ytitle("Effective Tax Hike") ylabel(0(0.5)2)
graph export "${outputpath}\fig_e3_b.png", replace

* lower-left
tw  (scatter tax_firm_com_eff_change7 taxchange  ,msiz(*.5) color(navy%50) mlw(0) )  , ytitle("Effective Tax Hike") ylabel(0(0.5)2)
graph export "${outputpath}\fig_e3_c.png", replace

* lower-right
tw  (scatter tax_firm_com_eff_change11 taxchange  ,msiz(*.5) color(navy%50) mlw(0) )  , ytitle("Effective Tax Hike") ylabel(0(0.5)2)
graph export "${graphs}\fig_e3_d.png", replace

********************************************************************************
* Figure E.4: Relation of Changes in Effective Tax Rates and Changes in User Cost of Capital
********************************************************************************

* Panel A: Time-constant discount rate (7%)
tw  (scatter tax_eff_change7_c tax_eff_change7  ,msiz(*.5) color(navy%50) mlw(0) )  , ytitle("Change in User Cost of Capital") xtitle("Effective Tax Hike") ylabel(0(0.5)2)
graph export "${outputpath}\fig_e4_a.png", replace

* Panel B: Time-varying discount rate
tw  (scatter tax_eff_change11_c tax_eff_change11  ,msiz(*.5) color(navy%50) mlw(0) )  , ytitle("Change in User Cost of Capital") xtitle("Effective Tax Hike") ylabel(0(0.5)2)
graph export "${outputpath}\fig_e4_b.png", replace
