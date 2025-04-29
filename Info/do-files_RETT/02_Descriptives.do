capture close all
capture log close
clear all
set maxvar 100000
set matsize 10000

log using "${logs}\log_02_Descriptives_${today}.log", replace
                 

use ags plz bula quellenname daylast jahr ersterpreis letzterpreis ln_preisqm preisqm pricediff pricediff_pc betrag flaeche zimmeranzahl basement balcony parking kitchen garden baujahr heatingtype centralheat fancy fancyequip quietloc bright popg popgallwp05 popgallwp95 ln_bip ln_pop alq ln_debtpc wmt wmt_agg kreistyp monlast jahr daysposted kreis using "${data}/F_u_B/ifo_etwp_4q19_prep.dta", clear
gen housetype = "etwp"
append using "${data}/F_u_B/ifo_ehp_4q19_prep.dta", keep(ags plz bula quellenname daylast jahr ersterpreis letzterpreis ln_preisqm preisqm pricediff pricediff_pc betrag flaeche zimmeranzahl basement balcony parking kitchen garden baujahr heatingtype centralheat fancy fancyequip quietloc bright popg popgallwp05 popgallwp95 ln_bip ln_pop alq ln_debtpc wmt wmt_agg kreistyp monlast jahr daysposted kreis)
replace housetype = "ehp" if housetype==""
append using "${data}/F_u_B/ifo_mfhp_4q19_prep.dta", keep(ags plz bula quellenname daylast jahr ersterpreis letzterpreis ln_preisqm preisqm pricediff pricediff_pc betrag flaeche zimmeranzahl basement balcony parking kitchen garden baujahr heatingtype centralheat fancy fancyequip quietloc bright popg popgallwp05 popgallwp95 ln_bip ln_pop alq ln_debtpc wmt wmt_agg kreistyp monlast jahr daysposted kreis)
replace housetype = "mfhp" if housetype==""
gen ehp = 0
replace ehp = 1 if housetype == "ehp"
gen etwp = 0
replace etwp = 1 if housetype == "etwp"
gen mfhp = 0
replace mfhp = 1 if housetype == "mfhp"

drop if jahr == .

gen baujahrd = (baujahr <= 1918)
label var baujahrd "Construction year (ordinal indicator)"
replace baujahrd = 2 if baujahr>1918 & baujahr<=1929
replace baujahrd = 3 if baujahr>1929 & baujahr<=1948
replace baujahrd = 4 if baujahr>1948 & baujahr<=1966
replace baujahrd = 5 if baujahr>1966 & baujahr<=1977
replace baujahrd = 6 if baujahr>1977 & baujahr<=1988
replace baujahrd = 7 if baujahr>1988 & baujahr<=1998
replace baujahrd = 8 if baujahr>1998 & baujahr<=2008
replace baujahrd = 9 if baujahr>2008 & baujahr<=2012
replace baujahrd = 10 if baujahr>2012 & baujahr<=2015
replace baujahrd = 11 if baujahr>2015 & baujahr<=2018
replace baujahrd = 12 if baujahr>2018 & baujahr<=2022

gen zimmerd = zimmeranzahl
replace zimmerd = 6 if zimmeranzahl >= 6



*** Figure A.1: Average property prices per square meter, 2005-2019
preserve
	collapse (mean) preisqm, by(jahr housetype)
	drop if jahr == .
	reshape wide preisqm, i(jahr) j(housetype) string

	twoway connected preisqmehp jahr, msymbol(o) || connected preisqmetwp jahr, msymbol(T) ///
	, scheme(s1color) xtitle("Year") legend(label(1 "Single-family houses") label(2 "Apartments")) xlab(2005 (1) 2019, angle(90)) ytitle("Price per square meter (in euros)") ysize(12) xsize(20)
	graph export "${graphs}\avgprice_etwp_ehp.pdf", replace
restore

split quellenname, p(,) gen(quelle)
gen is24 = 0

foreach num of numlist 1(1)10 {
	replace is24 = 1 if quelle`num' == "IS24"
}
label var is24 "ImmoScout 24"


*** Table 2: Real estate data: Full vs. truncated sample
foreach type in etwp ehp mfhp {
	preserve
		keep if `type' == 1
		gen count = 1
		collapse (mean) ersterpreis letzterpreis daysposted flaeche zimmeranzahl baujahr kitchen parking garden balcony basement (sum) count 
		gen ersterpreis_qm = ersterpreis/flaeche
		gen letzterpreis_qm = letzterpreis/flaeche
		tabstat ersterpreis_qm letzterpreis_qm daysposted flaeche zimmeranzahl baujahr kitchen parking garden balcony basement count, stats(mean) 
	restore

	preserve
		keep if `type' == 1 & (popg>= popgallwp05 & popg<=popgallwp95)
		gen count = 1
		collapse (mean) ersterpreis letzterpreis daysposted flaeche zimmeranzahl baujahr kitchen parking garden balcony basement (sum) count 
		gen ersterpreis_qm = ersterpreis/flaeche
		gen letzterpreis_qm = letzterpreis/flaeche
		tabstat ersterpreis_qm letzterpreis_qm daysposted flaeche zimmeranzahl baujahr kitchen parking garden balcony basement count, stats(mean) 
	restore
}


** Table A.1: Real estate data: Summary statistics by data source
/*
foreach num of numlist 0 1 { 
	tabstat ersterpreis letzterpreis daysposted flaeche zimmeranzahl baujahr kitchen parking garden balcony basement if (popg>= popgallwp05 & popg<=popgallwp95) & is24==`num' & etwp == 1, stats(mean count) 
	tabstat ersterpreis letzterpreis daysposted flaeche zimmeranzahl baujahr kitchen parking garden balcony basement if (popg>= popgallwp05 & popg<=popgallwp95) & is24==`num' & ehp == 1, stats(mean count) 
	tabstat ersterpreis letzterpreis daysposted flaeche zimmeranzahl baujahr kitchen parking garden balcony basement if (popg>= popgallwp05 & popg<=popgallwp95) & is24==`num' & mfhp == 1, stats(mean count)
}
*/
foreach type in etwp ehp mfhp {
		preserve
			keep if `type' == 1 & (popg>= popgallwp05 & popg<=popgallwp95) & is24== 0
			gen count = 1
			collapse (mean) ersterpreis letzterpreis daysposted flaeche zimmeranzahl baujahr kitchen parking garden balcony basement (sum) count 
			gen ersterpreis_qm = ersterpreis/flaeche
			gen letzterpreis_qm = letzterpreis/flaeche
			tabstat ersterpreis_qm letzterpreis_qm daysposted flaeche zimmeranzahl baujahr kitchen parking garden balcony basement count, stats(mean) 
		restore
		
		preserve
			keep if `type' == 1 & (popg>= popgallwp05 & popg<=popgallwp95) & is24== 1
			gen count = 1
			collapse (mean) ersterpreis letzterpreis daysposted flaeche zimmeranzahl baujahr kitchen parking garden balcony basement (sum) count 
			gen ersterpreis_qm = ersterpreis/flaeche
			gen letzterpreis_qm = letzterpreis/flaeche
			tabstat ersterpreis_qm letzterpreis_qm daysposted flaeche zimmeranzahl baujahr kitchen parking garden balcony basement count, stats(mean) 
		restore	
}


*** Tables 3 and 4
global files  etwp ehp
foreach file of global files {
	use  daysposted pricediff pricediff_pc buildaged ln_flaeche zimmeranzahl basement balcony parking kitchen garden baujahrd heatingtype centralheat fancy fancyequip quietloc bright wmt* pricechpc jahr plz kreis ags kreistyp monlast ln_bip ln_pop alq ln_debtpc popg popgallwp05 popgallwp95 using "${data}/F_u_B/ifo_`file'_4q19_prep_3624.dta", clear
		
	gen discount = (pricediff < 0)
	gen pricereduc_pc = pricediff_pc if discount == 1
	replace pricereduc_pc = 0 if discount == 0
	
	*** Eisenach (kreis == 16056) does not exist in Gutachterausschuss data. Reason: Since 2021, it belongs to Wartburgkreis (Landkreis) which is kreis == 16063
	replace kreis = 16063 if kreis == 16056
	
	* Merge transaction frequencies from Gutachterausschuss for year 2011
	merge m:1 kreis using "${data}\external_data\GutAcht_Transaction_`file'.dta"
	
	preserve
		keep if popg>= popgallwp05 & popg<=popgallwp95
		keep if jahr <= 2006
		gen N = _N
		collapse (mean)  daysposted pricereduc_pc 
		export excel using "${tables}\Table3_`file'.xlsx", firstrow(variables) replace
	restore
	
	
	preserve
		keep if popg>= popgallwp05 & popg<=popgallwp95
		keep if jahr <= 2006
		gen wmt_growing = (wmt == 4 | wmt == 5)
		collapse (mean) daysposted pricereduc_pc `file'_trans_freq11, by(wmt_growing)
		export excel using "${tables}\Table4_`file'.xlsx", firstrow(variables) replace
	restore
}


log close