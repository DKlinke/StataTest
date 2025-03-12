********************************************************************************
* Numbers in the text 
********************************************************************************

********************************************************************************
* Page 5, FN 8
* "... our analysis could only exploit 236 firm-year observations
* (0.7% of all observations) that face a tax drop ..."
********************************************************************************

* include tax drops
global sample = 2

* prepare local business tax data
do "${code}\01_prep"

* prepare and match firm level data
do "${code}\02_prep"

* sample adjustments and further preparation
do "${code}\03_prep"

* show number of tax drops
tab taxdrop //0.7%

* prepare regular sample again

* exclude tax drops
global sample = 1

* prepare local business tax data
do "${code}\01_prep"

* prepare and match firm level data
do "${code}\02_prep"

* sample adjustments and further preparation
do "${code}\03_prep"

********************************************************************************
* Page 7
* "... approximately 7 percent of firms are exposed to a tax hike each year."
********************************************************************************

* use values from Table 1 (Full Sample, 4th and 6th column)
dis 2627 / (32683 + 2627) // 7%

********************************************************************************
* Page 9 (also in Appendix Page 14)
* "Our final sample consists of 35310 firm-year observations ...
* "that are spread across 1,192 municiplaities ..."
********************************************************************************
use ${datapath}\final_data, replace

distinct ao_gem_2017 year

********************************************************************************
* Page 9
* "... firms report zero investment in only 0.7% of all observations"
********************************************************************************

* calculate share of 0 revision ratio (plans != 0 and realizations == 0)
gen z_diff = (diff == 0)
tab z_diff // only 0.7% revisions to zero

********************************************************************************
* Page 21/22
* average tax rate and average effective tax rates
********************************************************************************

* average tax rate
sum taxrate  // 16.79%

* average effective tax rate (assuming discount rate of 7%)
sum tax_eff7  // 3.82%

* average effective tax rate (assuming time-varying discount rate)
sum tax_eff11  // 2.9%

********************************************************************************
* Back-of-the-Envelope Calculation
********************************************************************************
use ${datapath}\final_data, replace

* median revenues (also documented in Table B.2)
sum rev_k ,d // 45 m 

* median investment
sum reali_inv_k ,d // 1.4 m

* investment-revenue ratio:
dis 1.4 / 45 // 3.1%

* profit margin: use matched balance sheet data
use "F:\Bitte_Matchen\bilanzdata_no_totasset_miss_mitIdnum_nra.dta" , clear

destring nra , gen(plantnum) force
drop _merge

save "${datapath}\bilanzdata_new.dta"  , replace

use "${datapath}\final_data" ,clear
drop _merge

merge m:m plantnum year using ${datapath}\bilanzdata_new.dta

keep if _merge == 3

duplicates tag plantnum year , gen(a)
drop if a > 0

* profit margin
gen cf_rev = cash_flow / revenues	 
sum cf_rev , d // 4.4%

use ${datapath}\final_data, replace

* calculation:
* agg. profits: median revenue * median profit margin (from orbis)
dis 45 * 0.044 // 1.98 m

* investment / revenue median 
dis 45 * 0.031 // 1.4 m
* 1.4 mio

* 1 p.p. tax hike -> Revenue effect:
dis 1980000 * 0.01 // 19.800

* semi-elasticity: 3 -> investment decrease:
dis 1400000 * 0.03 // 42.000

* investment lost for each additional Euro of tax revenue
dis 42000 / 19800

* forgone future profits
dis 42000 * 0.022 // 924
dis 42000 * 0.22 // 9240

* average tax rate
use "$datapath\Gemeindedaten_ags2017_prepared.dta", replace

sum taxrate if year < 2008 ,d  // mean 15%
sum taxrate if year >= 2008 ,d  // mean 15%

* additional tax revenue loss
dis 924 * 0.15 // 139
dis 9240 * 0.15 // 1386

* add behavioral response to change in tax revenue
dis 42000 / (19800 - 139) // 2.14
dis 42000 / (19800 - 1386) // 2.28

* MVPF
dis 19800 / (19800 - 139) // 1.01
dis 19800 / (19800 - 1386) // 1.08

********************************************************************************
* Appendix
********************************************************************************

********************************************************************************
* Page 2
* tax rates before / after 2008
********************************************************************************

use "$datapath\Gemeindedaten_ags2017_prepared.dta", replace

sum taxrate if year < 2008 ,d  // mean 16%
sum taxrate if year >= 2008 ,d  // mean 12,25%

********************************************************************************
* Page 5
* "The median municipality experienced three tax hikes, while taxes were never
* increased in only 7% of municipalities"
* "The average duration between two tax hikes in our sample is 14-6 year"
********************************************************************************

use "${datapath}\Gemeindedaten_ags2017_halfprepared_firm_sample.dta", replace

preserve
gen count = 1
collapse (sum) taxhike (sum) n = count ,by(ao_gem_2017)
gen duration = n / taxhike
sum  taxhike , d // median number of hikes: 3
tab taxhike //  share of never-hiked: 6.3%
sum duration , d // median 13 years, mean 14.6 years
restore

********************************************************************************
* Page 10
* "approx. 1,500 firms over time"
********************************************************************************

* use data from Table B.1
use ${datapath}\linked_it_gemeindedaten_prepared, replace
keep if year == 2018
dis _N // 1474

