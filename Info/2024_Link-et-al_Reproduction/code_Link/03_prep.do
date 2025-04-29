* load prepared data

use ${datapath}\linked_it_gemeindedaten_prepared, clear

keep if year >= 1980

********************************************************************************
* Sample Adjustments
********************************************************************************

* generate log of diff
gen logdiff = log(diff)
label variable logdiff "Log Revision Ratio"

gen ld_p1 = .
gen ld_p99 = .

* drop outlier
forv y = 1980/2018 {
	sum logdiff if year == `y', d // 1%: -2.55, 5%: -1.43, 95% 1.38, 99% 2.66
	replace ld_p1 = r(p1) if year == `y'
	replace ld_p99 = r(p99) if year == `y'
}

* set outlier values to missing
replace logdiff = . if logdiff < ld_p1
replace logdiff = . if logdiff > ld_p99

xtset plantnum year

* generate down dummy
gen down_dummy = (diff < 1) if !missing(diff)
label variable down_dummy "Downward Revision"

* tax hike window: No Overlapping
xtset plantnum year

* at least 5 Firm Obs.
egen n_f = count(down_dummy) , by(plantnum)
label variable n_f "Downward Revision Observations per Firm"

drop if n_f < 5

xtset plantnum year

* define recession years
gen rec = 0
replace rec = 1 if year == 1974 | year == 1975 | year == 1980 | year == 1981 | year == 1982 | year == 1992 | year == 1993 | year == 2001 | year == 2002| year == 2003 | year == 2008 | year == 2009 
label variable rec "Indicator for Recession"

* drop singletons to have the same sample for the baseline regressions

drop if down_dummy == . | taxhike == .

eststo: reghdfe down_dummy c.taxhike#i.rec , absorb(plantnum year_X_industry year_X_state) vce(cl ao_gem_2017 ) 

br down_dummy taxhike plantnum state branche year_X_industry year_X_state if e(sample) != 1

drop  if e(sample) != 1

eststo: reghdfe logdiff taxhike , absorb(plantnum year_X_industry year_X_state) vce(cl ao_gem_2017 ) 

replace logdiff = . if e(sample) != 1


********************************************************************************
* Create further variables
********************************************************************************

* create employee dummies
gen large_emp = .
replace large_emp = 0 if avg_emp != . & avg_emp < 250
replace large_emp = 1 if avg_emp != . & avg_emp >= 250
label variable large_emp "Large Firm Indicator (>= 250 Employees)"

* financing cond
gen fin_p = .
replace fin_p = 0 if efak_finanz_dj != .
replace fin_p = 1 if efak_finanz_dj == 5
label variable fin_p "Financial Conditions Strongly Hampered Investment (Current Year)"

* profits 
gen prof_p = .
replace prof_p = 0 if efak_ertrag_dj != .
replace prof_p = 1 if efak_ertrag_dj == 5
label variable prof_p "Profit Situation Strongly Hampered Investment (Current Year)"

* log average employees 
gen log_avg_emp = ln(avg_emp)
label variable log_avg_emp "Log Average Employees"

* rural vs urban
gen land = (dis_type_max == 3 | dis_type_max == 4) if dis_type_max != .
label variable land "Indicator for Rural Area"

* sd deviation of revenue growth
gen gr_rev = (revenues - l.revenues) / l.revenues
egen sd_gr_inv = sd(gr_rev) , by(plantnum)

sum sd_gr_inv ,d
gen high_sd_gr_rev = (sd_gr_inv > r(p50)) if sd_gr_inv != .
label variable high_sd_gr_rev "Indicator for High Revenue Growth Volatility"

xtset plantnum year

* employment drop
gen emp_change = (f.besch_lj - besch_lj) / besch_lj

* winzorised employees (last year)
gen be_winz = besch_lj
replace be_winz = 4000 if besch_lj > 4000 & besch_lj != .

gen ln_emp = ln(besch_lj)
label variable high_sd_gr_rev "Log Employees (Last Year)"

* number of hikes as policy uncertainty
gen many_hikes = (n_hikes > 3) if n_hikes != .
label variable many_hikes "Many Tax Hikes (>3)"

* gen negative agg. growth in the year (world bank data)
gen rec_y = 0
replace rec_y = 1 if year == 1982 | year ==1993 | year == 2002 | year == 2003 | year == 2009
label variable rec_y "Indicator for Recession (Alternative Definition)"

* firm-specific effective tax rate
* calculate shares of machinery and building inv
egen inv_b_mean = mean(invbb_lj)  if invgm_lj != . &  invbb_lj != . & invges_lj != ., by(plantnum) 
egen inv_m_mean = mean(invgm_lj)  if invgm_lj != . &  invbb_lj != . & invges_lj != ., by(plantnum)
gen sum_i = inv_b_mean + inv_m_mean

gen share_m = inv_m_mean / sum_i
gen share_b = inv_b_mean / sum_i

egen n_bm = count(sum_i) , by(plantnum)

egen avg_share_m = max(share_m) if n_bm >= 3 , by(plantnum)
egen avg_share_b = max(share_b) if n_bm >= 3 , by(plantnum)

* firm specific eff tax change
foreach r in 7 11 {

	gen tax_firm_eff_change`r' = (avg_share_m*tax_m_eff_change`r') +  (avg_share_b*tax_b_eff_change`r')
	label variable rec_y "Effective Tax Change (Agg. Inv. Shares)"

	gen tax_firm_com_eff_change`r' = tax_firm_eff_change`r'
	replace tax_firm_com_eff_change`r' = tax_eff_change`r' if tax_firm_com_eff_change`r' == .
	
	label variable rec_y "Effective Tax Change (Firm-Specific Inv. Shares)"

}

* firm specific user cost of capital
foreach r in 7 11 {

	gen tax_firm_eff_change`r'_c = (avg_share_m*tax_m_eff_change`r'_c) +  (avg_share_b*tax_b_eff_change`r'_c)
	label variable rec_y "User Cost Change (Agg. Inv. Shares)"

	gen tax_firm_com_eff_change`r'_c = tax_firm_eff_change`r'_c
	replace tax_firm_com_eff_change`r'_c = tax_eff_change`r'_c if tax_firm_com_eff_change`r'_c == .
	label variable rec_y "User Cost Change (Firm-Specific Inv. Shares)"

}

* revenues and investment in thousands
gen rev_k = revenues / 1000
label variable revenues "Revenues in k (this year)"
 
gen reali_inv_k = reali_inv / 1000
label variable revenues "Investment in k (this year)"

* observations per firm
egen obs_f = count(down_dummy) , by(plantnum)
label variable obs_f "Observations per Firm"

* log expected and realized investment (and lags)
gen l_e_i = ln(expec_inv)
gen l_r_i = ln(reali_inv)

xtset plantnum year
gen l_l_e_i = l.l_e_i
gen l_l_r_i = l.l_r_i

label variable l_r_i "Log(Realized Investment)"
label variable l_e_i "Log(Planned Investment)"
label variable l_l_r_i "Log(Realized Investment) Lagged"
label variable l_l_e_i "Log(Planned Investment) Lagged"

* Municipality Revenues and Expenditures
xtset plantnum year

* Indicator for an Increase in Revenues
gen hh_rev_incr = (rev_tot - l.rev_tot > 0) if rev_tot != . & l.rev_tot != .
label variable hh_rev_incr "Indicator for an Increase in Revenues (Municipality)"

* Indicator for an Increase in Expenditures
gen hh_exp_incr = (exp_tot - l.exp_tot > 0) if exp_tot != . & l.exp_tot != .
label variable hh_exp_incr "Indicator for an Increase in Expenditures (Municipality)"

gen log_hhrev = ln(rev_tot)
label variable log_hhrev "Log Revenues (Municipality)"

gen log_hhexp = ln(exp_tot)
label variable log_hhexp "Log Expenditures (Municipality)"


save ${datapath}\final_data, replace
