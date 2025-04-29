capture close all
capture log close
clear all

*** Global for property types
global files etwp ehp mfhp

*** Spillover-Analysis: Maximum distance to the nearest inner-German state borders:
local maxdist = 10


////////////////////////////////////////////////
*** PART 1: DATA PREPARATION
////////////////////////////////////////////////

foreach file of global files {
	use ${data}/F_u_B/ifo_`file'_2019.dta, clear
	destring plz ags, replace	// variables are long in 2015-2018 data
	gen dayfirst = erstesangebot
	format dayfirst %td
	gen daylast = letztesangebot
	format daylast %td
	drop erstesangebot letztesangebot	// will be set missing anyway as these variables are long in this dataset, but long in 2015-2018 data
	save ${data}/F_u_B/ifo_`file'_2019_prep.dta, replace

	use ${data}/F_u_B/ifo_`file'_4q18.dta, clear
	gen dayfirst = date(erstesangebot, "MDY")
	format dayfirst %td
	gen daylast = date(letztesangebot, "MDY")
	format daylast %td
	drop erstesangebot letztesangebot	// will be set missing anyway as these variables are string in this dataset, but string in 2019 dataset
	
	append using ${data}/F_u_B/ifo_`file'_2019_prep.dta
	
	merge 1:1 idnr using ${data}/F_u_B/ifo_`file'_2005-2018_vermietet.dta, update
	drop if _merge == 2 // "using only (2)"
	drop _merge
	
	
	*** Merge with Wohnungsmarkttypen data 
	merge m:1 ags using ${data}/external_data/wohnungsmarkttypen.dta, keepusing(wmt wmt_bez)
	drop if _merge == 2
	drop _merge
	recode wmt (1 2 = 1) (3 = 2) (4 5  = 3), gen(wmt_agg)
	
	
	erase ${data}/F_u_B/ifo_`file'_2019_prep.dta

	***************************
	*** Region and Time IDs ***
	***************************
	*** Region IDs 
	tostring ags, gen(bula)
	gen agslength = length(bula)
	gen kreis = substr(bula,1,5) if agslength==8  // indicators for kreise incl. state (for later merging of regional data)
	replace kreis = substr(bula,1,4) if agslength==7
	destring kreis, replace
	replace bula = substr(bula,1,2) if agslength==8
	replace bula = substr(bula,1,1) if agslength==7
	destring bula, replace
	label var bula "State ID"
	label define bula 1 "SH" 2 "HH" 3 "NI" 4 "HB" 5 "NW" 6 "HE" 7 "RP" 8 "BW" 9 "BY" 10 "SL" 11 "BE" 12 "BB" 13 "MV" 14 "SN" 15 "ST" 16 "TH"
	label values bula bula
	label var kreis "County ID"
	label var ags "Municipality ID"
	label var dayfirst "First day of posting"
	label var daylast "Last day of posting"
	drop agslength

	*** Time variables
	gen daysposted = daylast - dayfirst + 1
	label var daysposted "Number of days property was posted"
	gen monlast = mofd(daylast)
	label var monlast "Month of last posting"
	format monlast %tm
	gen jahr = yofd(daylast)
	label var jahr "Year of posting"
	format jahr %ty

	gen daylast2 = daylast^2
	gen daylast3 = daylast^3
	gen monlast2 = monlast^2
	gen monlast3 = monlast^3

	*******************
	*** Tax Reforms ***
	*******************
	*** Tax rates and dates of tax rate changes
	gen taxrate = 0.035
	label var taxrate "Current RETT rate"

	foreach num of numlist 1 / 4 {
		gen datetaxinc`num' = .
		label var datetaxinc`num' "Date of tax rate hike no. `num'"
	}
		
	* Schleswig-Holstein
	replace datetaxinc1 = mdy(1,1,2012) if bula == 1
	replace taxrate = 0.05 if daylast >= datetaxinc1 & bula==1 
	replace datetaxinc2 = mdy(1,1,2014) if bula == 1 
	replace taxrate = 0.065 if daylast >= datetaxinc2 & bula==1 
	
	* Hamburg
	replace datetaxinc1 = mdy(1,1,2009) if bula == 2
	replace taxrate = 0.045 if daylast >= datetaxinc1 & bula==2 
	
	* Niedersachsen
	replace datetaxinc1 = mdy(1,1,2011) if bula == 3 
	replace taxrate = 0.045 if daylast >= datetaxinc1 & bula==3 
	replace datetaxinc2 = mdy(1,1,2014) if bula == 3 
	replace taxrate = 0.05 if daylast >= datetaxinc2 & bula==3 

	* Bremen
	replace datetaxinc1 = mdy(1,1,2011) if bula == 4
	replace taxrate = 0.045 if daylast >= datetaxinc1 & bula==4 
	replace datetaxinc2 = mdy(1,1,2014) if bula == 4 
	replace taxrate = 0.05 if daylast >= datetaxinc2 & bula==4 

	* Nordrhein-Westfalen
	replace datetaxinc1 = mdy(10,1,2011) if bula == 5
	replace taxrate = 0.05 if daylast >= datetaxinc1 & bula==5 
	replace datetaxinc2 = mdy(1,1,2015) if bula == 5 
	replace taxrate = 0.065 if daylast >= datetaxinc2 & bula==5 

	* Hessen
	replace datetaxinc1 = mdy(1,1,2013) if bula == 6
	replace taxrate = 0.05 if daylast >= datetaxinc1 & bula==6 
	replace datetaxinc2 = mdy(8,1,2014) if bula == 6 
	replace taxrate = 0.06 if daylast >= datetaxinc2 & bula==6 

	* Rheinland-Pfalz
	replace datetaxinc1 = mdy(3,1,2012) if bula == 7
	replace taxrate = 0.05 if daylast >= datetaxinc1 & bula==7 

	* Baden-Württemberg
	replace datetaxinc1 = mdy(11,5,2011) if bula == 8 
	replace taxrate = 0.05 if daylast >= datetaxinc1 & bula==8 

	* Saarland
	replace datetaxinc1 = mdy(1,1,2011) if bula == 10
	replace taxrate = 0.04 if daylast >= datetaxinc1 & bula==10 
	replace datetaxinc2 = mdy(1,1,2012) if bula == 10 
	replace taxrate = 0.045 if daylast >= datetaxinc2 & bula==10 
	replace datetaxinc3 = mdy(1,1,2013) if bula == 10 
	replace taxrate = 0.055 if daylast >= datetaxinc3 & bula==10 
	replace datetaxinc4 = mdy(1,1,2015) if bula == 10 
	replace taxrate = 0.065 if daylast >= datetaxinc4 & bula==10

	* Berlin
	replace datetaxinc1 = mdy(1,1,2007) if bula == 11
	replace taxrate = 0.045 if daylast >= datetaxinc1 & bula==11 
	replace datetaxinc2 = mdy(4,1,2012) if bula == 11 
	replace taxrate = 0.05 if daylast >= datetaxinc2 & bula==11 
	replace datetaxinc3 = mdy(1,1,2014) if bula == 11
	replace taxrate = 0.06 if daylast >= datetaxinc3 & bula==11 

	* Brandenburg
	replace datetaxinc1 = mdy(1,1,2011) if bula == 12
	replace taxrate = 0.05 if daylast >= datetaxinc1 & bula==12 
	replace datetaxinc2 = mdy(7,1,2015) if bula == 12 
	replace taxrate = 0.065 if daylast >= datetaxinc2 & bula==12 

	* Mecklenburg-Vorpommern
	replace datetaxinc1 = mdy(7,1,2012) if bula == 13
	replace taxrate = 0.05 if daylast >= datetaxinc1 & bula==13 

	* Sachsen-Anhalt
	replace datetaxinc1 = mdy(3,2,2010) if bula == 15
	replace taxrate = 0.045 if daylast >= datetaxinc1 & bula==15 
	replace datetaxinc2 = mdy(3,1,2012) if bula == 15 
	replace taxrate = 0.05 if daylast >= datetaxinc2 & bula==15 

	* Thüringen
	replace datetaxinc1 = mdy(4,7,2011) if bula == 16
	replace taxrate = 0.05 if daylast >= datetaxinc1 & bula==16 
	replace datetaxinc2 = mdy(1,1,2017) if bula == 16 
	replace taxrate = 0.065 if daylast >= datetaxinc2 & bula==16 

	format datetaxinc* %td

	foreach num of numlist 1/4 {
		gen montaxinc`num'    = mofd(datetaxinc`num')
		label var montaxinc`num'    "Month of RETT rate hike no. `num'"
		format montaxinc`num' %tm	
	}

	
	*** Construct variables that indicate the size of RETT rate hikes
	bysort bula: egen ratetaxinc1_ = mean(taxrate) if daylast >= datetaxinc1 & daylast < datetaxinc2
	bysort bula: egen ratetaxinc2_ = mean(taxrate) if daylast >= datetaxinc2 & daylast < datetaxinc3
	bysort bula: egen ratetaxinc3_ = mean(taxrate) if daylast >= datetaxinc3 & daylast < datetaxinc4
	bysort bula: egen ratetaxinc4_ = mean(taxrate) if daylast >= datetaxinc4 
	
	foreach num of numlist 1/4 {
		bysort bula: egen ratetaxinc`num' = mean(ratetaxinc`num'_)
		drop ratetaxinc`num'_
	}
	
	gen ratetaxdiff1 = ratetaxinc1 - 0.035
	label var ratetaxdiff1 "Size of RETT rate hike no. 1"
	gen ratetaxdiff2 = ratetaxinc2 - ratetaxinc1
	label var ratetaxdiff2 "Size of RETT rate hike no. 2"
	gen ratetaxdiff3 = ratetaxinc3 - ratetaxinc2
	label var ratetaxdiff3 "Size of RETT rate hike no. 3"
	gen ratetaxdiff4 = ratetaxinc4 - ratetaxinc3
	label var ratetaxdiff4 "Size of RETT rate hike no. 4"

	
	*** Construct variables that indicate the number of days between two RETT rate hikes
	gen timesincechange = .
	label var timesincechange "Number of days since last RETT rate hike"
	gen timetochange = .
	label var timetochange "Number of days until next RETT rate hike"

	foreach num of numlist 1/4 {
		replace timesincechange = daylast - datetaxinc`num' if daylast >= datetaxinc`num'
		replace timetochange = datetaxinc`num' - daylast if daylast < datetaxinc`num'
	}


	*** Construct dummies indicating maximum number of months until/since next/last RETT rate hike
	foreach num of numlist 1/6 {
		gen postref`num'm = (timesincechange != . & timesincechange <= 30.5*`num')
		label var postref`num'm "RETT rate hike occured within the past `num' months"
		gen preref`num'm = (timetochange != . & timetochange <= 30.5*`num')
		label var preref`num'm "RETT rate hike will occur within the next `num' months"
	}
	
	*** Announcement dates (day of first legal draft)
	foreach num of numlist 1 / 4 {
		gen datelawdraft`num' = .
		label var datelawdraft`num' "Announcement date of tax hike no. `num'"
	}
		
	* Schleswig-Holstein
	replace datelawdraft1 = mdy(8,23,2010) if bula == 1
	replace datelawdraft2 = mdy(7,26,2013) if bula == 1 

	* Hamburg
	replace datelawdraft1 = mdy(10,14,2008) if bula == 2

	* Niedersachsen
	replace datelawdraft1 = mdy(8,31,2010) if bula == 3
	replace datelawdraft2 = mdy(9,17,2013) if bula == 3 

	* Bremen
	replace datelawdraft1 = mdy(6,22,2010) if bula == 4
	replace datelawdraft2 = mdy(7,9,2013) if bula == 4 

	* Nordrhein-Westfalen
	replace datelawdraft1 = mdy(5,10,2011) if bula == 5
	replace datelawdraft2 = mdy(10,28,2014) if bula == 5 

	* Hessen
	replace datelawdraft1 = mdy(9,25,2012) if bula == 6
	replace datelawdraft2 = mdy(5,13,2014) if bula == 6 

	* Rheinland-Pfalz
	replace datelawdraft1 = mdy(11,23,2011) if bula == 7

	* Baden-Württemberg
	replace datelawdraft1 = mdy(9,13,2011) if bula == 8

	* Saarland
	replace datelawdraft1 = mdy(10,19,2010) if bula == 10
	replace datelawdraft2 = mdy(10,18,2011) if bula == 10 
	replace datelawdraft3 = mdy(10,8,2012) if bula == 10 
	replace datelawdraft4 = mdy(10,7,2014) if bula == 10 

	* Berlin
	replace datelawdraft1 = mdy(11,7,2006) if bula == 11
	replace datelawdraft2 = mdy(1,18,2012) if bula == 11 
	replace datelawdraft3 = mdy(10,10,2013) if bula == 11

	* Brandenburg
	replace datelawdraft1 = mdy(9,13,2010) if bula == 12
	replace datelawdraft2 = mdy(3,4,2015) if bula == 12 

	* Mecklenburg-Vorpommern
	replace datelawdraft1 = mdy(2,14,2012) if bula == 13

	* Sachsen-Anhalt
	replace datelawdraft1 = mdy(9,30,2009) if bula == 15
	replace datelawdraft2 = mdy(9,28,2011) if bula == 15 

	* Thüringen
	replace datelawdraft1 = mdy(1,6,2011) if bula == 16
	replace datelawdraft2 = mdy(9,23,2015) if bula == 16 

	format datelawdraft* %td
	
	foreach num of numlist 1/4 {
		gen daysdrafttolaw`num' = datetaxinc`num' - datelawdraft`num'
		label var daysdrafttolaw`num' "Number of days between law draft and RETT hike no `num'"
		gen monlawdraft`num' = mofd(datelawdraft`num')
		label var monlawdraft`num' "Month of draft bill for RETT rate hike no. `num'"
		format monlawdraft`num' %tm
	}
	
	*************************
	*** Control Variables ***
	*************************
	*** Compute difference between first and last offering price
	gen pricediff = letzterpreis - ersterpreis
	label var pricediff "Absolute change in offering price between the first and last day of posting"
	gen pricediff_pc = pricediff/ ersterpreis
	label var pricediff_pc "Relative change in offering price between the first and last day of posting"

	
	*** Property characteristics
	* Renovation status
	gen renovation = 1 if am0503 == 1 // Erstbezug
	replace renovation = 2 if am1902 == 1 // saniert (Erstebezüge nach Sanierung haben hier Wert 2)
	replace renovation = 3 if am2001 == 1 // teilmodernisiert (Erstebezüge nach Teilmodernisierung haben hier Wert 3)
	replace renovation = 4 if renovation == . // unklar/keine Angabe
	replace renovation = 5 if am1801==1 | am1903==1 // renovierungs-/sanierungsbedürftig
	label var renovation "Renovation status"
	label define renovation 1 "First occupancy" 2 "Renovated" 3 "Modernized" 4 "Unclear/none" 5 "In need of renovation"
	label values renovation renovation

	* Basement
	gen basement = (am1102==1 | (am1103==1 & am1104==0) | am2203==1 | am2301==1)
	label var basement "Equipped with basement"
	
	* Heating
	gen heatingtype = (am0502==1 | am1401==1) // Elektroheizung inkl. Nachtspeicher
	replace heatingtype = 2 if am0705==1 // Gasheizung
	replace heatingtype = 3 if am1501==1 // Ofenheizung
	replace heatingtype = 4 if am1503==1 // Ölzentralheizung
	replace heatingtype = 5 if am0502+am0705+am1501+am1503>1 // mehrere
	label var heatingtype "Heating type"
	label define heatingtype 0 "n/a" 1 "Electric" 2 "Gas" 3 "Furnace" 4 "Oil" 5 "Multiple"
	label values heatingtype heatingtype

	gen centralheat = (am0504==1) // Etagenheizung
	replace centralheat = 2 if am2602 == 1 | am1503 == 1 // Zentralheizung
	label var centralheat "Central heating"
	label define centralheat 0 "n/a" 1 "Floor" 2 "Central"
	label values centralheat centralheat

	* Balcony, terrace, conservatory, courtyard
	gen balcony = max(am0201,am0902,am2002,am2303)
	label var balcony "Equipped with balcony, terrace, conservatory, or courtyard"
	
	* fancy (exklusiv, Luxus, repräsentativ, Villa)
	gen fancy = max(am0505,am1203,am1802,am2202)
	label var fancy "Exclusive/luxury equipment or villa"

	* fancy equipment (pool, whirlpool, sauna)
	gen fancyequip = max(am1904,am1905,am2302)
	label var fancyequip "Equipped with pool, whirlpool, or sauna"

	* parking lot/garage
	gen parking = max(am0702,am0703,am1906)
	label var parking "Parking lot or garage available"

	* preparation of further variables
	rename am0501 kitchen
	label var kitchen "Equipped with kitchen"
	rename am0704 garden
	label var garden "Equipped with garden"
	rename am2101 publictrans // n/a for apartments
	label var publictrans "Public transportation nearby"
	rename am1803 quietloc
	label var quietloc "Quiet location"
	rename am0801 bright
	label var bright "Bright rooms"

	gen ln_betrag = ln(betrag)
	label var ln_betrag "log of F+B transaction price per square meter" 
	
	gen preisqm = letzterpreis/flaeche
	label var preisqm "Property price per sqm"
	gen ln_preisqm = ln(letzterpreis/flaeche)
	label var ln_preisqm "log of property price per sqm"

	gen ln_flaeche = ln(flaeche)
	label var ln_flaeche "log of floor space in sqm"
	gen flaeche2 = flaeche^2
	label var flaeche2 "Floor space squared"
	gen flaeche3 = flaeche^3
	label var flaeche3 "Floor space ^3"
	
	replace baujahr = . if baujahr == 0
	label var baujahr "Construction year"
	gen baujahr2 = baujahr^2
	label var baujahr2 "Construction year squared"
	gen baujahr3 = baujahr^3
	label var baujahr3 "Construction year ^3"

	if "`file'"!="all" {
		gen housetype = "`file'"
		label var housetype "Property type"
	}
	tab housetype, gen(housetype_)

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

	gen buildage = yofd(daylast) - baujahr
	label var buildage "Age of property"
	gen buildaged = (buildage<=0)
	label var buildaged "Age of property (ordinal indicator)"
	replace buildaged = 2 if buildage > 0 & buildage<=5
	replace buildaged = 3 if buildage > 5 & buildage<=10
	replace buildaged = 4 if buildage > 10 & buildage<=15
	replace buildaged = 5 if buildage > 15 & buildage<=20
	replace buildaged = 6 if buildage > 20 & buildage<=25
	replace buildaged = 7 if buildage > 25 & buildage<=30
	replace buildaged = 8 if buildage > 30 & buildage<=45
	replace buildaged = 9 if buildage > 45 & buildage<=50
	replace buildaged = 10 if buildage > 50 & buildage<=60
	replace buildaged = 11 if buildage > 60 & buildage<=70
	replace buildaged = 12 if buildage > 70 & buildage<=80
	replace buildaged = 13 if buildage > 80 & buildage<=90
	replace buildaged = 14 if buildage > 90 & buildage<=100
	replace buildaged = 15 if buildage > 100 & buildage<=120
	replace buildaged = 16 if buildage > 120 & buildage<=150
	replace buildaged = 17 if buildage > 150 & buildage!=.
	replace buildaged = 18 if buildage==.

	* New building
	gen newbuild = ((ym(baujahr,1) >= monlast & baujahr!=.) | renovation == 1) // Construction year in the future or Erstbezug
	label var newbuild "Property in construction"

	* Change in asking price
	gen pricechpc = (ersterpreis-letzterpreis)/ersterpreis*100

	* Dummy for 7 biggest cities
	gen top7 =(ags==11000000) // Berlin
	replace top7 = 1 if ags==05111000 // Düsseldorf
	replace top7 = 1 if ags==06412000 // Frankfurt
	replace top7 = 1 if ags==02000000 // Hamburg
	replace top7 = 1 if ags==05315000 // Köln
	replace top7 = 1 if ags==09162000 // München
	replace top7 = 1 if ags==08111000 // Stuttgart

	* Source of posting
	split quellenname, p(,) gen(quelle)

	gen is24 = 0
	gen webportal = 0
	label var is24 "Property listed on ImmoScout24"
	label var webportal "Property listed on major web portal"

	foreach num of numlist 1(1)10 {
		replace is24 = 1 if quelle`num' == "IS24"
		replace webportal = 1 if quelle`num' == "1A" | quelle`num' == "IPool" | quelle`num' == "INet" | quelle`num' == "IS24" | quelle`num' == "IWelt" 
	}
	

	////////////////////////////////////////////////
	*** PART 2: MERGE WITH OTHER DATASETS
	////////////////////////////////////////////////
	*** Merge with Siedlungsstruktur data 
	merge m:1 kreis using ${data}/external_data/Siedlungsstruktur2006_prep.dta
	drop _merge
	replace kreistyp = 5-kreistyp // appropriate order
	label define kreistyp 1 "dünn besiedelter ländlicher Kreis" 2 "ländlicher Kreis mit Verdichtungsansätzen" 3 "städtischer Kreis" 4 "kreisfreie Großstadt"
	label values kreistyp kreistyp
	
	*** Merge with distances to next border
	merge m:1 plz using ${data}/external_data/PLZ_mindist_border_allDE2.dta, keepusing(mindist*)
	drop if _merge==2
	drop _merge

	*** Merge with population growth
	merge m:1 ags using ${data}/external_data/Bevoelkerung_growth_prep.dta, keepusing(popg*)
	drop if _merge==2
	drop _merge

	*** Merge with state-level debt per capita
	merge m:1 bula jahr using ${data}/external_data/schuldenstaende_percap_prep.dta
	drop if _merge==2
	drop _merge
	gen ln_debtpc = ln(debtpc)

	*** Merge with regional variables (unemployment rate, GDP, etc.)
	merge m:1 kreis jahr using "${data}/external_data/arbeitslos_bip_einkommen_1992-2018_prep.dta", keepusing(alq verf_eink_einw bip einwohner)
	drop if _merge==2
	drop _merge
	gen ln_verf_eink_einw = ln(verf_eink_einw)
	gen ln_bip = ln(bip)
	gen ln_pop = ln(einwohner)
	drop einwohner

	*** Merge with housing market data
	merge m:1 ags using "${data}/external_data/Munidata.dta", keepusing(build* flat* rooms* ew_2011 *share)
	drop if _merge==2
	drop _merge

	
	xtset plz 


	////////////////////////////////////////////////
	*** PART 3: EVENT STUDY INDICATORS
	////////////////////////////////////////////////

	************************************
	*** RETT rate hikes in own state *** 
	************************************
	*** a) Event Dummies
	* Construct variables that indicate a) the number of months between posting date and date RETT rate hikes and b) the number of months between posting date and date first legal draft (announcement)
	foreach num of numlist 1/4 {
		gen monsincech`num' = monlast - montaxinc`num'
		label var monsincech`num' "Number of months until(-)/since(+) next/last RETT rate hike"
		gen monsinceann`num' = monlast - monlawdraft`num'
		label var monsinceann`num' "Number of months until(-)/since(+) next/last first legal draft RETT rate hike"
	}

	* Construct dummies that indicate whether a) a RETT rate hike occures in the next 12 months after posting date and b) a first legal draft for a RETT rate hike occures in the next 12 months after posting date
	foreach num of numlist 1/11 {
		gen preref_1224_`num' = 0
		gen preann_1224_`num' = 0
		label var preref_1224_`num' "Next RETT rate hike occurs in `num' month(s)"
		label var preann_1224_`num' "Next first legal draft for RETT rate hike occurs in `num' month(s)"
		foreach num2 of numlist 1/4 {
			replace preref_1224_`num' = 1 if monsincech`num2'==`num'*(-1) 
			replace preann_1224_`num' = 1 if monsinceann`num2'==`num'*(-1) 
		}
	}
	
	* End point
	gen preref_1224_12 = 0
	gen preann_1224_12 = 0
	label var preref_1224_12 "Number of RETT rate hikes that occured before event window"
	label var preann_1224_12 "Number of first legal bills for RETT rate hikes that occured before event window"
	foreach num2 of numlist 1/4 {
		replace preref_1224_12 = preref_1224_12 + 1 if monsincech`num2' <= -12	// Dieser Dummy zählt, wie viele Steuersatzerhöhungen insgesamt vor dem Event-Window stattgefunden haben
		replace preann_1224_12 = preann_1224_12 + 1 if monsinceann`num2' <= -12	// Dieser Dummy zählt, wie viele Steuersatzerhöhungen insgesamt vor dem Event-Window stattgefunden haben
	}
	
	* Construct dummies that indicate whether a) a RETT rate hike occured in the 24 months before posting date and b) a first legal draft for a RETT rate hike occured in the 24 months before posting date
	foreach num of numlist 0/22 {
		gen postref_1224_`num' = 0
		gen postann_1224_`num' = 0
		label var postref_1224_`num' "Last RETT rate hike occured `num' month(s) ago"
		label var postann_1224_`num' "Last first legal draft for RETT rate hike occured `num' month(s) ago"
		foreach num2 of numlist 1/4 {
			replace postref_1224_`num' = 1 if monsincech`num2'==`num'
			replace postann_1224_`num' = 1 if monsinceann`num2'==`num'
		}
	}
	
	* End point
	gen postref_1224_23 = 0
	gen postann_1224_23 = 0
	label var postref_1224_23 "Number of RETT rate hikes that occured after event window"
	label var postann_1224_23 "Number of first legal bills for RETT rate hikes that occured after event window"
	foreach num2 of numlist 1/4 {
		replace postref_1224_23 = postref_1224_23 + 1 if monsincech`num2' >= 23 & monsincech`num2' != .	// Dieser Dummy zählt, wie viele Steuersatzerhöhungen nach dem Event-Window noch kommen
		replace postann_1224_23 = postann_1224_23 + 1 if monsinceann`num2' >= 23 & monsinceann`num2' != .	// Dieser Dummy zählt, wie viele Steuersatzerhöhungen nach dem Event-Window noch kommen
	}

	*** b) RETT rate changes
	foreach num of numlist 1/4 { // tax rate changes as percentage points 
		replace ratetaxdiff`num' = ratetaxdiff`num'*100
	}

	* Construct variables that indicate the size of an RETT rate hike (a: implementation, b: first legal draft) in the next 12 months after posting date
	foreach num of numlist 1/11 {
		gen prereftax_1224_`num' = 0
		gen preanntax_1224_`num' = 0
		label var prereftax_1224_`num' "Size of RETT rate hike (implementation) that occurs in `num' month(s)"
		label var preanntax_1224_`num' "Size of RETT rate hike (announcement) that occurs in `num' month(s)"
		foreach num2 of numlist 1/4 {
			replace prereftax_1224_`num' = ratetaxdiff`num2' if monsincech`num2' == `num'*(-1) 
			replace preanntax_1224_`num' = ratetaxdiff`num2' if monsinceann`num2' == `num'*(-1) 
		}
	}
	
	* End point
	gen prereftax_1224_12 = 0
	gen preanntax_1224_12 = 0
	label var prereftax_1224_12 "Cumulated size of all RETT rate hikes that occured before event window"
	label var preanntax_1224_12 "Cumulated size of all RETT rate hikes that occured before event window"
	foreach num2 of numlist 1/4 {
		replace prereftax_1224_12 = prereftax_1224_12 + ratetaxdiff`num2' if monsincech`num2' <= -12
		replace preanntax_1224_12 = preanntax_1224_12 + ratetaxdiff`num2' if monsinceann`num2' <= -12
	}
	
	* Construct variables that indicate the size of an RETT rate hike (a: implementation, b: first legal draft) in the 24 months before posting date
	foreach num of numlist 0/22 {
		gen postreftax_1224_`num' = 0
		gen postanntax_1224_`num' = 0
		label var postreftax_1224_`num' "Size of RETT rate hike (implementation) that occured `num' month(s) ago"
		label var postanntax_1224_`num' "Size of RETT rate hike (announcement) that occured `num' month(s) ago"
		foreach num2 of numlist 1/4 {
			replace postreftax_1224_`num' = ratetaxdiff`num2' if monsincech`num2'==`num'
			replace postanntax_1224_`num' = ratetaxdiff`num2' if monsinceann`num2'==`num'
		}
	}
	
	* End point
	gen postreftax_1224_23 = 0
	gen postanntax_1224_23 = 0
	label var postreftax_1224_23 "Cumulated size of all RETT rate hikes (implementation) that occured after event window"
	label var postanntax_1224_23 "Cumulated size of all RETT rate hikes (announcement) that occured after event window"
	foreach num2 of numlist 1/4 {
		replace postreftax_1224_23 = postreftax_1224_23 + ratetaxdiff`num2' if monsincech`num2' >= 23 & monsincech`num2' != .
		replace postanntax_1224_23 = postanntax_1224_23 + ratetaxdiff`num2' if monsinceann`num2' >= 23 & monsinceann`num2' != .
	}

	*** c) Change in log net of tax rate
	gen lnnettaxdiff1 = ln(1-ratetaxinc1) - ln(1-0.035)
	gen lnnettaxdiff2 = ln(1-ratetaxinc2) - ln(1-ratetaxinc1)
	gen lnnettaxdiff3 = ln(1-ratetaxinc3) - ln(1-ratetaxinc2)
	gen lnnettaxdiff4 = ln(1-ratetaxinc4) - ln(1-ratetaxinc3)


	* Construct variables that indicate the size of a change in the log net-of-tax rate (a: implementation, b: first legal draft) in the next 12 months after posting date
	foreach num of numlist 1/11 {
		gen prereflntax_1224_`num' = 0
		gen preannlntax_1224_`num' = 0
		label var prereflntax_1224_`num' "Size of change in log net-of-tax rate (implementation) that occurs in `num' month(s)"
		label var preannlntax_1224_`num' "Size of change in log net-of-tax rate (announcement) that occurs in `num' month(s)"
		foreach num2 of numlist 1/4 {
			replace prereflntax_1224_`num' = lnnettaxdiff`num2' if monsincech`num2'==`num'*(-1) 
			replace preannlntax_1224_`num' = lnnettaxdiff`num2' if monsinceann`num2'==`num'*(-1) 
		}
	}
	
	* End point
	gen prereflntax_1224_12 = 0
	gen preannlntax_1224_12 = 0
	label var prereflntax_1224_12 "Cumulated size of all changes in log net-of-tax rate (implementation) that occured before event window"
	label var preannlntax_1224_12 "Cumulated size of all changes in log net-of-tax rate (announcement) that occured before event window"
	foreach num2 of numlist 1/4 {
		replace prereflntax_1224_12 = prereflntax_1224_12 + lnnettaxdiff`num2' if monsincech`num2'<=-12
		replace preannlntax_1224_12 = preannlntax_1224_12 + lnnettaxdiff`num2' if monsinceann`num2'<=-12
	}
	
	* Construct variables that indicate the size of a change in the log net-of-tax rate (a: implementation, b: first legal draft) in the 24 months before posting date
	foreach num of numlist 0/22 {
		gen postreflntax_1224_`num' = 0
		gen postannlntax_1224_`num' = 0
		label var postreftax_1224_`num' "Size of change in log net-of-tax rate (implementation) that occured `num' month(s) ago"
		label var postanntax_1224_`num' "Size of change in log net-of-tax rate (announcement) that occured `num' month(s) ago"
		foreach num2 of numlist 1/4 {
			replace postreflntax_1224_`num' = lnnettaxdiff`num2' if monsincech`num2'==`num'
			replace postannlntax_1224_`num' = lnnettaxdiff`num2' if monsinceann`num2'==`num'
		}
	}
	
	* End point
	gen postreflntax_1224_23 = 0
	gen postannlntax_1224_23 = 0
	label var postreflntax_1224_23 "Cumulated size of all changes in log net-of-tax rate (implementation) that occured after event window"
	label var postannlntax_1224_23 "Cumulated size of all changes in log net-of-tax rate (announcement) that occured after event window"
	foreach num2 of numlist 1/4 {
		replace postreflntax_1224_23 = postreflntax_1224_23 + lnnettaxdiff`num2' if monsincech`num2'>=23 & monsincech`num2'!=.
		replace postannlntax_1224_23 = postannlntax_1224_23 + lnnettaxdiff`num2' if monsinceann`num2'>=23 & monsinceann`num2'!=.
	}
	
	
	*****************************************
	*** RETT rate hikes in neighbor state *** 
	*****************************************
	*** Generate variables depicting closest neighboring states
	foreach num of numlist 1 / 16 {
		gen nachbar`num' = (mindist`num' <= `maxdist' & bula != `num')
		label var nachbar`num' "Dummy equals 1 if border to state no. `num' is maximum `maxdist' km away"
		tab nachbar`num' bula if bula == `num'
	}	
	egen Nnachbar = rowtotal(nachbar*)
	label var Nnachbar "Number of neighbors within a distance of maximum `maxdist' km"
	tab Nnachbar

	gen nachbar_1st = .
	label var nachbar_1st "Closest neighboring state"
	gen nachbar_2nd = .
	label var nachbar_2nd "2nd closest neighboring state"
	gen nachbar_3rd = .
	label var nachbar_3rd "3rd closest neighboring state"
	
	
	foreach num of numlist 1 / 16 {
		replace nachbar_1st = `num' if nachbar`num' == 1 & Nnachbar == 1
		replace nachbar_1st = `num' if nachbar`num' == 1 & mindist`num' == mindist_inner & Nnachbar == 2
		replace nachbar_2nd = `num' if nachbar`num' == 1 & nachbar_1st != `num' & Nnachbar == 2
		replace nachbar_3rd = `num' if nachbar`num' == 1 & nachbar_1st != `num' & nachbar_2nd != `num' & Nnachbar == 3
	}	
	tab nachbar_2nd if Nnachbar == 2, m
	
	*** Tax rate changes in neighboring states and day of reform
	gen taxratenb = 0.035
	label var taxratenb "Current RETT rate in neighboring state"

	foreach num of numlist 1 / 4 {
		gen datetaxincnb`num' = .
		label var datetaxincnb`num' "Date of tax rate hike no. `num' in neighboring state"
	}

	* Schleswig-Holstein
	replace datetaxincnb1 = mdy(1,1,2012) if nachbar_1st == 1 // Schleswig-Holstein
	replace taxratenb = 0.05 if daylast >= datetaxincnb1 & nachbar_1st==1 
	replace datetaxincnb2 = mdy(1,1,2014) if nachbar_1st == 1 
	replace taxratenb = 0.065 if daylast >= datetaxincnb2 & nachbar_1st==1 

	* Hamburg
	replace datetaxincnb1 = mdy(1,1,2009) if nachbar_1st == 2 // Hamburg
	replace taxratenb = 0.045 if daylast >= datetaxincnb1 & nachbar_1st==2 

	* Niedersachsen
	replace datetaxincnb1 = mdy(1,1,2011) if nachbar_1st == 3 // Niedersachsen
	replace taxratenb = 0.045 if daylast >= datetaxincnb1 & nachbar_1st==3 
	replace datetaxincnb2 = mdy(1,1,2014) if nachbar_1st == 3 
	replace taxratenb = 0.05 if daylast >= datetaxincnb2 & nachbar_1st==3 

	* Bremen
	replace datetaxincnb1 = mdy(1,1,2011) if nachbar_1st == 4 // Bremen
	replace taxratenb = 0.045 if daylast >= datetaxincnb1 & nachbar_1st==4 
	replace datetaxincnb2 = mdy(1,1,2014) if nachbar_1st == 4 
	replace taxratenb = 0.05 if daylast >= datetaxincnb2 & nachbar_1st==4 

	* Nordrhein-Westfalen
	replace datetaxincnb1 = mdy(10,1,2011) if nachbar_1st == 5 // NRW
	replace taxratenb = 0.05 if daylast >= datetaxincnb1 & nachbar_1st==5 
	replace datetaxincnb2 = mdy(1,1,2015) if nachbar_1st == 5 
	replace taxratenb = 0.065 if daylast >= datetaxincnb2 & nachbar_1st==5 

	* Hessen
	replace datetaxincnb1 = mdy(1,1,2013) if nachbar_1st == 6 // Hessen
	replace taxratenb = 0.05 if daylast >= datetaxincnb1 & nachbar_1st==6 
	replace datetaxincnb2 = mdy(8,1,2014) if nachbar_1st == 6 
	replace taxratenb = 0.06 if daylast >= datetaxincnb2 & nachbar_1st==6 

	* Rheinland-Pfalz
	replace datetaxincnb1 = mdy(3,1,2012) if nachbar_1st == 7 // RLP
	replace taxratenb = 0.05 if daylast >= datetaxincnb1 & nachbar_1st==7 

	* Baden-Württemberg
	replace taxratenb = 0.035
	replace datetaxincnb1 = mdy(11,5,2011) if nachbar_1st == 8 // BW
	replace taxratenb = 0.05 if daylast >= datetaxincnb1 & nachbar_1st==8 

	* Saarland
	replace datetaxincnb1 = mdy(1,1,2011) if nachbar_1st == 10 // Saarland
	replace taxratenb = 0.04 if daylast >= datetaxincnb1 & nachbar_1st==10 
	replace datetaxincnb2 = mdy(1,1,2012) if nachbar_1st == 10 
	replace taxratenb = 0.045 if daylast >= datetaxincnb2 & nachbar_1st==10 
	replace datetaxincnb3 = mdy(1,1,2013) if nachbar_1st == 10 
	replace taxratenb = 0.055 if daylast >= datetaxincnb3 & nachbar_1st==10 
	replace datetaxincnb4 = mdy(1,1,2015) if nachbar_1st == 10 
	replace taxratenb = 0.065 if daylast >= datetaxincnb4 & nachbar_1st==10

	* Berlin
	replace datetaxincnb1 = mdy(1,1,2007) if nachbar_1st == 11 // Berlin
	replace taxratenb = 0.045 if daylast >= datetaxincnb1 & nachbar_1st==11 
	replace datetaxincnb2 = mdy(4,1,2012) if nachbar_1st == 11 
	replace taxratenb = 0.05 if daylast >= datetaxincnb2 & nachbar_1st==11 
	replace datetaxincnb3 = mdy(1,1,2014) if nachbar_1st == 11
	replace taxratenb = 0.06 if daylast >= datetaxincnb3 & nachbar_1st==11 
	
	* Brandenburg
	replace datetaxincnb1 = mdy(1,1,2011) if nachbar_1st == 12 // Brandenburg
	replace taxratenb = 0.05 if daylast >= datetaxincnb1 & nachbar_1st==12 
	replace datetaxincnb2 = mdy(7,1,2015) if nachbar_1st == 12 
	replace taxratenb = 0.065 if daylast >= datetaxincnb2 & nachbar_1st==12 

	* Mecklenburg-Vorpommern
	replace datetaxincnb1 = mdy(7,1,2012) if nachbar_1st == 13 // Mecklenburg-Vorpommern
	replace taxratenb = 0.05 if daylast >= datetaxincnb1 & nachbar_1st==13 

	* Sachsen-Anhalt
	replace datetaxincnb1 = mdy(3,2,2010) if nachbar_1st == 15 // Sachsen-Anhalt
	replace taxratenb = 0.045 if daylast >= datetaxincnb1 & nachbar_1st==15 
	replace datetaxincnb2 = mdy(3,1,2012) if nachbar_1st == 15 
	replace taxratenb = 0.05 if daylast >= datetaxincnb2 & nachbar_1st==15 

	* Thüringen
	replace datetaxincnb1 = mdy(4,7,2011) if nachbar_1st == 16 // Thüringen
	replace taxratenb = 0.05 if daylast >= datetaxincnb1 & nachbar_1st==16 
	replace datetaxincnb2 = mdy(1,1,2017) if nachbar_1st == 16 
	replace taxratenb = 0.065 if daylast >= datetaxincnb2 & nachbar_1st==16 

	format datetaxincnb* %td
	
		
	*** Construct variables that indicate the size of RETT rate hikes
	bysort nachbar_1st: egen ratetaxincnb1_ = mean(taxratenb) if daylast >= datetaxincnb1 & daylast < datetaxincnb2
	bysort nachbar_1st: egen ratetaxincnb2_ = mean(taxratenb) if daylast >= datetaxincnb2 & daylast < datetaxincnb3
	bysort nachbar_1st: egen ratetaxincnb3_ = mean(taxratenb) if daylast >= datetaxincnb3 & daylast < datetaxincnb4
	bysort nachbar_1st: egen ratetaxincnb4_ = mean(taxratenb) if daylast >= datetaxincnb4 
		
	foreach num of numlist 1/4 {
		bysort nachbar_1st: egen ratetaxincnb`num' = mean(ratetaxincnb`num'_)
		drop ratetaxincnb`num'_
	}
	
	gen ratetaxdiffnb1 = ratetaxincnb1 - 0.035
	label var ratetaxdiffnb1 "Size of RETT rate hike no. 1 in neighbor state"
	gen ratetaxdiffnb2 = ratetaxincnb2 - ratetaxincnb1
	label var ratetaxdiffnb2 "Size of RETT rate hike no. 2 in neighbor state"
	gen ratetaxdiffnb3 = ratetaxincnb3 - ratetaxincnb2
	label var ratetaxdiffnb3 "Size of RETT rate hike no. 3 in neighbor state"
	gen ratetaxdiffnb4 = ratetaxincnb4 - ratetaxincnb3
	label var ratetaxdiffnb4 "Size of RETT rate hike no. 4 in neighbor state"

	
	*** Construct variables that indicate the number of days between two RETT rate hikes
	gen timesincechangenb = .
	label var timesincechangenb "Number of days since last RETT rate hike in neighbor state"
	gen timetochangenb = .
	label var timetochangenb "Number of days until next RETT rate hike in neighbor state"
	
	foreach num of numlist 1/4 {
		replace timesincechangenb = daylast - datetaxincnb`num' if daylast >= datetaxincnb`num'
		replace timetochangenb    = datetaxincnb`num' - daylast if daylast < datetaxincnb`num'
	}

	*** Construct dummies indicating maximum number of months until/since next/last RETT rate hike
	foreach num of numlist 1/6 {
		gen postrefnb`num'm = (timesincechangenb != . & timesincechangenb <= 30.5*`num')
		label var postrefnb`num'm "RETT rate hike in neighbor state occured within the past `num' months"
		gen prerefnb`num'm = (timetochangenb != . & timetochangenb <= 30.5*`num')
		label var prerefnb`num'm "RETT rate hike in neighbor state will occur within the next `num' months"
	}
	
		
	*** b) Rate change
	foreach num of numlist 1/4 { // tax rate changes as percentage points 
		replace ratetaxdiffnb`num' = ratetaxdiffnb`num'*100
	}

	* Construct variable that indicates the month of an RETT rate hike in neighbor state
	foreach num of numlist 1/4 {
		gen montaxincnb`num' = mofd(datetaxincnb`num')
		label var montaxincnb`num' "Month of RETT rate hike no. `num' in neighbor state"
		format montaxincnb`num' %tm
	}
		
	* Construct variable that indicates the number of months that have passed since an RETT rate hike in a neighbor state
	foreach num of numlist 1/4 {
		gen monsincechnb`num' = monlast - montaxincnb`num'
		label var monsincechnb`num' "Number of months until(-)/since(+) next/last RETT rate hike in neighbor state"
	}
	
	* Construct variables that indicate the size of an RETT rate hike in neighbor state in the next 12 months after posting date
	foreach num of numlist 1/11 {
		gen prereftaxnb_1224_`num' = 0
		label var prereftaxnb_1224_`num' "Size of RETT rate hike in neighbor state that occurs in `num' month(s)"
		foreach num2 of numlist 1/4 {
			replace prereftaxnb_1224_`num' = ratetaxdiffnb`num2' if monsincechnb`num2' == `num'*(-1) 
		}
	}
	* End point
	gen prereftaxnb_1224_12 = 0
	label var prereftaxnb_1224_12 "Cumulated size of all RETT rate hikes in neighbor state that occured before event window"
	foreach num of numlist 1/4 {
		replace prereftaxnb_1224_12 = prereftaxnb_1224_12 + ratetaxdiffnb`num' if monsincechnb`num' <= -12
	}
	
	* Construct variables that indicate the size of an RETT rate hike in neighbor state in the 24 months before posting date
	foreach num of numlist 0/22 {
		gen postreftaxnb_1224_`num' = 0
		label var postreftaxnb_1224_`num' "Size of RETT rate hike in neighbor state that occured `num' month(s) ago"
		foreach num2 of numlist 1/4 {
			replace postreftaxnb_1224_`num' = ratetaxdiffnb`num2' if monsincechnb`num2'==`num'
		}
	}
	
	* End point
	gen postreftaxnb_1224_23 = 0
	label var postreftaxnb_1224_23 "Cumulated size of all RETT rate hikes in neighbor state that occured after event window"
	foreach num of numlist 1/4 {
		replace postreftaxnb_1224_23 = postreftaxnb_1224_23 + ratetaxdiffnb`num' if monsincechnb`num' >= 23 & monsincechnb`num' != .
	}



	////////////////////////////////////////////////
	*** PART 4: PROXIES FOR TRANSACTION FREQUENCIES AND BARGAINING POWER
	////////////////////////////////////////////////
	************************************
	*** Transaction frequencies *** 
	************************************
	*** Absolute and relative number of postings
	* Number of postings per inhabitant
	bysort ags jahr: egen totpost_ags = count(ags)
	label var totpost_ags "Number of postings per municipality and year"
	sum totpost_ags, detail
	bysort ags: egen totpost_ags_all = count(ags)
	label var totpost_ags_all "Number of postings per municipality during the whole sample period"

	* Number of postings per building
	if "`file'"=="etwp"  {
		gen post_perprop = totpost_ags / (flat_all - build_1hh)  // posting per non-single family home (based on 2011 census)
		label var post_perprop "Number of postings divided by property stock per municipality and year"
		gen post_perprop_all = totpost_ags_all / (flat_all - build_1hh) 
		label var post_perprop_all "Number of postings divided by property stock per municipality during the whole sample period"
	}
	if "`file'"=="mfhp" {
		gen post_perprop = totpost_ags / (build_2hh + build_3hh)  // posting per non-single family home (based on 2011 census)
		label var post_perprop "Number of postings divided by property stock per municipality and year"
		gen post_perprop_all = totpost_ags_all / (build_2hh + build_3hh) 
		label var post_perprop_all "Number of postings divided by property stock per municipality during the whole sample period"
	}
	if "`file'"=="ehp" {
		gen post_perprop = totpost_ags / build_1hh  // posting per single family home
		label var post_perprop "Number of postings divided by property stock per municipality and year"
		gen post_perprop_all = totpost_ags_all / build_1hh 
		label var post_perprop_all "Number of postings divided by property stock per municipality during the whole sample period"
	}

	*** Transaction frequency quartiles
	* Version 1: Only include municipalities with more than 1,000 buildings, use post_perprop in 2005-2008 (prior to most reforms), compute kreistyp-specific quartiles
	gen post_perprop_0508_ = post_perprop if jahr>=2005 & jahr<=2008 & flat_all >= 1000
	bysort ags: egen post_perprop_0508 = max(post_perprop_0508_)
	label var post_perprop_0508 "Maximum number of postings per year published between 2005-2008 divided by property stock per municipality"
	drop post_perprop_0508_
	bysort kreistyp: egen post_perprop_0508_q = xtile(post_perprop_0508) , nq(4)

	* Version 2: Only include municipalities with more than 1,000 buildings, use the average of post_perprop across all years, compute state-specific quartiles
	bysort bula: egen post_perprop_all_q = xtile(post_perprop_all) if flat_all>=1000, nq(4)

	* Descriptives
	sum post_perprop_all if flat_all >= 1000, detail

	* Overall number of postings in a given month and postal code. TBD: better deal with missings in estimation?
	bysort plz monlast: egen npost = total(monlast!=.)
	gen ln_npost = ln(npost)
	bysort plz monlast: gen nobs = _n

	* Version 4: Transaction frequencies within growing housing market regions
	bysort wmt_agg: egen post_perprop_wmt_q = xtile(post_perprop_all), nq(4)
	

	save ${data}/F_u_B/ifo_`file'_4q19_prep.dta, replace

	*** Merge with Wohnungsmarkttypen data 
	use ${data}/F_u_B/ifo_`file'_4q19_prep.dta, clear

	*** Merge with state-level debt per capita
	cap drop debtpc ln_debtpc
	merge m:1 bula jahr using ${data}/external_data/schuldenstaende_percap_prep_new.dta
	drop if _merge==2
	drop _merge
	gen ln_debtpc = ln(debtpc)
	
	
	*** Merge with regional variables (unemployment rate, GDP, etc.)
	cap drop bip alq 
	merge m:1 kreis jahr using "${data}/external_data/alq_bip_einwohner_2005-2019_prep_new.dta", keepusing(alq_2 bip einwohner)
	drop if _merge==2
	drop _merge
	cap drop ln_bip ln_pop
	gen ln_bip = ln(bip)
	gen ln_pop = ln(einwohner)
	drop einwohner
	rename alq_2 alq
	
	
	
	save ${data}/F_u_B/ifo_`file'_4q19_prep.dta, replace
	
	
	////////////////////////////////////////////////
	*** longer pre-trends
	////////////////////////////////////////////////
	
	use ${data}/F_u_B/ifo_`file'_4q19_prep.dta, clear
	
	************************************
	*** RETT rate hikes in own state *** 
	************************************
	*** a) Event Dummies

	
	/// 17 months pre-period
	* Construct dummies that indicate whether a) a RETT rate hike occures in the next 17 months after posting date and b) a first legal draft for a RETT rate hike occures in the next 12 months after posting date
	foreach num of numlist 1/16 {
		gen preref_1724_`num' = 0
		label var preref_1724_`num' "Next RETT rate hike occurs in `num' month(s)"
		foreach num2 of numlist 1/4 {
			replace preref_1724_`num' = 1 if monsincech`num2'==`num'*(-1) 
		}
	}
	
	* End point
	gen preref_1724_17 = 0
	label var preref_1724_17 "Number of RETT rate hikes that occured before event window"
	foreach num2 of numlist 1/4 {
		replace preref_1724_17 = preref_1724_17 + 1 if monsincech`num2' <= -17	// Dieser Dummy zählt, wie viele Steuersatzerhöhungen insgesamt vor dem Event-Window stattgefunden haben
	}
	
	*** b) RETT rate changes

	* Construct variables that indicate the size of an RETT rate hike (a: implementation, b: first legal draft) in the next 12 months after posting date
	foreach num of numlist 1/16 {
		gen prereftax_1724_`num' = 0
		label var prereftax_1724_`num' "Size of RETT rate hike (implementation) that occurs in `num' month(s)"
		foreach num2 of numlist 1/4 {
			replace prereftax_1724_`num' = ratetaxdiff`num2' if monsincech`num2' == `num'*(-1) 
		}
	}
	
	* End point
	gen prereftax_1724_17 = 0
	label var prereftax_1724_17 "Cumulated size of all RETT rate hikes that occured before event window"
	foreach num2 of numlist 1/4 {
		replace prereftax_1724_17 = prereftax_1724_17 + ratetaxdiff`num2' if monsincech`num2' <= -17
	}
	
	
	*** c) Log of net-of-tax rate
	* Construct variables that indicate the size of an RETT rate hike (a: implementation, b: first legal draft) in the next 12 months after posting date
	foreach num of numlist 1/16 {
		gen prereflntax_1724_`num' = 0
		label var prereflntax_1724_`num' "Size of change in log net-of-tax rate (implementation) that occurs in `num' month(s)s)"
		foreach num2 of numlist 1/4 {
			replace prereflntax_1724_`num' = lnnettaxdiff`num2' if monsincech`num2' == `num'*(-1) 
		}
	}
	
	* End point
	gen prereflntax_1724_17 = 0
	label var prereflntax_1724_17 "Cumulated size of all changes in log net-of-tax rate (implementation) that occured before event window"
	foreach num2 of numlist 1/4 {
		replace prereflntax_1724_17 = prereflntax_1724_17 + lnnettaxdiff`num2' if monsincech`num2' <= -17
	}
		
		
	
	save ${data}/F_u_B/ifo_`file'_4q19_prep_3624.dta, replace
}
