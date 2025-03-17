*-------------------------------------------------------------------------------------------------------------------
*   Project Title: THE DETERMINANTS OF TAX COMPLIANCE
*	Code: Analyze full_gwap.dta
/* 
 04_DATUM_DiDEvent.do Schätzt erste DiD bzw EventStudien mit zuvor festgelegter Ziel Variable

******************************************************************
* Umbenannte Variablen 		 									 *
****************************************************************** 
	rename e_c25120 e_personalausg
 */
*-------------------------------------------------------------------------------------------------------------------

*-------------------------------------------------------------------------------------------------------------------

// Vorab über Kette der Programm 00 und 01 02 laufen lassen, oder direkt durchlaufen lassen
/*
	if $FDZ == 1 {
    use "$datenpfad/full_gwap.dta", clear
}
else if $FDZ == 0 {
    use "$datenpfad/full_test.dta", clear
}
else if $FDZ == 2 {
    use "$datenpfad/full_gwap.dta", clear
	
}
*/
	
	*use "$neudatenpfad/Temp/preperation.dta", clear
	rename e_c25120 e_personalausg  // Umbenennung übertragen von 03_... .do File
	
	
	
*	-------------------------------------------------------------------------------------------------------------------
*	----
*	----	Block 0 : Reminder zu neg Personalausgaben und gaps über xtset
*	----
*	-------------------------------------------------------------------------------------------------------------------
// neg Personalausgaben	und ags
generate negative = (e_personalausg < 0)

// ags mit führenden nullen
list ags in 1/10
describe ags 
tostring ags, replace force // String Formatierung um führende nullen einzufügen
replace ags = "0" + ags if strlen(ags) == 7 // führende 0en hinzufügen
generate bundesland = substr(ags, 1, 2)

tabulate negative bundesland 
tabulate negative rechtsform, col // Rechtsform des Unternehmens



/*
// gaps	und Anzahl ids
xtdescribe
xtdescribe, patterns(150) // Zeigt die häufigsten Muster an.

// Behalte nur volle id Jahr Kombinationen
by id: gen n_years =_N  // Gibt für jede id die Anzahl der Beobachtungen, also Anzahl der Jahre die sie auftaucht in n_years aus
tab n_years
keep if n_years == 7


save "$neudatenpfad/Temp/preperation_allyears.dta", replace
*/


/*
// funktioniert noch nicht. Ziel zusammenhängende Jahr Beobachtungen für 7 Jahre und 6 Jahre, jedoch nur für muster .111111 111111. und 5 Jahre nach Muster .11111. und ..11111 um Anzahl Beobachtungen zu erhöhen

bysort id (jahr): gen present = !missing(jahr)
egen pattern = concat(present), by(id) p(" ")  //  Muster als String
tabulate pattern, sort  // Zeigt alle Muster und ihre Häufigkeiten an, absteigend sortiert.

// Beispiel Muster "1.1...."
list id jahr if pattern == "1010000"
*/

// Erstelle pattern variablen wie  bei xtdescribe (sodass gefiltert werden kann)

summarize jahr, meanonly
local max = r(max)
local min = r(min)
local range = r(max) - r(min) + 1
local miss : display _dup(`range') "." //  string an Punkten kreieren entsprechend der range
bysort id (jahr) : gen this = substr("`miss'", 1, jahr[1]-`min') + "1" if _n == 1
by id : replace this = substr("`miss'", 1, jahr - jahr[_n-1] - 1) + "1" if _n > 1
by id : replace this = this + substr("`miss'", 1, `max'- jahr[_N]) if _n == _N
by id : gen pattern = this[1]
by id : replace pattern = pattern[_n-1] + this if _n > 1
by id : replace pattern = pattern[_N]
tab pattern
xtdescribe
save "$neudatenpfad/Temp/preperation_allyears.dta", replace


* Bestimme die pattern die behalten werden sollen

// keep if substr(pattern, 1, 3) == "11."  // behält patterns like "11.1...", "11....", etc.
// keep if substr(pattern, strlen(pattern)-2, 3) == "11."  // behält patterns like "...11.", ".1.11."
keep if inlist(pattern,, ".111111", "111111.", ".11111.", "..11111", "11111..")
xtdescribe









use "$neudatenpfad/Temp/preperation_allyears.dta", clear




























*******************************************************************************************************************************************************************************************************************DID

*	-------------------------------------------------------------------------------------------------------------------
*	----
*	----	Block 1 : Simples DiD n_years == 7
*	----
*	-------------------------------------------------------------------------------------------------------------------










use "$neudatenpfad/Temp/preperation_allyears.dta", clear


* Behandlungs und Kontrollgruppe festlegen

* Treatmentgruppe:  Beobachtungen mit Tax Change nur in 2017 und sonst nicht (2014-2016, 2018-2019)
gen treat = (taxhike == 1 & jahr == 2017)
bysort id: egen temp_treat = max(treat) //Für alle Jahre der id treat auf 1 setzen
replace treat = temp_treat
drop temp_treat  


* Kontrollgruppe: Keine Steuererhöhung in irgendeinem Jahr
bysort id (jahr): gen id_hike = sum(changes) // Häufigkeit von steuererhöhung je ID
gen control = (id_hike == 0) // 1 falls nie hike
drop id_hike

tab treat control

generate post = (jahr >= 2017)  // Prüfe mit 2018
generate treat_post = treat * post 


xtreg stpfgew treat post treat_post, re


xtreg  e_personalausg	 treat post treat_post, re


xtreg e_reings treat post treat_post, re












* Assuming your data is xtset with id and jahr
* If not:  xtset id jahr

* --- Treatment Group ---
* 1. Check for taxhike ONLY in 2017, and count total taxhikes
bysort id: egen total_taxhikes = total(taxhike == 1)  // Count total taxhikes per ID
gen treat = (total_taxhikes == 1) // Only one taxhike across all years
bysort id: replace treat = 1 if (taxhike == 1 & jahr == 2017) //and in 2017
bysort id: replace treat = max(treat)

* --- Control Group ---
* 1. Check for NO tax changes in ANY year
bysort id: egen total_changes = total(changes) // Count total changes per ID
gen control = (total_changes == 0)

* --- Clean Up ---
drop total_taxhikes total_changes

* --- Verification (CRUCIAL!) ---
tabulate treat control, row col // Cross-tabulation
list id jahr taxhike changes treat control if treat == 1 | control == 1 // Examine a few cases

* --- DiD Variables ---
gen post = (jahr >= 2017)
gen treat_post = treat * post

* --- Regressions (Now Correct) ---
xtreg stpfgew treat post treat_post, re
xtreg  e_personalausg     treat post treat_post, re
xtreg e_reings treat post treat_post, re












*	-------------------------------------------------------------------------------------------------------------------
*	----
*	----	Block III: Remember ado Files die genutzt werden können für die Analyse mit DiD und Event am GWAP
*	----
*	-------------------------------------------------------------------------------------------------------------------

/* 
csdid
did_multiplegt
drdid
eventstudyinteract
*/


