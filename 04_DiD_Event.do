
***********************
* Extrem vereinfachte DiD Study für erstes gefühl *
***********************	


* ******************* Einfache Difference-in-Differences Analyse *********************


* **1. Treat und Control

generate treated_group = 0  
generate control_group = 0   
* Treatmentgruppe:  Beobachtungen mit Tax Change *nur* in 2017 und sonst keine (2014-2016, 2018-2019)
replace treated_group = 1 if (jahr == 2017 & taxchange == 1) ///
                         & (jahr == 2014 & taxchange == 0) ///
                         & (jahr == 2015 & taxchange == 0) ///
                         & (jahr == 2016 & taxchange == 0) ///
                         & (jahr == 2018 & taxchange == 0) ///
                         & (jahr == 2019 & taxchange == 0)

replace control_group = 1 if changes == 0 & jahr >= 2014 & jahr <= 2019


keep if treated_group == 1 | control_group == 1
keep if jahr >= 2014 & jahr <= 2019


generate treat = treated_group  // Treatment-Dummy (1=Treatmentgruppe, 0=Kontrollgruppe)
generate post = (jahr >= 2018)  // Post-Treatment-Dummy 
generate treat_post = treat * post // Interaktionsterm (DID-Term)


* **2. Einfaches Panel DID Modell

xtreg e_c25219 treat post treat_post, re


* **3. Verbessertes Panel DID Modell mit Firm Fixed Effects 

xtreg e_c25219 treat post treat_post, fe


* **4.  Panel DID Modell mit Firm *und* Jahr Fixed Effects (Modell 3) **

xtreg e_c25219 treat post treat_post i.jahr, fe



* **6. Ausgabe der Ergebnisse (optional)**

* Für Modell 1 (Random Effects):
eststo: xtreg e_c25219 treat post treat_post, re
esttab using "did_modell1_panel_re_2017_only.rtf", cells(b(fmt(3)) se(par fmt(2)))  ///
        star(* 0.10 ** 0.05 *** 0.01)  ///
        title(Panel DID Modell - Random Effects - Treatment 2017 Only)  ///
        nogaps nonotes

* Für Modell 2 (Firm Fixed Effects):
eststo: xtreg e_c25219 treat post treat_post, fe
esttab using "did_modell2_panel_fe_2017_only.rtf", cells(b(fmt(3)) se(par fmt(2)))  ///
        star(* 0.10 ** 0.05 *** 0.01)  ///
        title(Panel DID Modell - Firm Fixed Effects - Treatment 2017 Only)  ///
        nogaps nonotes

* Für Modell 3 (Firm und Jahr Fixed Effects):
eststo: xtreg e_c25219 treat post treat_post i.jahr, fe
esttab using "did_modell3_panel_fe_yearfe_2017_only.rtf", cells(b(fmt(3)) se(par fmt(2)))  ///
        star(* 0.10 ** 0.05 *** 0.01)  ///
        title(Panel DID Modell - Firm & Jahr Fixed Effects - Treatment 2017 Only)  ///
        nogaps nonotes

* Für Modell 4 (Firm und Jahr Fixed Effects, robuste Clustered SE):
eststo: xtreg e_c25219 treat post treat_post i.jahr, fe robust vce(cluster id)
esttab using "did_modell4_panel_fe_yearfe_robustse_2017_only.rtf", cells(b(fmt(3)) se(par fmt(2)))  ///
        star(* 0.10 ** 0.05 *** 0.01)  ///
        title(Panel DID Modell - Firm & Jahr FE, robuste Clustered SE - Treatment 2017 Only)  ///
        nogaps nonotes











	
	
			
	
***********************	
* Erste Event Study   *
***********************	
	
// Code könnte schnell angepasst werden wenn bspw nicht nur 2016 als treatment jahr sondern auch 15 und 17 und dann die 2 Jahre pre bzw post treatment gefragt sind
	
local pre_periods = 3  // da nur 6 zeitpunkte als Beobachtung also nur change in 2014-2019 ergo
local post_periods = 3

foreach v in taxhike  taxchange {  // iteriere über variable taxhike und dann über taxchange
	forval f = `pre_periods'(-1)1 { // lead bzw. pre variables, iteriere von 3 rückwärts um 1 bis 1 , also 3,2,1.
		sort g_fef307 year // soritere erst über ags und dann Jahr
		qui gen F`f'_`v' = F`f'.`v' // qui verhindert dass output angezeigt wird , neue variable wird generiert mit entsprechendem namen (bspw. F1_taxhike) welcher den Wert des ags im entsprechenden Jahr (F1.taxhike also im Jahr vor dem event annimmt)
	} 

	forval l = 0/`post_periods' {  // lag bzw post variables iteriere von 0 um 1 bis 3, also 0,1,2,3
		sort g_fef307 year
		qui gen L`l'_`v' = L`l'.`v'
	} 
} 



















*** 1. Datenaufbereitung ***

* Annahme: Ihre Daten enthalten die Variablen `plantnum` (Firmen-ID), `year` (Jahr), `taxhike` (Indikator für Steuererhöhung), `e_c65140` (Reingewinnsatz) und `rechtsform` (Rechtsform).

* Personengesellschaften filtern
preserve
keep if rechtsform == 2 // Annahme: 2 kodiert Personengesellschaften
save temp_personengesellschaften.dta, replace
restore

* Panel-Datenstruktur erstellen
xtset plantnum year

* Behandlungsgruppe erstellen (nur Steuererhöhung in 2016)
gen treated = (taxhike == 1 & year == 2016) 
replace treated = 0 if missing(taxhike) //  Beobachtungen ohne Steueränderung als Kontrolle

* Interaktionsvariable erstellen
gen treated_time = treated * (year - 2016)

*** 2. Differenz-in-Differenzen-Modell ***

* Modell schätzen
reghdfe e_c65140 treated_time treated, absorb(plantnum year) vce(cluster plantnum)

* Ergebnisse anzeigen
esttab, se star(* 0.10 ** 0.05 *** 0.01)

*** 3. Grafik ***

* Mittelwerte des Reingewinnsatzes für Behandlungs- und Kontrollgruppe über die Zeit berechnen
preserve
use temp_personengesellschaften.dta, clear
collapse e_c65140, by(year treated)
save temp_means.dta, replace
restore

* Grafik erstellen
twoway (connected e_c65140 year if treated == 1, color(blue) label(Behandlung)) ///
       (connected e_c65140 year if treated == 0, color(red) label(Kontrolle)), ///
       xtitle(Jahr) ytitle(Reingewinnsatz) legend(order(1 "Behandlung" 2 "Kontrolle"))
graph export "did_grafik.png", replace

* Temporäre Dateien löschen
erase temp_personengesellschaften.dta
erase temp_means.dta

/*
ado Files:

asdoc
astile
avar
binscatter
boottest
bunching
carryforward
coefplot
colrspace
csdid
did_multiplegt
drdid
dseg
ebalance
ebalfit
egen_inequal
egenmore
ereplace
estout
eventstudyinteract
fastxtile
ftools
geodist
geonear
gmlabvpos
gr0075
groups
grstyle
hhi
iscogen
kmatch
lasn
makematrix
metaparm
moremata
outreg
outreg2
outtable
parallel
parmest
ppmlhdfe
psweight
ranktest
reghdfe
reldist
savespss
shp2dta
st0085
st0523
st0536_1
st0541
st0682
st0684
synth
tab_chi
texdoc
twostepweakiv
unique
xtabond2
xtbalance2
xtcd2
xtcse2
xtdcce2
xtdpdml
gtools
regsave
labutil
cem
psmatch2
moremata
prodest
*/


			

	
	
	
	