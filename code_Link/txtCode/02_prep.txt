
*******************************************************************************
* merge Investment Test
*******************************************************************************
use "$datapath\Gemeindedaten_ags2017_prepared_anonym.dta", replace

merge 1:m ao_gem_2017 year using "$datapath\it_ags_2019_raw_anonym"

label variable ao_gem_2017 "municipality id (anonymized)"

drop if _merge != 3

local dropdrops z_mach* z_build* share_build share_mach z_weighted* tax_eff* tax_m_eff* tax_b_eff* l_tax_eff* l_tax_m_eff* l_tax_b_eff*  tax_eff_change* tax_m_eff_change* tax_b_eff_change* n_hikes   hike_5noyears  

keep `dropdrops' drop_around* mingew  _merge dis2016  merged_muni F* L* taxrate averaged taxdrop  taxhike taxchange cumul_treat log_net ao_gem_2017  year state   agrataxm proptaxm busitaxm rev_tot rev_tax rev_fedtrans rev_fees rev_contrib rev_inv rev_credit exp_tot exp_personell exp_materials exp_redempt exp_invest exp_netexpenses tax_sharePIT tax_shareVAT tax_totrev_agri tax_totrev_prop tax_totrev_busi tax_basic_agri tax_basic_prop tax_basic_busi tax_busi_trans tax_rev_busi popul unemp   dis_unempr dis_unemp  dis_type_fine dis_type_combined dis_type_max ///
	waehr  plantnum idnum season westeast branche sector_wz93 sector_wz03 sector_wz08 invges_* invbb_* invgm_* umsatz_* fedsta umsatz_* besch_* invbb_* invgm_* kaperw* umstr* rat* ersb* andinv_*  ziel* invf_k* efak_rahmen* efak_finanz*  efak_*
save ${datapath}\linked_it_gemeindedaten, replace

*******************************************************************************
* clean and prepare linked data
*******************************************************************************

use ${datapath}\linked_it_gemeindedaten, clear

* drop few duplicates (exactly identical)
duplicates tag year season plantnum, gen(a)
drop if a == 1 
drop a

* merge cpi index
drop _merge
merge m:1 year using "${datapath}\cpi"
keep if _merge == 3
drop _merge

* calculate real values in 2015 €
foreach var in invges_lj invbb_lj invgm_lj umsatz_lj  {
	replace `var' = `var' / 1.95583 if waehr == 2 | waehr == 3  // DM to Euro
	replace `var' = `var' * 1000								// 1k to 1000
	replace `var' = `var' / (lag_cpi/100)						// inflation adjusted
}
foreach var in  invges_nj  invges_dj {
	replace `var' = `var' / 1.95583 if waehr == 2 | waehr == 3  // DM to Euro
	replace `var' = `var' * 1000								// 1k to 1000
	replace `var' = `var' / (cpi/100)							// inflation adjusted
}

* only keep autmn value for inv this year
replace invges_dj = . if season != 2

* from biannual to one observation per year

foreach var in invges_lj invges_nj invges_dj invgm_lj invbb_lj umsatz_lj besch_lj ziel1_dj  kaperw_nj umstr_nj rat_nj ersb_nj andinv_nj efak_rahmen_dj efak_finanz_dj efak_finanz_nj efak_ertrag_dj efak_ertrag_nj ///
				 invges_nj2 invges_nj3  {
	egen num_`var' = count(`var'), by(plantnum year)
	su num_`var' 															
	egen mean_`var' = mean(`var'), by(plantnum year)
	if `var' == invges_lj {
	gen dev_`var' = (`var'-mean_`var')/mean_`var'    if num_`var' == 2
	egen deviation_`var' = max(abs(dev_`var')) , by(plantnum year)
	replace mean_`var' = . if (deviation_`var' < -.2 | deviation_`var' > .2) & `var' == invges_lj  & deviation_`var' != .  //drop if deviation is greater than 20% 
	}
	replace `var' = mean_`var'
	drop mean_`var'
}

foreach var in branche {
	egen max_`var' = max(`var'), by(plantnum year)
	replace `var' = max_`var'
	drop max_`var'
}

sort plantnum year

* now, collapse the data from biannual to annual
duplicates drop year plantnum, force

xtset plantnum year

*******************************************************************************
* Generate Variables
*******************************************************************************

* adjust year
gen inv_total = f.invges_lj
label variable inv_total "Total Investment (this year)"

gen inv_buildings = f.invbb_lj
label variable inv_buildings "Building Investment (this year)"

gen inv_machinery = f.invgm_lj
label variable inv_machinery "Machinery Investment (this year)"

gen revenues = f.umsatz_lj
label variable revenues "Revenues (this year)"

gen emply = f.besch_lj
label variable emply "Employees (this year)"

* generate next year investments (before 2005 only in percent of current year)
gen invges_nj_imput = invges_dj if invges_nj2 == 2
replace invges_nj_imput = invges_dj * (1+invges_nj3/100) if invges_nj2 == 1
replace invges_nj_imput = invges_dj * (1-invges_nj3/100) if invges_nj2 == 3

replace invges_nj = invges_nj_imput if invges_nj == .

* generate revision variable 
bys plantnum: gen expec_inv = l.invges_nj 
label variable expec_inv "Investment Plans (for this year)"

bys plantnum: gen reali_inv = f.invges_lj
label variable reali_inv "Investment Realization (for this year)"

* create main dep. var.
gen diff = reali_inv / expec_inv
label variable diff "Investment Revision"

order plantnum year season

bys plantnum: gen count = _n

* add rechtsformen
cap drop _merge
merge m:1 idnum using ${datapath}\rechtsformen
label variable rechtsform "Rechtsform"
drop if _merge != 3

xtset plantnum year

* average number of employees
egen avg_emp = mean(besch_lj) , by(plantnum)
label variable avg_emp "Average Employees"

* generate FEs interacted with year

egen year_X_state = group(state year)
label variable year_X_state "Year X State id"
egen year_X_industry = group(year branche)
label variable year_X_industry "Year X Industry id"
egen year_X_industry_X_state = group(year branche state)
label variable year_X_industry_X_state "year X State Y Industry id"

* create log variables

gen log_inv_total = log(inv_total)
label variable log_inv_total "Log Total Investment (this year)"

gen log_rev = log(revenues)
label variable log_rev "Log Revenues (this year)"

gen log_emply = log(emply) 
label variable log_emply "Log Employees (this year)"

* revenue drop
gen umsatzdropf = ((f.umsatz_lj-umsatz_lj) / umsatz_lj < -0.1) if f.umsatz_lj != . & umsatz_lj != .
label variable umsatzdropf "Indicator for Large Decrease in Revenues in the Current Year"

* only keep corporate firms
tab rechtsform
* in-text numbers: 6.2% have legal forms which are exemot from paying the LBT (App. Page 14)

drop if rechtsform != 1 

* exclude 2019 (no realization data)
drop if year > 2018

save ${datapath}\linked_it_gemeindedaten_prepared, replace

