capture close all
capture log close
clear all
set maxvar 100000
set matsize 10000
log using "${logs}\log_03_Eventstudy_prices_${today}.log", replace






			
global prereftax17 prereftax_1724_17 prereftax_1724_16 prereftax_1724_15 prereftax_1724_14 prereftax_1724_13 ///
 					prereftax_1724_12 prereftax_1724_11 prereftax_1724_10 prereftax_1724_9 prereftax_1724_8 prereftax_1724_7 prereftax_1724_6 prereftax_1724_5 prereftax_1724_3 prereftax_1724_2 prereftax_1724_1 					
global postreftax postreftax_1224_0 postreftax_1224_1 postreftax_1224_2 postreftax_1224_3 postreftax_1224_4 postreftax_1224_5 postreftax_1224_6 postreftax_1224_7 postreftax_1224_8 postreftax_1224_9 postreftax_1224_10 postreftax_1224_11 postreftax_1224_12 ///
				  postreftax_1224_13 postreftax_1224_14 postreftax_1224_15 postreftax_1224_16 postreftax_1224_17 postreftax_1224_18 postreftax_1224_19 postreftax_1224_20 postreftax_1224_21 postreftax_1224_22 postreftax_1224_23 		  

				  
global prereflntax17   prereflntax_1724_17 prereflntax_1724_16 prereflntax_1724_15 prereflntax_1724_14 prereflntax_1724_13 ///
					prereflntax_1724_12 prereflntax_1724_11 prereflntax_1724_10 prereflntax_1724_9 prereflntax_1724_8 prereflntax_1724_7 prereflntax_1724_6 prereflntax_1724_5 prereflntax_1724_3 prereflntax_1724_2 prereflntax_1724_1 
global postreflntax postreflntax_1224_0 postreflntax_1224_1 postreflntax_1224_2 postreflntax_1224_3 postreflntax_1224_4 postreflntax_1224_5 postreflntax_1224_6 postreflntax_1224_7 postreflntax_1224_8 postreflntax_1224_9 postreflntax_1224_10 postreflntax_1224_11 postreflntax_1224_12 ///
					postreflntax_1224_13 postreflntax_1224_14 postreflntax_1224_15 postreflntax_1224_16 postreflntax_1224_17 postreflntax_1224_18 postreflntax_1224_19 postreflntax_1224_20 postreflntax_1224_21 postreflntax_1224_22 postreflntax_1224_23 
				
global ctrl1 ln_flaeche i.zimmeranzahl basement balcony parking kitchen garden i.baujahrd


global depvars  ln_preisqm



global files  etwp ehp


if $Figure1 == 1 {
	
	global graphinput all_noctrl_ife 
	use $depvars Nnachbar $prereftaxnb $postreftaxnb flaeche ersterpreis ort daysposted pricediff pricediff_pc $prereform $postreform $prereftax17 prereftax_1224_4 $postreftax $prereflntax $postreflntax buildaged ln_flaeche zimmeranzahl basement balcony parking kitchen garden baujahrd heatingtype centralheat fancy fancyequip quietloc bright  wmt* pricechpc jahr plz kreis ags bula betrag preisqm kreistyp monlast popg popgallwp05 popgallwp95 ln_bip ln_pop alq ln_debtpc using "${data}/F_u_B/ifo_etwp_4q19_prep_3624.dta", clear      
	gen housetype = "etwp"
	append using "${data}/F_u_B/ifo_ehp_4q19_prep_3624.dta", keep($depvars Nnachbar $prereftaxnb $postreftaxnb flaeche ersterpreis ort daysposted pricediff pricediff_pc $prereform $postreform $prereftax17 prereftax_1224_4 $postreftax $prereflntax $postreflntax buildaged ln_flaeche zimmeranzahl basement balcony parking kitchen garden baujahrd heatingtype centralheat fancy fancyequip quietloc bright  wmt* pricechpc jahr plz kreis ags bula betrag preisqm kreistyp monlast popg popgallwp05 popgallwp95 ln_bip ln_pop alq ln_debtpc)
	replace housetype = "ehp" if housetype==""
	append using "${data}/F_u_B/ifo_mfhp_4q19_prep_3624.dta",keep($depvars Nnachbar $prereftaxnb $postreftaxnb flaeche ersterpreis ort daysposted pricediff pricediff_pc $prereform $postreform $prereftax17 prereftax_1224_4 $postreftax $prereflntax $postreflntax buildaged ln_flaeche zimmeranzahl basement balcony parking kitchen garden baujahrd heatingtype centralheat fancy fancyequip quietloc bright  wmt* pricechpc jahr plz kreis ags bula betrag preisqm kreistyp monlast popg popgallwp05 popgallwp95 ln_bip ln_pop alq ln_debtpc)
	replace housetype = "mfhp" if housetype==""
	gen ehp = 0
	replace ehp = 1 if housetype == "ehp"
	gen etwp = 0
	replace etwp = 1 if housetype == "etwp"
	gen mfhp = 0
	replace mfhp = 1 if housetype == "mfhp"
	
	foreach pctype in popgallwp {
		foreach depvar of varlist $depvars {
			qui {
				xtreg `depvar' $prereftax17 $postreftax i.monlast#i.kreistyp ehp etwp mfhp if popg>= `pctype'05 & popg<=`pctype'95, fe vce(cluster plz)
				estimates store all_noctrl_ife_pfe, title(Int. trends)
			}
			display "Event study, continuous treatment, no controls, all distances, `depvar'"
			estout all*ctrl*, varwidth(30) cells(b(star fmt(3)) se(fmt(3)) p(par fmt(3))) starlevels(* 0.05 ** 0.01 *** 0.001) stats(r2 ar2_w N, labels("R^2" "R^2 within" N) fmt(3 0)) keep($prereftax17 $postreftax) style(fixed) label collabels(none) replace
			qui {
				foreach type in all_noctrl_ife_pfe {
					estimates restore `type'
					matrix b=e(b)
					matrix coeff1 = b[1,14..39]
					matrix coeff2 = b[1,2..13]
					
					matrix lowerb = [_b[prereftax_1724_16] - invttail(e(df_r),0.025)*_se[prereftax_1724_16], _b[prereftax_1724_15] - invttail(e(df_r),0.025)*_se[prereftax_1724_15], _b[prereftax_1724_14] - invttail(e(df_r),0.025)*_se[prereftax_1724_14], _b[prereftax_1724_13] - invttail(e(df_r),0.025)*_se[prereftax_1724_13],_b[prereftax_1724_12] - invttail(e(df_r),0.025)*_se[prereftax_1724_12], ///
					_b[prereftax_1724_11] - invttail(e(df_r),0.025)*_se[prereftax_1724_11], _b[prereftax_1724_10] - invttail(e(df_r),0.025)*_se[prereftax_1724_10], _b[prereftax_1724_9] - invttail(e(df_r),0.025)*_se[prereftax_1724_9], _b[prereftax_1724_8] - invttail(e(df_r),0.025)*_se[prereftax_1724_8], _b[prereftax_1724_7] - invttail(e(df_r),0.025)*_se[prereftax_1724_7], _b[prereftax_1724_6] - invttail(e(df_r),0.025)*_se[prereftax_1724_6], _b[prereftax_1724_5] - invttail(e(df_r),0.025)*_se[prereftax_1724_5], 0, _b[prereftax_1724_3] - invttail(e(df_r),0.025)*_se[prereftax_1724_3], _b[prereftax_1724_2] - invttail(e(df_r),0.025)*_se[prereftax_1724_2],_b[prereftax_1724_1] - invttail(e(df_r),0.025)*_se[prereftax_1724_1], ///
					_b[postreftax_1224_0] - invttail(e(df_r),0.025)*_se[postreftax_1224_0],_b[postreftax_1224_1] - invttail(e(df_r),0.025)*_se[postreftax_1224_1],_b[postreftax_1224_2] - invttail(e(df_r),0.025)*_se[postreftax_1224_2],_b[postreftax_1224_3] - invttail(e(df_r),0.025)*_se[postreftax_1224_3],_b[postreftax_1224_4] - invttail(e(df_r),0.025)*_se[postreftax_1224_4],_b[postreftax_1224_5] - invttail(e(df_r),0.025)*_se[postreftax_1224_5],_b[postreftax_1224_6] - invttail(e(df_r),0.025)*_se[postreftax_1224_6],_b[postreftax_1224_7] - invttail(e(df_r),0.025)*_se[postreftax_1224_7],_b[postreftax_1224_8] - invttail(e(df_r),0.025)*_se[postreftax_1224_8],_b[postreftax_1224_9] - invttail(e(df_r),0.025)*_se[postreftax_1224_9],_b[postreftax_1224_10] - invttail(e(df_r),0.025)*_se[postreftax_1224_10],_b[postreftax_1224_11] - invttail(e(df_r),0.025)*_se[postreftax_1224_11],_b[postreftax_1224_12] - invttail(e(df_r),0.025)*_se[postreftax_1224_12], ///
					_b[postreftax_1224_13] - invttail(e(df_r),0.025)*_se[postreftax_1224_13],_b[postreftax_1224_14] - invttail(e(df_r),0.025)*_se[postreftax_1224_14],_b[postreftax_1224_15] - invttail(e(df_r),0.025)*_se[postreftax_1224_15],_b[postreftax_1224_16] - invttail(e(df_r),0.025)*_se[postreftax_1224_16],_b[postreftax_1224_17] - invttail(e(df_r),0.025)*_se[postreftax_1224_17],_b[postreftax_1224_18] - invttail(e(df_r),0.025)*_se[postreftax_1224_18],_b[postreftax_1224_19] - invttail(e(df_r),0.025)*_se[postreftax_1224_19],_b[postreftax_1224_20] - invttail(e(df_r),0.025)*_se[postreftax_1224_20],_b[postreftax_1224_21] - invttail(e(df_r),0.025)*_se[postreftax_1224_21],_b[postreftax_1224_22] - invttail(e(df_r),0.025)*_se[postreftax_1224_22]]
					
					matrix upperb = [_b[prereftax_1724_16] + invttail(e(df_r),0.025)*_se[prereftax_1724_16], _b[prereftax_1724_15] + invttail(e(df_r),0.025)*_se[prereftax_1724_15], _b[prereftax_1724_14] + invttail(e(df_r),0.025)*_se[prereftax_1724_14], _b[prereftax_1724_13] + invttail(e(df_r),0.025)*_se[prereftax_1724_13],_b[prereftax_1724_12] + invttail(e(df_r),0.025)*_se[prereftax_1724_12], ///
					_b[prereftax_1724_11] + invttail(e(df_r),0.025)*_se[prereftax_1724_11], _b[prereftax_1724_10] + invttail(e(df_r),0.025)*_se[prereftax_1724_10], _b[prereftax_1724_9] + invttail(e(df_r),0.025)*_se[prereftax_1724_9], _b[prereftax_1724_8] + invttail(e(df_r),0.025)*_se[prereftax_1724_8], _b[prereftax_1724_7] + invttail(e(df_r),0.025)*_se[prereftax_1724_7], _b[prereftax_1724_6] + invttail(e(df_r),0.025)*_se[prereftax_1724_6], _b[prereftax_1724_5] + invttail(e(df_r),0.025)*_se[prereftax_1724_5], 0, _b[prereftax_1724_3] + invttail(e(df_r),0.025)*_se[prereftax_1724_3], _b[prereftax_1724_2] + invttail(e(df_r),0.025)*_se[prereftax_1724_2],_b[prereftax_1724_1] + invttail(e(df_r),0.025)*_se[prereftax_1724_1], ///
					_b[postreftax_1224_0] + invttail(e(df_r),0.025)*_se[postreftax_1224_0],_b[postreftax_1224_1] + invttail(e(df_r),0.025)*_se[postreftax_1224_1],_b[postreftax_1224_2] + invttail(e(df_r),0.025)*_se[postreftax_1224_2],_b[postreftax_1224_3] + invttail(e(df_r),0.025)*_se[postreftax_1224_3],_b[postreftax_1224_4] + invttail(e(df_r),0.025)*_se[postreftax_1224_4],_b[postreftax_1224_5] + invttail(e(df_r),0.025)*_se[postreftax_1224_5],_b[postreftax_1224_6] + invttail(e(df_r),0.025)*_se[postreftax_1224_6],_b[postreftax_1224_7] + invttail(e(df_r),0.025)*_se[postreftax_1224_7],_b[postreftax_1224_8] + invttail(e(df_r),0.025)*_se[postreftax_1224_8],_b[postreftax_1224_9] + invttail(e(df_r),0.025)*_se[postreftax_1224_9],_b[postreftax_1224_10] + invttail(e(df_r),0.025)*_se[postreftax_1224_10],_b[postreftax_1224_11] + invttail(e(df_r),0.025)*_se[postreftax_1224_11],_b[postreftax_1224_12] + invttail(e(df_r),0.025)*_se[postreftax_1224_12], ///
					_b[postreftax_1224_13] + invttail(e(df_r),0.025)*_se[postreftax_1224_13],_b[postreftax_1224_14] + invttail(e(df_r),0.025)*_se[postreftax_1224_14],_b[postreftax_1224_15] + invttail(e(df_r),0.025)*_se[postreftax_1224_15],_b[postreftax_1224_16] + invttail(e(df_r),0.025)*_se[postreftax_1224_16],_b[postreftax_1224_17] + invttail(e(df_r),0.025)*_se[postreftax_1224_17],_b[postreftax_1224_18] + invttail(e(df_r),0.025)*_se[postreftax_1224_18],_b[postreftax_1224_19] + invttail(e(df_r),0.025)*_se[postreftax_1224_19],_b[postreftax_1224_20] + invttail(e(df_r),0.025)*_se[postreftax_1224_20],_b[postreftax_1224_21] + invttail(e(df_r),0.025)*_se[postreftax_1224_21],_b[postreftax_1224_22] + invttail(e(df_r),0.025)*_se[postreftax_1224_22]]
					
					matrix res_`type' = [coeff2, 0, coeff1 \  -16, -15, -14, -13, -12, -11, -10, -9, -8, -7, -6, -5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22 \ upperb \ lowerb ]'
					svmat res_`type'
					scatter res_`type'1 res_`type'2, connect(l) yline(0) xline(-4) xline(0, lpattern(dash)) || rcap res_`type'3 res_`type'4 res_`type'2, scheme(s1color) xtitle("Months before/after tax increase") legend(label(1 "Price effect") label(2 "95% confidence interval")) xlab(-15 (5) 20) ylab(-.06 "-6%" -.04 "-4%" -.02 "-2%" 0 "0%" .02 "2%") yscale(range(-0.065 0.025)) ytitle("Tax semi-elasticity")                                                                                                                                                                                                                                                           
					graph export "${graphs}\ESi_all_popgallwp_deltatax_`depvar'_`type'.pdf", replace
					matrix drop _all
					drop res_`type'*
				}
			}
		qui estimates drop *
		}
	}
}



if $Figure2 == 1 {
	foreach file of global files {
		global graphinput  `file'_noctrl_ife 
		use $depvars $prereform $postreform $prereftax17 $postreftax $prereflntax $postreflntax ersterpreis daysposted pricediff pricediff_pc buildaged ln_flaeche flaeche zimmeranzahl basement balcony parking kitchen garden baujahrd heatingtype centralheat fancy fancyequip quietloc bright  wmt* pricechpc jahr plz betrag preisqm kreistyp monlast popg popgallwp05 popgallwp95 using "${data}/F_u_B/ifo_`file'_4q19_prep_3624.dta", clear
		
	
		foreach pctype in popgallwp {
			foreach depvar of varlist $depvars {
				qui {
					xtreg `depvar' $prereftax17 $postreftax i.monlast#i.kreistyp if popg>= `pctype'05 & popg<=`pctype'95, fe vce(cluster plz)
					estimates store `file'_noctrl_ife, title(Int. trends)
				}
				display "Event study, all distances, `depvar'"
				estout `file'*ctrl*, varwidth(30) cells(b(star fmt(3)) se(fmt(3)) p(par fmt(3))) starlevels(* 0.05 ** 0.01 *** 0.001) stats(r2 ar2_w N, labels("R^2" "R^2 within" N) fmt(3 0)) keep($prereftax17 $postreftax) style(fixed) label collabels(none) replace
				
				qui {
					foreach type in $graphinput  {
						estimates restore `type'
						matrix b=e(b)
						matrix coeff1 = b[1,14..39]
						matrix coeff2 = b[1,2..13]
									
						matrix lowerb = [_b[prereftax_1724_16] - invttail(e(df_r),0.025)*_se[prereftax_1724_16], _b[prereftax_1724_15] - invttail(e(df_r),0.025)*_se[prereftax_1724_15], _b[prereftax_1724_14] - invttail(e(df_r),0.025)*_se[prereftax_1724_14], _b[prereftax_1724_13] - invttail(e(df_r),0.025)*_se[prereftax_1724_13],_b[prereftax_1724_12] - invttail(e(df_r),0.025)*_se[prereftax_1724_12], ///
						_b[prereftax_1724_11] - invttail(e(df_r),0.025)*_se[prereftax_1724_11], _b[prereftax_1724_10] - invttail(e(df_r),0.025)*_se[prereftax_1724_10], _b[prereftax_1724_9] - invttail(e(df_r),0.025)*_se[prereftax_1724_9], _b[prereftax_1724_8] - invttail(e(df_r),0.025)*_se[prereftax_1724_8], _b[prereftax_1724_7] - invttail(e(df_r),0.025)*_se[prereftax_1724_7], _b[prereftax_1724_6] - invttail(e(df_r),0.025)*_se[prereftax_1724_6], _b[prereftax_1724_5] - invttail(e(df_r),0.025)*_se[prereftax_1724_5], 0, _b[prereftax_1724_3] - invttail(e(df_r),0.025)*_se[prereftax_1724_3], _b[prereftax_1724_2] - invttail(e(df_r),0.025)*_se[prereftax_1724_2],_b[prereftax_1724_1] - invttail(e(df_r),0.025)*_se[prereftax_1724_1], ///
						_b[postreftax_1224_0] - invttail(e(df_r),0.025)*_se[postreftax_1224_0],_b[postreftax_1224_1] - invttail(e(df_r),0.025)*_se[postreftax_1224_1],_b[postreftax_1224_2] - invttail(e(df_r),0.025)*_se[postreftax_1224_2],_b[postreftax_1224_3] - invttail(e(df_r),0.025)*_se[postreftax_1224_3],_b[postreftax_1224_4] - invttail(e(df_r),0.025)*_se[postreftax_1224_4],_b[postreftax_1224_5] - invttail(e(df_r),0.025)*_se[postreftax_1224_5],_b[postreftax_1224_6] - invttail(e(df_r),0.025)*_se[postreftax_1224_6],_b[postreftax_1224_7] - invttail(e(df_r),0.025)*_se[postreftax_1224_7],_b[postreftax_1224_8] - invttail(e(df_r),0.025)*_se[postreftax_1224_8],_b[postreftax_1224_9] - invttail(e(df_r),0.025)*_se[postreftax_1224_9],_b[postreftax_1224_10] - invttail(e(df_r),0.025)*_se[postreftax_1224_10],_b[postreftax_1224_11] - invttail(e(df_r),0.025)*_se[postreftax_1224_11],_b[postreftax_1224_12] - invttail(e(df_r),0.025)*_se[postreftax_1224_12], ///
						_b[postreftax_1224_13] - invttail(e(df_r),0.025)*_se[postreftax_1224_13],_b[postreftax_1224_14] - invttail(e(df_r),0.025)*_se[postreftax_1224_14],_b[postreftax_1224_15] - invttail(e(df_r),0.025)*_se[postreftax_1224_15],_b[postreftax_1224_16] - invttail(e(df_r),0.025)*_se[postreftax_1224_16],_b[postreftax_1224_17] - invttail(e(df_r),0.025)*_se[postreftax_1224_17],_b[postreftax_1224_18] - invttail(e(df_r),0.025)*_se[postreftax_1224_18],_b[postreftax_1224_19] - invttail(e(df_r),0.025)*_se[postreftax_1224_19],_b[postreftax_1224_20] - invttail(e(df_r),0.025)*_se[postreftax_1224_20],_b[postreftax_1224_21] - invttail(e(df_r),0.025)*_se[postreftax_1224_21],_b[postreftax_1224_22] - invttail(e(df_r),0.025)*_se[postreftax_1224_22]]
						
						matrix upperb = [_b[prereftax_1724_16] + invttail(e(df_r),0.025)*_se[prereftax_1724_16], _b[prereftax_1724_15] + invttail(e(df_r),0.025)*_se[prereftax_1724_15], _b[prereftax_1724_14] + invttail(e(df_r),0.025)*_se[prereftax_1724_14], _b[prereftax_1724_13] + invttail(e(df_r),0.025)*_se[prereftax_1724_13],_b[prereftax_1724_12] + invttail(e(df_r),0.025)*_se[prereftax_1724_12], ///
						_b[prereftax_1724_11] + invttail(e(df_r),0.025)*_se[prereftax_1724_11], _b[prereftax_1724_10] + invttail(e(df_r),0.025)*_se[prereftax_1724_10], _b[prereftax_1724_9] + invttail(e(df_r),0.025)*_se[prereftax_1724_9], _b[prereftax_1724_8] + invttail(e(df_r),0.025)*_se[prereftax_1724_8], _b[prereftax_1724_7] + invttail(e(df_r),0.025)*_se[prereftax_1724_7], _b[prereftax_1724_6] + invttail(e(df_r),0.025)*_se[prereftax_1724_6], _b[prereftax_1724_5] + invttail(e(df_r),0.025)*_se[prereftax_1724_5], 0, _b[prereftax_1724_3] + invttail(e(df_r),0.025)*_se[prereftax_1724_3], _b[prereftax_1724_2] + invttail(e(df_r),0.025)*_se[prereftax_1724_2],_b[prereftax_1724_1] + invttail(e(df_r),0.025)*_se[prereftax_1724_1], ///
						_b[postreftax_1224_0] + invttail(e(df_r),0.025)*_se[postreftax_1224_0],_b[postreftax_1224_1] + invttail(e(df_r),0.025)*_se[postreftax_1224_1],_b[postreftax_1224_2] + invttail(e(df_r),0.025)*_se[postreftax_1224_2],_b[postreftax_1224_3] + invttail(e(df_r),0.025)*_se[postreftax_1224_3],_b[postreftax_1224_4] + invttail(e(df_r),0.025)*_se[postreftax_1224_4],_b[postreftax_1224_5] + invttail(e(df_r),0.025)*_se[postreftax_1224_5],_b[postreftax_1224_6] + invttail(e(df_r),0.025)*_se[postreftax_1224_6],_b[postreftax_1224_7] + invttail(e(df_r),0.025)*_se[postreftax_1224_7],_b[postreftax_1224_8] + invttail(e(df_r),0.025)*_se[postreftax_1224_8],_b[postreftax_1224_9] + invttail(e(df_r),0.025)*_se[postreftax_1224_9],_b[postreftax_1224_10] + invttail(e(df_r),0.025)*_se[postreftax_1224_10],_b[postreftax_1224_11] + invttail(e(df_r),0.025)*_se[postreftax_1224_11],_b[postreftax_1224_12] + invttail(e(df_r),0.025)*_se[postreftax_1224_12], ///
						_b[postreftax_1224_13] + invttail(e(df_r),0.025)*_se[postreftax_1224_13],_b[postreftax_1224_14] + invttail(e(df_r),0.025)*_se[postreftax_1224_14],_b[postreftax_1224_15] + invttail(e(df_r),0.025)*_se[postreftax_1224_15],_b[postreftax_1224_16] + invttail(e(df_r),0.025)*_se[postreftax_1224_16],_b[postreftax_1224_17] + invttail(e(df_r),0.025)*_se[postreftax_1224_17],_b[postreftax_1224_18] + invttail(e(df_r),0.025)*_se[postreftax_1224_18],_b[postreftax_1224_19] + invttail(e(df_r),0.025)*_se[postreftax_1224_19],_b[postreftax_1224_20] + invttail(e(df_r),0.025)*_se[postreftax_1224_20],_b[postreftax_1224_21] + invttail(e(df_r),0.025)*_se[postreftax_1224_21],_b[postreftax_1224_22] + invttail(e(df_r),0.025)*_se[postreftax_1224_22]]
						
						
						matrix res_`type' = [coeff2, 0, coeff1 \  -16, -15, -14, -13, -12, -11, -10, -9, -8, -7, -6, -5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22 \ upperb \ lowerb ]'
						svmat res_`type'
						scatter res_`type'1 res_`type'2, connect(l) yline(0) xline(-4) xline(0, lpattern(dash)) || rcap res_`type'3 res_`type'4 res_`type'2, scheme(s1color) xtitle("Months before/after tax increase") legend(label(1 "Price effect") label(2 "95% confidence interval")) xlab(-15 (5) 20) ylab(-.06 "-6%" -.04 "-4%" -.02 "-2%" 0 "0%" .02 "2%") yscale(range(-0.065 0.025)) ytitle("Tax semi-elasticity")
						graph export "${graphs}\ESi_`file'_`pctype'_deltatax_`depvar'_`type'_1724.pdf", replace
						matrix drop _all
						drop res_`type'*
					}
				}
				qui estimates drop *
			}
		}
	}  
	
	   
	global graphinput  ehpetwp_noctrl_ife                                  
	use $depvars Nnachbar $prereftaxnb $postreftaxnb flaeche ersterpreis ort daysposted pricediff pricediff_pc $prereform $postreform $prereftax $prereftax17 prereftax_1224_4 $postreftax $prereflntax17 $postreflntax buildaged ln_flaeche zimmeranzahl basement balcony parking kitchen garden baujahrd heatingtype centralheat fancy fancyequip quietloc bright  wmt* pricechpc jahr plz kreis ags bula betrag preisqm kreistyp monlast popg popgallwp05 popgallwp95 ln_bip ln_pop alq ln_debtpc using "${data}/F_u_B/ifo_etwp_4q19_prep_3624.dta", clear
	gen housetype = "etwp"
	append using "${data}/F_u_B/ifo_ehp_4q19_prep_3624.dta", keep($depvars Nnachbar $prereftaxnb $postreftaxnb flaeche ersterpreis ort daysposted pricediff pricediff_pc $prereform $postreform $prereftax $prereftax17 prereftax_1224_4 $postreftax $prereflntax17 $postreflntax buildaged ln_flaeche zimmeranzahl basement balcony parking kitchen garden baujahrd heatingtype centralheat fancy fancyequip quietloc bright  wmt* pricechpc jahr plz kreis ags bula betrag preisqm kreistyp monlast popg popgallwp05 popgallwp95 ln_bip ln_pop alq ln_debtpc)
	replace housetype = "ehp" if housetype==""
	gen ehp = 0
	replace ehp = 1 if housetype == "ehp"
	gen etwp = 0
	replace etwp = 1 if housetype == "etwp"
	
	gen wmt_growing      = (wmt == 4 | wmt == 5)
	gen wmt_growing_etwp = ((wmt == 4 | wmt == 5) & etwp == 1)
	gen wmt_growing_ehp  = ((wmt == 4 | wmt == 5) & ehp == 1)
	
	foreach pctype in popgallwp {
		foreach depvar of varlist $depvars {
			reghdfe `depvar' (c.(${prereftax17}) c.(${postreftax}))##i.etwp if popg>= `pctype'05 & popg<=`pctype'95, a(i.plz#i.etwp i.monlast#i.kreistyp#i.etwp) vce(cluster plz)
			estimates store ehpetwp_noctrl_ife_pfe_v9, title(Int. trends)
			
			estimates restore ehpetwp_noctrl_ife_pfe_v9
			matrix b=e(b)
			matrix coeff1 = (b[1,70],b[1,72],b[1,74],b[1,76],b[1,78],b[1,80],b[1,82],b[1,84],b[1,86],b[1,88],b[1,90],b[1,92],b[1,94],b[1,96],b[1,98],b[1,100],b[1,102],b[1,104],b[1,106],b[1,108],b[1,110],b[1,112],b[1,114],b[1,116],b[1,118],b[1,120])
			matrix coeff2 = (b[1,46],b[1,48],b[1,50],b[1,52],b[1,54],b[1,56],b[1,58],b[1,60],b[1,62],b[1,64],b[1,66],b[1,68])
			matrix lowerb = [_b[1.etwp#c.prereftax_1724_16] - invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_16], _b[1.etwp#c.prereftax_1724_15] - invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_15], _b[1.etwp#c.prereftax_1724_14] - invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_14], _b[1.etwp#c.prereftax_1724_13] - invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_13], _b[1.etwp#c.prereftax_1724_12] - invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_12], _b[1.etwp#c.prereftax_1724_11] - invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_11], _b[1.etwp#c.prereftax_1724_10] - invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_10], _b[1.etwp#c.prereftax_1724_9] - invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_9], _b[1.etwp#c.prereftax_1724_8] - invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_8], _b[1.etwp#c.prereftax_1724_7] - invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_7], _b[1.etwp#c.prereftax_1724_6] - invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_6], _b[1.etwp#c.prereftax_1724_5] - invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_5], 0, _b[1.etwp#c.prereftax_1724_3] - invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_3], _b[1.etwp#c.prereftax_1724_2] - invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_2],_b[1.etwp#c.prereftax_1724_1] - invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_1], ///
			_b[1.etwp#c.postreftax_1224_0] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_0],_b[1.etwp#c.postreftax_1224_1] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_1],_b[1.etwp#c.postreftax_1224_2] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_2],_b[1.etwp#c.postreftax_1224_3] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_3],_b[1.etwp#c.postreftax_1224_4] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_4],_b[1.etwp#c.postreftax_1224_5] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_5],_b[1.etwp#c.postreftax_1224_6] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_6],_b[1.etwp#c.postreftax_1224_7] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_7],_b[1.etwp#c.postreftax_1224_8] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_8],_b[1.etwp#c.postreftax_1224_9] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_9],_b[1.etwp#c.postreftax_1224_10] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_10],_b[1.etwp#c.postreftax_1224_11] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_11],_b[1.etwp#c.postreftax_1224_12] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_12] ///
			,_b[1.etwp#c.postreftax_1224_13] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_13],_b[1.etwp#c.postreftax_1224_14] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_14],_b[1.etwp#c.postreftax_1224_15] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_15],_b[1.etwp#c.postreftax_1224_16] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_16],_b[1.etwp#c.postreftax_1224_17] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_17],_b[1.etwp#c.postreftax_1224_18] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_18],_b[1.etwp#c.postreftax_1224_19] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_19],_b[1.etwp#c.postreftax_1224_20] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_20],_b[1.etwp#c.postreftax_1224_21] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_21],_b[1.etwp#c.postreftax_1224_22] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_22]]
			matrix upperb = [_b[1.etwp#c.prereftax_1724_16] + invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_16], _b[1.etwp#c.prereftax_1724_15] + invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_15], _b[1.etwp#c.prereftax_1724_14] + invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_14], _b[1.etwp#c.prereftax_1724_13] + invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_13], _b[1.etwp#c.prereftax_1724_12] + invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_12], _b[1.etwp#c.prereftax_1724_11] + invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_11], _b[1.etwp#c.prereftax_1724_10] + invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_10], _b[1.etwp#c.prereftax_1724_9] + invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_9], _b[1.etwp#c.prereftax_1724_8] + invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_8], _b[1.etwp#c.prereftax_1724_7] + invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_7], _b[1.etwp#c.prereftax_1724_6] + invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_6], _b[1.etwp#c.prereftax_1724_5] + invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_5], 0, _b[1.etwp#c.prereftax_1724_3] + invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_3], _b[1.etwp#c.prereftax_1724_2] + invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_2],_b[1.etwp#c.prereftax_1724_1] + invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_1], ///
			_b[1.etwp#c.postreftax_1224_0] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_0],_b[1.etwp#c.postreftax_1224_1] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_1],_b[1.etwp#c.postreftax_1224_2] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_2],_b[1.etwp#c.postreftax_1224_3] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_3],_b[1.etwp#c.postreftax_1224_4] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_4],_b[1.etwp#c.postreftax_1224_5] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_5],_b[1.etwp#c.postreftax_1224_6] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_6],_b[1.etwp#c.postreftax_1224_7] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_7],_b[1.etwp#c.postreftax_1224_8] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_8],_b[1.etwp#c.postreftax_1224_9] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_9],_b[1.etwp#c.postreftax_1224_10] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_10],_b[1.etwp#c.postreftax_1224_11] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_11],_b[1.etwp#c.postreftax_1224_12] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_12] ///
			,_b[1.etwp#c.postreftax_1224_13] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_13],_b[1.etwp#c.postreftax_1224_14] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_14],_b[1.etwp#c.postreftax_1224_15] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_15],_b[1.etwp#c.postreftax_1224_16] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_16],_b[1.etwp#c.postreftax_1224_17] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_17],_b[1.etwp#c.postreftax_1224_18] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_18],_b[1.etwp#c.postreftax_1224_19] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_19],_b[1.etwp#c.postreftax_1224_20] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_20],_b[1.etwp#c.postreftax_1224_21] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_21],_b[1.etwp#c.postreftax_1224_22] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_22]]
			matrix res_ehpetwp_noctrl_ife_pfe_v9 = [coeff2, 0, coeff1 \  -16, -15, -14, -13, -12, -11, -10, -9, -8, -7, -6, -5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22 \ upperb \ lowerb ]'
			svmat res_ehpetwp_noctrl_ife_pfe_v9
			scatter res_ehpetwp_noctrl_ife_pfe_v91 res_ehpetwp_noctrl_ife_pfe_v92, connect(l) yline(0) xline(-4) xline(0, lpattern(dash)) || rcap res_ehpetwp_noctrl_ife_pfe_v93 res_ehpetwp_noctrl_ife_pfe_v94 res_ehpetwp_noctrl_ife_pfe_v92, scheme(s1color) xtitle("Months before/after tax increase") legend(label(1 "Difference SFH-APT") label(2 "95% confidence interval")) xlab(-15 (5) 20) ylab(-.06 "-6%" -.04 "-4%" -.02 "-2%" 0 "0%" .02 "2%") yscale(range(-0.065 0.025)) ytitle("Difference") 
			graph export "${graphs}\ESi_diff_popgallwp_deltatax_`depvar'_ehpetwp_noctrl_ife_pfe_v9.pdf", replace
			matrix drop _all
			drop res_ehpetwp_noctrl_ife_pfe_v9*
		}
	}
}

if $Figure4 == 1 {
	foreach file of global files {
		use $prereform $postreform $prereftax17 $postreftax $prereflntax $postreflntax $depvars daysposted pricediff pricediff_pc buildaged ln_flaeche zimmeranzahl basement balcony parking kitchen garden baujahrd heatingtype centralheat fancy fancyequip quietloc bright wmt* pricechpc jahr plz kreis ags kreistyp monlast ln_bip ln_pop alq ln_debtpc popg popgallwp05 popgallwp95 using "${data}/F_u_B/ifo_`file'_4q19_prep_3624.dta", clear
		
		gen discount = (pricediff < 0)
		gen pricereduc_pc = pricediff_pc if discount == 1
		replace pricereduc_pc = 0 if discount == 0
		
			
		preserve
			keep if jahr <= 2006
			collapse (mean) discount daysposted pricereduc_pc, by(kreis)
						
			gsort + daysposted
			gen daysposted_rank = _n

			gsort + discount
			gen discount_rank = _n
			
			gsort - pricereduc_pc
			gen pricereduc_pc_rank = _n
			
			** Sum stats
			sum daysposted discount pricereduc_pc daysposted_rank discount_rank pricereduc_pc_rank, d

			gen mean_rank2_uw = (daysposted_rank + pricereduc_pc_rank)/2
			
			keep kreis  mean_rank2_uw 

			tempfile rank_kreis_uw
			save `rank_kreis_uw'
		restore
		

		merge m:1 kreis using `rank_kreis_uw', nogen
		xtile mean_rank2_q_uw = mean_rank2_uw, n(4)
		

		foreach pctype in popgallwp {
			foreach depvar of varlist $depvars {
				qui {					
					xtreg `depvar' $prereftax17 $postreftax i.monlast#i.kreistyp if (mean_rank2_q_uw  == 1) & popg>= `pctype'05 & popg<=`pctype'95, fe vce(cluster plz)
					estimates store `file'_noctrl_ife_r2kuw1, title(Int. trends)
					xtreg `depvar' $prereftax17 $postreftax i.monlast#i.kreistyp if (mean_rank2_q_uw  == 4) & popg>= `pctype'05 & popg<=`pctype'95, fe vce(cluster plz)
					estimates store `file'_noctrl_ife_r2kuw4, title(Int. trends)
				}
				display "`file', bargaining power, winsorized, `depvar'"
				estout `file'*ctrl*, varwidth(30) cells(b(star fmt(3)) se(fmt(3)) p(par fmt(3))) starlevels(* 0.05 ** 0.01 *** 0.001) stats(r2 ar2_w N, labels("R^2" "R^2 within" N) fmt(3 0)) keep($prereftax17 $postreftax) style(fixed) label collabels(none) replace
				qui {
					foreach type in `file'_noctrl_ife_r2kuw1 `file'_noctrl_ife_r2kuw4  {
						estimates restore `type'
						matrix b=e(b)
						matrix coeff1 = b[1,14..39]
						matrix coeff2 = b[1,2..13]
						
						matrix lowerb = [_b[prereftax_1724_16] - invttail(e(df_r),0.025)*_se[prereftax_1724_16], _b[prereftax_1724_15] - invttail(e(df_r),0.025)*_se[prereftax_1724_15], _b[prereftax_1724_14] - invttail(e(df_r),0.025)*_se[prereftax_1724_14], _b[prereftax_1724_13] - invttail(e(df_r),0.025)*_se[prereftax_1724_13],_b[prereftax_1724_12] - invttail(e(df_r),0.025)*_se[prereftax_1724_12], ///
						_b[prereftax_1724_11] - invttail(e(df_r),0.025)*_se[prereftax_1724_11], _b[prereftax_1724_10] - invttail(e(df_r),0.025)*_se[prereftax_1724_10], _b[prereftax_1724_9] - invttail(e(df_r),0.025)*_se[prereftax_1724_9], _b[prereftax_1724_8] - invttail(e(df_r),0.025)*_se[prereftax_1724_8], _b[prereftax_1724_7] - invttail(e(df_r),0.025)*_se[prereftax_1724_7], _b[prereftax_1724_6] - invttail(e(df_r),0.025)*_se[prereftax_1724_6], _b[prereftax_1724_5] - invttail(e(df_r),0.025)*_se[prereftax_1724_5], 0, _b[prereftax_1724_3] - invttail(e(df_r),0.025)*_se[prereftax_1724_3], _b[prereftax_1724_2] - invttail(e(df_r),0.025)*_se[prereftax_1724_2],_b[prereftax_1724_1] - invttail(e(df_r),0.025)*_se[prereftax_1724_1], ///
						_b[postreftax_1224_0] - invttail(e(df_r),0.025)*_se[postreftax_1224_0],_b[postreftax_1224_1] - invttail(e(df_r),0.025)*_se[postreftax_1224_1],_b[postreftax_1224_2] - invttail(e(df_r),0.025)*_se[postreftax_1224_2],_b[postreftax_1224_3] - invttail(e(df_r),0.025)*_se[postreftax_1224_3],_b[postreftax_1224_4] - invttail(e(df_r),0.025)*_se[postreftax_1224_4],_b[postreftax_1224_5] - invttail(e(df_r),0.025)*_se[postreftax_1224_5],_b[postreftax_1224_6] - invttail(e(df_r),0.025)*_se[postreftax_1224_6],_b[postreftax_1224_7] - invttail(e(df_r),0.025)*_se[postreftax_1224_7],_b[postreftax_1224_8] - invttail(e(df_r),0.025)*_se[postreftax_1224_8],_b[postreftax_1224_9] - invttail(e(df_r),0.025)*_se[postreftax_1224_9],_b[postreftax_1224_10] - invttail(e(df_r),0.025)*_se[postreftax_1224_10],_b[postreftax_1224_11] - invttail(e(df_r),0.025)*_se[postreftax_1224_11],_b[postreftax_1224_12] - invttail(e(df_r),0.025)*_se[postreftax_1224_12], ///
						_b[postreftax_1224_13] - invttail(e(df_r),0.025)*_se[postreftax_1224_13],_b[postreftax_1224_14] - invttail(e(df_r),0.025)*_se[postreftax_1224_14],_b[postreftax_1224_15] - invttail(e(df_r),0.025)*_se[postreftax_1224_15],_b[postreftax_1224_16] - invttail(e(df_r),0.025)*_se[postreftax_1224_16],_b[postreftax_1224_17] - invttail(e(df_r),0.025)*_se[postreftax_1224_17],_b[postreftax_1224_18] - invttail(e(df_r),0.025)*_se[postreftax_1224_18],_b[postreftax_1224_19] - invttail(e(df_r),0.025)*_se[postreftax_1224_19],_b[postreftax_1224_20] - invttail(e(df_r),0.025)*_se[postreftax_1224_20],_b[postreftax_1224_21] - invttail(e(df_r),0.025)*_se[postreftax_1224_21],_b[postreftax_1224_22] - invttail(e(df_r),0.025)*_se[postreftax_1224_22]]
						
						matrix upperb = [_b[prereftax_1724_16] + invttail(e(df_r),0.025)*_se[prereftax_1724_16], _b[prereftax_1724_15] + invttail(e(df_r),0.025)*_se[prereftax_1724_15], _b[prereftax_1724_14] + invttail(e(df_r),0.025)*_se[prereftax_1724_14], _b[prereftax_1724_13] + invttail(e(df_r),0.025)*_se[prereftax_1724_13],_b[prereftax_1724_12] + invttail(e(df_r),0.025)*_se[prereftax_1724_12], ///
						_b[prereftax_1724_11] + invttail(e(df_r),0.025)*_se[prereftax_1724_11], _b[prereftax_1724_10] + invttail(e(df_r),0.025)*_se[prereftax_1724_10], _b[prereftax_1724_9] + invttail(e(df_r),0.025)*_se[prereftax_1724_9], _b[prereftax_1724_8] + invttail(e(df_r),0.025)*_se[prereftax_1724_8], _b[prereftax_1724_7] + invttail(e(df_r),0.025)*_se[prereftax_1724_7], _b[prereftax_1724_6] + invttail(e(df_r),0.025)*_se[prereftax_1724_6], _b[prereftax_1724_5] + invttail(e(df_r),0.025)*_se[prereftax_1724_5], 0, _b[prereftax_1724_3] + invttail(e(df_r),0.025)*_se[prereftax_1724_3], _b[prereftax_1724_2] + invttail(e(df_r),0.025)*_se[prereftax_1724_2],_b[prereftax_1724_1] + invttail(e(df_r),0.025)*_se[prereftax_1724_1], ///
						_b[postreftax_1224_0] + invttail(e(df_r),0.025)*_se[postreftax_1224_0],_b[postreftax_1224_1] + invttail(e(df_r),0.025)*_se[postreftax_1224_1],_b[postreftax_1224_2] + invttail(e(df_r),0.025)*_se[postreftax_1224_2],_b[postreftax_1224_3] + invttail(e(df_r),0.025)*_se[postreftax_1224_3],_b[postreftax_1224_4] + invttail(e(df_r),0.025)*_se[postreftax_1224_4],_b[postreftax_1224_5] + invttail(e(df_r),0.025)*_se[postreftax_1224_5],_b[postreftax_1224_6] + invttail(e(df_r),0.025)*_se[postreftax_1224_6],_b[postreftax_1224_7] + invttail(e(df_r),0.025)*_se[postreftax_1224_7],_b[postreftax_1224_8] + invttail(e(df_r),0.025)*_se[postreftax_1224_8],_b[postreftax_1224_9] + invttail(e(df_r),0.025)*_se[postreftax_1224_9],_b[postreftax_1224_10] + invttail(e(df_r),0.025)*_se[postreftax_1224_10],_b[postreftax_1224_11] + invttail(e(df_r),0.025)*_se[postreftax_1224_11],_b[postreftax_1224_12] + invttail(e(df_r),0.025)*_se[postreftax_1224_12], ///
						_b[postreftax_1224_13] + invttail(e(df_r),0.025)*_se[postreftax_1224_13],_b[postreftax_1224_14] + invttail(e(df_r),0.025)*_se[postreftax_1224_14],_b[postreftax_1224_15] + invttail(e(df_r),0.025)*_se[postreftax_1224_15],_b[postreftax_1224_16] + invttail(e(df_r),0.025)*_se[postreftax_1224_16],_b[postreftax_1224_17] + invttail(e(df_r),0.025)*_se[postreftax_1224_17],_b[postreftax_1224_18] + invttail(e(df_r),0.025)*_se[postreftax_1224_18],_b[postreftax_1224_19] + invttail(e(df_r),0.025)*_se[postreftax_1224_19],_b[postreftax_1224_20] + invttail(e(df_r),0.025)*_se[postreftax_1224_20],_b[postreftax_1224_21] + invttail(e(df_r),0.025)*_se[postreftax_1224_21],_b[postreftax_1224_22] + invttail(e(df_r),0.025)*_se[postreftax_1224_22]]
											
						matrix res_`type' = [coeff2, 0, coeff1 \  -16, -15, -14, -13, -12, -11, -10, -9, -8, -7, -6, -5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22 \ upperb \ lowerb ]'
						svmat res_`type'
						scatter res_`type'1 res_`type'2, connect(l) yline(0) xline(-4) xline(0, lpattern(dash)) || rcap res_`type'3 res_`type'4 res_`type'2, scheme(s1color) xtitle("Months before/after tax increase") legend(label(1 "Price effect") label(2 "95% confidence interval")) xlab(-15 (5) 20) ylab(-.06 "-6%" -.04 "-4%" -.02 "-2%" 0 "0%" .02 "2%") yscale(range(-0.065 0.025)) ytitle("Tax semi-elasticity")
						graph export "${graphs}\ESi_`file'_`pctype'_bargaining_deltatax_`depvar'_`type'.pdf", replace
						matrix drop _all
						drop res_`type'*
					}
				}
				qui estimates drop *
			}
		}
	}
}
	

if $Figure5 == 1 {
	foreach file of global files {
		global graphinput  `file'_noctrl_ife 
		use $prereform $postreform $prereftax17 $postreftax $prereflntax $postreflntax $depvars pricechpc jahr plz ags betrag preisqm wmt monlast popg popgallwp05 popgallwp95 kreistyp using "${data}/F_u_B/ifo_`file'_4q19_prep_3624.dta", clear
		
		merge m:1 ags using "${data}/external_data/wohnungsmarkttypen.dta", keepusing(wmt_punkte) 
		drop _merge
		
		xtile wmt_quartiles = wmt_punkte, n(4)
	
		foreach pctype in popgallwp {
			foreach depvar of varlist $depvars {
				qui {
					xtreg `depvar' $prereftax17 $postreftax i.monlast#i.kreistyp if (wmt == 1 | wmt == 2 | wmt == 3) & popg>= `pctype'05 & popg<=`pctype'95, fe vce(cluster plz)
					estimates store `file'_noctrl_ife123, title(Int. trends)

					xtreg `depvar' $prereftax17 $postreftax i.monlast#i.kreistyp if (wmt == 4 | wmt == 5) & popg>= `pctype'05 & popg<=`pctype'95, fe vce(cluster plz)
					estimates store `file'_noctrl_ife45, title(Int. trends)
				}
				display "`file', Wohnungsmarkttypen, winsorized, `depvar'"
				estout `file'*ctrl*, varwidth(30) cells(b(star fmt(3)) se(fmt(3)) p(par fmt(3))) starlevels(* 0.05 ** 0.01 *** 0.001) stats(r2 ar2_w N, labels("R^2" "R^2 within" N) fmt(3 0)) keep($prereftax17 $postreftax) style(fixed) label collabels(none) replace
				qui {
					foreach type in  `file'_noctrl_ife123  `file'_noctrl_ife45 {
						estimates restore `type'
						matrix b=e(b)
						matrix coeff1 = b[1,14..39]
						matrix coeff2 = b[1,2..13]
						
						matrix lowerb = [_b[prereftax_1724_16] - invttail(e(df_r),0.025)*_se[prereftax_1724_16], _b[prereftax_1724_15] - invttail(e(df_r),0.025)*_se[prereftax_1724_15], _b[prereftax_1724_14] - invttail(e(df_r),0.025)*_se[prereftax_1724_14], _b[prereftax_1724_13] - invttail(e(df_r),0.025)*_se[prereftax_1724_13],_b[prereftax_1724_12] - invttail(e(df_r),0.025)*_se[prereftax_1724_12], ///
						_b[prereftax_1724_11] - invttail(e(df_r),0.025)*_se[prereftax_1724_11], _b[prereftax_1724_10] - invttail(e(df_r),0.025)*_se[prereftax_1724_10], _b[prereftax_1724_9] - invttail(e(df_r),0.025)*_se[prereftax_1724_9], _b[prereftax_1724_8] - invttail(e(df_r),0.025)*_se[prereftax_1724_8], _b[prereftax_1724_7] - invttail(e(df_r),0.025)*_se[prereftax_1724_7], _b[prereftax_1724_6] - invttail(e(df_r),0.025)*_se[prereftax_1724_6], _b[prereftax_1724_5] - invttail(e(df_r),0.025)*_se[prereftax_1724_5], 0, _b[prereftax_1724_3] - invttail(e(df_r),0.025)*_se[prereftax_1724_3], _b[prereftax_1724_2] - invttail(e(df_r),0.025)*_se[prereftax_1724_2],_b[prereftax_1724_1] - invttail(e(df_r),0.025)*_se[prereftax_1724_1], ///
						_b[postreftax_1224_0] - invttail(e(df_r),0.025)*_se[postreftax_1224_0],_b[postreftax_1224_1] - invttail(e(df_r),0.025)*_se[postreftax_1224_1],_b[postreftax_1224_2] - invttail(e(df_r),0.025)*_se[postreftax_1224_2],_b[postreftax_1224_3] - invttail(e(df_r),0.025)*_se[postreftax_1224_3],_b[postreftax_1224_4] - invttail(e(df_r),0.025)*_se[postreftax_1224_4],_b[postreftax_1224_5] - invttail(e(df_r),0.025)*_se[postreftax_1224_5],_b[postreftax_1224_6] - invttail(e(df_r),0.025)*_se[postreftax_1224_6],_b[postreftax_1224_7] - invttail(e(df_r),0.025)*_se[postreftax_1224_7],_b[postreftax_1224_8] - invttail(e(df_r),0.025)*_se[postreftax_1224_8],_b[postreftax_1224_9] - invttail(e(df_r),0.025)*_se[postreftax_1224_9],_b[postreftax_1224_10] - invttail(e(df_r),0.025)*_se[postreftax_1224_10],_b[postreftax_1224_11] - invttail(e(df_r),0.025)*_se[postreftax_1224_11],_b[postreftax_1224_12] - invttail(e(df_r),0.025)*_se[postreftax_1224_12], ///
						_b[postreftax_1224_13] - invttail(e(df_r),0.025)*_se[postreftax_1224_13],_b[postreftax_1224_14] - invttail(e(df_r),0.025)*_se[postreftax_1224_14],_b[postreftax_1224_15] - invttail(e(df_r),0.025)*_se[postreftax_1224_15],_b[postreftax_1224_16] - invttail(e(df_r),0.025)*_se[postreftax_1224_16],_b[postreftax_1224_17] - invttail(e(df_r),0.025)*_se[postreftax_1224_17],_b[postreftax_1224_18] - invttail(e(df_r),0.025)*_se[postreftax_1224_18],_b[postreftax_1224_19] - invttail(e(df_r),0.025)*_se[postreftax_1224_19],_b[postreftax_1224_20] - invttail(e(df_r),0.025)*_se[postreftax_1224_20],_b[postreftax_1224_21] - invttail(e(df_r),0.025)*_se[postreftax_1224_21],_b[postreftax_1224_22] - invttail(e(df_r),0.025)*_se[postreftax_1224_22]]
						
						matrix upperb = [_b[prereftax_1724_16] + invttail(e(df_r),0.025)*_se[prereftax_1724_16], _b[prereftax_1724_15] + invttail(e(df_r),0.025)*_se[prereftax_1724_15], _b[prereftax_1724_14] + invttail(e(df_r),0.025)*_se[prereftax_1724_14], _b[prereftax_1724_13] + invttail(e(df_r),0.025)*_se[prereftax_1724_13],_b[prereftax_1724_12] + invttail(e(df_r),0.025)*_se[prereftax_1724_12], ///
						_b[prereftax_1724_11] + invttail(e(df_r),0.025)*_se[prereftax_1724_11], _b[prereftax_1724_10] + invttail(e(df_r),0.025)*_se[prereftax_1724_10], _b[prereftax_1724_9] + invttail(e(df_r),0.025)*_se[prereftax_1724_9], _b[prereftax_1724_8] + invttail(e(df_r),0.025)*_se[prereftax_1724_8], _b[prereftax_1724_7] + invttail(e(df_r),0.025)*_se[prereftax_1724_7], _b[prereftax_1724_6] + invttail(e(df_r),0.025)*_se[prereftax_1724_6], _b[prereftax_1724_5] + invttail(e(df_r),0.025)*_se[prereftax_1724_5], 0, _b[prereftax_1724_3] + invttail(e(df_r),0.025)*_se[prereftax_1724_3], _b[prereftax_1724_2] + invttail(e(df_r),0.025)*_se[prereftax_1724_2],_b[prereftax_1724_1] + invttail(e(df_r),0.025)*_se[prereftax_1724_1], ///
						_b[postreftax_1224_0] + invttail(e(df_r),0.025)*_se[postreftax_1224_0],_b[postreftax_1224_1] + invttail(e(df_r),0.025)*_se[postreftax_1224_1],_b[postreftax_1224_2] + invttail(e(df_r),0.025)*_se[postreftax_1224_2],_b[postreftax_1224_3] + invttail(e(df_r),0.025)*_se[postreftax_1224_3],_b[postreftax_1224_4] + invttail(e(df_r),0.025)*_se[postreftax_1224_4],_b[postreftax_1224_5] + invttail(e(df_r),0.025)*_se[postreftax_1224_5],_b[postreftax_1224_6] + invttail(e(df_r),0.025)*_se[postreftax_1224_6],_b[postreftax_1224_7] + invttail(e(df_r),0.025)*_se[postreftax_1224_7],_b[postreftax_1224_8] + invttail(e(df_r),0.025)*_se[postreftax_1224_8],_b[postreftax_1224_9] + invttail(e(df_r),0.025)*_se[postreftax_1224_9],_b[postreftax_1224_10] + invttail(e(df_r),0.025)*_se[postreftax_1224_10],_b[postreftax_1224_11] + invttail(e(df_r),0.025)*_se[postreftax_1224_11],_b[postreftax_1224_12] + invttail(e(df_r),0.025)*_se[postreftax_1224_12], ///
						_b[postreftax_1224_13] + invttail(e(df_r),0.025)*_se[postreftax_1224_13],_b[postreftax_1224_14] + invttail(e(df_r),0.025)*_se[postreftax_1224_14],_b[postreftax_1224_15] + invttail(e(df_r),0.025)*_se[postreftax_1224_15],_b[postreftax_1224_16] + invttail(e(df_r),0.025)*_se[postreftax_1224_16],_b[postreftax_1224_17] + invttail(e(df_r),0.025)*_se[postreftax_1224_17],_b[postreftax_1224_18] + invttail(e(df_r),0.025)*_se[postreftax_1224_18],_b[postreftax_1224_19] + invttail(e(df_r),0.025)*_se[postreftax_1224_19],_b[postreftax_1224_20] + invttail(e(df_r),0.025)*_se[postreftax_1224_20],_b[postreftax_1224_21] + invttail(e(df_r),0.025)*_se[postreftax_1224_21],_b[postreftax_1224_22] + invttail(e(df_r),0.025)*_se[postreftax_1224_22]]
						
						matrix res_`type' = [coeff2, 0, coeff1 \  -16, -15, -14, -13, -12, -11, -10, -9, -8, -7, -6, -5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22 \ upperb \ lowerb ]'
						svmat res_`type'
						scatter res_`type'1 res_`type'2, connect(l) yline(0) xline(-4) xline(0, lpattern(dash)) || rcap res_`type'3 res_`type'4 res_`type'2, scheme(s1color) xtitle("Months before/after tax increase") legend(label(1 "Price effect") label(2 "95% confidence interval")) xlab(-15 (5) 20) ylab(-.06 "-6%" -.04 "-4%" -.02 "-2%" 0 "0%" .02 "2%") yscale(range(-0.065 0.025)) ytitle("Tax semi-elasticity")
						graph export "${graphs}\ESi_`file'_`pctype'_wmt_deltatax_`depvar'_`type'_1724.pdf", replace
						matrix drop _all
						drop res_`type'*
					}
				}
				qui estimates drop *
			}
		}
	
	}
}

if $FigureA5 == 1 {
	foreach file of global files {
		global graphinput `file'_noctrl_ife 
		use $prereform $postreform $prereftax $postreftax $prereflntax17 $postreflntax buildaged ln_flaeche zimmeranzahl basement balcony parking kitchen garden baujahrd heatingtype centralheat fancy fancyequip quietloc bright $depvars wmt* pricechpc jahr plz betrag preisqm kreistyp monlast popg popgallwp05 popgallwp95 using "${data}/F_u_B/ifo_`file'_4q19_prep_3624.dta", clear
		
		foreach pctype in popgallwp {
			foreach depvar of varlist $depvars {
				qui {
					xtreg `depvar' $prereflntax17 $postreflntax i.monlast#i.kreistyp if popg>= `pctype'05 & popg<=`pctype'95, fe vce(cluster plz)
					estimates store `file'_noctrl_ife, title(Int. trends)
				}
				display "Event study, all distances, `depvar'"
				estout `file'*ctrl*, varwidth(30) cells(b(star fmt(3)) se(fmt(3)) p(par fmt(3))) starlevels(* 0.05 ** 0.01 *** 0.001) stats(r2 ar2_w N, labels("R^2" "R^2 within" N) fmt(3 0)) keep($prereflntax17 $postreflntax) style(fixed) label collabels(none) replace
				qui {
					foreach type in $graphinput {
						estimates restore `type'
						matrix b=e(b)
						matrix coeff1 = b[1,14..39]
						matrix coeff2 = b[1,2..13]
						
						matrix lowerb = [_b[prereflntax_1724_16] - invttail(e(df_r),0.025)*_se[prereflntax_1724_16], _b[prereflntax_1724_15] - invttail(e(df_r),0.025)*_se[prereflntax_1724_15], _b[prereflntax_1724_14] - invttail(e(df_r),0.025)*_se[prereflntax_1724_14], _b[prereflntax_1724_13] - invttail(e(df_r),0.025)*_se[prereflntax_1724_13],_b[prereflntax_1724_12] - invttail(e(df_r),0.025)*_se[prereflntax_1724_12], ///
						_b[prereflntax_1724_11] - invttail(e(df_r),0.025)*_se[prereflntax_1724_11], _b[prereflntax_1724_10] - invttail(e(df_r),0.025)*_se[prereflntax_1724_10], _b[prereflntax_1724_9] - invttail(e(df_r),0.025)*_se[prereflntax_1724_9], _b[prereflntax_1724_8] - invttail(e(df_r),0.025)*_se[prereflntax_1724_8], _b[prereflntax_1724_7] - invttail(e(df_r),0.025)*_se[prereflntax_1724_7], _b[prereflntax_1724_6] - invttail(e(df_r),0.025)*_se[prereflntax_1724_6], _b[prereflntax_1724_5] - invttail(e(df_r),0.025)*_se[prereflntax_1724_5], 0, _b[prereflntax_1724_3] - invttail(e(df_r),0.025)*_se[prereflntax_1724_3], _b[prereflntax_1724_2] - invttail(e(df_r),0.025)*_se[prereflntax_1724_2],_b[prereflntax_1724_1] - invttail(e(df_r),0.025)*_se[prereflntax_1724_1], ///
						_b[postreflntax_1224_0] - invttail(e(df_r),0.025)*_se[postreflntax_1224_0],_b[postreflntax_1224_1] - invttail(e(df_r),0.025)*_se[postreflntax_1224_1],_b[postreflntax_1224_2] - invttail(e(df_r),0.025)*_se[postreflntax_1224_2],_b[postreflntax_1224_3] - invttail(e(df_r),0.025)*_se[postreflntax_1224_3],_b[postreflntax_1224_4] - invttail(e(df_r),0.025)*_se[postreflntax_1224_4],_b[postreflntax_1224_5] - invttail(e(df_r),0.025)*_se[postreflntax_1224_5],_b[postreflntax_1224_6] - invttail(e(df_r),0.025)*_se[postreflntax_1224_6],_b[postreflntax_1224_7] - invttail(e(df_r),0.025)*_se[postreflntax_1224_7],_b[postreflntax_1224_8] - invttail(e(df_r),0.025)*_se[postreflntax_1224_8],_b[postreflntax_1224_9] - invttail(e(df_r),0.025)*_se[postreflntax_1224_9],_b[postreflntax_1224_10] - invttail(e(df_r),0.025)*_se[postreflntax_1224_10],_b[postreflntax_1224_11] - invttail(e(df_r),0.025)*_se[postreflntax_1224_11],_b[postreflntax_1224_12] - invttail(e(df_r),0.025)*_se[postreflntax_1224_12], ///
						_b[postreflntax_1224_13] - invttail(e(df_r),0.025)*_se[postreflntax_1224_13],_b[postreflntax_1224_14] - invttail(e(df_r),0.025)*_se[postreflntax_1224_14],_b[postreflntax_1224_15] - invttail(e(df_r),0.025)*_se[postreflntax_1224_15],_b[postreflntax_1224_16] - invttail(e(df_r),0.025)*_se[postreflntax_1224_16],_b[postreflntax_1224_17] - invttail(e(df_r),0.025)*_se[postreflntax_1224_17],_b[postreflntax_1224_18] - invttail(e(df_r),0.025)*_se[postreflntax_1224_18],_b[postreflntax_1224_19] - invttail(e(df_r),0.025)*_se[postreflntax_1224_19],_b[postreflntax_1224_20] - invttail(e(df_r),0.025)*_se[postreflntax_1224_20],_b[postreflntax_1224_21] - invttail(e(df_r),0.025)*_se[postreflntax_1224_21],_b[postreflntax_1224_22] - invttail(e(df_r),0.025)*_se[postreflntax_1224_22]]
						
						matrix upperb = [_b[prereflntax_1724_16] + invttail(e(df_r),0.025)*_se[prereflntax_1724_16], _b[prereflntax_1724_15] + invttail(e(df_r),0.025)*_se[prereflntax_1724_15], _b[prereflntax_1724_14] + invttail(e(df_r),0.025)*_se[prereflntax_1724_14], _b[prereflntax_1724_13] + invttail(e(df_r),0.025)*_se[prereflntax_1724_13],_b[prereflntax_1724_12] + invttail(e(df_r),0.025)*_se[prereflntax_1724_12], ///
						_b[prereflntax_1724_11] + invttail(e(df_r),0.025)*_se[prereflntax_1724_11], _b[prereflntax_1724_10] + invttail(e(df_r),0.025)*_se[prereflntax_1724_10], _b[prereflntax_1724_9] + invttail(e(df_r),0.025)*_se[prereflntax_1724_9], _b[prereflntax_1724_8] + invttail(e(df_r),0.025)*_se[prereflntax_1724_8], _b[prereflntax_1724_7] + invttail(e(df_r),0.025)*_se[prereflntax_1724_7], _b[prereflntax_1724_6] + invttail(e(df_r),0.025)*_se[prereflntax_1724_6], _b[prereflntax_1724_5] + invttail(e(df_r),0.025)*_se[prereflntax_1724_5], 0, _b[prereflntax_1724_3] + invttail(e(df_r),0.025)*_se[prereflntax_1724_3], _b[prereflntax_1724_2] + invttail(e(df_r),0.025)*_se[prereflntax_1724_2],_b[prereflntax_1724_1] + invttail(e(df_r),0.025)*_se[prereflntax_1724_1], ///
						_b[postreflntax_1224_0] + invttail(e(df_r),0.025)*_se[postreflntax_1224_0],_b[postreflntax_1224_1] + invttail(e(df_r),0.025)*_se[postreflntax_1224_1],_b[postreflntax_1224_2] + invttail(e(df_r),0.025)*_se[postreflntax_1224_2],_b[postreflntax_1224_3] + invttail(e(df_r),0.025)*_se[postreflntax_1224_3],_b[postreflntax_1224_4] + invttail(e(df_r),0.025)*_se[postreflntax_1224_4],_b[postreflntax_1224_5] + invttail(e(df_r),0.025)*_se[postreflntax_1224_5],_b[postreflntax_1224_6] + invttail(e(df_r),0.025)*_se[postreflntax_1224_6],_b[postreflntax_1224_7] + invttail(e(df_r),0.025)*_se[postreflntax_1224_7],_b[postreflntax_1224_8] + invttail(e(df_r),0.025)*_se[postreflntax_1224_8],_b[postreflntax_1224_9] + invttail(e(df_r),0.025)*_se[postreflntax_1224_9],_b[postreflntax_1224_10] + invttail(e(df_r),0.025)*_se[postreflntax_1224_10],_b[postreflntax_1224_11] + invttail(e(df_r),0.025)*_se[postreflntax_1224_11],_b[postreflntax_1224_12] + invttail(e(df_r),0.025)*_se[postreflntax_1224_12], ///
						_b[postreflntax_1224_13] + invttail(e(df_r),0.025)*_se[postreflntax_1224_13],_b[postreflntax_1224_14] + invttail(e(df_r),0.025)*_se[postreflntax_1224_14],_b[postreflntax_1224_15] + invttail(e(df_r),0.025)*_se[postreflntax_1224_15],_b[postreflntax_1224_16] + invttail(e(df_r),0.025)*_se[postreflntax_1224_16],_b[postreflntax_1224_17] + invttail(e(df_r),0.025)*_se[postreflntax_1224_17],_b[postreflntax_1224_18] + invttail(e(df_r),0.025)*_se[postreflntax_1224_18],_b[postreflntax_1224_19] + invttail(e(df_r),0.025)*_se[postreflntax_1224_19],_b[postreflntax_1224_20] + invttail(e(df_r),0.025)*_se[postreflntax_1224_20],_b[postreflntax_1224_21] + invttail(e(df_r),0.025)*_se[postreflntax_1224_21],_b[postreflntax_1224_22] + invttail(e(df_r),0.025)*_se[postreflntax_1224_22]]
						
						matrix res_`type' = [coeff2, 0, coeff1 \  -16, -15, -14, -13, -12, -11, -10, -9, -8, -7, -6, -5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22 \ upperb \ lowerb ]'
						svmat res_`type'
						scatter res_`type'1 res_`type'2, connect(l) yline(0) xline(-4) xline(0, lpattern(dash)) || rcap res_`type'3 res_`type'4 res_`type'2, scheme(s1color) xtitle("Months before/after tax increase") legend(label(1 "Price effect") label(2 "95% confidence interval")) xlab(-15 (5) 20) ylab(-2 "-2%"  0 "0%" 2 "2%" 4 "4%" 6 "6%") yscale(range(-2.5 6.5)) ytitle("Tax elasticity") 
						graph export "${graphs}\ESi_`file'_popgallwp_lognettax_`depvar'_`type'.pdf", replace
						matrix drop _all
						drop res_`type'*
					}
				}
				qui estimates drop *
			}
		}
	}
	
	global graphinput ehpetwp_noctrl_ife                                        
	use $depvars Nnachbar $prereftaxnb $postreftaxnb flaeche ersterpreis ort daysposted pricediff pricediff_pc $prereform $postreform $prereftax $prereftax17 prereftax_1224_4 $postreftax $prereflntax17 $postreflntax buildaged ln_flaeche zimmeranzahl basement balcony parking kitchen garden baujahrd heatingtype centralheat fancy fancyequip quietloc bright wmt* pricechpc jahr plz kreis ags bula betrag preisqm kreistyp monlast popg popgallwp05 popgallwp95 ln_bip ln_pop alq ln_debtpc using "${data}/F_u_B/ifo_etwp_4q19_prep_3624.dta", clear
	gen housetype = "etwp"
	append using "${data}/F_u_B/ifo_ehp_4q19_prep_3624.dta", keep($depvars Nnachbar $prereftaxnb $postreftaxnb flaeche ersterpreis ort daysposted pricediff pricediff_pc $prereform $postreform $prereftax $prereftax17 prereftax_1224_4 $postreftax $prereflntax17 $postreflntax buildaged ln_flaeche zimmeranzahl basement balcony parking kitchen garden baujahrd heatingtype centralheat fancy fancyequip quietloc bright wmt* pricechpc jahr plz kreis ags bula betrag preisqm kreistyp monlast popg popgallwp05 popgallwp95 ln_bip ln_pop alq ln_debtpc)
	replace housetype = "ehp" if housetype==""
	gen ehp = 0
	replace ehp = 1 if housetype == "ehp"
	gen etwp = 0
	replace etwp = 1 if housetype == "etwp"
	
	foreach pctype in popgallwp {
		foreach depvar of varlist $depvars {
	
			reghdfe `depvar' (c.(${prereflntax17}) c.(${postreflntax}))##i.etwp if popg>= `pctype'05 & popg<=`pctype'95, a(i.plz#i.etwp i.monlast#i.kreistyp#i.etwp) vce(cluster plz)
			estimates store ehpetwp_lognettax_ife_pfe, title(Int. trends)
			
			matrix b=e(b)
			matrix coeff1 = (b[1,70],b[1,72],b[1,74],b[1,76],b[1,78],b[1,80],b[1,82],b[1,84],b[1,86],b[1,88],b[1,90],b[1,92],b[1,94],b[1,96],b[1,98],b[1,100],b[1,102],b[1,104],b[1,106],b[1,108],b[1,110],b[1,112],b[1,114],b[1,116],b[1,118],b[1,120])
			matrix coeff2 = (b[1,46],b[1,48],b[1,50],b[1,52],b[1,54],b[1,56],b[1,58],b[1,60],b[1,62],b[1,64],b[1,66],b[1,68])
			
			matrix lowerb = [_b[1.etwp#c.prereflntax_1724_16] - invttail(e(df_r),0.025)*_se[1.etwp#c.prereflntax_1724_16], _b[1.etwp#c.prereflntax_1724_15] - invttail(e(df_r),0.025)*_se[1.etwp#c.prereflntax_1724_15], _b[1.etwp#c.prereflntax_1724_14] - invttail(e(df_r),0.025)*_se[1.etwp#c.prereflntax_1724_14], _b[1.etwp#c.prereflntax_1724_13] - invttail(e(df_r),0.025)*_se[1.etwp#c.prereflntax_1724_13], _b[1.etwp#c.prereflntax_1724_12] - invttail(e(df_r),0.025)*_se[1.etwp#c.prereflntax_1724_12], _b[1.etwp#c.prereflntax_1724_11] - invttail(e(df_r),0.025)*_se[1.etwp#c.prereflntax_1724_11], _b[1.etwp#c.prereflntax_1724_10] - invttail(e(df_r),0.025)*_se[1.etwp#c.prereflntax_1724_10], _b[1.etwp#c.prereflntax_1724_9] - invttail(e(df_r),0.025)*_se[1.etwp#c.prereflntax_1724_9], _b[1.etwp#c.prereflntax_1724_8] - invttail(e(df_r),0.025)*_se[1.etwp#c.prereflntax_1724_8], _b[1.etwp#c.prereflntax_1724_7] - invttail(e(df_r),0.025)*_se[1.etwp#c.prereflntax_1724_7], _b[1.etwp#c.prereflntax_1724_6] - invttail(e(df_r),0.025)*_se[1.etwp#c.prereflntax_1724_6], _b[1.etwp#c.prereflntax_1724_5] - invttail(e(df_r),0.025)*_se[1.etwp#c.prereflntax_1724_5], 0, _b[1.etwp#c.prereflntax_1724_3] - invttail(e(df_r),0.025)*_se[1.etwp#c.prereflntax_1724_3], _b[1.etwp#c.prereflntax_1724_2] - invttail(e(df_r),0.025)*_se[1.etwp#c.prereflntax_1724_2],_b[1.etwp#c.prereflntax_1724_1] - invttail(e(df_r),0.025)*_se[1.etwp#c.prereflntax_1724_1], ///
			_b[1.etwp#c.postreflntax_1224_0] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreflntax_1224_0],_b[1.etwp#c.postreflntax_1224_1] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreflntax_1224_1],_b[1.etwp#c.postreflntax_1224_2] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreflntax_1224_2],_b[1.etwp#c.postreflntax_1224_3] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreflntax_1224_3],_b[1.etwp#c.postreflntax_1224_4] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreflntax_1224_4],_b[1.etwp#c.postreflntax_1224_5] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreflntax_1224_5],_b[1.etwp#c.postreflntax_1224_6] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreflntax_1224_6],_b[1.etwp#c.postreflntax_1224_7] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreflntax_1224_7],_b[1.etwp#c.postreflntax_1224_8] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreflntax_1224_8],_b[1.etwp#c.postreflntax_1224_9] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreflntax_1224_9],_b[1.etwp#c.postreflntax_1224_10] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreflntax_1224_10],_b[1.etwp#c.postreflntax_1224_11] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreflntax_1224_11],_b[1.etwp#c.postreflntax_1224_12] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreflntax_1224_12] ///
			,_b[1.etwp#c.postreflntax_1224_13] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreflntax_1224_13],_b[1.etwp#c.postreflntax_1224_14] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreflntax_1224_14],_b[1.etwp#c.postreflntax_1224_15] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreflntax_1224_15],_b[1.etwp#c.postreflntax_1224_16] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreflntax_1224_16],_b[1.etwp#c.postreflntax_1224_17] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreflntax_1224_17],_b[1.etwp#c.postreflntax_1224_18] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreflntax_1224_18],_b[1.etwp#c.postreflntax_1224_19] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreflntax_1224_19],_b[1.etwp#c.postreflntax_1224_20] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreflntax_1224_20],_b[1.etwp#c.postreflntax_1224_21] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreflntax_1224_21],_b[1.etwp#c.postreflntax_1224_22] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreflntax_1224_22]]
			
			matrix upperb = [_b[1.etwp#c.prereflntax_1724_16] + invttail(e(df_r),0.025)*_se[1.etwp#c.prereflntax_1724_16], _b[1.etwp#c.prereflntax_1724_15] + invttail(e(df_r),0.025)*_se[1.etwp#c.prereflntax_1724_15], _b[1.etwp#c.prereflntax_1724_14] + invttail(e(df_r),0.025)*_se[1.etwp#c.prereflntax_1724_14], _b[1.etwp#c.prereflntax_1724_13] + invttail(e(df_r),0.025)*_se[1.etwp#c.prereflntax_1724_13], _b[1.etwp#c.prereflntax_1724_12] + invttail(e(df_r),0.025)*_se[1.etwp#c.prereflntax_1724_12], _b[1.etwp#c.prereflntax_1724_11] + invttail(e(df_r),0.025)*_se[1.etwp#c.prereflntax_1724_11], _b[1.etwp#c.prereflntax_1724_10] + invttail(e(df_r),0.025)*_se[1.etwp#c.prereflntax_1724_10], _b[1.etwp#c.prereflntax_1724_9] + invttail(e(df_r),0.025)*_se[1.etwp#c.prereflntax_1724_9], _b[1.etwp#c.prereflntax_1724_8] + invttail(e(df_r),0.025)*_se[1.etwp#c.prereflntax_1724_8], _b[1.etwp#c.prereflntax_1724_7] + invttail(e(df_r),0.025)*_se[1.etwp#c.prereflntax_1724_7], _b[1.etwp#c.prereflntax_1724_6] + invttail(e(df_r),0.025)*_se[1.etwp#c.prereflntax_1724_6], _b[1.etwp#c.prereflntax_1724_5] + invttail(e(df_r),0.025)*_se[1.etwp#c.prereflntax_1724_5], 0, _b[1.etwp#c.prereflntax_1724_3] + invttail(e(df_r),0.025)*_se[1.etwp#c.prereflntax_1724_3], _b[1.etwp#c.prereflntax_1724_2] + invttail(e(df_r),0.025)*_se[1.etwp#c.prereflntax_1724_2],_b[1.etwp#c.prereflntax_1724_1] + invttail(e(df_r),0.025)*_se[1.etwp#c.prereflntax_1724_1], ///
			_b[1.etwp#c.postreflntax_1224_0] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreflntax_1224_0],_b[1.etwp#c.postreflntax_1224_1] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreflntax_1224_1],_b[1.etwp#c.postreflntax_1224_2] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreflntax_1224_2],_b[1.etwp#c.postreflntax_1224_3] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreflntax_1224_3],_b[1.etwp#c.postreflntax_1224_4] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreflntax_1224_4],_b[1.etwp#c.postreflntax_1224_5] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreflntax_1224_5],_b[1.etwp#c.postreflntax_1224_6] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreflntax_1224_6],_b[1.etwp#c.postreflntax_1224_7] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreflntax_1224_7],_b[1.etwp#c.postreflntax_1224_8] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreflntax_1224_8],_b[1.etwp#c.postreflntax_1224_9] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreflntax_1224_9],_b[1.etwp#c.postreflntax_1224_10] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreflntax_1224_10],_b[1.etwp#c.postreflntax_1224_11] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreflntax_1224_11],_b[1.etwp#c.postreflntax_1224_12] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreflntax_1224_12] ///
			,_b[1.etwp#c.postreflntax_1224_13] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreflntax_1224_13],_b[1.etwp#c.postreflntax_1224_14] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreflntax_1224_14],_b[1.etwp#c.postreflntax_1224_15] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreflntax_1224_15],_b[1.etwp#c.postreflntax_1224_16] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreflntax_1224_16],_b[1.etwp#c.postreflntax_1224_17] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreflntax_1224_17],_b[1.etwp#c.postreflntax_1224_18] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreflntax_1224_18],_b[1.etwp#c.postreflntax_1224_19] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreflntax_1224_19],_b[1.etwp#c.postreflntax_1224_20] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreflntax_1224_20],_b[1.etwp#c.postreflntax_1224_21] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreflntax_1224_21],_b[1.etwp#c.postreflntax_1224_22] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreflntax_1224_22]]
			
			matrix res_ehpetwp_lognettax_ife_pfe = [coeff2, 0, coeff1 \  -16, -15, -14, -13, -12, -11, -10, -9, -8, -7, -6, -5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22 \ upperb \ lowerb ]'
			svmat  res_ehpetwp_lognettax_ife_pfe
			scatter res_ehpetwp_lognettax_ife_pfe1 res_ehpetwp_lognettax_ife_pfe2, connect(l) yline(0) xline(-4) xline(0, lpattern(dash)) || rcap res_ehpetwp_lognettax_ife_pfe3 res_ehpetwp_lognettax_ife_pfe4 res_ehpetwp_lognettax_ife_pfe2, scheme(s1color) xtitle("Months before/after tax increase") legend(label(1 "Difference SFH-APT") label(2 "95% confidence interval")) xlab(-15 (5) 20) ylab(-2 "-2%"  0 "0%" 2 "2%" 4 "4%" 6 "6%") yscale(range(-2.5 6.5)) ytitle("Difference") 
			graph export "${graphs}\ESi_diff_popgallwp_deltatax_`depvar'_ehpetwp_lognettax_ife_pfe.pdf", replace
			matrix drop _all
			drop res_ehpetwp_lognettax_ife_pfe*
		}
	}	
}

if $FigureA6 == 1 {
	foreach file of global files {
		use $depvars $prereform $postreform $prereftax17 $postreftax $prereflntax $postreflntax buildaged ln_flaeche zimmeranzahl basement balcony parking kitchen garden baujahrd heatingtype centralheat fancy fancyequip quietloc bright wmt* pricechpc jahr plz betrag preisqm kreistyp monlast ln_bip ln_pop alq ln_debtpc popg popgallwp05 popgallwp95 using "${data}/F_u_B/ifo_`file'_4q19_prep_3624.dta", clear

		foreach pctype in popgallwp {
			foreach depvar of varlist $depvars {
				qui {
					xtreg `depvar' $prereftax17 $postreftax i.monlast#i.kreistyp ${ctrl1} if popg>= `pctype'05 & popg<=`pctype'95, fe vce(cluster plz)
					estimates store `file'_ctrl_ife, title(Int. trends)
				}
				display "Event study, all distances, `depvar'"
				estout `file'*ctrl*, varwidth(30) cells(b(star fmt(3)) se(fmt(3)) p(par fmt(3))) starlevels(* 0.05 ** 0.01 *** 0.001) stats(r2 ar2_w N, labels("R^2" "R^2 within" N) fmt(3 0)) keep($prereftax17 $postreftax) style(fixed) label collabels(none) replace
				qui {
					foreach type in `file'_ctrl_ife {
						estimates restore `type'
						matrix b=e(b)
						matrix coeff1 = b[1,14..39]
						matrix coeff2 = b[1,2..13]

						matrix lowerb = [_b[prereftax_1724_16] - invttail(e(df_r),0.025)*_se[prereftax_1724_16], _b[prereftax_1724_15] - invttail(e(df_r),0.025)*_se[prereftax_1724_15], _b[prereftax_1724_14] - invttail(e(df_r),0.025)*_se[prereftax_1724_14], _b[prereftax_1724_13] - invttail(e(df_r),0.025)*_se[prereftax_1724_13],_b[prereftax_1724_12] - invttail(e(df_r),0.025)*_se[prereftax_1724_12], ///
						_b[prereftax_1724_11] - invttail(e(df_r),0.025)*_se[prereftax_1724_11], _b[prereftax_1724_10] - invttail(e(df_r),0.025)*_se[prereftax_1724_10], _b[prereftax_1724_9] - invttail(e(df_r),0.025)*_se[prereftax_1724_9], _b[prereftax_1724_8] - invttail(e(df_r),0.025)*_se[prereftax_1724_8], _b[prereftax_1724_7] - invttail(e(df_r),0.025)*_se[prereftax_1724_7], _b[prereftax_1724_6] - invttail(e(df_r),0.025)*_se[prereftax_1724_6], _b[prereftax_1724_5] - invttail(e(df_r),0.025)*_se[prereftax_1724_5], 0, _b[prereftax_1724_3] - invttail(e(df_r),0.025)*_se[prereftax_1724_3], _b[prereftax_1724_2] - invttail(e(df_r),0.025)*_se[prereftax_1724_2],_b[prereftax_1724_1] - invttail(e(df_r),0.025)*_se[prereftax_1724_1], ///
						_b[postreftax_1224_0] - invttail(e(df_r),0.025)*_se[postreftax_1224_0],_b[postreftax_1224_1] - invttail(e(df_r),0.025)*_se[postreftax_1224_1],_b[postreftax_1224_2] - invttail(e(df_r),0.025)*_se[postreftax_1224_2],_b[postreftax_1224_3] - invttail(e(df_r),0.025)*_se[postreftax_1224_3],_b[postreftax_1224_4] - invttail(e(df_r),0.025)*_se[postreftax_1224_4],_b[postreftax_1224_5] - invttail(e(df_r),0.025)*_se[postreftax_1224_5],_b[postreftax_1224_6] - invttail(e(df_r),0.025)*_se[postreftax_1224_6],_b[postreftax_1224_7] - invttail(e(df_r),0.025)*_se[postreftax_1224_7],_b[postreftax_1224_8] - invttail(e(df_r),0.025)*_se[postreftax_1224_8],_b[postreftax_1224_9] - invttail(e(df_r),0.025)*_se[postreftax_1224_9],_b[postreftax_1224_10] - invttail(e(df_r),0.025)*_se[postreftax_1224_10],_b[postreftax_1224_11] - invttail(e(df_r),0.025)*_se[postreftax_1224_11],_b[postreftax_1224_12] - invttail(e(df_r),0.025)*_se[postreftax_1224_12], ///
						_b[postreftax_1224_13] - invttail(e(df_r),0.025)*_se[postreftax_1224_13],_b[postreftax_1224_14] - invttail(e(df_r),0.025)*_se[postreftax_1224_14],_b[postreftax_1224_15] - invttail(e(df_r),0.025)*_se[postreftax_1224_15],_b[postreftax_1224_16] - invttail(e(df_r),0.025)*_se[postreftax_1224_16],_b[postreftax_1224_17] - invttail(e(df_r),0.025)*_se[postreftax_1224_17],_b[postreftax_1224_18] - invttail(e(df_r),0.025)*_se[postreftax_1224_18],_b[postreftax_1224_19] - invttail(e(df_r),0.025)*_se[postreftax_1224_19],_b[postreftax_1224_20] - invttail(e(df_r),0.025)*_se[postreftax_1224_20],_b[postreftax_1224_21] - invttail(e(df_r),0.025)*_se[postreftax_1224_21],_b[postreftax_1224_22] - invttail(e(df_r),0.025)*_se[postreftax_1224_22]]
						
						matrix upperb = [_b[prereftax_1724_16] + invttail(e(df_r),0.025)*_se[prereftax_1724_16], _b[prereftax_1724_15] + invttail(e(df_r),0.025)*_se[prereftax_1724_15], _b[prereftax_1724_14] + invttail(e(df_r),0.025)*_se[prereftax_1724_14], _b[prereftax_1724_13] + invttail(e(df_r),0.025)*_se[prereftax_1724_13],_b[prereftax_1724_12] + invttail(e(df_r),0.025)*_se[prereftax_1724_12], ///
						_b[prereftax_1724_11] + invttail(e(df_r),0.025)*_se[prereftax_1724_11], _b[prereftax_1724_10] + invttail(e(df_r),0.025)*_se[prereftax_1724_10], _b[prereftax_1724_9] + invttail(e(df_r),0.025)*_se[prereftax_1724_9], _b[prereftax_1724_8] + invttail(e(df_r),0.025)*_se[prereftax_1724_8], _b[prereftax_1724_7] + invttail(e(df_r),0.025)*_se[prereftax_1724_7], _b[prereftax_1724_6] + invttail(e(df_r),0.025)*_se[prereftax_1724_6], _b[prereftax_1724_5] + invttail(e(df_r),0.025)*_se[prereftax_1724_5], 0, _b[prereftax_1724_3] + invttail(e(df_r),0.025)*_se[prereftax_1724_3], _b[prereftax_1724_2] + invttail(e(df_r),0.025)*_se[prereftax_1724_2],_b[prereftax_1724_1] + invttail(e(df_r),0.025)*_se[prereftax_1724_1], ///
						_b[postreftax_1224_0] + invttail(e(df_r),0.025)*_se[postreftax_1224_0],_b[postreftax_1224_1] + invttail(e(df_r),0.025)*_se[postreftax_1224_1],_b[postreftax_1224_2] + invttail(e(df_r),0.025)*_se[postreftax_1224_2],_b[postreftax_1224_3] + invttail(e(df_r),0.025)*_se[postreftax_1224_3],_b[postreftax_1224_4] + invttail(e(df_r),0.025)*_se[postreftax_1224_4],_b[postreftax_1224_5] + invttail(e(df_r),0.025)*_se[postreftax_1224_5],_b[postreftax_1224_6] + invttail(e(df_r),0.025)*_se[postreftax_1224_6],_b[postreftax_1224_7] + invttail(e(df_r),0.025)*_se[postreftax_1224_7],_b[postreftax_1224_8] + invttail(e(df_r),0.025)*_se[postreftax_1224_8],_b[postreftax_1224_9] + invttail(e(df_r),0.025)*_se[postreftax_1224_9],_b[postreftax_1224_10] + invttail(e(df_r),0.025)*_se[postreftax_1224_10],_b[postreftax_1224_11] + invttail(e(df_r),0.025)*_se[postreftax_1224_11],_b[postreftax_1224_12] + invttail(e(df_r),0.025)*_se[postreftax_1224_12], ///
						_b[postreftax_1224_13] + invttail(e(df_r),0.025)*_se[postreftax_1224_13],_b[postreftax_1224_14] + invttail(e(df_r),0.025)*_se[postreftax_1224_14],_b[postreftax_1224_15] + invttail(e(df_r),0.025)*_se[postreftax_1224_15],_b[postreftax_1224_16] + invttail(e(df_r),0.025)*_se[postreftax_1224_16],_b[postreftax_1224_17] + invttail(e(df_r),0.025)*_se[postreftax_1224_17],_b[postreftax_1224_18] + invttail(e(df_r),0.025)*_se[postreftax_1224_18],_b[postreftax_1224_19] + invttail(e(df_r),0.025)*_se[postreftax_1224_19],_b[postreftax_1224_20] + invttail(e(df_r),0.025)*_se[postreftax_1224_20],_b[postreftax_1224_21] + invttail(e(df_r),0.025)*_se[postreftax_1224_21],_b[postreftax_1224_22] + invttail(e(df_r),0.025)*_se[postreftax_1224_22]]
						
						matrix res_`type' = [coeff2, 0, coeff1 \  -16, -15, -14, -13, -12, -11, -10, -9, -8, -7, -6, -5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22 \ upperb \ lowerb ]'
						svmat res_`type'
						scatter res_`type'1 res_`type'2, connect(l) yline(0) xline(-4) xline(0, lpattern(dash)) || rcap res_`type'3 res_`type'4 res_`type'2, scheme(s1color) xtitle("Months before/after tax increase") legend(label(1 "Price effect") label(2 "95% confidence interval")) xlab(-15 (5) 20) ylab(-.06 "-6%" -.04 "-4%" -.02 "-2%" 0 "0%" .02 "2%") yscale(range(-0.065 0.025)) ytitle("Tax semi-elasticity")
						graph export "${graphs}\ESi_`file'_ctrl_`pctype'_deltatax_`depvar'_`type'.pdf", replace
						matrix drop _all
						drop res_`type'*
					}
				}
				qui estimates drop *
			}
		}
	}
	
	global graphinput ehpetwp_noctrl_ife                                        
	use $depvars Nnachbar $prereftaxnb $postreftaxnb flaeche ersterpreis ort daysposted pricediff pricediff_pc $prereform $postreform $prereftax $prereftax17 prereftax_1224_4 $postreftax $prereflntax17 $postreflntax buildaged ln_flaeche zimmeranzahl basement balcony parking kitchen garden baujahrd heatingtype centralheat fancy fancyequip quietloc bright wmt* pricechpc jahr plz kreis ags bula betrag preisqm kreistyp monlast popg popgallwp05 popgallwp95 ln_bip ln_pop alq ln_debtpc using "${data}/F_u_B/ifo_etwp_4q19_prep_3624.dta", clear
	gen housetype = "etwp"
	append using "${data}/F_u_B/ifo_ehp_4q19_prep_3624.dta", keep($depvars Nnachbar $prereftaxnb $postreftaxnb flaeche ersterpreis ort daysposted pricediff pricediff_pc $prereform $postreform $prereftax $prereftax17 prereftax_1224_4 $postreftax $prereflntax17 $postreflntax buildaged ln_flaeche zimmeranzahl basement balcony parking kitchen garden baujahrd heatingtype centralheat fancy fancyequip quietloc bright wmt* pricechpc jahr plz kreis ags bula betrag preisqm kreistyp monlast popg popgallwp05 popgallwp95 ln_bip ln_pop alq ln_debtpc)
	replace housetype = "ehp" if housetype==""
	gen ehp = 0
	replace ehp = 1 if housetype == "ehp"
	gen etwp = 0
	replace etwp = 1 if housetype == "etwp"
	
	foreach pctype in popgallwp {
		foreach depvar of varlist $depvars {
			reghdfe `depvar' (c.(${prereftax17}) c.(${postreftax}))##i.etwp ${ctrl1}##i.etwp if popg>= `pctype'05 & popg<=`pctype'95, a(i.plz#i.etwp i.monlast#i.kreistyp#i.etwp) vce(cluster plz)
			estimates store ehpetwp_ctrl_ife_pfe, title(Int. trends)
			
			matrix b=e(b)
			matrix coeff1 = (b[1,70],b[1,72],b[1,74],b[1,76],b[1,78],b[1,80],b[1,82],b[1,84],b[1,86],b[1,88],b[1,90],b[1,92],b[1,94],b[1,96],b[1,98],b[1,100],b[1,102],b[1,104],b[1,106],b[1,108],b[1,110],b[1,112],b[1,114],b[1,116],b[1,118],b[1,120])
			matrix coeff2 = (b[1,46],b[1,48],b[1,50],b[1,52],b[1,54],b[1,56],b[1,58],b[1,60],b[1,62],b[1,64],b[1,66],b[1,68])
			matrix lowerb = [_b[1.etwp#c.prereftax_1724_16] - invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_16], _b[1.etwp#c.prereftax_1724_15] - invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_15], _b[1.etwp#c.prereftax_1724_14] - invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_14], _b[1.etwp#c.prereftax_1724_13] - invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_13], _b[1.etwp#c.prereftax_1724_12] - invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_12], _b[1.etwp#c.prereftax_1724_11] - invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_11], _b[1.etwp#c.prereftax_1724_10] - invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_10], _b[1.etwp#c.prereftax_1724_9] - invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_9], _b[1.etwp#c.prereftax_1724_8] - invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_8], _b[1.etwp#c.prereftax_1724_7] - invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_7], _b[1.etwp#c.prereftax_1724_6] - invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_6], _b[1.etwp#c.prereftax_1724_5] - invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_5], 0, _b[1.etwp#c.prereftax_1724_3] - invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_3], _b[1.etwp#c.prereftax_1724_2] - invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_2],_b[1.etwp#c.prereftax_1724_1] - invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_1], ///
			_b[1.etwp#c.postreftax_1224_0] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_0],_b[1.etwp#c.postreftax_1224_1] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_1],_b[1.etwp#c.postreftax_1224_2] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_2],_b[1.etwp#c.postreftax_1224_3] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_3],_b[1.etwp#c.postreftax_1224_4] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_4],_b[1.etwp#c.postreftax_1224_5] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_5],_b[1.etwp#c.postreftax_1224_6] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_6],_b[1.etwp#c.postreftax_1224_7] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_7],_b[1.etwp#c.postreftax_1224_8] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_8],_b[1.etwp#c.postreftax_1224_9] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_9],_b[1.etwp#c.postreftax_1224_10] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_10],_b[1.etwp#c.postreftax_1224_11] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_11],_b[1.etwp#c.postreftax_1224_12] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_12] ///
			,_b[1.etwp#c.postreftax_1224_13] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_13],_b[1.etwp#c.postreftax_1224_14] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_14],_b[1.etwp#c.postreftax_1224_15] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_15],_b[1.etwp#c.postreftax_1224_16] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_16],_b[1.etwp#c.postreftax_1224_17] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_17],_b[1.etwp#c.postreftax_1224_18] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_18],_b[1.etwp#c.postreftax_1224_19] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_19],_b[1.etwp#c.postreftax_1224_20] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_20],_b[1.etwp#c.postreftax_1224_21] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_21],_b[1.etwp#c.postreftax_1224_22] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_22]]
			
			matrix upperb = [_b[1.etwp#c.prereftax_1724_16] + invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_16], _b[1.etwp#c.prereftax_1724_15] + invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_15], _b[1.etwp#c.prereftax_1724_14] + invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_14], _b[1.etwp#c.prereftax_1724_13] + invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_13], _b[1.etwp#c.prereftax_1724_12] + invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_12], _b[1.etwp#c.prereftax_1724_11] + invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_11], _b[1.etwp#c.prereftax_1724_10] + invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_10], _b[1.etwp#c.prereftax_1724_9] + invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_9], _b[1.etwp#c.prereftax_1724_8] + invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_8], _b[1.etwp#c.prereftax_1724_7] + invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_7], _b[1.etwp#c.prereftax_1724_6] + invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_6], _b[1.etwp#c.prereftax_1724_5] + invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_5], 0, _b[1.etwp#c.prereftax_1724_3] + invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_3], _b[1.etwp#c.prereftax_1724_2] + invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_2],_b[1.etwp#c.prereftax_1724_1] + invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_1], ///
			_b[1.etwp#c.postreftax_1224_0] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_0],_b[1.etwp#c.postreftax_1224_1] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_1],_b[1.etwp#c.postreftax_1224_2] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_2],_b[1.etwp#c.postreftax_1224_3] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_3],_b[1.etwp#c.postreftax_1224_4] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_4],_b[1.etwp#c.postreftax_1224_5] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_5],_b[1.etwp#c.postreftax_1224_6] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_6],_b[1.etwp#c.postreftax_1224_7] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_7],_b[1.etwp#c.postreftax_1224_8] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_8],_b[1.etwp#c.postreftax_1224_9] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_9],_b[1.etwp#c.postreftax_1224_10] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_10],_b[1.etwp#c.postreftax_1224_11] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_11],_b[1.etwp#c.postreftax_1224_12] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_12] ///
			,_b[1.etwp#c.postreftax_1224_13] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_13],_b[1.etwp#c.postreftax_1224_14] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_14],_b[1.etwp#c.postreftax_1224_15] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_15],_b[1.etwp#c.postreftax_1224_16] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_16],_b[1.etwp#c.postreftax_1224_17] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_17],_b[1.etwp#c.postreftax_1224_18] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_18],_b[1.etwp#c.postreftax_1224_19] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_19],_b[1.etwp#c.postreftax_1224_20] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_20],_b[1.etwp#c.postreftax_1224_21] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_21],_b[1.etwp#c.postreftax_1224_22] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_22]]
			
			matrix res_ehpetwp_ctrl_ife_pfe = [coeff2, 0, coeff1 \  -16, -15, -14, -13, -12, -11, -10, -9, -8, -7, -6, -5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22 \ upperb \ lowerb ]'
			svmat  res_ehpetwp_ctrl_ife_pfe
			scatter res_ehpetwp_ctrl_ife_pfe1 res_ehpetwp_ctrl_ife_pfe2, connect(l) yline(0) xline(-4) xline(0, lpattern(dash)) || rcap res_ehpetwp_ctrl_ife_pfe3 res_ehpetwp_ctrl_ife_pfe4 res_ehpetwp_ctrl_ife_pfe2, scheme(s1color) xtitle("Months before/after tax increase") legend(label(1 "Difference SFH-APT") label(2 "95% confidence interval")) xlab(-15 (5) 20) ylab(-.06 "-6%" -.04 "-4%" -.02 "-2%" 0 "0%" .02 "2%") yscale(range(-0.065 0.025)) ytitle("Difference")  
			graph export "${graphs}\ESi_diff_popgallwp_deltatax_`depvar'_ehpetwp_ctrl_ife_pfe.pdf", replace
			matrix drop _all
			drop res_ehpetwp_ctrl_ife_pfe*
		}
	}
}

if $FigureA7 == 1 {
	foreach file of global files {
	
		global graphinput  `file'_noctrl_ife
		use $depvars $prereform $postreform $prereftax17 $postreftax $prereflntax $postreflntax buildaged ln_flaeche zimmeranzahl basement balcony parking kitchen garden baujahrd heatingtype centralheat fancy fancyequip quietloc bright wmt* pricechpc jahr plz betrag preisqm kreistyp monlast popg popgallwp05 popgallwp95 ln_bip ln_pop alq ln_debtpc using "${data}/F_u_B/ifo_`file'_4q19_prep_3624.dta", clear
		
		foreach pctype in popgallwp {
			foreach depvar of varlist $depvars {
				qui {
					xtreg `depvar' $prereftax17 $postreftax i.monlast#i.kreistyp ln_bip alq ln_debtpc if popg>= `pctype'05 & popg<=`pctype'95, fe vce(cluster plz)					
					estimates store `file'_noctrl_ife, title(Int. trends)
				}
				display "Event study, continuous treatment, all distances, `depvar'"
				estout `file'*ctrl*, varwidth(30) cells(b(star fmt(3)) se(fmt(3)) p(par fmt(3))) starlevels(* 0.05 ** 0.01 *** 0.001) stats(r2 ar2_w N, labels("R^2" "R^2 within" N) fmt(3 0)) keep($prereftax17 $postreftax) style(fixed) label collabels(none) replace
				qui {
					foreach type in $graphinput {
						estimates restore `type'
						matrix b=e(b)
						matrix coeff1 = b[1,14..39]
						matrix coeff2 = b[1,2..13]
			
						matrix lowerb = [_b[prereftax_1724_16] - invttail(e(df_r),0.025)*_se[prereftax_1724_16], _b[prereftax_1724_15] - invttail(e(df_r),0.025)*_se[prereftax_1724_15], _b[prereftax_1724_14] - invttail(e(df_r),0.025)*_se[prereftax_1724_14], _b[prereftax_1724_13] - invttail(e(df_r),0.025)*_se[prereftax_1724_13],_b[prereftax_1724_12] - invttail(e(df_r),0.025)*_se[prereftax_1724_12], ///
						_b[prereftax_1724_11] - invttail(e(df_r),0.025)*_se[prereftax_1724_11], _b[prereftax_1724_10] - invttail(e(df_r),0.025)*_se[prereftax_1724_10], _b[prereftax_1724_9] - invttail(e(df_r),0.025)*_se[prereftax_1724_9], _b[prereftax_1724_8] - invttail(e(df_r),0.025)*_se[prereftax_1724_8], _b[prereftax_1724_7] - invttail(e(df_r),0.025)*_se[prereftax_1724_7], _b[prereftax_1724_6] - invttail(e(df_r),0.025)*_se[prereftax_1724_6], _b[prereftax_1724_5] - invttail(e(df_r),0.025)*_se[prereftax_1724_5], 0, _b[prereftax_1724_3] - invttail(e(df_r),0.025)*_se[prereftax_1724_3], _b[prereftax_1724_2] - invttail(e(df_r),0.025)*_se[prereftax_1724_2],_b[prereftax_1724_1] - invttail(e(df_r),0.025)*_se[prereftax_1724_1], ///
						_b[postreftax_1224_0] - invttail(e(df_r),0.025)*_se[postreftax_1224_0],_b[postreftax_1224_1] - invttail(e(df_r),0.025)*_se[postreftax_1224_1],_b[postreftax_1224_2] - invttail(e(df_r),0.025)*_se[postreftax_1224_2],_b[postreftax_1224_3] - invttail(e(df_r),0.025)*_se[postreftax_1224_3],_b[postreftax_1224_4] - invttail(e(df_r),0.025)*_se[postreftax_1224_4],_b[postreftax_1224_5] - invttail(e(df_r),0.025)*_se[postreftax_1224_5],_b[postreftax_1224_6] - invttail(e(df_r),0.025)*_se[postreftax_1224_6],_b[postreftax_1224_7] - invttail(e(df_r),0.025)*_se[postreftax_1224_7],_b[postreftax_1224_8] - invttail(e(df_r),0.025)*_se[postreftax_1224_8],_b[postreftax_1224_9] - invttail(e(df_r),0.025)*_se[postreftax_1224_9],_b[postreftax_1224_10] - invttail(e(df_r),0.025)*_se[postreftax_1224_10],_b[postreftax_1224_11] - invttail(e(df_r),0.025)*_se[postreftax_1224_11],_b[postreftax_1224_12] - invttail(e(df_r),0.025)*_se[postreftax_1224_12], ///
						_b[postreftax_1224_13] - invttail(e(df_r),0.025)*_se[postreftax_1224_13],_b[postreftax_1224_14] - invttail(e(df_r),0.025)*_se[postreftax_1224_14],_b[postreftax_1224_15] - invttail(e(df_r),0.025)*_se[postreftax_1224_15],_b[postreftax_1224_16] - invttail(e(df_r),0.025)*_se[postreftax_1224_16],_b[postreftax_1224_17] - invttail(e(df_r),0.025)*_se[postreftax_1224_17],_b[postreftax_1224_18] - invttail(e(df_r),0.025)*_se[postreftax_1224_18],_b[postreftax_1224_19] - invttail(e(df_r),0.025)*_se[postreftax_1224_19],_b[postreftax_1224_20] - invttail(e(df_r),0.025)*_se[postreftax_1224_20],_b[postreftax_1224_21] - invttail(e(df_r),0.025)*_se[postreftax_1224_21],_b[postreftax_1224_22] - invttail(e(df_r),0.025)*_se[postreftax_1224_22]]
						
						matrix upperb = [_b[prereftax_1724_16] + invttail(e(df_r),0.025)*_se[prereftax_1724_16], _b[prereftax_1724_15] + invttail(e(df_r),0.025)*_se[prereftax_1724_15], _b[prereftax_1724_14] + invttail(e(df_r),0.025)*_se[prereftax_1724_14], _b[prereftax_1724_13] + invttail(e(df_r),0.025)*_se[prereftax_1724_13],_b[prereftax_1724_12] + invttail(e(df_r),0.025)*_se[prereftax_1724_12], ///
						_b[prereftax_1724_11] + invttail(e(df_r),0.025)*_se[prereftax_1724_11], _b[prereftax_1724_10] + invttail(e(df_r),0.025)*_se[prereftax_1724_10], _b[prereftax_1724_9] + invttail(e(df_r),0.025)*_se[prereftax_1724_9], _b[prereftax_1724_8] + invttail(e(df_r),0.025)*_se[prereftax_1724_8], _b[prereftax_1724_7] + invttail(e(df_r),0.025)*_se[prereftax_1724_7], _b[prereftax_1724_6] + invttail(e(df_r),0.025)*_se[prereftax_1724_6], _b[prereftax_1724_5] + invttail(e(df_r),0.025)*_se[prereftax_1724_5], 0, _b[prereftax_1724_3] + invttail(e(df_r),0.025)*_se[prereftax_1724_3], _b[prereftax_1724_2] + invttail(e(df_r),0.025)*_se[prereftax_1724_2],_b[prereftax_1724_1] + invttail(e(df_r),0.025)*_se[prereftax_1724_1], ///
						_b[postreftax_1224_0] + invttail(e(df_r),0.025)*_se[postreftax_1224_0],_b[postreftax_1224_1] + invttail(e(df_r),0.025)*_se[postreftax_1224_1],_b[postreftax_1224_2] + invttail(e(df_r),0.025)*_se[postreftax_1224_2],_b[postreftax_1224_3] + invttail(e(df_r),0.025)*_se[postreftax_1224_3],_b[postreftax_1224_4] + invttail(e(df_r),0.025)*_se[postreftax_1224_4],_b[postreftax_1224_5] + invttail(e(df_r),0.025)*_se[postreftax_1224_5],_b[postreftax_1224_6] + invttail(e(df_r),0.025)*_se[postreftax_1224_6],_b[postreftax_1224_7] + invttail(e(df_r),0.025)*_se[postreftax_1224_7],_b[postreftax_1224_8] + invttail(e(df_r),0.025)*_se[postreftax_1224_8],_b[postreftax_1224_9] + invttail(e(df_r),0.025)*_se[postreftax_1224_9],_b[postreftax_1224_10] + invttail(e(df_r),0.025)*_se[postreftax_1224_10],_b[postreftax_1224_11] + invttail(e(df_r),0.025)*_se[postreftax_1224_11],_b[postreftax_1224_12] + invttail(e(df_r),0.025)*_se[postreftax_1224_12], ///
						_b[postreftax_1224_13] + invttail(e(df_r),0.025)*_se[postreftax_1224_13],_b[postreftax_1224_14] + invttail(e(df_r),0.025)*_se[postreftax_1224_14],_b[postreftax_1224_15] + invttail(e(df_r),0.025)*_se[postreftax_1224_15],_b[postreftax_1224_16] + invttail(e(df_r),0.025)*_se[postreftax_1224_16],_b[postreftax_1224_17] + invttail(e(df_r),0.025)*_se[postreftax_1224_17],_b[postreftax_1224_18] + invttail(e(df_r),0.025)*_se[postreftax_1224_18],_b[postreftax_1224_19] + invttail(e(df_r),0.025)*_se[postreftax_1224_19],_b[postreftax_1224_20] + invttail(e(df_r),0.025)*_se[postreftax_1224_20],_b[postreftax_1224_21] + invttail(e(df_r),0.025)*_se[postreftax_1224_21],_b[postreftax_1224_22] + invttail(e(df_r),0.025)*_se[postreftax_1224_22]]
						
						
						matrix res_`type' = [coeff2, 0, coeff1 \  -16, -15, -14, -13, -12, -11, -10, -9, -8, -7, -6, -5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22 \ upperb \ lowerb ]'
						svmat res_`type'
						scatter res_`type'1 res_`type'2, connect(l) yline(0) xline(-4) xline(0, lpattern(dash)) || rcap res_`type'3 res_`type'4 res_`type'2, scheme(s1color) xtitle("Months before/after tax increase") legend(label(1 "Price effect") label(2 "95% confidence interval")) xlab(-15 (5) 20) ylab(-.06 "-6%" -.04 "-4%" -.02 "-2%" 0 "0%" .02 "2%") yscale(range(-0.065 0.025)) ytitle("Tax semi-elasticity")
						graph export "${graphs}\ESi_`file'_regctrl2_`pctype'_deltatax_`depvar'_`type'ohne_pop.pdf", replace
						matrix drop _all
						drop res_`type'*
					}
				}
				qui estimates drop *
			}
		}
	}
	global graphinput ehpetwp_noctrl_ife                                        
	use $depvars Nnachbar $prereftaxnb $postreftaxnb flaeche ersterpreis ort daysposted pricediff pricediff_pc $prereform $postreform $prereftax $prereftax17 prereftax_1224_4 $postreftax $prereflntax17 $postreflntax buildaged ln_flaeche zimmeranzahl basement balcony parking kitchen garden baujahrd heatingtype centralheat fancy fancyequip quietloc bright wmt* pricechpc jahr plz kreis ags bula betrag preisqm kreistyp monlast popg popgallwp05 popgallwp95 ln_bip ln_pop alq ln_debtpc using "${data}/F_u_B/ifo_etwp_4q19_prep_3624.dta", clear
	gen housetype = "etwp"
	append using "${data}/F_u_B/ifo_ehp_4q19_prep_3624.dta", keep($depvars Nnachbar $prereftaxnb $postreftaxnb flaeche ersterpreis ort daysposted pricediff pricediff_pc $prereform $postreform $prereftax $prereftax17 prereftax_1224_4 $postreftax $prereflntax17 $postreflntax buildaged ln_flaeche zimmeranzahl basement balcony parking kitchen garden baujahrd heatingtype centralheat fancy fancyequip quietloc bright wmt* pricechpc jahr plz kreis ags bula betrag preisqm kreistyp monlast popg popgallwp05 popgallwp95 ln_bip ln_pop alq ln_debtpc)
	replace housetype = "ehp" if housetype==""
	gen ehp = 0
	replace ehp = 1 if housetype == "ehp"
	gen etwp = 0
	replace etwp = 1 if housetype == "etwp"
	
	foreach pctype in popgallwp {
		foreach depvar of varlist $depvars {
			reghdfe `depvar' (c.(${prereftax17}) c.(${postreftax}))##i.etwp (c.(ln_bip alq ln_debtpc))##i.etwp if popg>= `pctype'05 & popg<=`pctype'95, a(i.plz#i.etwp i.monlast#i.kreistyp#i.etwp) vce(cluster plz)
			estimates store ehpetwp_regctrl2_ife_pfe, title(Int. trends)
			
			matrix b=e(b)
			matrix coeff1 = (b[1,70],b[1,72],b[1,74],b[1,76],b[1,78],b[1,80],b[1,82],b[1,84],b[1,86],b[1,88],b[1,90],b[1,92],b[1,94],b[1,96],b[1,98],b[1,100],b[1,102],b[1,104],b[1,106],b[1,108],b[1,110],b[1,112],b[1,114],b[1,116],b[1,118],b[1,120])
			matrix coeff2 = (b[1,46],b[1,48],b[1,50],b[1,52],b[1,54],b[1,56],b[1,58],b[1,60],b[1,62],b[1,64],b[1,66],b[1,68])
			matrix lowerb = [_b[1.etwp#c.prereftax_1724_16] - invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_16], _b[1.etwp#c.prereftax_1724_15] - invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_15], _b[1.etwp#c.prereftax_1724_14] - invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_14], _b[1.etwp#c.prereftax_1724_13] - invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_13], _b[1.etwp#c.prereftax_1724_12] - invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_12], _b[1.etwp#c.prereftax_1724_11] - invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_11], _b[1.etwp#c.prereftax_1724_10] - invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_10], _b[1.etwp#c.prereftax_1724_9] - invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_9], _b[1.etwp#c.prereftax_1724_8] - invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_8], _b[1.etwp#c.prereftax_1724_7] - invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_7], _b[1.etwp#c.prereftax_1724_6] - invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_6], _b[1.etwp#c.prereftax_1724_5] - invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_5], 0, _b[1.etwp#c.prereftax_1724_3] - invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_3], _b[1.etwp#c.prereftax_1724_2] - invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_2],_b[1.etwp#c.prereftax_1724_1] - invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_1], ///
			_b[1.etwp#c.postreftax_1224_0] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_0],_b[1.etwp#c.postreftax_1224_1] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_1],_b[1.etwp#c.postreftax_1224_2] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_2],_b[1.etwp#c.postreftax_1224_3] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_3],_b[1.etwp#c.postreftax_1224_4] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_4],_b[1.etwp#c.postreftax_1224_5] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_5],_b[1.etwp#c.postreftax_1224_6] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_6],_b[1.etwp#c.postreftax_1224_7] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_7],_b[1.etwp#c.postreftax_1224_8] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_8],_b[1.etwp#c.postreftax_1224_9] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_9],_b[1.etwp#c.postreftax_1224_10] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_10],_b[1.etwp#c.postreftax_1224_11] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_11],_b[1.etwp#c.postreftax_1224_12] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_12] ///
			,_b[1.etwp#c.postreftax_1224_13] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_13],_b[1.etwp#c.postreftax_1224_14] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_14],_b[1.etwp#c.postreftax_1224_15] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_15],_b[1.etwp#c.postreftax_1224_16] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_16],_b[1.etwp#c.postreftax_1224_17] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_17],_b[1.etwp#c.postreftax_1224_18] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_18],_b[1.etwp#c.postreftax_1224_19] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_19],_b[1.etwp#c.postreftax_1224_20] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_20],_b[1.etwp#c.postreftax_1224_21] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_21],_b[1.etwp#c.postreftax_1224_22] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_22]]
			
			matrix upperb = [_b[1.etwp#c.prereftax_1724_16] + invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_16], _b[1.etwp#c.prereftax_1724_15] + invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_15], _b[1.etwp#c.prereftax_1724_14] + invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_14], _b[1.etwp#c.prereftax_1724_13] + invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_13], _b[1.etwp#c.prereftax_1724_12] + invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_12], _b[1.etwp#c.prereftax_1724_11] + invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_11], _b[1.etwp#c.prereftax_1724_10] + invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_10], _b[1.etwp#c.prereftax_1724_9] + invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_9], _b[1.etwp#c.prereftax_1724_8] + invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_8], _b[1.etwp#c.prereftax_1724_7] + invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_7], _b[1.etwp#c.prereftax_1724_6] + invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_6], _b[1.etwp#c.prereftax_1724_5] + invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_5], 0, _b[1.etwp#c.prereftax_1724_3] + invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_3], _b[1.etwp#c.prereftax_1724_2] + invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_2],_b[1.etwp#c.prereftax_1724_1] + invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_1], ///
			_b[1.etwp#c.postreftax_1224_0] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_0],_b[1.etwp#c.postreftax_1224_1] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_1],_b[1.etwp#c.postreftax_1224_2] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_2],_b[1.etwp#c.postreftax_1224_3] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_3],_b[1.etwp#c.postreftax_1224_4] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_4],_b[1.etwp#c.postreftax_1224_5] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_5],_b[1.etwp#c.postreftax_1224_6] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_6],_b[1.etwp#c.postreftax_1224_7] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_7],_b[1.etwp#c.postreftax_1224_8] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_8],_b[1.etwp#c.postreftax_1224_9] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_9],_b[1.etwp#c.postreftax_1224_10] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_10],_b[1.etwp#c.postreftax_1224_11] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_11],_b[1.etwp#c.postreftax_1224_12] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_12] ///
			,_b[1.etwp#c.postreftax_1224_13] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_13],_b[1.etwp#c.postreftax_1224_14] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_14],_b[1.etwp#c.postreftax_1224_15] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_15],_b[1.etwp#c.postreftax_1224_16] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_16],_b[1.etwp#c.postreftax_1224_17] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_17],_b[1.etwp#c.postreftax_1224_18] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_18],_b[1.etwp#c.postreftax_1224_19] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_19],_b[1.etwp#c.postreftax_1224_20] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_20],_b[1.etwp#c.postreftax_1224_21] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_21],_b[1.etwp#c.postreftax_1224_22] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_22]]
			
			matrix res_ehpetwp_regctrl2_ife_pfe = [coeff2, 0, coeff1 \  -16, -15, -14, -13, -12, -11, -10, -9, -8, -7, -6, -5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22 \ upperb \ lowerb ]'
			svmat  res_ehpetwp_regctrl2_ife_pfe
			scatter res_ehpetwp_regctrl2_ife_pfe1 res_ehpetwp_regctrl2_ife_pfe2, connect(l) yline(0) xline(-4) xline(0, lpattern(dash)) || rcap res_ehpetwp_regctrl2_ife_pfe3 res_ehpetwp_regctrl2_ife_pfe4 res_ehpetwp_regctrl2_ife_pfe2, scheme(s1color) xtitle("Months before/after tax increase") legend(label(1 "Difference SFH-APT") label(2 "95% confidence interval")) xlab(-15 (5) 20) ylab(-.06 "-6%" -.04 "-4%" -.02 "-2%" 0 "0%" .02 "2%") yscale(range(-0.065 0.025)) ytitle("Difference")  
			graph export "${graphs}\ESi_diff_popgallwp_deltatax_`depvar'_ehpetwp_regctrl2_ife_pfe.pdf", replace
			matrix drop _all
			drop res_ehpetwp_regctrl2_ife_pfe*
		}
	}
}	


if $FigureA8 == 1 {
	foreach file of global files {
		global graphinput `file'_noctrl_ife 
		use $prereform $postreform $prereftax17 $postreftax $prereflntax $postreflntax buildaged ln_flaeche zimmeranzahl basement balcony parking kitchen garden baujahrd heatingtype centralheat fancy fancyequip quietloc bright $depvars wmt* pricechpc jahr plz betrag preisqm kreistyp monlast popg popgallwp05 popgallwp95 using "${data}/F_u_B/ifo_`file'_4q19_prep_3624.dta", clear
	
		cap drop aggmindist mindist_inner 
		merge m:1 plz using "${data}/external_data/PLZ_mindist_border_allDE2.dta", keepusing(aggmindist mindist_inner lowermindist)
		drop if _merge==2
		drop _merge

		foreach pctype in popgallwp {
			foreach dist of numlist 10  {
				qui {
					xtreg ln_preisqm $prereftax17 $postreftax i.monlast#i.kreistyp if aggmindist>=`dist' & aggmindist!=. & lowermindist>0.05 & popg>= `pctype'05 & popg<=`pctype'95, fe vce(cluster plz)					
					estimates store `file'_noctrl_ife, title(Int. trends)
				}
				display "Event study, continuous treatment, min. distance to border: `dist'"
				estout `file'*ctrl*, varwidth(30) cells(b(star fmt(3)) se(fmt(3)) p(par fmt(3))) starlevels(* 0.05 ** 0.01 *** 0.001) stats(r2 ar2_w N, labels("R^2" "R^2 within" N) fmt(3 0)) keep($prereftax17 $postreftax) style(fixed) label collabels(none) replace
				qui {
					foreach type in $graphinput {
						estimates restore `type'
						matrix b=e(b)
						matrix coeff1 = b[1,14..39]
						matrix coeff2 = b[1,2..13]

						matrix lowerb = [_b[prereftax_1724_16] - invttail(e(df_r),0.025)*_se[prereftax_1724_16], _b[prereftax_1724_15] - invttail(e(df_r),0.025)*_se[prereftax_1724_15], _b[prereftax_1724_14] - invttail(e(df_r),0.025)*_se[prereftax_1724_14], _b[prereftax_1724_13] - invttail(e(df_r),0.025)*_se[prereftax_1724_13],_b[prereftax_1724_12] - invttail(e(df_r),0.025)*_se[prereftax_1724_12], ///
						_b[prereftax_1724_11] - invttail(e(df_r),0.025)*_se[prereftax_1724_11], _b[prereftax_1724_10] - invttail(e(df_r),0.025)*_se[prereftax_1724_10], _b[prereftax_1724_9] - invttail(e(df_r),0.025)*_se[prereftax_1724_9], _b[prereftax_1724_8] - invttail(e(df_r),0.025)*_se[prereftax_1724_8], _b[prereftax_1724_7] - invttail(e(df_r),0.025)*_se[prereftax_1724_7], _b[prereftax_1724_6] - invttail(e(df_r),0.025)*_se[prereftax_1724_6], _b[prereftax_1724_5] - invttail(e(df_r),0.025)*_se[prereftax_1724_5], 0, _b[prereftax_1724_3] - invttail(e(df_r),0.025)*_se[prereftax_1724_3], _b[prereftax_1724_2] - invttail(e(df_r),0.025)*_se[prereftax_1724_2],_b[prereftax_1724_1] - invttail(e(df_r),0.025)*_se[prereftax_1724_1], ///
						_b[postreftax_1224_0] - invttail(e(df_r),0.025)*_se[postreftax_1224_0],_b[postreftax_1224_1] - invttail(e(df_r),0.025)*_se[postreftax_1224_1],_b[postreftax_1224_2] - invttail(e(df_r),0.025)*_se[postreftax_1224_2],_b[postreftax_1224_3] - invttail(e(df_r),0.025)*_se[postreftax_1224_3],_b[postreftax_1224_4] - invttail(e(df_r),0.025)*_se[postreftax_1224_4],_b[postreftax_1224_5] - invttail(e(df_r),0.025)*_se[postreftax_1224_5],_b[postreftax_1224_6] - invttail(e(df_r),0.025)*_se[postreftax_1224_6],_b[postreftax_1224_7] - invttail(e(df_r),0.025)*_se[postreftax_1224_7],_b[postreftax_1224_8] - invttail(e(df_r),0.025)*_se[postreftax_1224_8],_b[postreftax_1224_9] - invttail(e(df_r),0.025)*_se[postreftax_1224_9],_b[postreftax_1224_10] - invttail(e(df_r),0.025)*_se[postreftax_1224_10],_b[postreftax_1224_11] - invttail(e(df_r),0.025)*_se[postreftax_1224_11],_b[postreftax_1224_12] - invttail(e(df_r),0.025)*_se[postreftax_1224_12], ///
						_b[postreftax_1224_13] - invttail(e(df_r),0.025)*_se[postreftax_1224_13],_b[postreftax_1224_14] - invttail(e(df_r),0.025)*_se[postreftax_1224_14],_b[postreftax_1224_15] - invttail(e(df_r),0.025)*_se[postreftax_1224_15],_b[postreftax_1224_16] - invttail(e(df_r),0.025)*_se[postreftax_1224_16],_b[postreftax_1224_17] - invttail(e(df_r),0.025)*_se[postreftax_1224_17],_b[postreftax_1224_18] - invttail(e(df_r),0.025)*_se[postreftax_1224_18],_b[postreftax_1224_19] - invttail(e(df_r),0.025)*_se[postreftax_1224_19],_b[postreftax_1224_20] - invttail(e(df_r),0.025)*_se[postreftax_1224_20],_b[postreftax_1224_21] - invttail(e(df_r),0.025)*_se[postreftax_1224_21],_b[postreftax_1224_22] - invttail(e(df_r),0.025)*_se[postreftax_1224_22]]
						
						matrix upperb = [_b[prereftax_1724_16] + invttail(e(df_r),0.025)*_se[prereftax_1724_16], _b[prereftax_1724_15] + invttail(e(df_r),0.025)*_se[prereftax_1724_15], _b[prereftax_1724_14] + invttail(e(df_r),0.025)*_se[prereftax_1724_14], _b[prereftax_1724_13] + invttail(e(df_r),0.025)*_se[prereftax_1724_13],_b[prereftax_1724_12] + invttail(e(df_r),0.025)*_se[prereftax_1724_12], ///
						_b[prereftax_1724_11] + invttail(e(df_r),0.025)*_se[prereftax_1724_11], _b[prereftax_1724_10] + invttail(e(df_r),0.025)*_se[prereftax_1724_10], _b[prereftax_1724_9] + invttail(e(df_r),0.025)*_se[prereftax_1724_9], _b[prereftax_1724_8] + invttail(e(df_r),0.025)*_se[prereftax_1724_8], _b[prereftax_1724_7] + invttail(e(df_r),0.025)*_se[prereftax_1724_7], _b[prereftax_1724_6] + invttail(e(df_r),0.025)*_se[prereftax_1724_6], _b[prereftax_1724_5] + invttail(e(df_r),0.025)*_se[prereftax_1724_5], 0, _b[prereftax_1724_3] + invttail(e(df_r),0.025)*_se[prereftax_1724_3], _b[prereftax_1724_2] + invttail(e(df_r),0.025)*_se[prereftax_1724_2],_b[prereftax_1724_1] + invttail(e(df_r),0.025)*_se[prereftax_1724_1], ///
						_b[postreftax_1224_0] + invttail(e(df_r),0.025)*_se[postreftax_1224_0],_b[postreftax_1224_1] + invttail(e(df_r),0.025)*_se[postreftax_1224_1],_b[postreftax_1224_2] + invttail(e(df_r),0.025)*_se[postreftax_1224_2],_b[postreftax_1224_3] + invttail(e(df_r),0.025)*_se[postreftax_1224_3],_b[postreftax_1224_4] + invttail(e(df_r),0.025)*_se[postreftax_1224_4],_b[postreftax_1224_5] + invttail(e(df_r),0.025)*_se[postreftax_1224_5],_b[postreftax_1224_6] + invttail(e(df_r),0.025)*_se[postreftax_1224_6],_b[postreftax_1224_7] + invttail(e(df_r),0.025)*_se[postreftax_1224_7],_b[postreftax_1224_8] + invttail(e(df_r),0.025)*_se[postreftax_1224_8],_b[postreftax_1224_9] + invttail(e(df_r),0.025)*_se[postreftax_1224_9],_b[postreftax_1224_10] + invttail(e(df_r),0.025)*_se[postreftax_1224_10],_b[postreftax_1224_11] + invttail(e(df_r),0.025)*_se[postreftax_1224_11],_b[postreftax_1224_12] + invttail(e(df_r),0.025)*_se[postreftax_1224_12], ///
						_b[postreftax_1224_13] + invttail(e(df_r),0.025)*_se[postreftax_1224_13],_b[postreftax_1224_14] + invttail(e(df_r),0.025)*_se[postreftax_1224_14],_b[postreftax_1224_15] + invttail(e(df_r),0.025)*_se[postreftax_1224_15],_b[postreftax_1224_16] + invttail(e(df_r),0.025)*_se[postreftax_1224_16],_b[postreftax_1224_17] + invttail(e(df_r),0.025)*_se[postreftax_1224_17],_b[postreftax_1224_18] + invttail(e(df_r),0.025)*_se[postreftax_1224_18],_b[postreftax_1224_19] + invttail(e(df_r),0.025)*_se[postreftax_1224_19],_b[postreftax_1224_20] + invttail(e(df_r),0.025)*_se[postreftax_1224_20],_b[postreftax_1224_21] + invttail(e(df_r),0.025)*_se[postreftax_1224_21],_b[postreftax_1224_22] + invttail(e(df_r),0.025)*_se[postreftax_1224_22]]
	
						matrix res_`type' = [coeff2, 0, coeff1 \  -16, -15, -14, -13, -12, -11, -10, -9, -8, -7, -6, -5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22 \ upperb \ lowerb ]'
						svmat res_`type'
						scatter res_`type'1 res_`type'2, connect(l) yline(0) xline(-4) xline(0, lpattern(dash)) || rcap res_`type'3 res_`type'4 res_`type'2, scheme(s1color) xtitle("Months before/after tax increase") legend(label(1 "Price effect") label(2 "95% confidence interval")) xlab(-15 (5) 20) ylab(-.06 "-6%" -.04 "-4%" -.02 "-2%" 0 "0%" .02 "2%") yscale(range(-0.065 0.025)) ytitle("Tax semi-elasticity")
						graph export "${graphs}\ESi_`file'_popgallwp_border`dist'_deltatax_ln_preisqm_`type'.pdf", replace
						matrix drop _all
						drop res_`type'*
					}
				}
				qui estimates drop *
			}
		}
	}
	global graphinput ehpetwp_noctrl_ife                                        
	use $depvars Nnachbar $prereftaxnb $postreftaxnb flaeche ersterpreis ort daysposted pricediff pricediff_pc $prereform $postreform $prereftax $prereftax17 prereftax_1224_4 $postreftax $prereflntax17 $postreflntax buildaged ln_flaeche zimmeranzahl basement balcony parking kitchen garden baujahrd heatingtype centralheat fancy fancyequip quietloc bright wmt* pricechpc jahr plz kreis ags bula betrag preisqm kreistyp monlast popg popgallwp05 popgallwp95 ln_bip ln_pop alq ln_debtpc using "${data}/F_u_B/ifo_etwp_4q19_prep_3624.dta", clear
	gen housetype = "etwp"
	append using "${data}/F_u_B/ifo_ehp_4q19_prep_3624.dta", keep($depvars Nnachbar $prereftaxnb $postreftaxnb flaeche ersterpreis ort daysposted pricediff pricediff_pc $prereform $postreform $prereftax $prereftax17 prereftax_1224_4 $postreftax $prereflntax17 $postreflntax buildaged ln_flaeche zimmeranzahl basement balcony parking kitchen garden baujahrd heatingtype centralheat fancy fancyequip quietloc bright wmt* pricechpc jahr plz kreis ags bula betrag preisqm kreistyp monlast popg popgallwp05 popgallwp95 ln_bip ln_pop alq ln_debtpc)
	replace housetype = "ehp" if housetype==""
	gen ehp = 0
	replace ehp = 1 if housetype == "ehp"
	gen etwp = 0
	replace etwp = 1 if housetype == "etwp"
	
	foreach pctype in popgallwp {
		foreach depvar of varlist $depvars {
			cap drop aggmindist mindist_inner 
			merge m:1 plz using "${data}/external_data/PLZ_mindist_border_allDE2.dta", keepusing(aggmindist mindist_inner lowermindist)
			drop if _merge==2
			drop _merge
			
			reghdfe `depvar' (c.(${prereftax17}) c.(${postreftax}))##i.etwp if aggmindist>=10 & aggmindist!=. & lowermindist>0.05 & popg>= `pctype'05 & popg<=`pctype'95, a(i.plz#i.etwp i.monlast#i.kreistyp#i.etwp) vce(cluster plz)
			estimates store ehpetwp_border10_ife_pfe, title(Int. trends)
			
			matrix b=e(b)
			matrix coeff1 = (b[1,70],b[1,72],b[1,74],b[1,76],b[1,78],b[1,80],b[1,82],b[1,84],b[1,86],b[1,88],b[1,90],b[1,92],b[1,94],b[1,96],b[1,98],b[1,100],b[1,102],b[1,104],b[1,106],b[1,108],b[1,110],b[1,112],b[1,114],b[1,116],b[1,118],b[1,120])
			matrix coeff2 = (b[1,46],b[1,48],b[1,50],b[1,52],b[1,54],b[1,56],b[1,58],b[1,60],b[1,62],b[1,64],b[1,66],b[1,68])
			matrix lowerb = [_b[1.etwp#c.prereftax_1724_16] - invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_16], _b[1.etwp#c.prereftax_1724_15] - invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_15], _b[1.etwp#c.prereftax_1724_14] - invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_14], _b[1.etwp#c.prereftax_1724_13] - invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_13], _b[1.etwp#c.prereftax_1724_12] - invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_12], _b[1.etwp#c.prereftax_1724_11] - invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_11], _b[1.etwp#c.prereftax_1724_10] - invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_10], _b[1.etwp#c.prereftax_1724_9] - invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_9], _b[1.etwp#c.prereftax_1724_8] - invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_8], _b[1.etwp#c.prereftax_1724_7] - invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_7], _b[1.etwp#c.prereftax_1724_6] - invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_6], _b[1.etwp#c.prereftax_1724_5] - invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_5], 0, _b[1.etwp#c.prereftax_1724_3] - invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_3], _b[1.etwp#c.prereftax_1724_2] - invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_2],_b[1.etwp#c.prereftax_1724_1] - invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_1], ///
			_b[1.etwp#c.postreftax_1224_0] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_0],_b[1.etwp#c.postreftax_1224_1] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_1],_b[1.etwp#c.postreftax_1224_2] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_2],_b[1.etwp#c.postreftax_1224_3] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_3],_b[1.etwp#c.postreftax_1224_4] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_4],_b[1.etwp#c.postreftax_1224_5] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_5],_b[1.etwp#c.postreftax_1224_6] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_6],_b[1.etwp#c.postreftax_1224_7] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_7],_b[1.etwp#c.postreftax_1224_8] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_8],_b[1.etwp#c.postreftax_1224_9] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_9],_b[1.etwp#c.postreftax_1224_10] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_10],_b[1.etwp#c.postreftax_1224_11] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_11],_b[1.etwp#c.postreftax_1224_12] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_12] ///
			,_b[1.etwp#c.postreftax_1224_13] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_13],_b[1.etwp#c.postreftax_1224_14] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_14],_b[1.etwp#c.postreftax_1224_15] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_15],_b[1.etwp#c.postreftax_1224_16] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_16],_b[1.etwp#c.postreftax_1224_17] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_17],_b[1.etwp#c.postreftax_1224_18] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_18],_b[1.etwp#c.postreftax_1224_19] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_19],_b[1.etwp#c.postreftax_1224_20] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_20],_b[1.etwp#c.postreftax_1224_21] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_21],_b[1.etwp#c.postreftax_1224_22] - invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_22]]
			
			matrix upperb = [_b[1.etwp#c.prereftax_1724_16] + invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_16], _b[1.etwp#c.prereftax_1724_15] + invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_15], _b[1.etwp#c.prereftax_1724_14] + invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_14], _b[1.etwp#c.prereftax_1724_13] + invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_13], _b[1.etwp#c.prereftax_1724_12] + invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_12], _b[1.etwp#c.prereftax_1724_11] + invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_11], _b[1.etwp#c.prereftax_1724_10] + invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_10], _b[1.etwp#c.prereftax_1724_9] + invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_9], _b[1.etwp#c.prereftax_1724_8] + invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_8], _b[1.etwp#c.prereftax_1724_7] + invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_7], _b[1.etwp#c.prereftax_1724_6] + invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_6], _b[1.etwp#c.prereftax_1724_5] + invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_5], 0, _b[1.etwp#c.prereftax_1724_3] + invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_3], _b[1.etwp#c.prereftax_1724_2] + invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_2],_b[1.etwp#c.prereftax_1724_1] + invttail(e(df_r),0.025)*_se[1.etwp#c.prereftax_1724_1], ///
			_b[1.etwp#c.postreftax_1224_0] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_0],_b[1.etwp#c.postreftax_1224_1] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_1],_b[1.etwp#c.postreftax_1224_2] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_2],_b[1.etwp#c.postreftax_1224_3] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_3],_b[1.etwp#c.postreftax_1224_4] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_4],_b[1.etwp#c.postreftax_1224_5] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_5],_b[1.etwp#c.postreftax_1224_6] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_6],_b[1.etwp#c.postreftax_1224_7] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_7],_b[1.etwp#c.postreftax_1224_8] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_8],_b[1.etwp#c.postreftax_1224_9] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_9],_b[1.etwp#c.postreftax_1224_10] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_10],_b[1.etwp#c.postreftax_1224_11] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_11],_b[1.etwp#c.postreftax_1224_12] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_12] ///
			,_b[1.etwp#c.postreftax_1224_13] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_13],_b[1.etwp#c.postreftax_1224_14] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_14],_b[1.etwp#c.postreftax_1224_15] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_15],_b[1.etwp#c.postreftax_1224_16] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_16],_b[1.etwp#c.postreftax_1224_17] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_17],_b[1.etwp#c.postreftax_1224_18] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_18],_b[1.etwp#c.postreftax_1224_19] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_19],_b[1.etwp#c.postreftax_1224_20] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_20],_b[1.etwp#c.postreftax_1224_21] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_21],_b[1.etwp#c.postreftax_1224_22] + invttail(e(df_r),0.025)*_se[1.etwp#c.postreftax_1224_22]]
			
			matrix res_ehpetwp_border10_ife_pfe = [coeff2, 0, coeff1 \  -16, -15, -14, -13, -12, -11, -10, -9, -8, -7, -6, -5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22 \ upperb \ lowerb ]'
			svmat  res_ehpetwp_border10_ife_pfe
			scatter res_ehpetwp_border10_ife_pfe1 res_ehpetwp_border10_ife_pfe2, connect(l) yline(0) xline(-4) xline(0, lpattern(dash)) || rcap res_ehpetwp_border10_ife_pfe3 res_ehpetwp_border10_ife_pfe4 res_ehpetwp_border10_ife_pfe2, scheme(s1color) xtitle("Months before/after tax increase") legend(label(1 "Difference SFH-APT") label(2 "95% confidence interval")) xlab(-15 (5) 20) ylab(-.06 "-6%" -.04 "-4%" -.02 "-2%" 0 "0%" .02 "2%") yscale(range(-0.065 0.025)) ytitle("Difference")  
			graph export "${graphs}\ESi_diff_popgallwp_deltatax_`depvar'_ehpetwp_border10_ife_pfe.pdf", replace
			matrix drop _all
			drop res_ehpetwp_border10_ife_pfe*
		}
	}
}





***********************************************************************************
***** End of replication file (24-09-2024)
***********************************************************************************





	

	
	
*** for high and low property prices

foreach file of global files {

		* winsorized_longer 17
	if $byprice == 1 {
		*** time trends interagiert mit kreistyp
		global graphinput /*`file'_noctrl_fe*/ `file'_noctrl_ife // `file'_ctrl1_ife `file'_ctrl2_ife `file'_ctrl3_ife `file'_ctrl4_ife `file'_ctrl5_ife `file'_ctrl6_ife
		use $prereform $postreform $prereftax17 $postreftax $prereflntax $postreflntax ersterpreis daysposted pricediff pricediff_pc buildaged ln_flaeche flaeche zimmeranzahl basement balcony parking kitchen garden baujahrd heatingtype centralheat fancy fancyequip quietloc bright $depvars2 wmt* pricechpc jahr plz betrag preisqm kreistyp monlast popg popgallwp05 popgallwp95 letzterpreis kreis using "F:/Neumeier_RETT/98 not classified/Output/ifo_`file'_4q19_prep_3624.dta".dta, clear
		bysort kreis jahr: egen medianpreis_kreis = median(letzterpreis)
		gen preisabovemedian = (letzterpreis > medianpreis_kreis)
		*gen ln_ersterpreisqm = ln(ersterpreis/flaeche)
		
		
		**** Use final price as dependent variable
		* without municipalities below the 5% / above the 95% population growth percentile 
		foreach prmed of numlist 0 1 {
		foreach pctype in popgallwp {
			foreach depvar of varlist ln_preisqm {
				qui {
					xtreg `depvar' $prereftax17 $postreftax i.monlast#i.kreistyp if popg>= `pctype'05 & popg<=`pctype'95 & preisabovemedian==`prmed', fe vce(cluster plz)
					estimates store `file'_noctrl_ife, title(Int. trends)
				}
				display "Event study, all distances, `depvar'"
				estout `file'*ctrl*, varwidth(30) cells(b(star fmt(3)) se(fmt(3)) p(par fmt(3))) starlevels(* 0.05 ** 0.01 *** 0.001) stats(r2 ar2_w N, labels("R^2" "R^2 within" N) fmt(3 0)) keep($prereftax17 $postreftax) style(fixed) label collabels(none) replace
				*estout `file'*ctrl*, varwidth(30) cells(b(fmt(3)) se(fmt(3)) p(par fmt(3))) stats(r2 ar2_w N, labels("R^2" "R^2 within" N) fmt(3 0)) keep($prereftax $postreftax) style(fixed) label collabels(none) replace
				qui {
					foreach type in $graphinput /*`file'_noctrl_fe_no1 `file'_noctrl_fe_no2  `file'_noctrl_fe_no3  `file'_noctrl_fe_no4  `file'_noctrl_fe_no5  `file'_noctrl_fe_no6 `file'_noctrl_fe_no7 `file'_noctrl_fe_no8 `file'_noctrl_fe_no9 `file'_noctrl_fe_no10 `file'_noctrl_fe_no11 `file'_noctrl_fe_no12 `file'_noctrl_fe_no13 `file'_noctrl_fe_no14 `file'_noctrl_fe_no15 `file'_noctrl_fe_no16*/ {
						estimates restore `type'
						matrix b=e(b)
						matrix coeff1 = b[1,14..39]
						matrix coeff2 = b[1,2..13]
									
						matrix lowerb = [_b[prereftax_1724_16] - invttail(e(df_r),0.025)*_se[prereftax_1724_16], _b[prereftax_1724_15] - invttail(e(df_r),0.025)*_se[prereftax_1724_15], _b[prereftax_1724_14] - invttail(e(df_r),0.025)*_se[prereftax_1724_14], _b[prereftax_1724_13] - invttail(e(df_r),0.025)*_se[prereftax_1724_13],_b[prereftax_1724_12] - invttail(e(df_r),0.025)*_se[prereftax_1724_12], ///
						_b[prereftax_1724_11] - invttail(e(df_r),0.025)*_se[prereftax_1724_11], _b[prereftax_1724_10] - invttail(e(df_r),0.025)*_se[prereftax_1724_10], _b[prereftax_1724_9] - invttail(e(df_r),0.025)*_se[prereftax_1724_9], _b[prereftax_1724_8] - invttail(e(df_r),0.025)*_se[prereftax_1724_8], _b[prereftax_1724_7] - invttail(e(df_r),0.025)*_se[prereftax_1724_7], _b[prereftax_1724_6] - invttail(e(df_r),0.025)*_se[prereftax_1724_6], _b[prereftax_1724_5] - invttail(e(df_r),0.025)*_se[prereftax_1724_5], 0, _b[prereftax_1724_3] - invttail(e(df_r),0.025)*_se[prereftax_1724_3], _b[prereftax_1724_2] - invttail(e(df_r),0.025)*_se[prereftax_1724_2],_b[prereftax_1724_1] - invttail(e(df_r),0.025)*_se[prereftax_1724_1], ///
						_b[postreftax_1224_0] - invttail(e(df_r),0.025)*_se[postreftax_1224_0],_b[postreftax_1224_1] - invttail(e(df_r),0.025)*_se[postreftax_1224_1],_b[postreftax_1224_2] - invttail(e(df_r),0.025)*_se[postreftax_1224_2],_b[postreftax_1224_3] - invttail(e(df_r),0.025)*_se[postreftax_1224_3],_b[postreftax_1224_4] - invttail(e(df_r),0.025)*_se[postreftax_1224_4],_b[postreftax_1224_5] - invttail(e(df_r),0.025)*_se[postreftax_1224_5],_b[postreftax_1224_6] - invttail(e(df_r),0.025)*_se[postreftax_1224_6],_b[postreftax_1224_7] - invttail(e(df_r),0.025)*_se[postreftax_1224_7],_b[postreftax_1224_8] - invttail(e(df_r),0.025)*_se[postreftax_1224_8],_b[postreftax_1224_9] - invttail(e(df_r),0.025)*_se[postreftax_1224_9],_b[postreftax_1224_10] - invttail(e(df_r),0.025)*_se[postreftax_1224_10],_b[postreftax_1224_11] - invttail(e(df_r),0.025)*_se[postreftax_1224_11],_b[postreftax_1224_12] - invttail(e(df_r),0.025)*_se[postreftax_1224_12], ///
						_b[postreftax_1224_13] - invttail(e(df_r),0.025)*_se[postreftax_1224_13],_b[postreftax_1224_14] - invttail(e(df_r),0.025)*_se[postreftax_1224_14],_b[postreftax_1224_15] - invttail(e(df_r),0.025)*_se[postreftax_1224_15],_b[postreftax_1224_16] - invttail(e(df_r),0.025)*_se[postreftax_1224_16],_b[postreftax_1224_17] - invttail(e(df_r),0.025)*_se[postreftax_1224_17],_b[postreftax_1224_18] - invttail(e(df_r),0.025)*_se[postreftax_1224_18],_b[postreftax_1224_19] - invttail(e(df_r),0.025)*_se[postreftax_1224_19],_b[postreftax_1224_20] - invttail(e(df_r),0.025)*_se[postreftax_1224_20],_b[postreftax_1224_21] - invttail(e(df_r),0.025)*_se[postreftax_1224_21],_b[postreftax_1224_22] - invttail(e(df_r),0.025)*_se[postreftax_1224_22]]
						
						matrix upperb = [_b[prereftax_1724_16] + invttail(e(df_r),0.025)*_se[prereftax_1724_16], _b[prereftax_1724_15] + invttail(e(df_r),0.025)*_se[prereftax_1724_15], _b[prereftax_1724_14] + invttail(e(df_r),0.025)*_se[prereftax_1724_14], _b[prereftax_1724_13] + invttail(e(df_r),0.025)*_se[prereftax_1724_13],_b[prereftax_1724_12] + invttail(e(df_r),0.025)*_se[prereftax_1724_12], ///
						_b[prereftax_1724_11] + invttail(e(df_r),0.025)*_se[prereftax_1724_11], _b[prereftax_1724_10] + invttail(e(df_r),0.025)*_se[prereftax_1724_10], _b[prereftax_1724_9] + invttail(e(df_r),0.025)*_se[prereftax_1724_9], _b[prereftax_1724_8] + invttail(e(df_r),0.025)*_se[prereftax_1724_8], _b[prereftax_1724_7] + invttail(e(df_r),0.025)*_se[prereftax_1724_7], _b[prereftax_1724_6] + invttail(e(df_r),0.025)*_se[prereftax_1724_6], _b[prereftax_1724_5] + invttail(e(df_r),0.025)*_se[prereftax_1724_5], 0, _b[prereftax_1724_3] + invttail(e(df_r),0.025)*_se[prereftax_1724_3], _b[prereftax_1724_2] + invttail(e(df_r),0.025)*_se[prereftax_1724_2],_b[prereftax_1724_1] + invttail(e(df_r),0.025)*_se[prereftax_1724_1], ///
						_b[postreftax_1224_0] + invttail(e(df_r),0.025)*_se[postreftax_1224_0],_b[postreftax_1224_1] + invttail(e(df_r),0.025)*_se[postreftax_1224_1],_b[postreftax_1224_2] + invttail(e(df_r),0.025)*_se[postreftax_1224_2],_b[postreftax_1224_3] + invttail(e(df_r),0.025)*_se[postreftax_1224_3],_b[postreftax_1224_4] + invttail(e(df_r),0.025)*_se[postreftax_1224_4],_b[postreftax_1224_5] + invttail(e(df_r),0.025)*_se[postreftax_1224_5],_b[postreftax_1224_6] + invttail(e(df_r),0.025)*_se[postreftax_1224_6],_b[postreftax_1224_7] + invttail(e(df_r),0.025)*_se[postreftax_1224_7],_b[postreftax_1224_8] + invttail(e(df_r),0.025)*_se[postreftax_1224_8],_b[postreftax_1224_9] + invttail(e(df_r),0.025)*_se[postreftax_1224_9],_b[postreftax_1224_10] + invttail(e(df_r),0.025)*_se[postreftax_1224_10],_b[postreftax_1224_11] + invttail(e(df_r),0.025)*_se[postreftax_1224_11],_b[postreftax_1224_12] + invttail(e(df_r),0.025)*_se[postreftax_1224_12], ///
						_b[postreftax_1224_13] + invttail(e(df_r),0.025)*_se[postreftax_1224_13],_b[postreftax_1224_14] + invttail(e(df_r),0.025)*_se[postreftax_1224_14],_b[postreftax_1224_15] + invttail(e(df_r),0.025)*_se[postreftax_1224_15],_b[postreftax_1224_16] + invttail(e(df_r),0.025)*_se[postreftax_1224_16],_b[postreftax_1224_17] + invttail(e(df_r),0.025)*_se[postreftax_1224_17],_b[postreftax_1224_18] + invttail(e(df_r),0.025)*_se[postreftax_1224_18],_b[postreftax_1224_19] + invttail(e(df_r),0.025)*_se[postreftax_1224_19],_b[postreftax_1224_20] + invttail(e(df_r),0.025)*_se[postreftax_1224_20],_b[postreftax_1224_21] + invttail(e(df_r),0.025)*_se[postreftax_1224_21],_b[postreftax_1224_22] + invttail(e(df_r),0.025)*_se[postreftax_1224_22]]
						
						
						matrix res_`type' = [coeff2, 0, coeff1 \  -16, -15, -14, -13, -12, -11, -10, -9, -8, -7, -6, -5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22 \ upperb \ lowerb ]'
						svmat res_`type'
						scatter res_`type'1 res_`type'2, connect(l) yline(0) xline(-4) xline(0, lpattern(dash)) || rcap res_`type'3 res_`type'4 res_`type'2, scheme(s1color) xtitle("Months before/after tax increase") legend(label(1 "Price effect") label(2 "95% confidence interval")) xlab(-15 (5) 20) ylab(-0.06 (0.02) 0.02) yscale(range(-0.065 0.025))
						graph export "${graphs}\ESi_`file'_`pctype'_deltatax_`depvar'_`type'_1724_abovemedianp`prmed'.pdf", replace
						matrix drop _all
						drop res_`type'*
					}
				}
		
				qui estimates drop *
			}
		}
		}
	
		
	}   // winsorized longer	
	
	
** differential effect between properties with low/high price	
	if $byprice_diff == 1 {
		*** time trends interagiert mit kreistyp
		global graphinput /*`file'_noctrl_fe*/ `file'_noctrl_ife // `file'_ctrl1_ife `file'_ctrl2_ife `file'_ctrl3_ife `file'_ctrl4_ife `file'_ctrl5_ife `file'_ctrl6_ife
		use $prereform $postreform $prereftax17 $postreftax $prereflntax $postreflntax ersterpreis daysposted pricediff pricediff_pc buildaged ln_flaeche flaeche zimmeranzahl basement balcony parking kitchen garden baujahrd heatingtype centralheat fancy fancyequip quietloc bright $depvars2 wmt* pricechpc jahr plz betrag preisqm kreistyp monlast popg popgallwp05 popgallwp95 letzterpreis kreis using "F:/Neumeier_RETT/98 not classified/Output/ifo_`file'_4q19_prep_3624.dta", clear
		bysort kreis jahr: egen medianpreis_kreis = median(letzterpreis)
		gen preisabovemedian = (letzterpreis > medianpreis_kreis)
		gen belowmedian = 1 - preisabovemedian
		*gen ln_ersterpreisqm = ln(ersterpreis/flaeche)
		
		
		**** Use final price as dependent variable
		* without municipalities below the 5% / above the 95% population growth percentile 
		foreach pctype in popgallwp {
			foreach depvar of varlist ln_preisqm {
				
					xtreg `depvar' c.(${prereftax17} ${postreftax}) (c.(${prereftax17}) c.(${postreftax}))#1.belowmedian i.monlast#i.kreistyp preisabovemedian if popg>= `pctype'05 & popg<=`pctype'95, fe vce(cluster plz)
					estimates store `file'_noctrl_ife, title(Int. trends)
				
				display "Event study, all distances, `depvar'"
				estout `file'*ctrl*, varwidth(30) cells(b(star fmt(3)) se(fmt(3)) p(par fmt(3))) starlevels(* 0.05 ** 0.01 *** 0.001) stats(r2 ar2_w N, labels("R^2" "R^2 within" N) fmt(3 0)) /keep(belowmedian*) style(fixed) label collabels(none) replace
				*estout `file'*ctrl*, varwidth(30) cells(b(fmt(3)) se(fmt(3)) p(par fmt(3))) stats(r2 ar2_w N, labels("R^2" "R^2 within" N) fmt(3 0)) keep($prereftax $postreftax) style(fixed) label collabels(none) replace
				qui {
					foreach type in $graphinput /*`file'_noctrl_fe_no1 `file'_noctrl_fe_no2  `file'_noctrl_fe_no3  `file'_noctrl_fe_no4  `file'_noctrl_fe_no5  `file'_noctrl_fe_no6 `file'_noctrl_fe_no7 `file'_noctrl_fe_no8 `file'_noctrl_fe_no9 `file'_noctrl_fe_no10 `file'_noctrl_fe_no11 `file'_noctrl_fe_no12 `file'_noctrl_fe_no13 `file'_noctrl_fe_no14 `file'_noctrl_fe_no15 `file'_noctrl_fe_no16*/ {
						estimates restore `type'
						matrix b=e(b)
						matrix coeff1 = b[1,14..39]
						matrix coeff2 = b[1,2..13]
									
						matrix lowerb = [_b[belowmedian#c.prereftax_1724_16] - invttail(e(df_r),0.025)*_se[belowmedian#c.prereftax_1724_16], _b[belowmedian#c.prereftax_1724_15] - invttail(e(df_r),0.025)*_se[belowmedian#c.prereftax_1724_15], _b[belowmedian#c.prereftax_1724_14] - invttail(e(df_r),0.025)*_se[belowmedian#c.prereftax_1724_14], _b[belowmedian#c.prereftax_1724_13] - invttail(e(df_r),0.025)*_se[belowmedian#c.prereftax_1724_13],_b[belowmedian#c.prereftax_1724_12] - invttail(e(df_r),0.025)*_se[belowmedian#c.prereftax_1724_12], ///
						_b[belowmedian#c.prereftax_1724_11] - invttail(e(df_r),0.025)*_se[belowmedian#c.prereftax_1724_11], _b[belowmedian#c.prereftax_1724_10] - invttail(e(df_r),0.025)*_se[belowmedian#c.prereftax_1724_10], _b[belowmedian#c.prereftax_1724_9] - invttail(e(df_r),0.025)*_se[belowmedian#c.prereftax_1724_9], _b[belowmedian#c.prereftax_1724_8] - invttail(e(df_r),0.025)*_se[belowmedian#c.prereftax_1724_8], _b[belowmedian#c.prereftax_1724_7] - invttail(e(df_r),0.025)*_se[belowmedian#c.prereftax_1724_7], _b[belowmedian#c.prereftax_1724_6] - invttail(e(df_r),0.025)*_se[belowmedian#c.prereftax_1724_6], _b[belowmedian#c.prereftax_1724_5] - invttail(e(df_r),0.025)*_se[belowmedian#c.prereftax_1724_5], 0, _b[belowmedian#c.prereftax_1724_3] - invttail(e(df_r),0.025)*_se[belowmedian#c.prereftax_1724_3], _b[belowmedian#c.prereftax_1724_2] - invttail(e(df_r),0.025)*_se[belowmedian#c.prereftax_1724_2],_b[belowmedian#c.prereftax_1724_1] - invttail(e(df_r),0.025)*_se[belowmedian#c.prereftax_1724_1], ///
						_b[belowmedian#c.postreftax_1224_0] - invttail(e(df_r),0.025)*_se[belowmedian#c.postreftax_1224_0],_b[belowmedian#c.postreftax_1224_1] - invttail(e(df_r),0.025)*_se[belowmedian#c.postreftax_1224_1],_b[belowmedian#c.postreftax_1224_2] - invttail(e(df_r),0.025)*_se[belowmedian#c.postreftax_1224_2],_b[belowmedian#c.postreftax_1224_3] - invttail(e(df_r),0.025)*_se[belowmedian#c.postreftax_1224_3],_b[belowmedian#c.postreftax_1224_4] - invttail(e(df_r),0.025)*_se[belowmedian#c.postreftax_1224_4],_b[belowmedian#c.postreftax_1224_5] - invttail(e(df_r),0.025)*_se[belowmedian#c.postreftax_1224_5],_b[belowmedian#c.postreftax_1224_6] - invttail(e(df_r),0.025)*_se[belowmedian#c.postreftax_1224_6],_b[belowmedian#c.postreftax_1224_7] - invttail(e(df_r),0.025)*_se[belowmedian#c.postreftax_1224_7],_b[belowmedian#c.postreftax_1224_8] - invttail(e(df_r),0.025)*_se[belowmedian#c.postreftax_1224_8],_b[belowmedian#c.postreftax_1224_9] - invttail(e(df_r),0.025)*_se[belowmedian#c.postreftax_1224_9],_b[belowmedian#c.postreftax_1224_10] - invttail(e(df_r),0.025)*_se[belowmedian#c.postreftax_1224_10],_b[belowmedian#c.postreftax_1224_11] - invttail(e(df_r),0.025)*_se[belowmedian#c.postreftax_1224_11],_b[belowmedian#c.postreftax_1224_12] - invttail(e(df_r),0.025)*_se[belowmedian#c.postreftax_1224_12], ///
						_b[belowmedian#c.postreftax_1224_13] - invttail(e(df_r),0.025)*_se[belowmedian#c.postreftax_1224_13],_b[belowmedian#c.postreftax_1224_14] - invttail(e(df_r),0.025)*_se[belowmedian#c.postreftax_1224_14],_b[belowmedian#c.postreftax_1224_15] - invttail(e(df_r),0.025)*_se[belowmedian#c.postreftax_1224_15],_b[belowmedian#c.postreftax_1224_16] - invttail(e(df_r),0.025)*_se[belowmedian#c.postreftax_1224_16],_b[belowmedian#c.postreftax_1224_17] - invttail(e(df_r),0.025)*_se[belowmedian#c.postreftax_1224_17],_b[belowmedian#c.postreftax_1224_18] - invttail(e(df_r),0.025)*_se[belowmedian#c.postreftax_1224_18],_b[belowmedian#c.postreftax_1224_19] - invttail(e(df_r),0.025)*_se[belowmedian#c.postreftax_1224_19],_b[belowmedian#c.postreftax_1224_20] - invttail(e(df_r),0.025)*_se[belowmedian#c.postreftax_1224_20],_b[belowmedian#c.postreftax_1224_21] - invttail(e(df_r),0.025)*_se[belowmedian#c.postreftax_1224_21],_b[belowmedian#c.postreftax_1224_22] - invttail(e(df_r),0.025)*_se[belowmedian#c.postreftax_1224_22]]
						
						matrix upperb = [_b[belowmedian#c.prereftax_1724_16] + invttail(e(df_r),0.025)*_se[belowmedian#c.prereftax_1724_16], _b[belowmedian#c.prereftax_1724_15] + invttail(e(df_r),0.025)*_se[belowmedian#c.prereftax_1724_15], _b[belowmedian#c.prereftax_1724_14] + invttail(e(df_r),0.025)*_se[belowmedian#c.prereftax_1724_14], _b[belowmedian#c.prereftax_1724_13] + invttail(e(df_r),0.025)*_se[belowmedian#c.prereftax_1724_13],_b[belowmedian#c.prereftax_1724_12] + invttail(e(df_r),0.025)*_se[belowmedian#c.prereftax_1724_12], ///
						_b[belowmedian#c.prereftax_1724_11] + invttail(e(df_r),0.025)*_se[belowmedian#c.prereftax_1724_11], _b[belowmedian#c.prereftax_1724_10] + invttail(e(df_r),0.025)*_se[belowmedian#c.prereftax_1724_10], _b[belowmedian#c.prereftax_1724_9] + invttail(e(df_r),0.025)*_se[belowmedian#c.prereftax_1724_9], _b[belowmedian#c.prereftax_1724_8] + invttail(e(df_r),0.025)*_se[belowmedian#c.prereftax_1724_8], _b[belowmedian#c.prereftax_1724_7] + invttail(e(df_r),0.025)*_se[belowmedian#c.prereftax_1724_7], _b[belowmedian#c.prereftax_1724_6] + invttail(e(df_r),0.025)*_se[belowmedian#c.prereftax_1724_6], _b[belowmedian#c.prereftax_1724_5] + invttail(e(df_r),0.025)*_se[belowmedian#c.prereftax_1724_5], 0, _b[belowmedian#c.prereftax_1724_3] + invttail(e(df_r),0.025)*_se[belowmedian#c.prereftax_1724_3], _b[belowmedian#c.prereftax_1724_2] + invttail(e(df_r),0.025)*_se[belowmedian#c.prereftax_1724_2],_b[belowmedian#c.prereftax_1724_1] + invttail(e(df_r),0.025)*_se[belowmedian#c.prereftax_1724_1], ///
						_b[belowmedian#c.postreftax_1224_0] + invttail(e(df_r),0.025)*_se[belowmedian#c.postreftax_1224_0],_b[belowmedian#c.postreftax_1224_1] + invttail(e(df_r),0.025)*_se[belowmedian#c.postreftax_1224_1],_b[belowmedian#c.postreftax_1224_2] + invttail(e(df_r),0.025)*_se[belowmedian#c.postreftax_1224_2],_b[belowmedian#c.postreftax_1224_3] + invttail(e(df_r),0.025)*_se[belowmedian#c.postreftax_1224_3],_b[belowmedian#c.postreftax_1224_4] + invttail(e(df_r),0.025)*_se[belowmedian#c.postreftax_1224_4],_b[belowmedian#c.postreftax_1224_5] + invttail(e(df_r),0.025)*_se[belowmedian#c.postreftax_1224_5],_b[belowmedian#c.postreftax_1224_6] + invttail(e(df_r),0.025)*_se[belowmedian#c.postreftax_1224_6],_b[belowmedian#c.postreftax_1224_7] + invttail(e(df_r),0.025)*_se[belowmedian#c.postreftax_1224_7],_b[belowmedian#c.postreftax_1224_8] + invttail(e(df_r),0.025)*_se[belowmedian#c.postreftax_1224_8],_b[belowmedian#c.postreftax_1224_9] + invttail(e(df_r),0.025)*_se[belowmedian#c.postreftax_1224_9],_b[belowmedian#c.postreftax_1224_10] + invttail(e(df_r),0.025)*_se[belowmedian#c.postreftax_1224_10],_b[belowmedian#c.postreftax_1224_11] + invttail(e(df_r),0.025)*_se[belowmedian#c.postreftax_1224_11],_b[belowmedian#c.postreftax_1224_12] + invttail(e(df_r),0.025)*_se[belowmedian#c.postreftax_1224_12], ///
						_b[belowmedian#c.postreftax_1224_13] + invttail(e(df_r),0.025)*_se[belowmedian#c.postreftax_1224_13],_b[belowmedian#c.postreftax_1224_14] + invttail(e(df_r),0.025)*_se[belowmedian#c.postreftax_1224_14],_b[belowmedian#c.postreftax_1224_15] + invttail(e(df_r),0.025)*_se[belowmedian#c.postreftax_1224_15],_b[belowmedian#c.postreftax_1224_16] + invttail(e(df_r),0.025)*_se[belowmedian#c.postreftax_1224_16],_b[belowmedian#c.postreftax_1224_17] + invttail(e(df_r),0.025)*_se[belowmedian#c.postreftax_1224_17],_b[belowmedian#c.postreftax_1224_18] + invttail(e(df_r),0.025)*_se[belowmedian#c.postreftax_1224_18],_b[belowmedian#c.postreftax_1224_19] + invttail(e(df_r),0.025)*_se[belowmedian#c.postreftax_1224_19],_b[belowmedian#c.postreftax_1224_20] + invttail(e(df_r),0.025)*_se[belowmedian#c.postreftax_1224_20],_b[belowmedian#c.postreftax_1224_21] + invttail(e(df_r),0.025)*_se[belowmedian#c.postreftax_1224_21],_b[belowmedian#c.postreftax_1224_22] + invttail(e(df_r),0.025)*_se[belowmedian#c.postreftax_1224_22]]
						
						
						matrix res_`type' = [coeff2, 0, coeff1 \  -16, -15, -14, -13, -12, -11, -10, -9, -8, -7, -6, -5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22 \ upperb \ lowerb ]'
						svmat res_`type'
						scatter res_`type'1 res_`type'2, connect(l) yline(0) xline(-4) xline(0, lpattern(dash)) || rcap res_`type'3 res_`type'4 res_`type'2, scheme(s1color) xtitle("Months before/after tax increase") legend(label(1 "Price effect") label(2 "95% confidence interval")) xlab(-15 (5) 20) ylab(-0.06 (0.02) 0.02) yscale(range(-0.065 0.025))
						graph export "${graphs}\ESi_`file'_`pctype'_deltatax_`depvar'_`type'_1724_bymedprice.pdf", replace
						matrix drop _all
						drop res_`type'*
					}
				}
		
				qui estimates drop *
			}
		}
		
	
		
	}   // $byprice_diff 		
	
* 	
	

*** by share of units held by professional investors
* 1) share of all units in market 

		* winsorized_longer 17
	if $byprofinv == 1 {
		
		*** time trends interagiert mit kreistyp
		global graphinput /*`file'_noctrl_fe*/ `file'_noctrl_ife // `file'_ctrl1_ife `file'_ctrl2_ife `file'_ctrl3_ife `file'_ctrl4_ife `file'_ctrl5_ife `file'_ctrl6_ife
		use $prereform $postreform $prereftax17 $postreftax $prereflntax $postreflntax ersterpreis daysposted pricediff pricediff_pc buildaged ln_flaeche flaeche zimmeranzahl basement balcony parking kitchen garden baujahrd heatingtype centralheat fancy fancyequip quietloc bright $depvars2 wmt* pricechpc jahr plz betrag preisqm kreistyp monlast popg popgallwp05 popgallwp95 letzterpreis kreis using "F:/Neumeier_RETT/98 not classified/Output/ifo_`file'_4q19_prep_3624.dta", clear
		merge m:1 kreis using "F:\Neumeier_RETT\1 data\ExternalData\Wohnungsbestand_ownership.dta", keepusing(abovemed_u_profess_s)
		*gen ln_ersterpreisqm = ln(ersterpreis/flaeche)
		
		
		**** Use final price as dependent variable
		* without municipalities below the 5% / above the 95% population growth percentile 
		foreach prmed of numlist 0 1 {
		foreach pctype in popgallwp {
			foreach depvar of varlist ln_preisqm {
				qui {
					xtreg `depvar' $prereftax17 $postreftax i.monlast#i.kreistyp if popg>= `pctype'05 & popg<=`pctype'95 & abovemed_u_profess_s==`prmed', fe vce(cluster plz)
					estimates store `file'_noctrl_ife, title(Int. trends)
				}
				display "Event study, all distances, `depvar'"
				estout `file'*ctrl*, varwidth(30) cells(b(star fmt(3)) se(fmt(3)) p(par fmt(3))) starlevels(* 0.05 ** 0.01 *** 0.001) stats(r2 ar2_w N, labels("R^2" "R^2 within" N) fmt(3 0)) keep($prereftax17 $postreftax) style(fixed) label collabels(none) replace
				*estout `file'*ctrl*, varwidth(30) cells(b(fmt(3)) se(fmt(3)) p(par fmt(3))) stats(r2 ar2_w N, labels("R^2" "R^2 within" N) fmt(3 0)) keep($prereftax $postreftax) style(fixed) label collabels(none) replace
				qui {
					foreach type in $graphinput /*`file'_noctrl_fe_no1 `file'_noctrl_fe_no2  `file'_noctrl_fe_no3  `file'_noctrl_fe_no4  `file'_noctrl_fe_no5  `file'_noctrl_fe_no6 `file'_noctrl_fe_no7 `file'_noctrl_fe_no8 `file'_noctrl_fe_no9 `file'_noctrl_fe_no10 `file'_noctrl_fe_no11 `file'_noctrl_fe_no12 `file'_noctrl_fe_no13 `file'_noctrl_fe_no14 `file'_noctrl_fe_no15 `file'_noctrl_fe_no16*/ {
						estimates restore `type'
						matrix b=e(b)
						matrix coeff1 = b[1,14..39]
						matrix coeff2 = b[1,2..13]
									
						matrix lowerb = [_b[prereftax_1724_16] - invttail(e(df_r),0.025)*_se[prereftax_1724_16], _b[prereftax_1724_15] - invttail(e(df_r),0.025)*_se[prereftax_1724_15], _b[prereftax_1724_14] - invttail(e(df_r),0.025)*_se[prereftax_1724_14], _b[prereftax_1724_13] - invttail(e(df_r),0.025)*_se[prereftax_1724_13],_b[prereftax_1724_12] - invttail(e(df_r),0.025)*_se[prereftax_1724_12], ///
						_b[prereftax_1724_11] - invttail(e(df_r),0.025)*_se[prereftax_1724_11], _b[prereftax_1724_10] - invttail(e(df_r),0.025)*_se[prereftax_1724_10], _b[prereftax_1724_9] - invttail(e(df_r),0.025)*_se[prereftax_1724_9], _b[prereftax_1724_8] - invttail(e(df_r),0.025)*_se[prereftax_1724_8], _b[prereftax_1724_7] - invttail(e(df_r),0.025)*_se[prereftax_1724_7], _b[prereftax_1724_6] - invttail(e(df_r),0.025)*_se[prereftax_1724_6], _b[prereftax_1724_5] - invttail(e(df_r),0.025)*_se[prereftax_1724_5], 0, _b[prereftax_1724_3] - invttail(e(df_r),0.025)*_se[prereftax_1724_3], _b[prereftax_1724_2] - invttail(e(df_r),0.025)*_se[prereftax_1724_2],_b[prereftax_1724_1] - invttail(e(df_r),0.025)*_se[prereftax_1724_1], ///
						_b[postreftax_1224_0] - invttail(e(df_r),0.025)*_se[postreftax_1224_0],_b[postreftax_1224_1] - invttail(e(df_r),0.025)*_se[postreftax_1224_1],_b[postreftax_1224_2] - invttail(e(df_r),0.025)*_se[postreftax_1224_2],_b[postreftax_1224_3] - invttail(e(df_r),0.025)*_se[postreftax_1224_3],_b[postreftax_1224_4] - invttail(e(df_r),0.025)*_se[postreftax_1224_4],_b[postreftax_1224_5] - invttail(e(df_r),0.025)*_se[postreftax_1224_5],_b[postreftax_1224_6] - invttail(e(df_r),0.025)*_se[postreftax_1224_6],_b[postreftax_1224_7] - invttail(e(df_r),0.025)*_se[postreftax_1224_7],_b[postreftax_1224_8] - invttail(e(df_r),0.025)*_se[postreftax_1224_8],_b[postreftax_1224_9] - invttail(e(df_r),0.025)*_se[postreftax_1224_9],_b[postreftax_1224_10] - invttail(e(df_r),0.025)*_se[postreftax_1224_10],_b[postreftax_1224_11] - invttail(e(df_r),0.025)*_se[postreftax_1224_11],_b[postreftax_1224_12] - invttail(e(df_r),0.025)*_se[postreftax_1224_12], ///
						_b[postreftax_1224_13] - invttail(e(df_r),0.025)*_se[postreftax_1224_13],_b[postreftax_1224_14] - invttail(e(df_r),0.025)*_se[postreftax_1224_14],_b[postreftax_1224_15] - invttail(e(df_r),0.025)*_se[postreftax_1224_15],_b[postreftax_1224_16] - invttail(e(df_r),0.025)*_se[postreftax_1224_16],_b[postreftax_1224_17] - invttail(e(df_r),0.025)*_se[postreftax_1224_17],_b[postreftax_1224_18] - invttail(e(df_r),0.025)*_se[postreftax_1224_18],_b[postreftax_1224_19] - invttail(e(df_r),0.025)*_se[postreftax_1224_19],_b[postreftax_1224_20] - invttail(e(df_r),0.025)*_se[postreftax_1224_20],_b[postreftax_1224_21] - invttail(e(df_r),0.025)*_se[postreftax_1224_21],_b[postreftax_1224_22] - invttail(e(df_r),0.025)*_se[postreftax_1224_22]]
						
						matrix upperb = [_b[prereftax_1724_16] + invttail(e(df_r),0.025)*_se[prereftax_1724_16], _b[prereftax_1724_15] + invttail(e(df_r),0.025)*_se[prereftax_1724_15], _b[prereftax_1724_14] + invttail(e(df_r),0.025)*_se[prereftax_1724_14], _b[prereftax_1724_13] + invttail(e(df_r),0.025)*_se[prereftax_1724_13],_b[prereftax_1724_12] + invttail(e(df_r),0.025)*_se[prereftax_1724_12], ///
						_b[prereftax_1724_11] + invttail(e(df_r),0.025)*_se[prereftax_1724_11], _b[prereftax_1724_10] + invttail(e(df_r),0.025)*_se[prereftax_1724_10], _b[prereftax_1724_9] + invttail(e(df_r),0.025)*_se[prereftax_1724_9], _b[prereftax_1724_8] + invttail(e(df_r),0.025)*_se[prereftax_1724_8], _b[prereftax_1724_7] + invttail(e(df_r),0.025)*_se[prereftax_1724_7], _b[prereftax_1724_6] + invttail(e(df_r),0.025)*_se[prereftax_1724_6], _b[prereftax_1724_5] + invttail(e(df_r),0.025)*_se[prereftax_1724_5], 0, _b[prereftax_1724_3] + invttail(e(df_r),0.025)*_se[prereftax_1724_3], _b[prereftax_1724_2] + invttail(e(df_r),0.025)*_se[prereftax_1724_2],_b[prereftax_1724_1] + invttail(e(df_r),0.025)*_se[prereftax_1724_1], ///
						_b[postreftax_1224_0] + invttail(e(df_r),0.025)*_se[postreftax_1224_0],_b[postreftax_1224_1] + invttail(e(df_r),0.025)*_se[postreftax_1224_1],_b[postreftax_1224_2] + invttail(e(df_r),0.025)*_se[postreftax_1224_2],_b[postreftax_1224_3] + invttail(e(df_r),0.025)*_se[postreftax_1224_3],_b[postreftax_1224_4] + invttail(e(df_r),0.025)*_se[postreftax_1224_4],_b[postreftax_1224_5] + invttail(e(df_r),0.025)*_se[postreftax_1224_5],_b[postreftax_1224_6] + invttail(e(df_r),0.025)*_se[postreftax_1224_6],_b[postreftax_1224_7] + invttail(e(df_r),0.025)*_se[postreftax_1224_7],_b[postreftax_1224_8] + invttail(e(df_r),0.025)*_se[postreftax_1224_8],_b[postreftax_1224_9] + invttail(e(df_r),0.025)*_se[postreftax_1224_9],_b[postreftax_1224_10] + invttail(e(df_r),0.025)*_se[postreftax_1224_10],_b[postreftax_1224_11] + invttail(e(df_r),0.025)*_se[postreftax_1224_11],_b[postreftax_1224_12] + invttail(e(df_r),0.025)*_se[postreftax_1224_12], ///
						_b[postreftax_1224_13] + invttail(e(df_r),0.025)*_se[postreftax_1224_13],_b[postreftax_1224_14] + invttail(e(df_r),0.025)*_se[postreftax_1224_14],_b[postreftax_1224_15] + invttail(e(df_r),0.025)*_se[postreftax_1224_15],_b[postreftax_1224_16] + invttail(e(df_r),0.025)*_se[postreftax_1224_16],_b[postreftax_1224_17] + invttail(e(df_r),0.025)*_se[postreftax_1224_17],_b[postreftax_1224_18] + invttail(e(df_r),0.025)*_se[postreftax_1224_18],_b[postreftax_1224_19] + invttail(e(df_r),0.025)*_se[postreftax_1224_19],_b[postreftax_1224_20] + invttail(e(df_r),0.025)*_se[postreftax_1224_20],_b[postreftax_1224_21] + invttail(e(df_r),0.025)*_se[postreftax_1224_21],_b[postreftax_1224_22] + invttail(e(df_r),0.025)*_se[postreftax_1224_22]]
						
						
						matrix res_`type' = [coeff2, 0, coeff1 \  -16, -15, -14, -13, -12, -11, -10, -9, -8, -7, -6, -5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22 \ upperb \ lowerb ]'
						svmat res_`type'
						scatter res_`type'1 res_`type'2, connect(l) yline(0) xline(-4) xline(0, lpattern(dash)) || rcap res_`type'3 res_`type'4 res_`type'2, scheme(s1color) xtitle("Months before/after tax increase") legend(label(1 "Price effect") label(2 "95% confidence interval")) xlab(-15 (5) 20) ylab(-0.06 (0.02) 0.02) yscale(range(-0.065 0.025))
						graph export "${graphs}\ESi_`file'_`pctype'_deltatax_`depvar'_`type'_1724_professabovemed`prmed'.pdf", replace
						
						scatter res_`type'1 res_`type'2, connect(l) yline(0) xline(-4) xline(0, lpattern(dash)) mcolor(orange) lcolor(orange)	 || rcap res_`type'3 res_`type'4 res_`type'2, scheme(s1color) xtitle("Months before/after tax increase") legend(label(1 "Price effect") label(2 "95% confidence interval")) xlab(-15 (5) 20) ylab(-0.06 (0.02) 0.02) yscale(range(-0.065 0.025)) mcolor(orange) lcolor(orange)						
						graph save "${graphs}\ESi_`file'_`pctype'_deltatax_`depvar'_`type'_1724_professabovemed`prmed'.gph", replace
			if `prmed'==1 {
				graph use "${graphs}\ESi_`file'_`pctype'_deltatax_`depvar'_`type'_1724_professabovemed0.gph"
				addplot: 						scatter res_`type'1 res_`type'2, connect(l) yline(0) xline(-4) xline(0, lpattern(dash)) mcolor(dkgreen) lcolor(dkgreen) || rcap res_`type'3 res_`type'4 res_`type'2, xlab(-15 (5) 20) ylab(-0.06 (0.02) 0.02) yscale(range(-0.065 0.025)) legend(order(1 3) label(1 "Below median") label(3 "Above median")) xtitle("Months before/after tax increase") mcolor(dkgreen) lcolor(dkgreen)
						graph save "${graphs}\ESi_`file'_`pctype'_deltatax_`depvar'_`type'_1724_professabovemed01c.gph", replace

			}
						matrix drop _all
						drop res_`type'*
					}
				}
		
				qui estimates drop *
			}
		}
		}
	
		
	}   // $byprofinv

	* byquartiles

	* summary stats
	if $byprofinvq_s == 1 {
				global graphinput /*`file'_noctrl_fe*/ `file'_noctrl_ife // `file'_ctrl1_ife `file'_ctrl2_ife `file'_ctrl3_ife `file'_ctrl4_ife `file'_ctrl5_ife `file'_ctrl6_ife
		use $prereform $postreform $prereftax17 $postreftax $prereflntax $postreflntax ersterpreis daysposted pricediff pricediff_pc buildaged ln_flaeche flaeche zimmeranzahl basement balcony parking kitchen garden baujahrd heatingtype centralheat fancy fancyequip quietloc bright $depvars2 wmt* pricechpc jahr plz betrag preisqm kreistyp monlast popg popgallwp05 popgallwp95 letzterpreis kreis using "F:/Neumeier_RETT/98 not classified/Output/ifo_`file'_4q19_prep_3624.dta", clear
		merge m:1 kreis using "F:\Neumeier_RETT\1 data\ExternalData\Wohnungsbestand_ownership.dta", keepusing(q_u_profess_s)
		drop _merge
		merge m:1 kreis using "F:\Neumeier_RETT\1 data\ExternalData\GutAcht_Transaction_`file'.dta"
		drop _merge
		foreach prmed of numlist 1 4 {
			foreach pctype in popgallwp {
				sum `file'_trans_freq11 if popg>= `pctype'05 & popg<=`pctype'95 & q_u_profess_s==`prmed'
				
			}
		}
	}
		
	
	if $byprofinvq == 1 {
		*** time trends interagiert mit kreistyp
		global graphinput /*`file'_noctrl_fe*/ `file'_noctrl_ife // `file'_ctrl1_ife `file'_ctrl2_ife `file'_ctrl3_ife `file'_ctrl4_ife `file'_ctrl5_ife `file'_ctrl6_ife
		use $prereform $postreform $prereftax17 $postreftax $prereflntax $postreflntax ersterpreis daysposted pricediff pricediff_pc buildaged ln_flaeche flaeche zimmeranzahl basement balcony parking kitchen garden baujahrd heatingtype centralheat fancy fancyequip quietloc bright $depvars2 wmt* pricechpc jahr plz betrag preisqm kreistyp monlast popg popgallwp05 popgallwp95 letzterpreis kreis using "F:/Neumeier_RETT/98 not classified/Output/ifo_`file'_4q19_prep_3624.dta", clear
		merge m:1 kreis using "F:\Neumeier_RETT\1 data\ExternalData\Wohnungsbestand_ownership.dta", keepusing(q_u_profess_s)
		*gen ln_ersterpreisqm = ln(ersterpreis/flaeche)
		
		
		**** Use final price as dependent variable
		* without municipalities below the 5% / above the 95% population growth percentile 
		foreach prmed of numlist 1 4 {
		foreach pctype in popgallwp {
			foreach depvar of varlist ln_preisqm {
				qui {
					xtreg `depvar' $prereftax17 $postreftax i.monlast#i.kreistyp if popg>= `pctype'05 & popg<=`pctype'95 & q_u_profess_s==`prmed', fe vce(cluster plz)
					estimates store `file'_noctrl_ife, title(Int. trends)
				}
				display "Event study, all distances, `depvar'"
				estout `file'*ctrl*, varwidth(30) cells(b(star fmt(3)) se(fmt(3)) p(par fmt(3))) starlevels(* 0.05 ** 0.01 *** 0.001) stats(r2 ar2_w N, labels("R^2" "R^2 within" N) fmt(3 0)) keep($prereftax17 $postreftax) style(fixed) label collabels(none) replace
				*estout `file'*ctrl*, varwidth(30) cells(b(fmt(3)) se(fmt(3)) p(par fmt(3))) stats(r2 ar2_w N, labels("R^2" "R^2 within" N) fmt(3 0)) keep($prereftax $postreftax) style(fixed) label collabels(none) replace
				qui {
					foreach type in $graphinput /*`file'_noctrl_fe_no1 `file'_noctrl_fe_no2  `file'_noctrl_fe_no3  `file'_noctrl_fe_no4  `file'_noctrl_fe_no5  `file'_noctrl_fe_no6 `file'_noctrl_fe_no7 `file'_noctrl_fe_no8 `file'_noctrl_fe_no9 `file'_noctrl_fe_no10 `file'_noctrl_fe_no11 `file'_noctrl_fe_no12 `file'_noctrl_fe_no13 `file'_noctrl_fe_no14 `file'_noctrl_fe_no15 `file'_noctrl_fe_no16*/ {
						estimates restore `type'
						matrix b=e(b)
						matrix coeff1 = b[1,14..39]
						matrix coeff2 = b[1,2..13]
									
						matrix lowerb = [_b[prereftax_1724_16] - invttail(e(df_r),0.025)*_se[prereftax_1724_16], _b[prereftax_1724_15] - invttail(e(df_r),0.025)*_se[prereftax_1724_15], _b[prereftax_1724_14] - invttail(e(df_r),0.025)*_se[prereftax_1724_14], _b[prereftax_1724_13] - invttail(e(df_r),0.025)*_se[prereftax_1724_13],_b[prereftax_1724_12] - invttail(e(df_r),0.025)*_se[prereftax_1724_12], ///
						_b[prereftax_1724_11] - invttail(e(df_r),0.025)*_se[prereftax_1724_11], _b[prereftax_1724_10] - invttail(e(df_r),0.025)*_se[prereftax_1724_10], _b[prereftax_1724_9] - invttail(e(df_r),0.025)*_se[prereftax_1724_9], _b[prereftax_1724_8] - invttail(e(df_r),0.025)*_se[prereftax_1724_8], _b[prereftax_1724_7] - invttail(e(df_r),0.025)*_se[prereftax_1724_7], _b[prereftax_1724_6] - invttail(e(df_r),0.025)*_se[prereftax_1724_6], _b[prereftax_1724_5] - invttail(e(df_r),0.025)*_se[prereftax_1724_5], 0, _b[prereftax_1724_3] - invttail(e(df_r),0.025)*_se[prereftax_1724_3], _b[prereftax_1724_2] - invttail(e(df_r),0.025)*_se[prereftax_1724_2],_b[prereftax_1724_1] - invttail(e(df_r),0.025)*_se[prereftax_1724_1], ///
						_b[postreftax_1224_0] - invttail(e(df_r),0.025)*_se[postreftax_1224_0],_b[postreftax_1224_1] - invttail(e(df_r),0.025)*_se[postreftax_1224_1],_b[postreftax_1224_2] - invttail(e(df_r),0.025)*_se[postreftax_1224_2],_b[postreftax_1224_3] - invttail(e(df_r),0.025)*_se[postreftax_1224_3],_b[postreftax_1224_4] - invttail(e(df_r),0.025)*_se[postreftax_1224_4],_b[postreftax_1224_5] - invttail(e(df_r),0.025)*_se[postreftax_1224_5],_b[postreftax_1224_6] - invttail(e(df_r),0.025)*_se[postreftax_1224_6],_b[postreftax_1224_7] - invttail(e(df_r),0.025)*_se[postreftax_1224_7],_b[postreftax_1224_8] - invttail(e(df_r),0.025)*_se[postreftax_1224_8],_b[postreftax_1224_9] - invttail(e(df_r),0.025)*_se[postreftax_1224_9],_b[postreftax_1224_10] - invttail(e(df_r),0.025)*_se[postreftax_1224_10],_b[postreftax_1224_11] - invttail(e(df_r),0.025)*_se[postreftax_1224_11],_b[postreftax_1224_12] - invttail(e(df_r),0.025)*_se[postreftax_1224_12], ///
						_b[postreftax_1224_13] - invttail(e(df_r),0.025)*_se[postreftax_1224_13],_b[postreftax_1224_14] - invttail(e(df_r),0.025)*_se[postreftax_1224_14],_b[postreftax_1224_15] - invttail(e(df_r),0.025)*_se[postreftax_1224_15],_b[postreftax_1224_16] - invttail(e(df_r),0.025)*_se[postreftax_1224_16],_b[postreftax_1224_17] - invttail(e(df_r),0.025)*_se[postreftax_1224_17],_b[postreftax_1224_18] - invttail(e(df_r),0.025)*_se[postreftax_1224_18],_b[postreftax_1224_19] - invttail(e(df_r),0.025)*_se[postreftax_1224_19],_b[postreftax_1224_20] - invttail(e(df_r),0.025)*_se[postreftax_1224_20],_b[postreftax_1224_21] - invttail(e(df_r),0.025)*_se[postreftax_1224_21],_b[postreftax_1224_22] - invttail(e(df_r),0.025)*_se[postreftax_1224_22]]
						
						matrix upperb = [_b[prereftax_1724_16] + invttail(e(df_r),0.025)*_se[prereftax_1724_16], _b[prereftax_1724_15] + invttail(e(df_r),0.025)*_se[prereftax_1724_15], _b[prereftax_1724_14] + invttail(e(df_r),0.025)*_se[prereftax_1724_14], _b[prereftax_1724_13] + invttail(e(df_r),0.025)*_se[prereftax_1724_13],_b[prereftax_1724_12] + invttail(e(df_r),0.025)*_se[prereftax_1724_12], ///
						_b[prereftax_1724_11] + invttail(e(df_r),0.025)*_se[prereftax_1724_11], _b[prereftax_1724_10] + invttail(e(df_r),0.025)*_se[prereftax_1724_10], _b[prereftax_1724_9] + invttail(e(df_r),0.025)*_se[prereftax_1724_9], _b[prereftax_1724_8] + invttail(e(df_r),0.025)*_se[prereftax_1724_8], _b[prereftax_1724_7] + invttail(e(df_r),0.025)*_se[prereftax_1724_7], _b[prereftax_1724_6] + invttail(e(df_r),0.025)*_se[prereftax_1724_6], _b[prereftax_1724_5] + invttail(e(df_r),0.025)*_se[prereftax_1724_5], 0, _b[prereftax_1724_3] + invttail(e(df_r),0.025)*_se[prereftax_1724_3], _b[prereftax_1724_2] + invttail(e(df_r),0.025)*_se[prereftax_1724_2],_b[prereftax_1724_1] + invttail(e(df_r),0.025)*_se[prereftax_1724_1], ///
						_b[postreftax_1224_0] + invttail(e(df_r),0.025)*_se[postreftax_1224_0],_b[postreftax_1224_1] + invttail(e(df_r),0.025)*_se[postreftax_1224_1],_b[postreftax_1224_2] + invttail(e(df_r),0.025)*_se[postreftax_1224_2],_b[postreftax_1224_3] + invttail(e(df_r),0.025)*_se[postreftax_1224_3],_b[postreftax_1224_4] + invttail(e(df_r),0.025)*_se[postreftax_1224_4],_b[postreftax_1224_5] + invttail(e(df_r),0.025)*_se[postreftax_1224_5],_b[postreftax_1224_6] + invttail(e(df_r),0.025)*_se[postreftax_1224_6],_b[postreftax_1224_7] + invttail(e(df_r),0.025)*_se[postreftax_1224_7],_b[postreftax_1224_8] + invttail(e(df_r),0.025)*_se[postreftax_1224_8],_b[postreftax_1224_9] + invttail(e(df_r),0.025)*_se[postreftax_1224_9],_b[postreftax_1224_10] + invttail(e(df_r),0.025)*_se[postreftax_1224_10],_b[postreftax_1224_11] + invttail(e(df_r),0.025)*_se[postreftax_1224_11],_b[postreftax_1224_12] + invttail(e(df_r),0.025)*_se[postreftax_1224_12], ///
						_b[postreftax_1224_13] + invttail(e(df_r),0.025)*_se[postreftax_1224_13],_b[postreftax_1224_14] + invttail(e(df_r),0.025)*_se[postreftax_1224_14],_b[postreftax_1224_15] + invttail(e(df_r),0.025)*_se[postreftax_1224_15],_b[postreftax_1224_16] + invttail(e(df_r),0.025)*_se[postreftax_1224_16],_b[postreftax_1224_17] + invttail(e(df_r),0.025)*_se[postreftax_1224_17],_b[postreftax_1224_18] + invttail(e(df_r),0.025)*_se[postreftax_1224_18],_b[postreftax_1224_19] + invttail(e(df_r),0.025)*_se[postreftax_1224_19],_b[postreftax_1224_20] + invttail(e(df_r),0.025)*_se[postreftax_1224_20],_b[postreftax_1224_21] + invttail(e(df_r),0.025)*_se[postreftax_1224_21],_b[postreftax_1224_22] + invttail(e(df_r),0.025)*_se[postreftax_1224_22]]
						
						
						matrix res_`type' = [coeff2, 0, coeff1 \  -16, -15, -14, -13, -12, -11, -10, -9, -8, -7, -6, -5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22 \ upperb \ lowerb ]'
						svmat res_`type'
						scatter res_`type'1 res_`type'2, connect(l) yline(0) xline(-4) xline(0, lpattern(dash)) || rcap res_`type'3 res_`type'4 res_`type'2, scheme(s1color) xtitle("Months before/after tax increase") legend(label(1 "Price effect") label(2 "95% confidence interval")) xlab(-15 (5) 20) ylab(-.06 "-6%" -.04 "-4%" -.02 "-2%" 0 "0%" .02 "2%") yscale(range(-0.065 0.03)) ytitle("Tax semi-elasticity")
						graph export "${graphs}\ESi_`file'_`pctype'_deltatax_`depvar'_`type'_1724_professq`prmed'.pdf", replace
						

						matrix drop _all
						drop res_`type'*
					}
				}
		
				qui estimates drop *
			}
		}
		}
	
		
	}   // $byprofinv
	
	
	// 1b) difference between high and low investor shares
			
				
	if $byprofinv_hlq == 1 {
		*** time trends interagiert mit kreistyp
		global graphinput /*`file'_noctrl_fe*/ `file'_noctrl_ife // `file'_ctrl1_ife `file'_ctrl2_ife `file'_ctrl3_ife `file'_ctrl4_ife `file'_ctrl5_ife `file'_ctrl6_ife
		use $prereform $postreform $prereftax17 $postreftax $prereflntax $postreflntax ersterpreis daysposted pricediff pricediff_pc buildaged ln_flaeche flaeche zimmeranzahl basement balcony parking kitchen garden baujahrd heatingtype centralheat fancy fancyequip quietloc bright $depvars2 wmt* pricechpc jahr plz betrag preisqm kreistyp monlast popg popgallwp05 popgallwp95 letzterpreis kreis using "F:/Neumeier_RETT/98 not classified/Output/ifo_`file'_4q19_prep_3624.dta".dta, clear
		merge m:1 kreis using "F:\Neumeier_RETT\1 data\ExternalData\Wohnungsbestand_ownership.dta", keepusing(q_u_profess_s)
		*gen ln_ersterpreisqm = ln(ersterpreis/flaeche)
		
		keep if q_u_profess_s==1 | q_u_profess_s==4
		gen abovemed_u_profess_s = (q_u_profess_s==4)
		**** Use final price as dependent variable
		* without municipalities below the 5% / above the 95% population growth percentile 
		foreach pctype in popgallwp {
			foreach depvar of varlist ln_preisqm {
				qui {
					reghdfe `depvar' (c.(${prereftax17}) c.(${postreftax}))##i.abovemed_u_profess_s if popg>= `pctype'05 & popg<=`pctype'95, a(i.plz#i.abovemed_u_profess_s i.monlast#i.kreistyp#i.abovemed_u_profess_s) vce(cluster plz)
					estimates store `file'_noctrl_ife, title(Int. trends)
				}
				display "Event study, all distances, `depvar'"
				estout `file'*ctrl*, varwidth(30) cells(b(star fmt(3)) se(fmt(3)) p(par fmt(3))) starlevels(* 0.05 ** 0.01 *** 0.001) stats(r2 ar2_w N, labels("R^2" "R^2 within" N) fmt(3 0)) style(fixed) label collabels(none) replace
				*estout `file'*ctrl*, varwidth(30) cells(b(fmt(3)) se(fmt(3)) p(par fmt(3))) stats(r2 ar2_w N, labels("R^2" "R^2 within" N) fmt(3 0)) keep($prereftax $postreftax) style(fixed) label collabels(none) replace
				qui {
					foreach type in $graphinput /*`file'_noctrl_fe_no1 `file'_noctrl_fe_no2  `file'_noctrl_fe_no3  `file'_noctrl_fe_no4  `file'_noctrl_fe_no5  `file'_noctrl_fe_no6 `file'_noctrl_fe_no7 `file'_noctrl_fe_no8 `file'_noctrl_fe_no9 `file'_noctrl_fe_no10 `file'_noctrl_fe_no11 `file'_noctrl_fe_no12 `file'_noctrl_fe_no13 `file'_noctrl_fe_no14 `file'_noctrl_fe_no15 `file'_noctrl_fe_no16*/ {
						estimates restore `type'
						matrix b=e(b)
				/*matrix coeff1 = (_b[1.abovemed_u_profess_s#prereftax_1724_3], _b[1.abovemed_u_profess_s#prereftax_1724_2],_b[1.abovemed_u_profess_s#prereftax_1724_1], ///
						_b[1.abovemed_u_profess_s#postreftax_1224_0],_b[1.abovemed_u_profess_s#postreftax_1224_1],_b[1.abovemed_u_profess_s#postreftax_1224_2],_b[1.abovemed_u_profess_s#postreftax_1224_3],_b[1.abovemed_u_profess_s#postreftax_1224_4],_b[1.abovemed_u_profess_s#postreftax_1224_5],_b[1.abovemed_u_profess_s#postreftax_1224_6],_b[1.abovemed_u_profess_s#postreftax_1224_7],_b[1.abovemed_u_profess_s#postreftax_1224_8],_b[1.abovemed_u_profess_s#postreftax_1224_9],_b[1.abovemed_u_profess_s#postreftax_1224_10],_b[1.abovemed_u_profess_s#postreftax_1224_11],_b[1.abovemed_u_profess_s#postreftax_1224_12], _b[1.abovemed_u_profess_s#postreftax_1224_13] ,_b[1.abovemed_u_profess_s#postreftax_1224_14],_b[1.abovemed_u_profess_s#postreftax_1224_15],_b[1.abovemed_u_profess_s#postreftax_1224_16],_b[1.abovemed_u_profess_s#postreftax_1224_17],_b[1.abovemed_u_profess_s#postreftax_1224_18] ,_b[1.abovemed_u_profess_s#postreftax_1224_19],_b[1.abovemed_u_profess_s#postreftax_1224_20],_b[1.abovemed_u_profess_s#postreftax_1224_21],_b[1.abovemed_u_profess_s#postreftax_1224_22])
				matrix coeff2 = (_b[1.abovemed_u_profess_s#prereftax_1724_16], _b[1.abovemed_u_profess_s#prereftax_1724_15], _b[1.abovemed_u_profess_s#prereftax_1724_14], _b[1.abovemed_u_profess_s#prereftax_1724_13],_b[1.abovemed_u_profess_s#prereftax_1724_12], ///
						_b[1.abovemed_u_profess_s#prereftax_1724_11], _b[1.abovemed_u_profess_s#prereftax_1724_10], _b[1.abovemed_u_profess_s#prereftax_1724_9], _b[1.abovemed_u_profess_s#prereftax_1724_8], _b[1.abovemed_u_profess_s#prereftax_1724_7], _b[1.abovemed_u_profess_s#prereftax_1724_6], _b[1.abovemed_u_profess_s#prereftax_1724_5]) */
						
	matrix coeff1 = (b[1,70],b[1,72],b[1,74],b[1,76],b[1,78],b[1,80],b[1,82],b[1,84],b[1,86],b[1,88],b[1,90],b[1,92],b[1,94],b[1,96],b[1,98],b[1,100],b[1,102],b[1,104],b[1,106],b[1,108],b[1,110],b[1,112],b[1,114],b[1,116],b[1,118],b[1,120])
				matrix coeff2 = (b[1,46],b[1,48],b[1,50],b[1,52],b[1,54],b[1,56],b[1,58],b[1,60],b[1,62],b[1,64],b[1,66],b[1,68])						
									
						matrix lowerb = [_b[1.abovemed_u_profess_s#c.prereftax_1724_16] - invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.prereftax_1724_16], _b[1.abovemed_u_profess_s#c.prereftax_1724_15] - invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.prereftax_1724_15], _b[1.abovemed_u_profess_s#c.prereftax_1724_14] - invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.prereftax_1724_14], _b[1.abovemed_u_profess_s#c.prereftax_1724_13] - invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.prereftax_1724_13],_b[1.abovemed_u_profess_s#c.prereftax_1724_12] - invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.prereftax_1724_12], ///
						_b[1.abovemed_u_profess_s#c.prereftax_1724_11] - invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.prereftax_1724_11], _b[1.abovemed_u_profess_s#c.prereftax_1724_10] - invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.prereftax_1724_10], _b[1.abovemed_u_profess_s#c.prereftax_1724_9] - invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.prereftax_1724_9], _b[1.abovemed_u_profess_s#c.prereftax_1724_8] - invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.prereftax_1724_8], _b[1.abovemed_u_profess_s#c.prereftax_1724_7] - invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.prereftax_1724_7], _b[1.abovemed_u_profess_s#c.prereftax_1724_6] - invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.prereftax_1724_6], _b[1.abovemed_u_profess_s#c.prereftax_1724_5] - invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.prereftax_1724_5], 0, _b[1.abovemed_u_profess_s#c.prereftax_1724_3] - invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.prereftax_1724_3], _b[1.abovemed_u_profess_s#c.prereftax_1724_2] - invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.prereftax_1724_2],_b[1.abovemed_u_profess_s#c.prereftax_1724_1] - invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.prereftax_1724_1], ///
						_b[1.abovemed_u_profess_s#c.postreftax_1224_0] - invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_0],_b[1.abovemed_u_profess_s#c.postreftax_1224_1] - invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_1],_b[1.abovemed_u_profess_s#c.postreftax_1224_2] - invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_2],_b[1.abovemed_u_profess_s#c.postreftax_1224_3] - invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_3],_b[1.abovemed_u_profess_s#c.postreftax_1224_4] - invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_4],_b[1.abovemed_u_profess_s#c.postreftax_1224_5] - invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_5],_b[1.abovemed_u_profess_s#c.postreftax_1224_6] - invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_6],_b[1.abovemed_u_profess_s#c.postreftax_1224_7] - invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_7],_b[1.abovemed_u_profess_s#c.postreftax_1224_8] - invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_8],_b[1.abovemed_u_profess_s#c.postreftax_1224_9] - invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_9],_b[1.abovemed_u_profess_s#c.postreftax_1224_10] - invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_10],_b[1.abovemed_u_profess_s#c.postreftax_1224_11] - invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_11],_b[1.abovemed_u_profess_s#c.postreftax_1224_12] - invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_12], ///
						_b[1.abovemed_u_profess_s#c.postreftax_1224_13] - invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_13],_b[1.abovemed_u_profess_s#c.postreftax_1224_14] - invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_14],_b[1.abovemed_u_profess_s#c.postreftax_1224_15] - invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_15],_b[1.abovemed_u_profess_s#c.postreftax_1224_16] - invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_16],_b[1.abovemed_u_profess_s#c.postreftax_1224_17] - invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_17],_b[1.abovemed_u_profess_s#c.postreftax_1224_18] - invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_18],_b[1.abovemed_u_profess_s#c.postreftax_1224_19] - invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_19],_b[1.abovemed_u_profess_s#c.postreftax_1224_20] - invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_20],_b[1.abovemed_u_profess_s#c.postreftax_1224_21] - invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_21],_b[1.abovemed_u_profess_s#c.postreftax_1224_22] - invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_22]]
						
						matrix upperb = [_b[1.abovemed_u_profess_s#c.prereftax_1724_16] + invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.prereftax_1724_16], _b[1.abovemed_u_profess_s#c.prereftax_1724_15] + invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.prereftax_1724_15], _b[1.abovemed_u_profess_s#c.prereftax_1724_14] + invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.prereftax_1724_14], _b[1.abovemed_u_profess_s#c.prereftax_1724_13] + invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.prereftax_1724_13],_b[1.abovemed_u_profess_s#c.prereftax_1724_12] + invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.prereftax_1724_12], ///
						_b[1.abovemed_u_profess_s#c.prereftax_1724_11] + invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.prereftax_1724_11], _b[1.abovemed_u_profess_s#c.prereftax_1724_10] + invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.prereftax_1724_10], _b[1.abovemed_u_profess_s#c.prereftax_1724_9] + invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.prereftax_1724_9], _b[1.abovemed_u_profess_s#c.prereftax_1724_8] + invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.prereftax_1724_8], _b[1.abovemed_u_profess_s#c.prereftax_1724_7] + invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.prereftax_1724_7], _b[1.abovemed_u_profess_s#c.prereftax_1724_6] + invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.prereftax_1724_6], _b[1.abovemed_u_profess_s#c.prereftax_1724_5] + invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.prereftax_1724_5], 0, _b[1.abovemed_u_profess_s#c.prereftax_1724_3] + invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.prereftax_1724_3], _b[1.abovemed_u_profess_s#c.prereftax_1724_2] + invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.prereftax_1724_2],_b[1.abovemed_u_profess_s#c.prereftax_1724_1] + invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.prereftax_1724_1], ///
						_b[1.abovemed_u_profess_s#c.postreftax_1224_0] + invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_0],_b[1.abovemed_u_profess_s#c.postreftax_1224_1] + invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_1],_b[1.abovemed_u_profess_s#c.postreftax_1224_2] + invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_2],_b[1.abovemed_u_profess_s#c.postreftax_1224_3] + invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_3],_b[1.abovemed_u_profess_s#c.postreftax_1224_4] + invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_4],_b[1.abovemed_u_profess_s#c.postreftax_1224_5] + invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_5],_b[1.abovemed_u_profess_s#c.postreftax_1224_6] + invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_6],_b[1.abovemed_u_profess_s#c.postreftax_1224_7] + invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_7],_b[1.abovemed_u_profess_s#c.postreftax_1224_8] + invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_8],_b[1.abovemed_u_profess_s#c.postreftax_1224_9] + invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_9],_b[1.abovemed_u_profess_s#c.postreftax_1224_10] + invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_10],_b[1.abovemed_u_profess_s#c.postreftax_1224_11] + invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_11],_b[1.abovemed_u_profess_s#c.postreftax_1224_12] + invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_12], ///
						_b[1.abovemed_u_profess_s#c.postreftax_1224_13] + invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_13],_b[1.abovemed_u_profess_s#c.postreftax_1224_14] + invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_14],_b[1.abovemed_u_profess_s#c.postreftax_1224_15] + invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_15],_b[1.abovemed_u_profess_s#c.postreftax_1224_16] + invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_16],_b[1.abovemed_u_profess_s#c.postreftax_1224_17] + invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_17],_b[1.abovemed_u_profess_s#c.postreftax_1224_18] + invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_18],_b[1.abovemed_u_profess_s#c.postreftax_1224_19] + invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_19],_b[1.abovemed_u_profess_s#c.postreftax_1224_20] + invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_20],_b[1.abovemed_u_profess_s#c.postreftax_1224_21] + invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_21],_b[1.abovemed_u_profess_s#c.postreftax_1224_22] + invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_22]]
						
						
						matrix res_`type' = [coeff2, 0, coeff1 \  -16, -15, -14, -13, -12, -11, -10, -9, -8, -7, -6, -5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22 \ upperb \ lowerb ]'
						svmat res_`type'
						scatter res_`type'1 res_`type'2, connect(l) yline(0) xline(-4) xline(0, lpattern(dash)) || rcap res_`type'3 res_`type'4 res_`type'2, scheme(s1color) xtitle("Months before/after tax increase") legend(label(1 "Difference") label(2 "95% confidence interval")) xlab(-15 (5) 20) ylab(-0.06 (0.02) 0.02) yscale(range(-0.065 0.025))
						graph export "${graphs}\ESi_`file'_`pctype'_deltatax_`depvar'_`type'_1724_professq_14.pdf", replace
						matrix drop _all
						drop res_`type'*
					}
				}
		
				qui estimates drop *
			}
		}
		
	
		
	}   // $byprofinv_hl	
	
	
			
	if $byprofinv_hl == 1 {
		*** time trends interagiert mit kreistyp
		global graphinput /*`file'_noctrl_fe*/ `file'_noctrl_ife // `file'_ctrl1_ife `file'_ctrl2_ife `file'_ctrl3_ife `file'_ctrl4_ife `file'_ctrl5_ife `file'_ctrl6_ife
		use $prereform $postreform $prereftax17 $postreftax $prereflntax $postreflntax ersterpreis daysposted pricediff pricediff_pc buildaged ln_flaeche flaeche zimmeranzahl basement balcony parking kitchen garden baujahrd heatingtype centralheat fancy fancyequip quietloc bright $depvars2 wmt* pricechpc jahr plz betrag preisqm kreistyp monlast popg popgallwp05 popgallwp95 letzterpreis kreis using "F:/Neumeier_RETT/98 not classified/Output/ifo_`file'_4q19_prep_3624.dta".dta, clear
		merge m:1 kreis using "F:\Neumeier_RETT\1 data\ExternalData\Wohnungsbestand_ownership.dta", keepusing(abovemed_u_profess_s)
		*gen ln_ersterpreisqm = ln(ersterpreis/flaeche)
		
		**** Use final price as dependent variable
		* without municipalities below the 5% / above the 95% population growth percentile 
		foreach pctype in popgallwp {
			foreach depvar of varlist ln_preisqm {
				qui {
					reghdfe `depvar' (c.(${prereftax17}) c.(${postreftax}))##i.abovemed_u_profess_s if popg>= `pctype'05 & popg<=`pctype'95, a(i.plz#i.abovemed_u_profess_s i.monlast#i.kreistyp#i.abovemed_u_profess_s) vce(cluster plz)
					estimates store `file'_noctrl_ife, title(Int. trends)
				}
				display "Event study, all distances, `depvar'"
				estout `file'*ctrl*, varwidth(30) cells(b(star fmt(3)) se(fmt(3)) p(par fmt(3))) starlevels(* 0.05 ** 0.01 *** 0.001) stats(r2 ar2_w N, labels("R^2" "R^2 within" N) fmt(3 0)) style(fixed) label collabels(none) replace
				*estout `file'*ctrl*, varwidth(30) cells(b(fmt(3)) se(fmt(3)) p(par fmt(3))) stats(r2 ar2_w N, labels("R^2" "R^2 within" N) fmt(3 0)) keep($prereftax $postreftax) style(fixed) label collabels(none) replace
				qui {
					foreach type in $graphinput /*`file'_noctrl_fe_no1 `file'_noctrl_fe_no2  `file'_noctrl_fe_no3  `file'_noctrl_fe_no4  `file'_noctrl_fe_no5  `file'_noctrl_fe_no6 `file'_noctrl_fe_no7 `file'_noctrl_fe_no8 `file'_noctrl_fe_no9 `file'_noctrl_fe_no10 `file'_noctrl_fe_no11 `file'_noctrl_fe_no12 `file'_noctrl_fe_no13 `file'_noctrl_fe_no14 `file'_noctrl_fe_no15 `file'_noctrl_fe_no16*/ {
						estimates restore `type'
						matrix b=e(b)
				/*matrix coeff1 = (_b[1.abovemed_u_profess_s#prereftax_1724_3], _b[1.abovemed_u_profess_s#prereftax_1724_2],_b[1.abovemed_u_profess_s#prereftax_1724_1], ///
						_b[1.abovemed_u_profess_s#postreftax_1224_0],_b[1.abovemed_u_profess_s#postreftax_1224_1],_b[1.abovemed_u_profess_s#postreftax_1224_2],_b[1.abovemed_u_profess_s#postreftax_1224_3],_b[1.abovemed_u_profess_s#postreftax_1224_4],_b[1.abovemed_u_profess_s#postreftax_1224_5],_b[1.abovemed_u_profess_s#postreftax_1224_6],_b[1.abovemed_u_profess_s#postreftax_1224_7],_b[1.abovemed_u_profess_s#postreftax_1224_8],_b[1.abovemed_u_profess_s#postreftax_1224_9],_b[1.abovemed_u_profess_s#postreftax_1224_10],_b[1.abovemed_u_profess_s#postreftax_1224_11],_b[1.abovemed_u_profess_s#postreftax_1224_12], _b[1.abovemed_u_profess_s#postreftax_1224_13] ,_b[1.abovemed_u_profess_s#postreftax_1224_14],_b[1.abovemed_u_profess_s#postreftax_1224_15],_b[1.abovemed_u_profess_s#postreftax_1224_16],_b[1.abovemed_u_profess_s#postreftax_1224_17],_b[1.abovemed_u_profess_s#postreftax_1224_18] ,_b[1.abovemed_u_profess_s#postreftax_1224_19],_b[1.abovemed_u_profess_s#postreftax_1224_20],_b[1.abovemed_u_profess_s#postreftax_1224_21],_b[1.abovemed_u_profess_s#postreftax_1224_22])
				matrix coeff2 = (_b[1.abovemed_u_profess_s#prereftax_1724_16], _b[1.abovemed_u_profess_s#prereftax_1724_15], _b[1.abovemed_u_profess_s#prereftax_1724_14], _b[1.abovemed_u_profess_s#prereftax_1724_13],_b[1.abovemed_u_profess_s#prereftax_1724_12], ///
						_b[1.abovemed_u_profess_s#prereftax_1724_11], _b[1.abovemed_u_profess_s#prereftax_1724_10], _b[1.abovemed_u_profess_s#prereftax_1724_9], _b[1.abovemed_u_profess_s#prereftax_1724_8], _b[1.abovemed_u_profess_s#prereftax_1724_7], _b[1.abovemed_u_profess_s#prereftax_1724_6], _b[1.abovemed_u_profess_s#prereftax_1724_5]) */
						
	matrix coeff1 = (b[1,70],b[1,72],b[1,74],b[1,76],b[1,78],b[1,80],b[1,82],b[1,84],b[1,86],b[1,88],b[1,90],b[1,92],b[1,94],b[1,96],b[1,98],b[1,100],b[1,102],b[1,104],b[1,106],b[1,108],b[1,110],b[1,112],b[1,114],b[1,116],b[1,118],b[1,120])
				matrix coeff2 = (b[1,46],b[1,48],b[1,50],b[1,52],b[1,54],b[1,56],b[1,58],b[1,60],b[1,62],b[1,64],b[1,66],b[1,68])						
									
						matrix lowerb = [_b[1.abovemed_u_profess_s#c.prereftax_1724_16] - invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.prereftax_1724_16], _b[1.abovemed_u_profess_s#c.prereftax_1724_15] - invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.prereftax_1724_15], _b[1.abovemed_u_profess_s#c.prereftax_1724_14] - invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.prereftax_1724_14], _b[1.abovemed_u_profess_s#c.prereftax_1724_13] - invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.prereftax_1724_13],_b[1.abovemed_u_profess_s#c.prereftax_1724_12] - invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.prereftax_1724_12], ///
						_b[1.abovemed_u_profess_s#c.prereftax_1724_11] - invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.prereftax_1724_11], _b[1.abovemed_u_profess_s#c.prereftax_1724_10] - invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.prereftax_1724_10], _b[1.abovemed_u_profess_s#c.prereftax_1724_9] - invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.prereftax_1724_9], _b[1.abovemed_u_profess_s#c.prereftax_1724_8] - invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.prereftax_1724_8], _b[1.abovemed_u_profess_s#c.prereftax_1724_7] - invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.prereftax_1724_7], _b[1.abovemed_u_profess_s#c.prereftax_1724_6] - invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.prereftax_1724_6], _b[1.abovemed_u_profess_s#c.prereftax_1724_5] - invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.prereftax_1724_5], 0, _b[1.abovemed_u_profess_s#c.prereftax_1724_3] - invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.prereftax_1724_3], _b[1.abovemed_u_profess_s#c.prereftax_1724_2] - invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.prereftax_1724_2],_b[1.abovemed_u_profess_s#c.prereftax_1724_1] - invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.prereftax_1724_1], ///
						_b[1.abovemed_u_profess_s#c.postreftax_1224_0] - invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_0],_b[1.abovemed_u_profess_s#c.postreftax_1224_1] - invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_1],_b[1.abovemed_u_profess_s#c.postreftax_1224_2] - invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_2],_b[1.abovemed_u_profess_s#c.postreftax_1224_3] - invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_3],_b[1.abovemed_u_profess_s#c.postreftax_1224_4] - invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_4],_b[1.abovemed_u_profess_s#c.postreftax_1224_5] - invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_5],_b[1.abovemed_u_profess_s#c.postreftax_1224_6] - invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_6],_b[1.abovemed_u_profess_s#c.postreftax_1224_7] - invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_7],_b[1.abovemed_u_profess_s#c.postreftax_1224_8] - invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_8],_b[1.abovemed_u_profess_s#c.postreftax_1224_9] - invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_9],_b[1.abovemed_u_profess_s#c.postreftax_1224_10] - invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_10],_b[1.abovemed_u_profess_s#c.postreftax_1224_11] - invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_11],_b[1.abovemed_u_profess_s#c.postreftax_1224_12] - invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_12], ///
						_b[1.abovemed_u_profess_s#c.postreftax_1224_13] - invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_13],_b[1.abovemed_u_profess_s#c.postreftax_1224_14] - invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_14],_b[1.abovemed_u_profess_s#c.postreftax_1224_15] - invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_15],_b[1.abovemed_u_profess_s#c.postreftax_1224_16] - invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_16],_b[1.abovemed_u_profess_s#c.postreftax_1224_17] - invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_17],_b[1.abovemed_u_profess_s#c.postreftax_1224_18] - invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_18],_b[1.abovemed_u_profess_s#c.postreftax_1224_19] - invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_19],_b[1.abovemed_u_profess_s#c.postreftax_1224_20] - invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_20],_b[1.abovemed_u_profess_s#c.postreftax_1224_21] - invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_21],_b[1.abovemed_u_profess_s#c.postreftax_1224_22] - invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_22]]
						
						matrix upperb = [_b[1.abovemed_u_profess_s#c.prereftax_1724_16] + invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.prereftax_1724_16], _b[1.abovemed_u_profess_s#c.prereftax_1724_15] + invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.prereftax_1724_15], _b[1.abovemed_u_profess_s#c.prereftax_1724_14] + invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.prereftax_1724_14], _b[1.abovemed_u_profess_s#c.prereftax_1724_13] + invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.prereftax_1724_13],_b[1.abovemed_u_profess_s#c.prereftax_1724_12] + invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.prereftax_1724_12], ///
						_b[1.abovemed_u_profess_s#c.prereftax_1724_11] + invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.prereftax_1724_11], _b[1.abovemed_u_profess_s#c.prereftax_1724_10] + invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.prereftax_1724_10], _b[1.abovemed_u_profess_s#c.prereftax_1724_9] + invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.prereftax_1724_9], _b[1.abovemed_u_profess_s#c.prereftax_1724_8] + invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.prereftax_1724_8], _b[1.abovemed_u_profess_s#c.prereftax_1724_7] + invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.prereftax_1724_7], _b[1.abovemed_u_profess_s#c.prereftax_1724_6] + invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.prereftax_1724_6], _b[1.abovemed_u_profess_s#c.prereftax_1724_5] + invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.prereftax_1724_5], 0, _b[1.abovemed_u_profess_s#c.prereftax_1724_3] + invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.prereftax_1724_3], _b[1.abovemed_u_profess_s#c.prereftax_1724_2] + invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.prereftax_1724_2],_b[1.abovemed_u_profess_s#c.prereftax_1724_1] + invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.prereftax_1724_1], ///
						_b[1.abovemed_u_profess_s#c.postreftax_1224_0] + invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_0],_b[1.abovemed_u_profess_s#c.postreftax_1224_1] + invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_1],_b[1.abovemed_u_profess_s#c.postreftax_1224_2] + invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_2],_b[1.abovemed_u_profess_s#c.postreftax_1224_3] + invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_3],_b[1.abovemed_u_profess_s#c.postreftax_1224_4] + invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_4],_b[1.abovemed_u_profess_s#c.postreftax_1224_5] + invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_5],_b[1.abovemed_u_profess_s#c.postreftax_1224_6] + invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_6],_b[1.abovemed_u_profess_s#c.postreftax_1224_7] + invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_7],_b[1.abovemed_u_profess_s#c.postreftax_1224_8] + invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_8],_b[1.abovemed_u_profess_s#c.postreftax_1224_9] + invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_9],_b[1.abovemed_u_profess_s#c.postreftax_1224_10] + invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_10],_b[1.abovemed_u_profess_s#c.postreftax_1224_11] + invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_11],_b[1.abovemed_u_profess_s#c.postreftax_1224_12] + invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_12], ///
						_b[1.abovemed_u_profess_s#c.postreftax_1224_13] + invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_13],_b[1.abovemed_u_profess_s#c.postreftax_1224_14] + invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_14],_b[1.abovemed_u_profess_s#c.postreftax_1224_15] + invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_15],_b[1.abovemed_u_profess_s#c.postreftax_1224_16] + invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_16],_b[1.abovemed_u_profess_s#c.postreftax_1224_17] + invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_17],_b[1.abovemed_u_profess_s#c.postreftax_1224_18] + invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_18],_b[1.abovemed_u_profess_s#c.postreftax_1224_19] + invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_19],_b[1.abovemed_u_profess_s#c.postreftax_1224_20] + invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_20],_b[1.abovemed_u_profess_s#c.postreftax_1224_21] + invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_21],_b[1.abovemed_u_profess_s#c.postreftax_1224_22] + invttail(e(df_r),0.025)*_se[1.abovemed_u_profess_s#c.postreftax_1224_22]]
						
						
						matrix res_`type' = [coeff2, 0, coeff1 \  -16, -15, -14, -13, -12, -11, -10, -9, -8, -7, -6, -5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22 \ upperb \ lowerb ]'
						svmat res_`type'
						scatter res_`type'1 res_`type'2, connect(l) yline(0) xline(-4) xline(0, lpattern(dash)) || rcap res_`type'3 res_`type'4 res_`type'2, scheme(s1color) xtitle("Months before/after tax increase") legend(label(1 "Difference") label(2 "95% confidence interval")) xlab(-15 (5) 20) ylab(-0.06 (0.02) 0.02) yscale(range(-0.065 0.025))
						graph export "${graphs}\ESi_`file'_`pctype'_deltatax_`depvar'_`type'_1724_professabovemed_01.pdf", replace
						matrix drop _all
						drop res_`type'*
					}
				}
		
				qui estimates drop *
			}
		}
		
	
		
	}   // $byprofinv_hl		
	
	
* 2) share of investors relative to apartments

		* winsorized_longer 17
	if $byprofinvapp == 1 {
		*** time trends interagiert mit kreistyp
		global graphinput /*`file'_noctrl_fe*/ `file'_noctrl_ife // `file'_ctrl1_ife `file'_ctrl2_ife `file'_ctrl3_ife `file'_ctrl4_ife `file'_ctrl5_ife `file'_ctrl6_ife
		use $prereform $postreform $prereftax17 $postreftax $prereflntax $postreflntax ersterpreis daysposted pricediff pricediff_pc buildaged ln_flaeche flaeche zimmeranzahl basement balcony parking kitchen garden baujahrd heatingtype centralheat fancy fancyequip quietloc bright $depvars2 wmt* pricechpc jahr plz betrag preisqm kreistyp monlast popg popgallwp05 popgallwp95 letzterpreis kreis using "F:/Neumeier_RETT/98 not classified/Output/ifo_`file'_4q19_prep_3624.dta".dta, clear
		merge m:1 kreis using "F:\Neumeier_RETT\1 data\ExternalData\Wohnungsbestand_ownership.dta", keepusing(abovemed_u_profess_sa)
		*gen ln_ersterpreisqm = ln(ersterpreis/flaeche)
		
		
		**** Use final price as dependent variable
		* without municipalities below the 5% / above the 95% population growth percentile 
		foreach prmed of numlist 0 1 {
		foreach pctype in popgallwp {
			foreach depvar of varlist ln_preisqm {
				qui {
					xtreg `depvar' $prereftax17 $postreftax i.monlast#i.kreistyp if popg>= `pctype'05 & popg<=`pctype'95 & abovemed_u_profess_sa==`prmed', fe vce(cluster plz)
					estimates store `file'_noctrl_ife, title(Int. trends)
				}
				display "Event study, all distances, `depvar'"
				estout `file'*ctrl*, varwidth(30) cells(b(star fmt(3)) se(fmt(3)) p(par fmt(3))) starlevels(* 0.05 ** 0.01 *** 0.001) stats(r2 ar2_w N, labels("R^2" "R^2 within" N) fmt(3 0)) keep($prereftax17 $postreftax) style(fixed) label collabels(none) replace
				*estout `file'*ctrl*, varwidth(30) cells(b(fmt(3)) se(fmt(3)) p(par fmt(3))) stats(r2 ar2_w N, labels("R^2" "R^2 within" N) fmt(3 0)) keep($prereftax $postreftax) style(fixed) label collabels(none) replace
				qui {
					foreach type in $graphinput /*`file'_noctrl_fe_no1 `file'_noctrl_fe_no2  `file'_noctrl_fe_no3  `file'_noctrl_fe_no4  `file'_noctrl_fe_no5  `file'_noctrl_fe_no6 `file'_noctrl_fe_no7 `file'_noctrl_fe_no8 `file'_noctrl_fe_no9 `file'_noctrl_fe_no10 `file'_noctrl_fe_no11 `file'_noctrl_fe_no12 `file'_noctrl_fe_no13 `file'_noctrl_fe_no14 `file'_noctrl_fe_no15 `file'_noctrl_fe_no16*/ {
						estimates restore `type'
						matrix b=e(b)
						matrix coeff1 = b[1,14..39]
						matrix coeff2 = b[1,2..13]
									
						matrix lowerb = [_b[prereftax_1724_16] - invttail(e(df_r),0.025)*_se[prereftax_1724_16], _b[prereftax_1724_15] - invttail(e(df_r),0.025)*_se[prereftax_1724_15], _b[prereftax_1724_14] - invttail(e(df_r),0.025)*_se[prereftax_1724_14], _b[prereftax_1724_13] - invttail(e(df_r),0.025)*_se[prereftax_1724_13],_b[prereftax_1724_12] - invttail(e(df_r),0.025)*_se[prereftax_1724_12], ///
						_b[prereftax_1724_11] - invttail(e(df_r),0.025)*_se[prereftax_1724_11], _b[prereftax_1724_10] - invttail(e(df_r),0.025)*_se[prereftax_1724_10], _b[prereftax_1724_9] - invttail(e(df_r),0.025)*_se[prereftax_1724_9], _b[prereftax_1724_8] - invttail(e(df_r),0.025)*_se[prereftax_1724_8], _b[prereftax_1724_7] - invttail(e(df_r),0.025)*_se[prereftax_1724_7], _b[prereftax_1724_6] - invttail(e(df_r),0.025)*_se[prereftax_1724_6], _b[prereftax_1724_5] - invttail(e(df_r),0.025)*_se[prereftax_1724_5], 0, _b[prereftax_1724_3] - invttail(e(df_r),0.025)*_se[prereftax_1724_3], _b[prereftax_1724_2] - invttail(e(df_r),0.025)*_se[prereftax_1724_2],_b[prereftax_1724_1] - invttail(e(df_r),0.025)*_se[prereftax_1724_1], ///
						_b[postreftax_1224_0] - invttail(e(df_r),0.025)*_se[postreftax_1224_0],_b[postreftax_1224_1] - invttail(e(df_r),0.025)*_se[postreftax_1224_1],_b[postreftax_1224_2] - invttail(e(df_r),0.025)*_se[postreftax_1224_2],_b[postreftax_1224_3] - invttail(e(df_r),0.025)*_se[postreftax_1224_3],_b[postreftax_1224_4] - invttail(e(df_r),0.025)*_se[postreftax_1224_4],_b[postreftax_1224_5] - invttail(e(df_r),0.025)*_se[postreftax_1224_5],_b[postreftax_1224_6] - invttail(e(df_r),0.025)*_se[postreftax_1224_6],_b[postreftax_1224_7] - invttail(e(df_r),0.025)*_se[postreftax_1224_7],_b[postreftax_1224_8] - invttail(e(df_r),0.025)*_se[postreftax_1224_8],_b[postreftax_1224_9] - invttail(e(df_r),0.025)*_se[postreftax_1224_9],_b[postreftax_1224_10] - invttail(e(df_r),0.025)*_se[postreftax_1224_10],_b[postreftax_1224_11] - invttail(e(df_r),0.025)*_se[postreftax_1224_11],_b[postreftax_1224_12] - invttail(e(df_r),0.025)*_se[postreftax_1224_12], ///
						_b[postreftax_1224_13] - invttail(e(df_r),0.025)*_se[postreftax_1224_13],_b[postreftax_1224_14] - invttail(e(df_r),0.025)*_se[postreftax_1224_14],_b[postreftax_1224_15] - invttail(e(df_r),0.025)*_se[postreftax_1224_15],_b[postreftax_1224_16] - invttail(e(df_r),0.025)*_se[postreftax_1224_16],_b[postreftax_1224_17] - invttail(e(df_r),0.025)*_se[postreftax_1224_17],_b[postreftax_1224_18] - invttail(e(df_r),0.025)*_se[postreftax_1224_18],_b[postreftax_1224_19] - invttail(e(df_r),0.025)*_se[postreftax_1224_19],_b[postreftax_1224_20] - invttail(e(df_r),0.025)*_se[postreftax_1224_20],_b[postreftax_1224_21] - invttail(e(df_r),0.025)*_se[postreftax_1224_21],_b[postreftax_1224_22] - invttail(e(df_r),0.025)*_se[postreftax_1224_22]]
						
						matrix upperb = [_b[prereftax_1724_16] + invttail(e(df_r),0.025)*_se[prereftax_1724_16], _b[prereftax_1724_15] + invttail(e(df_r),0.025)*_se[prereftax_1724_15], _b[prereftax_1724_14] + invttail(e(df_r),0.025)*_se[prereftax_1724_14], _b[prereftax_1724_13] + invttail(e(df_r),0.025)*_se[prereftax_1724_13],_b[prereftax_1724_12] + invttail(e(df_r),0.025)*_se[prereftax_1724_12], ///
						_b[prereftax_1724_11] + invttail(e(df_r),0.025)*_se[prereftax_1724_11], _b[prereftax_1724_10] + invttail(e(df_r),0.025)*_se[prereftax_1724_10], _b[prereftax_1724_9] + invttail(e(df_r),0.025)*_se[prereftax_1724_9], _b[prereftax_1724_8] + invttail(e(df_r),0.025)*_se[prereftax_1724_8], _b[prereftax_1724_7] + invttail(e(df_r),0.025)*_se[prereftax_1724_7], _b[prereftax_1724_6] + invttail(e(df_r),0.025)*_se[prereftax_1724_6], _b[prereftax_1724_5] + invttail(e(df_r),0.025)*_se[prereftax_1724_5], 0, _b[prereftax_1724_3] + invttail(e(df_r),0.025)*_se[prereftax_1724_3], _b[prereftax_1724_2] + invttail(e(df_r),0.025)*_se[prereftax_1724_2],_b[prereftax_1724_1] + invttail(e(df_r),0.025)*_se[prereftax_1724_1], ///
						_b[postreftax_1224_0] + invttail(e(df_r),0.025)*_se[postreftax_1224_0],_b[postreftax_1224_1] + invttail(e(df_r),0.025)*_se[postreftax_1224_1],_b[postreftax_1224_2] + invttail(e(df_r),0.025)*_se[postreftax_1224_2],_b[postreftax_1224_3] + invttail(e(df_r),0.025)*_se[postreftax_1224_3],_b[postreftax_1224_4] + invttail(e(df_r),0.025)*_se[postreftax_1224_4],_b[postreftax_1224_5] + invttail(e(df_r),0.025)*_se[postreftax_1224_5],_b[postreftax_1224_6] + invttail(e(df_r),0.025)*_se[postreftax_1224_6],_b[postreftax_1224_7] + invttail(e(df_r),0.025)*_se[postreftax_1224_7],_b[postreftax_1224_8] + invttail(e(df_r),0.025)*_se[postreftax_1224_8],_b[postreftax_1224_9] + invttail(e(df_r),0.025)*_se[postreftax_1224_9],_b[postreftax_1224_10] + invttail(e(df_r),0.025)*_se[postreftax_1224_10],_b[postreftax_1224_11] + invttail(e(df_r),0.025)*_se[postreftax_1224_11],_b[postreftax_1224_12] + invttail(e(df_r),0.025)*_se[postreftax_1224_12], ///
						_b[postreftax_1224_13] + invttail(e(df_r),0.025)*_se[postreftax_1224_13],_b[postreftax_1224_14] + invttail(e(df_r),0.025)*_se[postreftax_1224_14],_b[postreftax_1224_15] + invttail(e(df_r),0.025)*_se[postreftax_1224_15],_b[postreftax_1224_16] + invttail(e(df_r),0.025)*_se[postreftax_1224_16],_b[postreftax_1224_17] + invttail(e(df_r),0.025)*_se[postreftax_1224_17],_b[postreftax_1224_18] + invttail(e(df_r),0.025)*_se[postreftax_1224_18],_b[postreftax_1224_19] + invttail(e(df_r),0.025)*_se[postreftax_1224_19],_b[postreftax_1224_20] + invttail(e(df_r),0.025)*_se[postreftax_1224_20],_b[postreftax_1224_21] + invttail(e(df_r),0.025)*_se[postreftax_1224_21],_b[postreftax_1224_22] + invttail(e(df_r),0.025)*_se[postreftax_1224_22]]
						
						
						matrix res_`type' = [coeff2, 0, coeff1 \  -16, -15, -14, -13, -12, -11, -10, -9, -8, -7, -6, -5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22 \ upperb \ lowerb ]'
						svmat res_`type'
						scatter res_`type'1 res_`type'2, connect(l) yline(0) xline(-4) xline(0, lpattern(dash)) || rcap res_`type'3 res_`type'4 res_`type'2, scheme(s1color) xtitle("Months before/after tax increase") legend(label(1 "Price effect") label(2 "95% confidence interval")) xlab(-15 (5) 20) ylab(-0.06 (0.02) 0.02) yscale(range(-0.065 0.025))
						graph export "${graphs}\ESi_`file'_`pctype'_deltatax_`depvar'_`type'_1724_profabovemedapp`prmed'.pdf", replace
						matrix drop _all
						drop res_`type'*
					}
				}
		
				qui estimates drop *
			}
		}
		}
	
		
	}   // $byprofinvapp
	
* 3) share of private investors
		* winsorized_longer 17
	if $byprivinv == 1 {
		*** time trends interagiert mit kreistyp
		global graphinput /*`file'_noctrl_fe*/ `file'_noctrl_ife // `file'_ctrl1_ife `file'_ctrl2_ife `file'_ctrl3_ife `file'_ctrl4_ife `file'_ctrl5_ife `file'_ctrl6_ife
		use $prereform $postreform $prereftax17 $postreftax $prereflntax $postreflntax ersterpreis daysposted pricediff pricediff_pc buildaged ln_flaeche flaeche zimmeranzahl basement balcony parking kitchen garden baujahrd heatingtype centralheat fancy fancyequip quietloc bright $depvars2 wmt* pricechpc jahr plz betrag preisqm kreistyp monlast popg popgallwp05 popgallwp95 letzterpreis kreis using "F:/Neumeier_RETT/98 not classified/Output/ifo_`file'_4q19_prep_3624.dta".dta, clear
		merge m:1 kreis using "F:\Neumeier_RETT\1 data\ExternalData\Wohnungsbestand_ownership.dta", keepusing(abovemed_u_priv_s)
		*gen ln_ersterpreisqm = ln(ersterpreis/flaeche)
		
		
		**** Use final price as dependent variable
		* without municipalities below the 5% / above the 95% population growth percentile 
		foreach prmed of numlist 0 1 {
		foreach pctype in popgallwp {
			foreach depvar of varlist ln_preisqm {
				qui {
					xtreg `depvar' $prereftax17 $postreftax i.monlast#i.kreistyp if popg>= `pctype'05 & popg<=`pctype'95 & abovemed_u_priv_s==`prmed', fe vce(cluster plz)
					estimates store `file'_noctrl_ife, title(Int. trends)
				}
				display "Event study, all distances, `depvar'"
				estout `file'*ctrl*, varwidth(30) cells(b(star fmt(3)) se(fmt(3)) p(par fmt(3))) starlevels(* 0.05 ** 0.01 *** 0.001) stats(r2 ar2_w N, labels("R^2" "R^2 within" N) fmt(3 0)) keep($prereftax17 $postreftax) style(fixed) label collabels(none) replace
				*estout `file'*ctrl*, varwidth(30) cells(b(fmt(3)) se(fmt(3)) p(par fmt(3))) stats(r2 ar2_w N, labels("R^2" "R^2 within" N) fmt(3 0)) keep($prereftax $postreftax) style(fixed) label collabels(none) replace
				qui {
					foreach type in $graphinput /*`file'_noctrl_fe_no1 `file'_noctrl_fe_no2  `file'_noctrl_fe_no3  `file'_noctrl_fe_no4  `file'_noctrl_fe_no5  `file'_noctrl_fe_no6 `file'_noctrl_fe_no7 `file'_noctrl_fe_no8 `file'_noctrl_fe_no9 `file'_noctrl_fe_no10 `file'_noctrl_fe_no11 `file'_noctrl_fe_no12 `file'_noctrl_fe_no13 `file'_noctrl_fe_no14 `file'_noctrl_fe_no15 `file'_noctrl_fe_no16*/ {
						estimates restore `type'
						matrix b=e(b)
						matrix coeff1 = b[1,14..39]
						matrix coeff2 = b[1,2..13]
									
						matrix lowerb = [_b[prereftax_1724_16] - invttail(e(df_r),0.025)*_se[prereftax_1724_16], _b[prereftax_1724_15] - invttail(e(df_r),0.025)*_se[prereftax_1724_15], _b[prereftax_1724_14] - invttail(e(df_r),0.025)*_se[prereftax_1724_14], _b[prereftax_1724_13] - invttail(e(df_r),0.025)*_se[prereftax_1724_13],_b[prereftax_1724_12] - invttail(e(df_r),0.025)*_se[prereftax_1724_12], ///
						_b[prereftax_1724_11] - invttail(e(df_r),0.025)*_se[prereftax_1724_11], _b[prereftax_1724_10] - invttail(e(df_r),0.025)*_se[prereftax_1724_10], _b[prereftax_1724_9] - invttail(e(df_r),0.025)*_se[prereftax_1724_9], _b[prereftax_1724_8] - invttail(e(df_r),0.025)*_se[prereftax_1724_8], _b[prereftax_1724_7] - invttail(e(df_r),0.025)*_se[prereftax_1724_7], _b[prereftax_1724_6] - invttail(e(df_r),0.025)*_se[prereftax_1724_6], _b[prereftax_1724_5] - invttail(e(df_r),0.025)*_se[prereftax_1724_5], 0, _b[prereftax_1724_3] - invttail(e(df_r),0.025)*_se[prereftax_1724_3], _b[prereftax_1724_2] - invttail(e(df_r),0.025)*_se[prereftax_1724_2],_b[prereftax_1724_1] - invttail(e(df_r),0.025)*_se[prereftax_1724_1], ///
						_b[postreftax_1224_0] - invttail(e(df_r),0.025)*_se[postreftax_1224_0],_b[postreftax_1224_1] - invttail(e(df_r),0.025)*_se[postreftax_1224_1],_b[postreftax_1224_2] - invttail(e(df_r),0.025)*_se[postreftax_1224_2],_b[postreftax_1224_3] - invttail(e(df_r),0.025)*_se[postreftax_1224_3],_b[postreftax_1224_4] - invttail(e(df_r),0.025)*_se[postreftax_1224_4],_b[postreftax_1224_5] - invttail(e(df_r),0.025)*_se[postreftax_1224_5],_b[postreftax_1224_6] - invttail(e(df_r),0.025)*_se[postreftax_1224_6],_b[postreftax_1224_7] - invttail(e(df_r),0.025)*_se[postreftax_1224_7],_b[postreftax_1224_8] - invttail(e(df_r),0.025)*_se[postreftax_1224_8],_b[postreftax_1224_9] - invttail(e(df_r),0.025)*_se[postreftax_1224_9],_b[postreftax_1224_10] - invttail(e(df_r),0.025)*_se[postreftax_1224_10],_b[postreftax_1224_11] - invttail(e(df_r),0.025)*_se[postreftax_1224_11],_b[postreftax_1224_12] - invttail(e(df_r),0.025)*_se[postreftax_1224_12], ///
						_b[postreftax_1224_13] - invttail(e(df_r),0.025)*_se[postreftax_1224_13],_b[postreftax_1224_14] - invttail(e(df_r),0.025)*_se[postreftax_1224_14],_b[postreftax_1224_15] - invttail(e(df_r),0.025)*_se[postreftax_1224_15],_b[postreftax_1224_16] - invttail(e(df_r),0.025)*_se[postreftax_1224_16],_b[postreftax_1224_17] - invttail(e(df_r),0.025)*_se[postreftax_1224_17],_b[postreftax_1224_18] - invttail(e(df_r),0.025)*_se[postreftax_1224_18],_b[postreftax_1224_19] - invttail(e(df_r),0.025)*_se[postreftax_1224_19],_b[postreftax_1224_20] - invttail(e(df_r),0.025)*_se[postreftax_1224_20],_b[postreftax_1224_21] - invttail(e(df_r),0.025)*_se[postreftax_1224_21],_b[postreftax_1224_22] - invttail(e(df_r),0.025)*_se[postreftax_1224_22]]
						
						matrix upperb = [_b[prereftax_1724_16] + invttail(e(df_r),0.025)*_se[prereftax_1724_16], _b[prereftax_1724_15] + invttail(e(df_r),0.025)*_se[prereftax_1724_15], _b[prereftax_1724_14] + invttail(e(df_r),0.025)*_se[prereftax_1724_14], _b[prereftax_1724_13] + invttail(e(df_r),0.025)*_se[prereftax_1724_13],_b[prereftax_1724_12] + invttail(e(df_r),0.025)*_se[prereftax_1724_12], ///
						_b[prereftax_1724_11] + invttail(e(df_r),0.025)*_se[prereftax_1724_11], _b[prereftax_1724_10] + invttail(e(df_r),0.025)*_se[prereftax_1724_10], _b[prereftax_1724_9] + invttail(e(df_r),0.025)*_se[prereftax_1724_9], _b[prereftax_1724_8] + invttail(e(df_r),0.025)*_se[prereftax_1724_8], _b[prereftax_1724_7] + invttail(e(df_r),0.025)*_se[prereftax_1724_7], _b[prereftax_1724_6] + invttail(e(df_r),0.025)*_se[prereftax_1724_6], _b[prereftax_1724_5] + invttail(e(df_r),0.025)*_se[prereftax_1724_5], 0, _b[prereftax_1724_3] + invttail(e(df_r),0.025)*_se[prereftax_1724_3], _b[prereftax_1724_2] + invttail(e(df_r),0.025)*_se[prereftax_1724_2],_b[prereftax_1724_1] + invttail(e(df_r),0.025)*_se[prereftax_1724_1], ///
						_b[postreftax_1224_0] + invttail(e(df_r),0.025)*_se[postreftax_1224_0],_b[postreftax_1224_1] + invttail(e(df_r),0.025)*_se[postreftax_1224_1],_b[postreftax_1224_2] + invttail(e(df_r),0.025)*_se[postreftax_1224_2],_b[postreftax_1224_3] + invttail(e(df_r),0.025)*_se[postreftax_1224_3],_b[postreftax_1224_4] + invttail(e(df_r),0.025)*_se[postreftax_1224_4],_b[postreftax_1224_5] + invttail(e(df_r),0.025)*_se[postreftax_1224_5],_b[postreftax_1224_6] + invttail(e(df_r),0.025)*_se[postreftax_1224_6],_b[postreftax_1224_7] + invttail(e(df_r),0.025)*_se[postreftax_1224_7],_b[postreftax_1224_8] + invttail(e(df_r),0.025)*_se[postreftax_1224_8],_b[postreftax_1224_9] + invttail(e(df_r),0.025)*_se[postreftax_1224_9],_b[postreftax_1224_10] + invttail(e(df_r),0.025)*_se[postreftax_1224_10],_b[postreftax_1224_11] + invttail(e(df_r),0.025)*_se[postreftax_1224_11],_b[postreftax_1224_12] + invttail(e(df_r),0.025)*_se[postreftax_1224_12], ///
						_b[postreftax_1224_13] + invttail(e(df_r),0.025)*_se[postreftax_1224_13],_b[postreftax_1224_14] + invttail(e(df_r),0.025)*_se[postreftax_1224_14],_b[postreftax_1224_15] + invttail(e(df_r),0.025)*_se[postreftax_1224_15],_b[postreftax_1224_16] + invttail(e(df_r),0.025)*_se[postreftax_1224_16],_b[postreftax_1224_17] + invttail(e(df_r),0.025)*_se[postreftax_1224_17],_b[postreftax_1224_18] + invttail(e(df_r),0.025)*_se[postreftax_1224_18],_b[postreftax_1224_19] + invttail(e(df_r),0.025)*_se[postreftax_1224_19],_b[postreftax_1224_20] + invttail(e(df_r),0.025)*_se[postreftax_1224_20],_b[postreftax_1224_21] + invttail(e(df_r),0.025)*_se[postreftax_1224_21],_b[postreftax_1224_22] + invttail(e(df_r),0.025)*_se[postreftax_1224_22]]
						
						
						matrix res_`type' = [coeff2, 0, coeff1 \  -16, -15, -14, -13, -12, -11, -10, -9, -8, -7, -6, -5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22 \ upperb \ lowerb ]'
						svmat res_`type'
						scatter res_`type'1 res_`type'2, connect(l) yline(0) xline(-4) xline(0, lpattern(dash)) || rcap res_`type'3 res_`type'4 res_`type'2, scheme(s1color) xtitle("Months before/after tax increase") legend(label(1 "Price effect") label(2 "95% confidence interval")) xlab(-15 (5) 20) ylab(-0.06 (0.02) 0.02) yscale(range(-0.065 0.025))
						graph export "${graphs}\ESi_`file'_`pctype'_deltatax_`depvar'_`type'_1724_privabovemed`prmed'.pdf", replace
						matrix drop _all
						drop res_`type'*
					}
				}
		
				qui estimates drop *
			}
		}
		}
	
		
	}   // $byprivinv	
}

*** graph combine for joint graphs on professional investor shares
if $byprofinv_c == 1 {
	foreach file of global files {
		*graph combine  "${graphs}\ESi_`file'_popgallwp_deltatax_ln_preisqm_`file'_noctrl_ife_1724_professabovemed1.gph" "${graphs}\ESi_`file'_popgallwp_deltatax_ln_preisqm_`file'_noctrl_ife_1724_professabovemed0.gph" 
		graph combine "${graphs}\ESi_`file'_popgallwp_deltatax_ln_preisqm_`file'_noctrl_ife_1724_professabovemed1.gph"  "${graphs}\ESi_`file'_popgallwp_deltatax_ln_preisqm_`file'_noctrl_ife_1724_professabovemed0.gph"
		stop
	}
}





log close
