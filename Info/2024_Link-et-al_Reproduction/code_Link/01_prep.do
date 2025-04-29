********************************************************************************
* load z values and merge to local business tax data 
********************************************************************************
use "${datapath}\mb_shares_zvals.dta", replace


merge 1:m year using ${datapath}\Gemeindedaten_agsGesamt_22_10 , nogen

*******************************************************************************
* clean and prepare municipality data
*******************************************************************************

* rename municipality
rename muni2018 ao_gem_2017

* create District ID
gen dis2016 = floor(ao_gem_2017 / 1000)
label var dis2016 "district id"

* create panel data
xtset ao_gem_2017 year

* drop east germany
drop if (state >= 11 & state < 17)

* Construction of final sample: Muni Numbers
distinct ao_gem_2017 if year >= 1980 & year < 2019
* in-text numbers: 326274 municipality x year observations, 8522 municipality observations (App. Page 14)


* drop merged municipalities, following Fuest-Peichl-Siegloch-2018
replace averaged = 0 if averaged == 2
label var averaged "Merged municipality"

by ao_gem_2017: egen merged_muni = max(averaged)

sum ao_gem_2017  if merged_muni != 0

dis 4590 / 326274 
* in-text numbers: 1.4% never-hike (App. Page 14)

drop if merged_muni != 0 

* create tax variables, following Fuest-Peichl-Siegloch
xtset ao_gem_2017 year

gen taxhike = busitaxm > L.busitaxm & L.busitaxm != .
replace taxhike = . if L.busitaxm == .
label variable taxhike "Tax Hike Indicator"


gen taxdrop = busitaxm < L.busitaxm & L.busitaxm != .
replace taxdrop = . if L.busitaxm == .
label variable taxdrop "Tax Drop Indicator"

* number of hikes
egen n_hikes = sum(taxhike) if year >= 1980 & year < 2019 ,by(ao_gem_2017)
label variable n_hikes "Number of Hikes"

gen 	messzahl = 0.05
replace messzahl = 0.035 if year >= 2008
gen taxrate = (busitaxm/100 * messzahl) * 100
gen taxchange = taxrate - L.taxrate  if L.taxrate != .

* new net-of tax
gen log_net = log(1-(taxrate/100)) - log(1-(L.taxrate/100))  if L.taxrate != .

gen muntaxchange = busitaxm - L.busitaxm  if L.busitaxm != .
replace taxchange = 0 if muntaxchange == 0  // only want scaling factor induced changes 
label variable taxchange "Tax Hike in PP"

replace log_net = 0 if taxchange == 0

sum muntaxchange if !mi(muntaxchange) & muntaxchange >0, d

*** Construction of final sample: Share of Tax Decreases in Raw Data
sum taxchange if taxchange != 0  & year >= 1980 & year < 2019
sum taxchange if taxchange < 0 & year >= 1980 & year < 2019 //13.5%
dis 4069 / 30246
* in-text numbers: 13.5% tax decreases (App. Page 14)

drop muntaxchange

local pre_periods = 30 
local post_periods = 30 

foreach v in taxhike  taxchange {
	forval f = `pre_periods'(-1)1 {  // iteriere von 3 rückwärts um 1 bis 1
		sort ao_gem_2017 year
		qui gen F`f'_`v' = F`f'.`v'
	} 

	forval l = 0/`post_periods' {  
		sort ao_gem_2017 year
		qui gen L`l'_`v' = L`l'.`v'
	} 
} 




* cumulative treatment
bys ao_gem_2017: gen cumul_treat = sum(taxhike)

gen bintaxhike = taxhike
gen bintaxchange = taxchange

* binned endperiods (4)
foreach v in bintaxhike   {
	forval f = 4(-1)1 { 
		sort ao_gem_2017 year
		qui gen F`f'_`v' = F`f'.`v'
		gsort ao_gem_2017 -year
		if `f' == 4 bys ao_gem_2017: gen sum_F`f'_`v' = sum(F`f'_`v')
	} //f

	forval l = 0/4 {  
		sort ao_gem_2017 year
		qui gen L`l'_`v' = L`l'.`v'
		if `l' == 4 bys ao_gem_2017: gen sum_L`l'_`v' = sum(L`l'_`v')
	} //l
	
	
	egen sum`v' = rowtotal(F?_`v' L?_`v') 

	replace F4_`v' = sum_F4_`v' if F4_`v' != .
	replace L4_`v' = sum_L4_`v' if L4_`v' != .

	drop sum_*_`v' F1_`v'
	
} 


* binned endperiods (3)

gen bin3taxhike = taxhike

foreach v in bin3taxhike    {
	forval f = 3(-1)1 { 
		sort ao_gem_2017 year
		qui gen F`f'_`v' = F`f'.`v'
		gsort ao_gem_2017 -year
		if `f' == 3 bys ao_gem_2017: gen sum_F`f'_`v' = sum(F`f'_`v')
	} //f

	forval l = 0/3 { 
		sort ao_gem_2017 year
		qui gen L`l'_`v' = L`l'.`v'
		if `l' == 3 bys ao_gem_2017: gen sum_L`l'_`v' = sum(L`l'_`v')
	} //l
	
	
	egen sum`v' = rowtotal(F?_`v' L?_`v') 

	replace F3_`v' = sum_F3_`v' if F3_`v' != .
	replace L3_`v' = sum_L3_`v' if L3_`v' != .

	drop sum_*_`v' F1_`v'
	
} 



* Drop muni with unplausible obs: legal minimum of 200 for local scaling factor
sort ao_gem_2017
egen min_busitaxm = rowmin(busitaxm)
by ao_gem_2017: egen mingew = min(min_busitaxm)
drop if mingew <  200

xtset ao_gem_2017 year

* tax hike after at least 5 years without hike

gen hike_5noyears = 0 if taxhike !=. & l.taxhike != . & l2.taxhike != . & l3.taxhike != . & l4.taxhike != . & l5.taxhike != . 
replace hike_5noyears = 1 if taxhike == 1 & l.taxhike == 0 & l2.taxhike == 0 & l3.taxhike == 0 & l4.taxhike == 0 & l5.taxhike == 0 
label variable hike_5noyears "No Hike in Last 5 Years"


********************************************************************************
* calculate effective marg tax
********************************************************************************

forv r = 5(2)11 {

	gen tax_eff`r' = 1 - ((1 - taxrate/100)/ (1 - (z_weighted`r' * taxrate/100)))
	gen tax_m_eff`r' = 1 - ((1 - taxrate/100)/ (1 - (z_mach`r' * taxrate/100)))
	gen tax_b_eff`r' = 1 - ((1 - taxrate/100)/ (1 - (z_build`r' * taxrate/100)))

	gen l_tax_eff`r' = 1 - ((1 - taxrate/100)/ (1 - (f.z_weighted`r' * taxrate/100)))
	gen l_tax_m_eff`r' = 1 - ((1 - taxrate/100)/ (1 - (f.z_mach`r' * taxrate/100)))
	gen l_tax_b_eff`r' = 1 - ((1 - taxrate/100)/ (1 - (f.z_build`r' * taxrate/100)))


	gen tax_eff_change`r' = (tax_eff`r' - l.l_tax_eff`r')*100
	replace tax_eff_change`r' = 0 if taxhike != 1

	gen tax_m_eff_change`r' = (tax_m_eff`r' - l.l_tax_m_eff`r')*100
	replace tax_m_eff_change`r' = 0 if taxhike != 1

	gen tax_b_eff_change`r' = (tax_b_eff`r' - l.l_tax_b_eff`r')*100
	replace tax_b_eff_change`r' = 0 if taxhike != 1
	
	* user cost of capital
	gen tax_eff`r'_c = (1 - (z_weighted`r' * taxrate/100)) / (1 - taxrate/100)
	gen tax_m_eff`r'_c = (1 - (z_mach`r' * taxrate/100)) / (1 - taxrate/100)
	gen tax_b_eff`r'_c = (1 - (z_build`r' * taxrate/100)) / (1 - taxrate/100)

	gen l_tax_eff`r'_c = (1 - (f.z_weighted`r' * taxrate/100)) / (1 - taxrate/100)
	gen l_tax_m_eff`r'_c = (1 - (f.z_mach`r' * taxrate/100)) / (1 - taxrate/100)
	gen l_tax_b_eff`r'_c = (1 - (f.z_build`r' * taxrate/100)) / (1 - taxrate/100)

	gen tax_eff_change`r'_c = (tax_eff`r'_c - l.l_tax_eff`r'_c)*100
	replace tax_eff_change`r'_c = 0 if taxhike != 1
	label variable tax_eff_change`r'_c "Effective Tax Hike"

	gen tax_m_eff_change`r'_c = (tax_m_eff`r'_c - l.l_tax_m_eff`r'_c)*100
	replace tax_m_eff_change`r'_c = 0 if taxhike != 1

	gen tax_b_eff_change`r'_c = (tax_b_eff`r'_c - l.l_tax_b_eff`r'_c)*100
	replace tax_b_eff_change`r'_c = 0 if taxhike != 1
}

* save data 
save "$datapath\Gemeindedaten_ags2017_halfprepared.dta", replace

* tax change window: No Overlapping
if ${sample} == 2 { 
	xtset ao_gem_2017 year

	gen taxcwin = 0
	replace taxcwin = 1 if (taxchange != 0 & f.taxchange != 0) | (taxchange != 0 & f2.taxchange != 0)  |(taxchange != 0 & l.taxchange != 0)  | (taxchange != 0 & l2.taxchange != 0) 
	gen drop_around = taxcwin
	replace drop_around = 1 if l.taxcwin == 1
	replace drop_around = 1 if l2.taxcwin  == 1
	replace drop_around = 1 if f.taxcwin  == 1
	replace drop_around = 1 if f2.taxcwin  == 1

	keep if drop_around == 0

	drop drop_around
}

* tax hike window: No Overlapping
gen taxhikewin = 0
replace taxhikewin = 1 if (taxhike == 1 & f.taxhike == 1) | (taxhike == 1 & f2.taxhike == 1)  |(taxhike == 1 & l.taxhike == 1)  | (taxhike == 1 & l2.taxhike == 1) 
gen drop_around = taxhikewin
replace drop_around = 1 if l.taxhikewin == 1
replace drop_around = 1 if l2.taxhikewin  == 1
replace drop_around = 1 if f.taxhikewin  == 1
replace drop_around = 1 if f2.taxhikewin  == 1

* 3-3 window
gen taxhikewin3 = 0
replace taxhikewin3 = 1 if (taxhike == 1 & f.taxhike == 1) | (taxhike == 1 & f2.taxhike == 1) | (taxhike == 1 & f3.taxhike == 1) |(taxhike == 1 & l.taxhike == 1)  | (taxhike == 1 & l2.taxhike == 1)  | (taxhike == 1 & l3.taxhike == 1) 

gen drop_around3 = taxhikewin3
replace drop_around3 = 1 if l.taxhikewin3 == 1
replace drop_around3 = 1 if l2.taxhikewin3  == 1
replace drop_around3 = 1 if l3.taxhikewin3  == 1

replace drop_around3 = 1 if f.taxhikewin3  == 1
replace drop_around3 = 1 if f2.taxhikewin3  == 1
replace drop_around3 = 1 if f3.taxhikewin3  == 1

* 4-4 window
gen taxhikewin4 = 0
replace taxhikewin4 = 1 if (taxhike == 1 & f.taxhike == 1) | (taxhike == 1 & f2.taxhike == 1) | (taxhike == 1 & f3.taxhike == 1) | (taxhike == 1 & f4.taxhike == 1)  |(taxhike == 1 & l.taxhike == 1)  | (taxhike == 1 & l2.taxhike == 1)  | (taxhike == 1 & l3.taxhike == 1) | (taxhike == 1 & l4.taxhike == 1) 

gen drop_around4 = taxhikewin4
replace drop_around4 = 1 if l.taxhikewin4 == 1
replace drop_around4 = 1 if l2.taxhikewin4  == 1
replace drop_around4 = 1 if l3.taxhikewin4  == 1
replace drop_around4 = 1 if l4.taxhikewin4  == 1

replace drop_around4 = 1 if f.taxhikewin4  == 1
replace drop_around4 = 1 if f2.taxhikewin4  == 1
replace drop_around4 = 1 if f3.taxhikewin4  == 1
replace drop_around4 = 1 if f4.taxhikewin4  == 1


* drop if tax window overlapping
keep if drop_around == 0
drop drop_around

* tax hike window: No Tax Drops
xtset ao_gem_2017 year

if ${sample} == 1 {
	gen taxdropwin = 0
	replace taxdropwin = 1 if (l2.taxdrop == 1 | l.taxdrop == 1 | taxdrop == 1 | f.taxdrop == 1 | f2.taxdrop == 1)

	keep if taxdropwin == 0 

	drop if taxchange < 0

}


if ${sample} == 2 {
	gen taxdropwin = 0
	replace taxdropwin = 1 if (taxdrop == 1 & f.taxdrop == 1) | (taxdrop == 1 & f2.taxdrop == 1)  |(taxdrop == 1 & l.taxdrop == 1)  | (taxdrop == 1 & l2.taxdrop == 1) 
	gen drop_around_d = taxdropwin
	replace drop_around_d = 1 if l.taxdropwin == 1
	replace drop_around_d = 1 if l2.taxdropwin  == 1
	replace drop_around_d = 1 if f.taxdropwin  == 1
	replace drop_around_d = 1 if f2.taxdropwin  == 1

	keep if drop_around_d == 0

}

* get district typ BBSR for all years
egen dis_type_max = max(dis_type_combined) ,by(ao_gem_2017)

distinct ao_gem_2017 if year >= 1980 & year <= 2018 // 283846 total, 8266 munis

save "$datapath\Gemeindedaten_ags2017_prepared.dta", replace
use "$datapath\Gemeindedaten_ags2017_prepared.dta", replace

