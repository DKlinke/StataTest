
********************************************************************************
* Figure A.1: Timing of Tax Hike News
********************************************************************************
use "${datapath}\local_newspaper.dta", replace

tw (line count date_m if date_m >= ym(2009,1), color(navy) lw(*1.5)) (line count_broad date_m if date_m >= ym(2009,1), color(maroon) lw(*1.5))  ,  xlabel(599(12)731, angle(30)) xline(599(12)731) scheme(s1mono) xsize(16) ysize(9) xtitle("") ytitle("Number of Newspaper Articles") legend(order(1 "Broad Definition" 2 "Narrow Definition"))
graph export "${outputpath}\fig_a1.pdf" , replace 

********************************************************************************
* Figure C.5: Collectively Bargained Wage Growth in Manufacturing
********************************************************************************
use "${datapath}\union_wages.dta", replace

tw (area up yq if Jahr >= 2000.5 & Jahr <= 2003.5 , lw(0) fcolor(black) fi(*.2) ) ///
 (area up yq if Jahr >= 2007.5 & Jahr <= 2009.5  , lw(0) fcolor(black) fi(*.2)) ///
 (line VerarbeitendesGewerbe yq , ytitle("Wage Changes (YoY in %)") xtitle("") color(navy)) if Jahr > 1995 , legend(off) ylabel(0(2)7) xsize(16) ysize(9) xlabel(144(8)244)
graph export "${outputpath}\fig_c5.pdf" , replace 

********************************************************************************
* Figure E.1: Time Series of Average Interest Rate on Loans for Firms
********************************************************************************
use "${datapath}\final_buba_zins.dta" , replace

tw connected zins year , xline(2003) xline(1996) color(navy) xtitle("") ytitle("interest rate in %")
graph export "${outputpath}\fig_e1.pdf" , replace 

sum zins if year < 2019 ,d


********************************************************************************
* Figure E.2: Present Discounted Value of Depreciation: 7% vs Time-Varying Interest Rate
********************************************************************************
use "${datapath}\mb_shares_zvals.dta", replace

tw  (connected z_mach7 year, color(navy)) (connected z_mach11 year, color(navy) lp(dash))  (connected z_build7 year, color(maroon)) (connected z_build11 year, color(maroon) lp(dash)) , ylabel(0(0.1)1) legend(order(1 "Machinery" 3 "Buildings")) xtitle("") ytitle("PDV Depreciation") xsize(16) ysize(9)
graph export "${outputpath}\fig_e2.pdf", replace 
