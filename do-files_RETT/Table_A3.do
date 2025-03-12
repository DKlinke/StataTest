import excel "F:\Neumeier_RETT\Replication_files\Data\external_data\Transaktionen_BuLa.xlsx", first clear
xtset bland Jahr

gen taxhike = 0
replace taxhike = 1 if bland == 1 & (Jahr == 2012 | Jahr == 2014)
replace taxhike = 1 if bland == 2 & (Jahr == 2009)   
replace taxhike = 1 if bland == 3 & (Jahr == 2011 | Jahr == 2014)   
replace taxhike = 1 if bland == 4 & (Jahr == 2011 | Jahr == 2014)   
replace taxhike = 1 if bland == 5 & (Jahr == 2011 | Jahr == 2015)   
replace taxhike = 1 if bland == 6 & (Jahr == 2013 | Jahr == 2014)   
replace taxhike = 1 if bland == 7 & (Jahr == 2012)   
replace taxhike = 1 if bland == 8 & (Jahr == 2011)   
replace taxhike = 1 if bland == 10 & (Jahr == 2011 | Jahr == 2012 | Jahr == 2013 | Jahr == 2015)   
replace taxhike = 1 if bland == 11 & (Jahr == 2007 | Jahr == 2012 | Jahr == 2014)   
replace taxhike = 1 if bland == 12 & (Jahr == 2011 | Jahr == 2015)   
replace taxhike = 1 if bland == 13 & (Jahr == 2012)   
replace taxhike = 1 if bland == 15 & (Jahr == 2010 | Jahr == 2012)   
replace taxhike = 1 if bland == 16 & (Jahr == 2011 | Jahr == 2017)   

gen f1_taxhike = F1.taxhike
gen l1_taxhike = L1.taxhike


gen log_transactions = log(transactions)


foreach depvar of varlist *transactions* {
	eststo `depvar': xtreg `depvar' f1_taxhike taxhike l1_taxhike i.Jahr, fe cluster(bland)
	eststo `depvar'_f: xtreg `depvar' f1_taxhike i.Jahr, fe cluster(bland)
	eststo `depvar'_c: xtreg `depvar' taxhike i.Jahr, fe cluster(bland)
	eststo `depvar'_l: xtreg `depvar' l1_taxhike i.Jahr, fe cluster(bland)
	eststo `depvar'_cf: xtreg `depvar' f1_taxhike taxhike i.Jahr, fe cluster(bland)
	eststo `depvar'_cl: xtreg `depvar' taxhike l1_taxhike i.Jahr, fe cluster(bland)
}

esttab log_transactions_f log_transactions_c log_transactions_l log_transactions using "G:\Forschung\Grunderwerbsteuer\JUrbE\log_transactions_consecutive.tex", replace drop(_cons *Jahr*) b(3) se(3) stats(r2_w N, fmt(3 0) labels("R-squared" "No. of Obs.")) coeflabel(f1_taxhike "tax hike in t+1" taxhike "tax hike in t" l1_taxhike "tax hike in t-1") nomtitles star(* 0.05 ** 0.01 *** 0.001) style(fixed) nogaps nonotes brackets compress lines varwidth(15) modelwidth(20)
