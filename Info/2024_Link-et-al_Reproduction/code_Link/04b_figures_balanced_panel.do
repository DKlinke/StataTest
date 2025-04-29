use ${datapath}\final_data, replace

********************************************************************************
* Figures with balanced sample
********************************************************************************

* Create Firms Flags for Balanced Panel

gen one = 1
collapse one , by(ao_gem_2017)
save ${datapath}\ags_it_firms, replace

* merge full municipality data
use "${datapath}\Gemeindedaten_ags2017_halfprepared_anonym.dta", replace
merge m:1 ao_gem_2017 using "${datapath}\ags_it_firms"

keep if one == 1

drop if year < 1980 | year > 2018

save "${datapath}\Gemeindedaten_ags2017_halfprepared_firm_sample.dta", replace

********************************************************************************
* Figure B.1: Time Series of Local Scaling Factors by Municipality
********************************************************************************

use "${datapath}\Gemeindedaten_ags2017_halfprepared_firm_sample.dta", replace

xtset ao_gem_2017 year

* combine states
gen com_state = 1 if state == 5 // North Rhine-Westphalia
replace com_state = 2 if state == 3 | state == 4 | state == 2 | state == 1 // Niedersachsen Bremem Hamburg Schleswig-Holstein (Northern Germany)
replace com_state = 3 if state == 7 | state == 10 // Rhineland-Palatinate Saarland
replace com_state = 4 if state == 6 // Hesse
replace com_state = 5 if state == 8 // Baden-Württemberg
replace com_state = 6 if state == 9 // Bavaria

forv st = 1/6 {
	preserve
	drop if year < 1980 | year > 2018

	keep if com_state == `st'

	levelsof ao_gem_2017, local(lev)

	foreach x of local lev {
		qui local customline3 `customline3' (line busitaxm year if ao_gem_2017 == `x' , lcolor(black%10) lw(*.5)) ||
	}

	tw `customline3'  , legend(off) xtitle("") xsize(16) ysize(9) ytitle("Local Scaling Factor")
	graph export "${outputpath}\fig_b1_`st'.png", replace 
	
	restore
}

********************************************************************************
* Figure B.2: Share of Municipalities Increasing the LBT over Time
********************************************************************************
use "${datapath}\Gemeindedaten_ags2017_halfprepared_firm_sample.dta", replace

gen year_r = year - 0.5

gen n = 1
collapse year_r (sum) taxhike n  , by( year)
gen up = 100
gen share = taxhike / n * 100
tw (area up year if year_r >= 1973.5 & year_r <= 1975.5 , lw(0) fcolor(black) fi(*.2)) ///
 (area up year_r if year_r >= 1979.5 & year_r <= 1982.5 , lw(0) fcolor(black) fi(*.2)) ///
 (area up year_r if  year_r >= 1991.5 & year_r <= 1993.5 , lw(0) fcolor(black) fi(*.2)) ///
 (area up year_r if year_r >= 2000.5 & year_r <= 2003.5 , lw(0) fcolor(black) fi(*.2) ) ///
 (area up year_r if year_r >= 2007.5 & year_r <= 2009.5  , lw(0) fcolor(black) fi(*.2)) ///
 (connected share year, color(navy)) , legend(off) xlab(1980(5)2020) ytitle("Share of Treated Municipalities (in %)") xtitle("") xsize(16) ysize(9) ylabel(0(20)100)
graph export "${outputpath}\fig_b2.pdf", replace 

********************************************************************************
* Figure B.3: Number of Tax Hikes and Distribution of Tax Changes
********************************************************************************

* Panel A: Number of Tax Hikes per Municipality
use "${datapath}\Gemeindedaten_ags2017_halfprepared_firm_sample.dta", replace

gen count = 1
collapse (sum) taxhike (sum) n = count ,by(ao_gem_2017)
hist taxhike , fraction disc xtitle("Number of Tax Hikes 1980-2018") wi(.5) lw(0) color(navy) xlabel(0(1)15)
graph export "${outputpath}\fig_b3_a.pdf", replace 

tab n

* Panel B: Distribution of Tax Hikes over Time
use "${datapath}\Gemeindedaten_ags2017_halfprepared_firm_sample.dta", replace

drop if taxchange == 0
drop if taxchange < 0

collapse taxchange (p25) p25_taxchange = taxchange (p75) p75_taxchange = taxchange  (p10) p10_taxchange = taxchange (p90) p90_taxchange = taxchange (p50) p50_taxchange = taxchange ,by(year)

tw (line taxchange year, color(black) lp(dash))  (line p50_taxchange  year , color(navy)) (rarea p25_taxchange p75_taxchange  year , lw(0) color(navy%50)) (rarea p10_taxchange p90_taxchange  year , lw(0) color(navy%20)) , ylabel(0(0.5)3) ytitle("Size of Tax Change") xtitle("") xsize(16) ysize(9) legend(order(1 "Average" 2 "Median" 3 "p25-p75" 4 "p10-p90") cols(4))
graph export "${outputpath}\fig_b3_b.pdf", replace 

********************************************************************************
* Figure B.4: Predictability of Tax Hikes as a Function of Past Tax Hikes in the Same Municipality
********************************************************************************
use "${datapath}\Gemeindedaten_ags2017_halfprepared_firm_sample.dta", replace

gen n = _n - 1
gen b = .
gen lb = .
gen ub = .

gen b_fe = .
gen lb_fe = .
gen ub_fe = .

gen correl = .

replace b = 1 if n == 0
replace lb = 1 if n == 0
replace ub = 1 if n == 0

replace b_fe = 1 if n == 0
replace lb_fe = 1 if n == 0
replace ub_fe = 1 if n == 0


replace correl = 1 if n == 0

xtset ao_gem_2017 year

forv t = 1/20 {
	
	reghdfe f`t'.taxhike  taxhike , noabs vce(cl ao_gem_2017 ) 
	replace b = _b[taxhike] if n == `t'
	replace lb = _b[taxhike] - 1.96*_se[taxhike] if n == `t'
	replace ub = _b[taxhike] + 1.96*_se[taxhike] if n == `t'
	
	reghdfe f`t'.taxhike  taxhike , absorb(ao_gem_2017) vce(cl ao_gem_2017 ) 
	replace b_fe = _b[taxhike] if n == `t'
	replace lb_fe = _b[taxhike] - 1.96*_se[taxhike] if n == `t'
	replace ub_fe = _b[taxhike] + 1.96*_se[taxhike] if n == `t'
	
	corr taxhike  f`t'.taxhike
	replace correl = r(rho) if n == `t'
	
}

sort n
* Panel A: Plain Relation
tw (rarea lb ub n, color(navy%50) lw(0)) (line b n, color(navy))  if n <21 , xtitle("Years after Tax Hike") ytitle("Probability of Tax Hike in X Years") legend(off)
graph export "${outputpath}\fig_b4_a.pdf", replace 

* Panel B: Municipality Fixed Effects
tw (rarea lb_fe ub_fe n, color(navy%50) lw(0)) (line b_fe n, color(navy))  if n <21 , xtitle("Years after Tax Hike") ytitle("Probability of Tax Hike in X Years") legend(off)
graph export "${outputpath}\fig_b4_b.pdf", replace 
