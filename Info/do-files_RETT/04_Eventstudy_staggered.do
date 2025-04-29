capture close all
capture log close
clear all
set maxvar 100000
set matsize 10000
log using "${logs}\log_03_Eventstudy_staggered_${today}.log", replace


	///////////////////////////////////////////////////////////////////
	*** PART 1: PREPARATION OF EVENT STUDY DATA FOR STACKED ESTIMATION
	//////////////////////////////////////////////////////////////////
			
global prereftax17 prereftax_1724_17 prereftax_1724_16 prereftax_1724_15 prereftax_1724_14 prereftax_1724_13 ///
 					prereftax_1724_12 prereftax_1724_11 prereftax_1724_10 prereftax_1724_9 prereftax_1724_8 prereftax_1724_7 prereftax_1724_6 prereftax_1724_5 prereftax_1724_3 prereftax_1724_2 prereftax_1724_1 					
global postreftax postreftax_1224_0 postreftax_1224_1 postreftax_1224_2 postreftax_1224_3 postreftax_1224_4 postreftax_1224_5 postreftax_1224_6 postreftax_1224_7 postreftax_1224_8 postreftax_1224_9 postreftax_1224_10 postreftax_1224_11 postreftax_1224_12 ///
				  postreftax_1224_13 postreftax_1224_14 postreftax_1224_15 postreftax_1224_16 postreftax_1224_17 postreftax_1224_18 postreftax_1224_19 postreftax_1224_20 postreftax_1224_21 postreftax_1224_22 postreftax_1224_23 		
				  
global files etwp ehp mfhp

if $stackprep ==1 {

foreach file of global files {

**
local count =1

***** stack treatments: per treatment timing: treatment group with same event date (+ no antedating events in 18 months) + control group with no events whatsoever in event period

use $prereftax17 $postreftax bula montaxinc* ersterpreis daysposted pricediff pricediff_pc buildaged ln_flaeche flaeche zimmeranzahl basement balcony parking kitchen garden baujahrd heatingtype centralheat fancy fancyequip quietloc bright ln_preisqm wmt* pricechpc jahr plz betrag preisqm kreistyp monlast popg popgallwp05 popgallwp95 letzterpreis kreis using "${data}/F_u_B/ifo_`file'_4q19_prep_3624.dta", clear

	egen sumtaxtot = rowtotal($prereftax17 $postreftax)
	egen sumtaxpre = rowtotal($prereftax17)
preserve

	* Change Berlin Jan 2007
	local datestart = ym(2007,1)-23
	local dateend = ym(2007,1)+24
		keep if (bula==11 | ((montaxinc1 < `datestart' | montaxinc1 >=`dateend' | montaxinc1==.) & (montaxinc2 < `datestart' | montaxinc2 >=`dateend' | montaxinc2==.) & (montaxinc3 < `datestart' | montaxinc3 >=`dateend' | montaxinc3==.) & (montaxinc4 < `datestart' | montaxinc4 >=`dateend' | montaxinc4==.) )) & monlast >=`datestart' & monlast < `dateend'
* 		keep if (bula==11 | ((montaxinc1 < ym(2007,1)-23 | montaxinc1 >= ym(2007,1)+24 | montaxinc1==.) & (montaxinc2 < ym(2007,1)-23 | montaxinc2 >= ym(2007,1)+24 | montaxinc2==.) & (montaxinc3 < ym(2007,1)-23 | montaxinc3 >= ym(2007,1)+24 | montaxinc3==.) & (montaxinc4 < ym(2007,1)-23 | montaxinc4 >= ym(2007,1)+24 | montaxinc4==.) ) & monlast >=ym(2007,1)-23 & monlast < ym(2007,1)+24 		
		gen countfe = `count'
		local count = `count'+1
		save "F:/Neumeier_RETT/Replication_files/Data/staggered/staggered24_20071_`file'.dta", replace

	restore
	preserve
	
	* Change Hamburg Jan 2009
	local datestart = ym(2009,1)-18
	local dateend = ym(2009,1)+24	
		keep if (bula==2 | ((montaxinc1 < `datestart' | montaxinc1 >=`dateend' | montaxinc1==.) & (montaxinc2 < `datestart' | montaxinc2 >=`dateend' | montaxinc2==.) & (montaxinc3 < `datestart' | montaxinc3 >=`dateend' | montaxinc3==.) & (montaxinc4 < `datestart' | montaxinc4 >=`dateend' | montaxinc4==.) )) & monlast >=`datestart' & monlast < `dateend'
		gen countfe = `count'
		local count = `count'+1
		save "F:/Neumeier_RETT/Replication_files/Data/staggered/staggered24_20091_`file'.dta", replace
		
	restore
	preserve
	
	* Change Saxony Anhalt Mar 2010
	local datestart = ym(2010,3)-18
	local dateend = ym(2010,3)+24
		keep if (bula==15 | ((montaxinc1 < `datestart' | montaxinc1 >=`dateend' | montaxinc1==.) & (montaxinc2 < `datestart' | montaxinc2 >=`dateend' | montaxinc2==.) & (montaxinc3 < `datestart' | montaxinc3 >=`dateend' | montaxinc3==.) & (montaxinc4 < `datestart' | montaxinc4 >=`dateend' | montaxinc4==.) )) & monlast >=`datestart' & monlast < `dateend'
		gen countfe = `count'
		local count = `count'+1
		save "F:/Neumeier_RETT/Replication_files/Data/staggered/staggered24_20103_`file'.dta", replace
				
	restore
	preserve

	* Change Brandenburg, Bremen, Lower Saxony, SL Jan 2011
	local datestart = ym(2011,1)-18
	local dateend = ym(2011,1)+24
		keep if (bula==12 | bula==4 | bula==3 | bula==10 |  ((montaxinc1 < `datestart' | montaxinc1 >=`dateend' | montaxinc1==.) & (montaxinc2 < `datestart' | montaxinc2 >=`dateend' | montaxinc2==.) & (montaxinc3 < `datestart' | montaxinc3 >=`dateend' | montaxinc3==.) & (montaxinc4 < `datestart' | montaxinc4 >=`dateend' | montaxinc4==.) )) & monlast >=`datestart' & monlast < `dateend'
		gen countfe = `count'
		local count = `count'+1
		save "F:/Neumeier_RETT/Replication_files/Data/staggered/staggered24_20111_`file'.dta", replace
						
	restore
	preserve
		
		
	* Change Thuringia Apr 2011
	local datestart = ym(2011,4)-18
	local dateend = ym(2011,4)+24	
		keep if (bula==16 | ((montaxinc1 < `datestart' | montaxinc1 >=`dateend' | montaxinc1==.) & (montaxinc2 < `datestart' | montaxinc2 >=`dateend' | montaxinc2==.) & (montaxinc3 < `datestart' | montaxinc3 >=`dateend' | montaxinc3==.) & (montaxinc4 < `datestart' | montaxinc4 >=`dateend' | montaxinc4==.) )) & monlast >=`datestart' & monlast < `dateend'
		gen countfe = `count'
		local count = `count'+1
		save "F:/Neumeier_RETT/Replication_files/Data/staggered/staggered24_20114_`file'.dta", replace
		
	restore
	preserve		
	
				
	* Change NRW Oct 2011
	local datestart = ym(2011,10)-18
	local dateend = ym(2011,10)+24	
		keep if (bula==5 | ((montaxinc1 < `datestart' | montaxinc1 >=`dateend' | montaxinc1==.) & (montaxinc2 < `datestart' | montaxinc2 >=`dateend' | montaxinc2==.) & (montaxinc3 < `datestart' | montaxinc3 >=`dateend' | montaxinc3==.) & (montaxinc4 < `datestart' | montaxinc4 >=`dateend' | montaxinc4==.) )) & monlast >=`datestart' & monlast < `dateend'
		gen countfe = `count'
		local count = `count'+1
		save "F:/Neumeier_RETT/Replication_files/Data/staggered/staggered24_201110_`file'.dta", replace
		
	restore
	preserve	

	* Change BW Nov 2011
	local datestart = ym(2011,11)-18
	local dateend = ym(2011,11)+24	
		keep if (bula==8 | ((montaxinc1 < `datestart' | montaxinc1 >=`dateend' | montaxinc1==.) & (montaxinc2 < `datestart' | montaxinc2 >=`dateend' | montaxinc2==.) & (montaxinc3 < `datestart' | montaxinc3 >=`dateend' | montaxinc3==.) & (montaxinc4 < `datestart' | montaxinc4 >=`dateend' | montaxinc4==.) )) & monlast >=`datestart' & monlast < `dateend'
		gen countfe = `count'
		local count = `count'+1
		save "F:/Neumeier_RETT/Replication_files/Data/staggered/staggered24_201111_`file'.dta", replace
		
	restore
	preserve		
		
	* Change SH Jan 2012
	local datestart = ym(2012,1)-18
	local dateend = ym(2012,1)+24	
		keep if (bula==1 | ((montaxinc1 < `datestart' | montaxinc1 >=`dateend' | montaxinc1==.) & (montaxinc2 < `datestart' | montaxinc2 >=`dateend' | montaxinc2==.) & (montaxinc3 < `datestart' | montaxinc3 >=`dateend' | montaxinc3==.) & (montaxinc4 < `datestart' | montaxinc4 >=`dateend' | montaxinc4==.) )) & monlast >=`datestart' & monlast < `dateend'
		gen countfe = `count'
		local count = `count'+1
		save "F:/Neumeier_RETT/Replication_files/Data/staggered/staggered24_20121_`file'.dta", replace
		
	restore
	preserve	
	
		* Change ST & RLP Mar 2012
	local datestart = ym(2012,3)-18
	local dateend = ym(2012,3)+24	
		keep if (bula==7 | bula==15 | ((montaxinc1 < `datestart' | montaxinc1 >=`dateend' | montaxinc1==.) & (montaxinc2 < `datestart' | montaxinc2 >=`dateend' | montaxinc2==.) & (montaxinc3 < `datestart' | montaxinc3 >=`dateend' | montaxinc3==.) & (montaxinc4 < `datestart' | montaxinc4 >=`dateend' | montaxinc4==.) )) & monlast >=`datestart' & monlast < `dateend'
		gen countfe = `count'
		local count = `count'+1
		save "F:/Neumeier_RETT/Replication_files/Data/staggered/staggered24_20123_`file'.dta", replace

	restore
	preserve
	
		* Change Berlin Apr 2012
	local datestart = ym(2012,4)-18
	local dateend = ym(2012,4)+24	
		keep if (bula==11 | ((montaxinc1 < `datestart' | montaxinc1 >=`dateend' | montaxinc1==.) & (montaxinc2 < `datestart' | montaxinc2 >=`dateend' | montaxinc2==.) & (montaxinc3 < `datestart' | montaxinc3 >=`dateend' | montaxinc3==.) & (montaxinc4 < `datestart' | montaxinc4 >=`dateend' | montaxinc4==.) )) & monlast >=`datestart' & monlast < `dateend'
		gen countfe = `count'
		local count = `count'+1
		save "F:/Neumeier_RETT/Replication_files/Data/staggered/staggered24_20124_`file'.dta", replace		
		
	restore
	preserve
	
		* Change MVP Jul 2012
	local datestart = ym(2012,7)-18
	local dateend = ym(2012,7)+24	
		keep if (bula==13 | ((montaxinc1 < `datestart' | montaxinc1 >=`dateend' | montaxinc1==.) & (montaxinc2 < `datestart' | montaxinc2 >=`dateend' | montaxinc2==.) & (montaxinc3 < `datestart' | montaxinc3 >=`dateend' | montaxinc3==.) & (montaxinc4 < `datestart' | montaxinc4 >=`dateend' | montaxinc4==.) )) & monlast >=`datestart' & monlast < `dateend'
		gen countfe = `count'
		local count = `count'+1
		save "F:/Neumeier_RETT/Replication_files/Data/staggered/staggered24_20127_`file'.dta", replace		
		
	restore
	preserve	
	
		* Change Hesse Jan 2013
	local datestart = ym(2013,1)-18
	local dateend = ym(2013,1)+24	
		keep if (bula==6 | ((montaxinc1 < `datestart' | montaxinc1 >=`dateend' | montaxinc1==.) & (montaxinc2 < `datestart' | montaxinc2 >=`dateend' | montaxinc2==.) & (montaxinc3 < `datestart' | montaxinc3 >=`dateend' | montaxinc3==.) & (montaxinc4 < `datestart' | montaxinc4 >=`dateend' | montaxinc4==.) )) & monlast >=`datestart' & monlast < `dateend'
		gen countfe = `count'
		local count = `count'+1
		save "F:/Neumeier_RETT/Replication_files/Data/staggered/staggered24_20131_`file'.dta", replace		
		
	restore
	preserve
	
		* Change Bremen, NI, SH Jan 2014
	local datestart = ym(2014,1)-18
	local dateend = ym(2014,1)+24	
		keep if ( bula==4 | bula==3 | bula==1 | ((montaxinc1 < `datestart' | montaxinc1 >=`dateend' | montaxinc1==.) & (montaxinc2 < `datestart' | montaxinc2 >=`dateend' | montaxinc2==.) & (montaxinc3 < `datestart' | montaxinc3 >=`dateend' | montaxinc3==.) & (montaxinc4 < `datestart' | montaxinc4 >=`dateend' | montaxinc4==.) )) & monlast >=`datestart' & monlast < `dateend'
		gen countfe = `count'
		local count = `count'+1
		*gen short = 1 if bula==11 // Berlin hat keine 2 Jahre vorweg
		save "F:/Neumeier_RETT/Replication_files/Data/staggered/staggered24_20141_`file'.dta", replace			
		
	restore
	preserve
	

	* Change SL & NRW Jan 2015
	local datestart = ym(2015,1)-18
	local dateend = ym(2015,1)+24	
		keep if (bula==10 | bula==5 | ((montaxinc1 < `datestart' | montaxinc1 >=`dateend' | montaxinc1==.) & (montaxinc2 < `datestart' | montaxinc2 >=`dateend' | montaxinc2==.) & (montaxinc3 < `datestart' | montaxinc3 >=`dateend' | montaxinc3==.) & (montaxinc4 < `datestart' | montaxinc4 >=`dateend' | montaxinc4==.) )) & monlast >=`datestart' & monlast < `dateend'
		gen countfe = `count'
		local count = `count'+1
		save "F:/Neumeier_RETT/Replication_files/Data/staggered/staggered24_20151_`file'.dta", replace		
		
	restore
	preserve
	
	* Change Brandenburg Jul 2015
	local datestart = ym(2015,7)-18
	local dateend = ym(2015,7)+24	
		keep if (bula==12 | ((montaxinc1 < `datestart' | montaxinc1 >=`dateend' | montaxinc1==.) & (montaxinc2 < `datestart' | montaxinc2 >=`dateend' | montaxinc2==.) & (montaxinc3 < `datestart' | montaxinc3 >=`dateend' | montaxinc3==.) & (montaxinc4 < `datestart' | montaxinc4 >=`dateend' | montaxinc4==.) )) & monlast >=`datestart' & monlast < `dateend'
		gen countfe = `count'
		local count = `count'+1
		save "F:/Neumeier_RETT/Replication_files/Data/staggered/staggered24_20157_`file'.dta", replace		
		
	restore
	preserve
	
	* Change Thuringia Jan 2017
	local datestart = ym(2017,1)-18
	local dateend = ym(2017,1)+24	
		keep if (bula==16 | ((montaxinc1 < `datestart' | montaxinc1 >=`dateend' | montaxinc1==.) & (montaxinc2 < `datestart' | montaxinc2 >=`dateend' | montaxinc2==.) & (montaxinc3 < `datestart' | montaxinc3 >=`dateend' | montaxinc3==.) & (montaxinc4 < `datestart' | montaxinc4 >=`dateend' | montaxinc4==.) )) & monlast >=`datestart' & monlast < `dateend'
		gen countfe = `count'
		local count = `count'+1
		save "F:/Neumeier_RETT/Replication_files/Data/staggered/staggered24_20171_`file'.dta", replace		
	restore	
	
	* combine different stacked events
		use "F:/Neumeier_RETT/Replication_files/Data/staggered/staggered24_20071_`file'.dta", clear
		append using "F:/Neumeier_RETT/Replication_files/Data/staggered/staggered24_20091_`file'.dta"
		append using "F:/Neumeier_RETT/Replication_files/Data/staggered/staggered24_20103_`file'.dta"
		append using "F:/Neumeier_RETT/Replication_files/Data/staggered/staggered24_20111_`file'.dta"
		append using "F:/Neumeier_RETT/Replication_files/Data/staggered/staggered24_20114_`file'.dta"
		append using "F:/Neumeier_RETT/Replication_files/Data/staggered/staggered24_201110_`file'.dta"
		append using "F:/Neumeier_RETT/Replication_files/Data/staggered/staggered24_201111_`file'.dta"
		append using "F:/Neumeier_RETT/Replication_files/Data/staggered/staggered24_20121_`file'.dta"
		append using "F:/Neumeier_RETT/Replication_files/Data/staggered/staggered24_20123_`file'.dta"
		append using "F:/Neumeier_RETT/Replication_files/Data/staggered/staggered24_20124_`file'.dta"
		append using "F:/Neumeier_RETT/Replication_files/Data/staggered/staggered24_20127_`file'.dta"
		append using "F:/Neumeier_RETT/Replication_files/Data/staggered/staggered24_20131_`file'.dta"
		append using "F:/Neumeier_RETT/Replication_files/Data/staggered/staggered24_20141_`file'.dta"
		append using "F:/Neumeier_RETT/Replication_files/Data/staggered/staggered24_20151_`file'.dta"
		append using "F:/Neumeier_RETT/Replication_files/Data/staggered/staggered24_20157_`file'.dta"
		append using "F:/Neumeier_RETT/Replication_files/Data/staggered/staggered24_20171_`file'.dta"
		save  "F:/Neumeier_RETT/Replication_files/Data/staggered/staggered_all24_`file'.dta", replace
		
	}	
}	
	
		
	///////////////////////////////
	*** PART 2: STACKED ESTIMATION
	///////////////////////////////
	
if ${FigureA3} == 1 {
	global graphinput all_noctrl_ife 
	use "F:/Neumeier_RETT/Replication_files/Data/staggered/staggered_all24_etwp.dta", clear
	gen housetype = "etwp"
	append using "F:/Neumeier_RETT/Replication_files/Data/staggered/staggered_all24_ehp.dta"
	replace housetype = "ehp" if housetype==""
	append using "F:/Neumeier_RETT/Replication_files/Data/staggered/staggered_all24_mfhp.dta"
	replace housetype = "ehp" if housetype==""	
	gen ehp = 0
	replace ehp = 1 if housetype == "ehp"
	gen etwp = 0
	replace etwp = 1 if housetype == "etwp"
	gen mfhp = 0
	replace mfhp = 1 if housetype == "mfhp"	
	encode housetype, gen(htype)
	
	
			* separate FE for every operation
		gen plz_countfe = plz*100 + countfe
		xtset plz_countfe
		
	
		foreach pctype in popgallwp {
			foreach depvar of varlist ln_preisqm {
				qui {
					reghdfe `depvar' $prereftax17 $postreftax ehp etwp mfhp if popg>= `pctype'05 & popg<=`pctype'95, absorb(i.monlast#i.kreistyp#i.countfe plz_countfe) vce(cluster plz_countfe)  
					estimates store `file'_noctrl_ife, title(Int. trends)
				}
				display "Event study, all distances, `depvar'"
				estout `file'*ctrl*, varwidth(30) cells(b(star fmt(3)) se(fmt(3)) p(par fmt(3))) starlevels(* 0.05 ** 0.01 *** 0.001) stats(r2 ar2_w N, labels("R^2" "R^2 within" N) fmt(3 0)) keep($prereftax17 $postreftax) style(fixed) label collabels(none) replace
				qui {
					foreach type in `file'_noctrl_ife  {
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
						graph export "${graphs}\ESi_`file'_`pctype'_deltatax_`depvar'_staggered24_1724_all_pfe.pdf", replace
						matrix drop _all
						drop res_`type'*
					}
				}
				qui estimates drop *
			}
		}
		
	
	}

	

