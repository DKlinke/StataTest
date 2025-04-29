********************************************************************************
* import prepared municipality level data
use "${datapath}\Gemeindedaten_ags2017_prepared.dta", replace

*set missing information for tax hike to zero for map_data
recode taxhike (.=0)

*1990-2018
keep if inrange(year, 1980, 2018)

*compute statistics of interest on collapse to cross section
collapse (mean) taxrate (sum) taxhike (firstnm) name2018 merged_muni state, by(ao_gem_2017)
	
*create west dummy
gen west = state <= 10
keep if west==1

*set values to missing for merged munis
foreach var of varlist taxrate taxhike  {
    replace `var'=. if merged_muni==1
}
*save
save "${datapath}\gemeindedata_for_maps_1980_2018.dta", replace

*transformation gemeinden
shp2dta using "${datapath}\Gemeindegrenzen_2017_mit_Einwohnerzahl-shp\Gemeindegrenzen_2017_mit_Einwohnerzahl", data("${datapath}\spatial_data")  coor("${datapath}\spatial_coordinates") replace

*data modification 1980-2018
use "${datapath}\spatial_data.dta", clear
rename *, lower
destring ags, gen(ao_gem_2017)
merge m:1 ao_gem_2017 using "${datapath}\gemeindedata_for_maps_1980_2018.dta"
drop if _merge==2	// these are the merged munis
drop _merge
save "${datapath}\spatial_data_1980_2018.dta", replace

* Create shapefiles with state borders
use "${datapath}\spatial_data.dta", clear
rename *, lower
mergepoly _ID using "${datapath}\spatial_coordinates.dta", coord("${datapath}\spatial_coordinates_state.dta") ///
	by(sn_l) replace

*******************************************************************************
* Figure 1: Variation in Local Business Tax Rates (1980-2018)
*******************************************************************************

* Merge cross-sectional dataset with content to be displayed to spatial_data.dta
use "${datapath}\spatial_data_1980_2018.dta", clear

* Panel A: Tax Rates
sum taxrate, d
format taxrate %9.0f
spmap taxrate using "${datapath}\spatial_coordinates.dta", id(_ID)  ///
	fcolor(Blues2) ocolor(none ..) ndocolor(none ..) ndfcolor(gs14 ..) ///                       
	clmethod(custom) clbreaks(12 14 15 17 19 34)  ///      
	legend(symy(*1.2) symx(*1.2) size(*1.2) position(6) rows(1) ring(1) bmargin(small) ///
	region(lcolor(black)) label(1 "Dropped")) ///
	legorder(lohi) legstyle(1) ///
	polygon(data("${datapath}\spatial_coordinates_state.dta") fcolor(none) ocolor(black) osize(medthin))
graph export "${outputpath}\fig_1_a.png", replace

* Panel B: Tax Hikes
sum taxhike
format taxhike %9.0f
spmap taxhike using "${datapath}\spatial_coordinates.dta", id(_ID)  ///
	fcolor(Blues2) ocolor(none ..) ndocolor(none ..) ndfcolor(gs14 ..) ///                       
	clmethod(custom) clbreaks(-1 0 1 3 5 14)  ///    
	legend(symy(*1.2) symx(*1.2) size(*1.2) position(6) rows(1) ring(1) bmargin(small) ///
	region(lcolor(black)) label(1 "Dropped") label(2 "0") label(3 "1") ///
	label(4 "2-3") label(5 "4-5") label(6 "6+"))    ///
	legorder(lohi) legstyle(1) /// 
	polygon(data("${datapath}\spatial_coordinates_state.dta") fcolor(none) ocolor(black) osize(medthin))
graph export "${outputpath}\fig_1_b.png", replace



