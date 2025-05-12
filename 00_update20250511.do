// Anpassen:


// Rechtsform variable vor filter stellen und g_fef303 umbenennen in Rechtsform


// TODO:

// Untergliederung in andere wz08 und jahrXindustry Effects

	//Generate Fixed Effects und dann in separaten Ordnern
	
	gen industry2 = substr(wz08_str, 1, 2)
	destring industry2, replace //transf. num Var

	// dann in 
	bysort id (jahr): gen tmp_industry = industry3 if _n == 1

// Untergliederung in andere Regionen und jahrXregionaleEbene Effects (am GWAP wenig sinnvoll wegen Bayern!)

	// Regierungsbezirke (ungenau, da nicht alle Bundesländer Regierungsbezirke) ungefähr NUTS2 tbd
	// MSA CZ tbd
	// Landkreis (5 Steller)  Counties NUTS3
	
	// 01 preperation.do
	generate county = substr(ags_string, 1, 5)
	destring county, gen(county_num)
	
	// 04 prep.do
	egen jahr_X_county = group(jahr county_num)
	label variable jahr_X_county "Jahr X county id"

	
// Wie viele Unternehmen sind betroffen von Standort und Rechtsformänderungen (potentielles Endogenitätsproblem)
// genauerer Untergliederun mit
	tab norfswitch
	tab pattern_tax moved if inlist(pattern_tax, "n001000","n000010","n000100", "n000000"), col 

// Todo: Teste ob Firmen mit >= 380 hebesatz selbe Effekte haben wie <= 380 haben. Dokumentiere Ergebnisse

// Verstehe ob die Effekte von Firmentypen (gk) oder Branchen (wz08) getrieben sind. Wie genau? -> // Ist es stärker im context stacked DiD? 

	// einige Unternehmen mit sehr hohen Gewerbeerträgen vermutlich von Steueranpassungen weniger beeindruckt als kleinere Unternehmen (wegen höherer Rentabilität, geringerer Flexibilität, etc.) -> nur inlist(gk,1,2) betrachten

	// schaue großen wz08: Treten Effekte über WZs hinweg auf oder ist er von bestimmten Firmentypen/Branchen getrieben? --> Schauen, ob man das eingrenzen/besser verstehen kann, was die Effekte treibt:





// Füge weitere abh. Variablen aus der Gewerbesteuerstatistik hinzu. NEHME GEWINNVARIABLE. sind hier die Effekte ähnlich seltsam?

/*
g_fef14     Zerlegungsfall  
g_fef19       Rechtsform wechsel
g_fef20     Art der Ertragssteuerpflicht 
g_fef21     Organschaft
g_fef303    Rechtsform aktualisiert
g_fef310      Zerlegungsanteil
g_fef311_round   Hebesatz
g_fef315      Summe Hinzurechnungen !
g_fef316      Summe Kürzungen !
g_k2131       Zinsen und andere Entgelte für Schulden, die dem Gewerbeertrag hinzugerechnet werden !
g_k6516       Gewerbeertrag vor Anrechnung der Gewerbeverluste (einschl. Gewerbeertrag der Organgesellschaften) !
g_k6520       Abgerundeter Gewerbeertrag (auf volle 100€) !
g_k6524      Verbleibender BEtrag nach abzug Freibetrag!
g_k65282     auf den 31.12 des EHZ festgestellter fortführungsgebundener Verlust Verluste aus dem Erhebungszeitraum, die in das nächste Jahr vorgetragen werden können !
g_fef17      Betriebsgrößenklasse 
g_fef301      anz zerlegungsgemeinden
g_fef307     ags 
g_fef311      hebesatz
g_k2110   Gewinn aus Gewerbebetrieb!    
g_k2152    Von Gewerbesteuer befreiter Anteil am Gewinn aus Gewerbebetrieb (Kz 21.10)
g_k6517    Angerechnete Gewerbeverluste (Verlustverbrauch § 10a GewStG) (K 65.17 bzw. K 37.17)
g_k6522    Freibetrag für den Gewerbeertrag nach § 11 Abs. 1 GewStG 
g_k65277     auf den 31.12 des Vorjahres festgestellter vortragsfähiger fortführungsgebundener Verlust Verluste aus dem Vorjahr, die in das aktuelle Jahr vorgetragen werden können, um den Gewerbeertrag zu mindern. 
g_wz08  Wirtschaftszweige 


BETRACHTE:

g_fef315      Summe Hinzurechnungen !
g_fef316      Summe Kürzungen !
g_k2131       Zinsen und andere Entgelte für Schulden, die dem Gewerbeertrag hinzugerechnet werden !
g_k6516       Gewerbeertrag vor Anrechnung der Gewerbeverluste (einschl. Gewerbeertrag der Organgesellschaften) !
g_k6520       Abgerundeter Gewerbeertrag (auf volle 100€) !
g_k6524      Verbleibender BEtrag nach abzug Freibetrag!
g_k65282     auf den 31.12 des EHZ festgestellter fortführungsgebundener Verlust Verluste aus dem Erhebungszeitraum, die in das nächste Jahr vorgetragen werden können.
g_k2110   Gewinn aus Gewerbebetrieb!
g_k2152    Von Gewerbesteuer befreiter Anteil am Gewinn aus Gewerbebetrieb (Kz 21.10)
g_k6517    Angerechnete Gewerbeverluste (Verlustverbrauch § 10a GewStG) (K 65.17 bzw. K 37.17)
g_k65277     auf den 31.12 des Vorjahres festgestellter vortragsfähiger fortführungsgebundener Verlust Verluste aus dem Vorjahr, die in das aktuelle Jahr vorgetragen werden können, um den Gewerbeertrag zu mindern. 

*/


// 1) NUTZE EIN stacked Modell wie in Link2024 und 2) justiere die Ränder, wie in Siegloch/Schmidheiny.

* 1. Relative Zeit Variablen


local pre_periods = 5 // Definiert, wie viele Perioden VOR einem Event maximal betrachtet werden sollen (hier wegen Treat 2018 5)
local post_periods = 3 // Definiert, wie viele Perioden NACH einem Event maximal betrachtet werden sollen (hier wegen Treat 2016 3)

// Diese Schleife läuft für zwei verschiedene Definitionen des "Events" durch:
// 1. v = "taxhike": Das Event ist eine SteuerERHÖHUNG (Dummy-Variable, die 1 ist, wenn eine Erhöhung stattfindet, sonst 0)
// 2. v = "taxchange": Das Event ist die GRÖSSE der Steueränderung (kann positiv oder negativ sein, oder 0)
foreach v in taxhike taxchange {

    // Innere Schleife für die PRE-EVENT Perioden (Leads)
    // Iteriert rückwärts von `pre_periods` (also 30) bis 1.
    // `f` nimmt also die Werte 30, 29, ..., 2, 1 an.
    forval f = `pre_periods'(-1)1 {
        sort ags jahr // Stellt sicher, dass die Daten korrekt nach Gemeinde und Jahr sortiert sind
        // Erstellt die Lead-Variable. Z.B. für f=1 und v="taxhike": F1_taxhike
        // F`f'.`v'` ist Stata-Syntax für den `f`-ten Lead der Variable `v`.
        // F1_taxhike ist also der Wert von taxhike im NÄCHSTEN Jahr (t+1).
        // Wenn taxhike im nächsten Jahr 1 ist (also eine Steuererhöhung in t+1 stattfindet),
        // dann ist F1_taxhike im aktuellen Jahr t gleich 1.
        // Das bedeutet, F1_taxhike im Jahr t zeigt an, dass in 1 Periode ein Event stattfindet (also in t+1).
        // Analog ist F2_taxhike im Jahr t gleich 1, wenn in 2 Perioden ein Event stattfindet (also in t+2).
        // Diese Variablen zeigen also an, dass ein Event "in der Zukunft" liegt.
        // Für die Event Study sind das die Dummies für die Perioden *vor* dem Event (t-1, t-2, etc.).
        // Wenn wir eine Beobachtung im Jahr t haben, und das Event ist im Jahr t+k, dann sind wir k Perioden *vor* dem Event.
        // Der Lead F`k`_taxhike wird dann 1 sein.
        qui gen F`f'_`v' = F`f'.`v'
    }

    // Innere Schleife für die POST-EVENT Perioden (Lags) und das Event-Jahr selbst
    // Iteriert von 0 bis `post_periods` (also 30).
    // `l` nimmt also die Werte 0, 1, ..., 29, 30 an.
    forval l = 0/`post_periods' {
        sort ags jahr // Stellt sicher, dass die Daten korrekt sortiert sind
        // Erstellt die Lag-Variable. Z.B. für l=0 und v="taxhike": L0_taxhike
        // L`l'.`v'` ist Stata-Syntax für den `l`-ten Lag der Variable `v`.
        // L0_taxhike ist der Wert von taxhike im AKTUELLEN Jahr (t). Das ist der Dummy für das Event-Jahr selbst.
        // L1_taxhike ist der Wert von taxhike im VORHERIGEN Jahr (t-1).
        // Wenn taxhike im vorherigen Jahr 1 war, dann ist L1_taxhike im aktuellen Jahr t gleich 1.
        // Das bedeutet, L1_taxhike im Jahr t zeigt an, dass vor 1 Periode ein Event stattgefunden hat (also in t-1).
        // Analog ist L2_taxhike im Jahr t gleich 1, wenn vor 2 Perioden ein Event stattgefunden hat (also in t-2).
        // Diese Variablen zeigen also an, dass ein Event "in der Vergangenheit" liegt oder gerade stattfindet.
        // Für die Event Study sind das die Dummies für das Eventjahr (t=0) und die Perioden *nach* dem Event (t+1, t+2, etc.).
        // Wenn wir eine Beobachtung im Jahr t haben, und das Event war im Jahr t-k, dann sind wir k Perioden *nach* dem Event.
        // Der Lag L`k`_taxhike wird dann 1 sein.
        qui gen L`l'_`v' = L`l'.`v'
    }
}


// Für die spätere Regression ist es oft einfacher, die Variablen direkt zu benennen:
// t_minus_2, t_minus_1, t_event, t_plus_1, t_plus_2
											
replace F1_taxhike = 0 // Setzt den Indikator für t-1 auf 0, macht es zur Referenz
// Ähnlich für gebinnte Variablen:


// In 06_event_studies.txt
global x_lbt_hike c.F2_taxhike c.F1_taxhike c.L0_taxhike c.L1_taxhike L2_taxhike											
					

// In 06_event_studies.txt
local var x_lbt_hike // Das oben definierte Set an Event-Time-Dummies
local fe plantnum year_X_industry year_X_state // Die Fixed Effects
eststo clear

// Für die abhängige Variable "Downward revision" (down_dummy)
local depvar down_dummy
reghdfe `depvar' $`var' , a(`fe') vce(cl ao_gem_2017 )
estimates store dd // Speichert die Ergebnisse

// Für die abhängige Variable "Log Revision Ratio" (logdiff)
local depvar logdiff
reghdfe `depvar' $`var' , a(`fe') vce(cl ao_gem_2017 )
estimates store ld // Speichert die Ergebnisse

*-----------------------------------------------------------


// Manuell die Event-Time Dummies erstellen, basierend auf 'treatment_year_group'

gen treatment_year_group = .
replace treatment_year_group = 2016 if inlist(pattern_tax,"n001000")
replace treatment_year_group = 2017 if inlist(pattern_tax,"n000100")
replace treatment_year_group = 2018 if inlist(pattern_tax,"n000010")

gen event_time = jahr - treatment_year_group // Relative Zeit zum Treatment
                                            // Fehlend für Nie-Behandelte



// Erstelle Dummies für dein Fenster (t-2 bis t+2)
// t-1 wird die Referenz
gen D_m2 = (event_time == -2) // t-2
// gen D_m1 = (event_time == -1) // t-1 (Referenz, wird weggelassen bzw setze gen D_m1 = 0)
gen D_0  = (event_time ==  0) // t0 (Eventjahr)
gen D_p1 = (event_time ==  1) // t+1
gen D_p2 = (event_time ==  2) // t+2

// Wichtig: Fehlende Werte korrekt behandeln!
// Für die 2018er Gruppe wird D_p2 immer 0 sein (oder fehlend, je nach Sample-Ende).
// Für die 2016er Gruppe wird D_m2 (relativ zu 2016) im Jahr 2014 sein.
// usw.



// Regression
// In 06_event_studies.txt
coefplot (dd , offset(-0.05) m(O) ) (ld , offset(0.05) m(S) ) , vert drop(_cons) omitted levels(95 90) recast(con) yline(0) ///
    rename(F2_taxhike=t-2 L0_taxhike=t0 L1_taxhike=t1 L2_taxhike=t2 ... ) /// // Umbenennung für die Achsenbeschriftung
    ytitle("Estimated Effect Relative to Period t = -1") ///
    legend(order(3 "Downward Revision" 6 "Log Revision Ratio")) ///
    ylabel(-0.075(0.025)0.075, format(%4.3f))
graph export "${outputpath}\fig_3_b.pdf", replace	


//Plotten

coefplot my_event_study ///
    , keep(D_m2 D_0 D_p1 D_p2) /// // Nur die relevanten Koeffizienten plotten
    omitted /// // Zeigt an, dass D_m1 (t-1) die Basis ist (implizit 0)
    coeflabels(D_m2 = "-2" D_0 = "0" D_p1 = "1" D_p2 = "2") /// // Schönere Labels für die X-Achse
    vert /// // Vertikale Linien für Konfidenzintervalle
    yline(0) /// // Nulllinie einzeichnen
    ytitle("Geschätzter Effekt relativ zu t-1") ///
    xtitle("Perioden relativ zur Steuererhöhung") ///
    legend(off) // Legende ggf. anpassen oder ausschalten
// Ggf. weitere Optionen für Konfidenzintervalle, Farben etc.		
									


*----------------------------

*moderne Schätzer

// Vorbereitung:
// 'first_treatment_year' ist eine Variable, die für jede Firma das erste Jahr des Treatments angibt (oder nie, wenn Kontrollgruppe)
// 'time_to_treatment' ist die relative Zeit zum Event (wie oben event_time)

// Beispiel mit eventstudyinteract (vereinfacht)
// Du würdest Dummies für die relativen Zeitperioden erstellen oder der Befehl macht das intern
// Hier ein konzeptioneller Aufruf:
eventstudyinteract deine_outcome_variable D_m* D_p* , /// // Die relativen Zeit-Dummies
                    cohort(first_treatment_year_variable) /// // Variable, die die Treatment-Kohorte definiert
                    control_cohort(wert_fuer_nie_behandelte) /// // Wert für die Kontrollgruppe
                    absorb(FE_firma FE_jahr) // Basis Fixed Effects

// Oder für csdid (Callaway & Sant'Anna)
// gvar ist die Variable, die das erste Treatment-Jahr anzeigt
// timevar ist die Kalenderjahresvariable
csdid deine_outcome_variable , ivar(firm_id) time(year) gvar(first_treatment_year) ///
      agg(event) // Um Event-Study-Koeffizienten zu bekommen
// Dann plotten mit csdid_plot






// Beantworte insgesamt folgende Fragen:
// i) Liegt es an der EÜR


// ii) Treiben nur bestimmte Subgruppen die Ergebnisse


// iii) Stimmt der CODE

/*
noch als kleine Ergänzung zum Vorgehen für morgen im FDZ:
 
- Du hast immer ID-FEs, oder? Die sollten drin sein.
- Ich würde eine Schleife laufen lassen, auf wie vielen WZ-Ebenen du die FE schätzt. Evtl. sieht es mit 2-Stellern anders aus?
- Genauso könntest du eine Schleife über verschiedene Varianten der Outcome-Variablen laufen lassen und z.B. mal schauen, ob es besser aussieht, wenn du winsorized oder die obersten und untersten Percentile aus dem Datensatz schmeißt - ggf. werden die komischen Ergebnisse auch von Outliern getrieben? Ich würde hier pragmatisch herumprobieren was funktioniert.
- Dann könntest du eine Schleife z.B. einzeln über die WZ 2-Steller o.ä. laufen lassen um zu checken, ob die komischen Ergebnisse von einzelnen Branchen getrieben werden.
- Wie gesagt: probier unbedingt aus, ob es mit Variablen aus der Gewerbesteuerstatistik besser aussieht als mit der EÜR.
*/







Absolut! Es ist sehr gut, dass du das so genau nachvollziehen möchtest und dich am Originalcode orientierst. Das hilft am meisten beim Verständnis und bei der Adaption.

Wir fokussieren uns jetzt auf dein gewünschtes Fenster von **t-2 bis t+2**, mit t-1 als Referenzperiode.

**Grundlagen aus dem Code von Link et al. (2024), die wir brauchen:**

1.  **Die Treatment-Variable:** Im Code von Link et al. ist das `taxhike` (ein Dummy: 1 bei Steuererhöhung, 0 sonst) oder `taxchange` (die Höhe der Änderung). Für eine Standard-Event-Study mit Dummies für relative Zeitperioden ist `taxhike` die relevantere Basis.
    * **Wo definiert?** In `01_prep.txt`.
    * **Dein Fall:** Du brauchst eine Variable, die für jede Firma und jedes Jahr anzeigt, ob *genau in diesem Jahr* das Treatment (deine Steuererhöhung für diese spezifische Kohorte) stattfindet. Nennen wir sie `treatment_event_dummy_it`.

2.  **Die Panelstruktur:** Der Code von Link et al. arbeitet mit `xtset ao_gem_2017 year` auf Gemeindeebene für die Erstellung der Leads/Lags der Steueränderungen und später mit `xtset plantnum year` für die firmenbezogenen Analysen.
    * **Dein Fall:** Du wirst wahrscheinlich `xtset deine_firmen_id deine_jahr_variable` verwenden.

**Schritt 1: Erstellung der relativen Zeit-Dummies (Event-Time Dummies) – Adaptiert von `01_prep.txt`**

Link et al. erstellen sehr viele Leads und Lags (`pre_periods = 30`, `post_periods = 30`). Das brauchen wir für dein fokussiertes Fenster nicht in diesem Umfang. Die Logik der Lead (`F.`) und Lag (`L.`) Operatoren ist aber zentral.

**Anpassung an deinen Fall (t-2 bis t+2, t-1 als Referenz):**

Angenommen, du hast:
* `firm_id`: Deine eindeutige Firmen-ID.
* `year`: Die Kalenderjahresvariable (2013-2019).
* `treatment_year_actual`: Eine Variable, die für jede Firma das *exakte Jahr* angibt, in dem sie ihre Steuererhöhung erfährt (also 2016 für Gruppe 1, 2017 für Gruppe 2, 2018 für Gruppe 3; und einen fehlenden Wert oder 0 für Firmen, die nie behandelt werden oder als reine Kontrollgruppe dienen).

```stata
// Dieses Skript demonstriert die Erstellung von Event-Study-Variablen
// und die Schätzung einer Event Study für ein gestaffeltes Treatment-Design
// mit Fokus auf t-2 bis t+2 (t-1 als Referenz).

// Annahmen für deine Daten (ersetze diese mit deinen Variablennamen):
// firm_id: Eindeutige Firmen-ID
// year: Kalenderjahr (z.B. 2013, 2014, ..., 2019)
// treatment_year_cohort: Variable, die für jede Firma das Jahr des Treatments ihrer Kohorte anzeigt
//                          (z.B. 2016, 2017, 2018). Für Kontrollfirmen ist dieser Wert
//                          fehlend (.) oder eine Zahl außerhalb des Sample-Zeitraums (z.B. 0 oder 9999).
// taxhike_indicator_firm: Ein 0/1 Indikator, der 1 ist, wenn die Firma `firm_id`
//                           im Jahr `year` ihre spezifische Steuererhöhung erfährt.
//                           Dieser Indikator sollte also nur im `treatment_year_cohort` für die jeweilige Firma 1 sein.
//                           (Wenn du diesen noch nicht hast, siehe den vorherigen Chatverlauf zur Erstellung
//                            basierend auf `taxhike_raw` und `treatment_year_cohort`).
//                            Für die Einfachheit nehmen wir an, du hast ihn schon als:
//                            gen taxhike_indicator_firm = (year == treatment_year_cohort)
//                            replace taxhike_indicator_firm = 0 if missing(taxhike_indicator_firm)
// outcome_var: Deine Ergebnisvariable (z.B. Investitionsrevision)
// firm_fe_id: Variable für Firmen-Fixed-Effects (oft identisch mit firm_id)
// year_fe_id: Variable für Jahres-Fixed-Effects (oft identisch mit year)
// (Optional) year_x_industry_fe: Variable für Jahr-mal-Industrie-Fixed-Effects
// cluster_var: Variable, auf deren Ebene Standardfehler geclustert werden sollen (z.B. firm_id oder gemeinde_id)


// ******************************************************************************
// Schritt 0: Vorbereitung (Beispieldaten erstellen, falls du es testen willst)
// ******************************************************************************
/*
clear
set obs 1000
gen firm_id = ceil(_n / 7) // Ca. 140 Firmen
gen year = 2013 + mod(_n-1, 7)
duplicates drop firm_id year, force
xtset firm_id year

// Treatment-Kohorten definieren (Beispiel)
gen treatment_year_cohort = .
replace treatment_year_cohort = 2016 if mod(firm_id, 3) == 0
replace treatment_year_cohort = 2017 if mod(firm_id, 3) == 1
replace treatment_year_cohort = 2018 if mod(firm_id, 3) == 2
// Einige Firmen bleiben ungetreated (treatment_year_cohort ist .)

gen taxhike_indicator_firm = (year == treatment_year_cohort)
replace taxhike_indicator_firm = 0 if missing(taxhike_indicator_firm)

// Outcome-Variable (Beispielhaft)
gen outcome_var = rnormal() + 0.5 * taxhike_indicator_firm + F1.taxhike_indicator_firm + L1.taxhike_indicator_firm
// Erstelle Beispiel Fixed Effects IDs
gen firm_fe_id = firm_id
gen year_fe_id = year
gen industry_id = mod(firm_id, 5) + 1 // Beispiel für Industrie
egen year_x_industry_fe = group(year industry_id)
gen cluster_var = firm_id
*/
// ENDE Beispielhafte Datenerstellung


// ******************************************************************************
// Schritt 1: Erstellung der relativen Zeit-Dummies (Event-Time Dummies)
// Fokus: t-2 bis t+2, mit t-1 als Referenz
// Basierend auf der Logik aus Link et al. (2024) 01_prep.txt
// ******************************************************************************

// Stelle sicher, dass die Daten korrekt sortiert und als Panel deklariert sind
// Ersetze firm_id und year mit deinen Variablennamen
sort firm_id year
xtset firm_id year

// `taxhike_indicator_firm` ist dein 0/1 Indikator, der 1 ist, wenn die Firma `firm_id`
// im Jahr `year` ihre spezifische Steuererhöhung (gemäß ihrer Kohorte) erfährt.

// Leads (relative Perioden vor dem firmenspezifischen Event)
// F1.var bedeutet "Wert von var in der nächsten Periode (t+1)"
// F2.var bedeutet "Wert von var in der übernächsten Periode (t+2)"
quietly gen event_dummy_m1 = F1.taxhike_indicator_firm // Diese Beobachtung ist t-1 relativ zu einem Event in t+1
quietly gen event_dummy_m2 = F2.taxhike_indicator_firm // Diese Beobachtung ist t-2 relativ zu einem Event in t+2

// Event-Jahr und Lags (relative Perioden ab und einschließlich dem firmenspezifischen Event)
// L0.var ist der Wert von var in der aktuellen Periode (t)
// L1.var ist der Wert von var in der vorherigen Periode (t-1)
// L2.var ist der Wert von var in der vorvorherigen Periode (t-2)
quietly gen event_dummy_0  = L0.taxhike_indicator_firm // Diese Beobachtung ist t0 (Eventjahr)
quietly gen event_dummy_p1 = L1.taxhike_indicator_firm // Diese Beobachtung ist t+1 relativ zu einem Event in t-1
quietly gen event_dummy_p2 = L2.taxhike_indicator_firm // Diese Beobachtung ist t+2 relativ zu einem Event in t-2

// Fehlende Werte, die durch Lead/Lag-Operatoren an den Rändern des Panels entstehen, zu 0 machen.
// Dies ist wichtig, damit Firmen, die nicht im gesamten Fenster beobachtet werden, korrekte Dummies haben.
foreach var of varlist event_dummy_m* event_dummy_0 event_dummy_p* {
    replace `var' = 0 if missing(`var')
}

// Für Firmen, die nie behandelt werden (d.h. `taxhike_indicator_firm` ist für sie immer 0),
// werden all diese Event-Dummies ebenfalls 0 sein, was korrekt ist.

// Label für Klarheit (optional)
label var event_dummy_m2 "Event Time: t-2"
label var event_dummy_m1 "Event Time: t-1 (Referenz)"
label var event_dummy_0  "Event Time: t0 (Event)"
label var event_dummy_p1 "Event Time: t+1"
label var event_dummy_p2 "Event Time: t+2"

// ******************************************************************************
// Schritt 2: Vorbereitung für die Regression
// Ähnlich zu Link et al. (2024) 06_event_studies.txt
// ******************************************************************************

// Referenzperiode ist t-1 (event_dummy_m1). Diese Variable wird in der Regression weggelassen.
// Wir nehmen die Dummies für t-2, t0, t+1, t+2 in die Regression auf.

// Definiere das Set der Event-Time-Variablen für die Regression
// (event_dummy_m1 wird weggelassen)
global deine_event_dummies "event_dummy_m2 event_dummy_0 event_dummy_p1 event_dummy_p2"

// Definiere die Fixed Effects, die du verwenden möchtest
// Ersetze dies mit deinen tatsächlichen Fixed-Effects-Variablen
// global deine_fixed_effects "firm_fe_id year_fe_id" // Einfachstes Modell: Firmen- und reine Jahres-FE
global deine_fixed_effects "firm_fe_id year_x_industry_fe" // Beispiel: Firmen- und Jahr x Industrie FE
// Wenn du keine Jahr x Industrie FE hast, nimm year_fe_id

// ******************************************************************************
// Schritt 3: Schätzung der Event Study Regression mit reghdfe
// Ähnlich zu Link et al. (2024) 06_event_studies.txt
// ******************************************************************************
display "Schätze Event Study für Outcome: outcome_var"
eststo clear // Lösche vorherige Schätzergebnisse

// Ersetze outcome_var und cluster_var mit deinen Variablennamen
reghdfe outcome_var $deine_event_dummies ///
    , absorb($deine_fixed_effects) vce(cluster cluster_var)

// Ergebnisse für den Plot und die Tabelle speichern
estimates store event_study_results

// ******************************************************************************
// Schritt 4: Erstellung eines Plots der Ergebnisse mit coefplot
// Ähnlich zu Link et al. (2024) 06_event_studies.txt
// ******************************************************************************
display "Erstelle Event Study Plot"

coefplot event_study_results ///
    , keep($deine_event_dummies) ///       // Nur die Koeffizienten unserer Event-Dummies
    omitted ///                           // Zeigt implizit, dass t-1 (event_dummy_m1) die Basis ist (auf 0 gesetzt)
    coeflabels(event_dummy_m2 = "-2" ///   // Labels für die X-Achse
               event_dummy_0  = "0"  ///
               event_dummy_p1 = "1"  ///
               event_dummy_p2 = "2") ///
    vertical ///                          // Vertikale Darstellung der Koeffizientenpunkte
    yline(0, lcolor(black) lwidth(thin)) /// // Nulllinie einzeichnen
    ytitle("Geschätzter Effekt relativ zu t-1") ///
    xtitle("Perioden relativ zur Steuererhöhung") ///
    legend(off) ///                       // Legende ausschalten (oder anpassen)
    ciopts(recast(rcap) color(%70)) ///   // Konfidenzintervalle als Kappen darstellen
    mcolor(%70) ///                       // Markerfarbe
    msymbol(O) ///                        // Markersymbol
    graphregion(color(white)) ///
    title("Event Study: Effekt auf Outcome Variable", size(medium)) ///
    subtitle("Fenster t-2 bis t+2 (t-1 Referenz)", size(small)) ///
    note("Konfidenzintervalle: 95%. Standardfehler geclustert auf `cluster_var'. " ///
         "Für 2018er Kohorte endet der dargestellte Effekt bei t+1.", size(vsmall) span)

// Ggf. Graph exportieren
// graph export "dein_event_study_plot.png", replace width(1600)

// ******************************************************************************
// Schritt 5: Erstellung einer Tabelle der Ergebnisse mit esttab
// Ähnlich zu Link et al. (2024) 07_tables.txt (für Tabellenexport)
// ******************************************************************************
display "Erstelle Ergebnistabelle"

// Definiere Labels für die Tabelle
local event_labels `" "-2" "event_dummy_m2" `"0" "event_dummy_0" `"1" "event_dummy_p1" `"2" "event_dummy_p2""'

esttab event_study_results using "deine_event_study_tabelle.rtf", ///
    replace ///
    cells(b(star fmt(3)) se(par fmt(3))) /// // Koeffizienten mit Sternen und Standardfehler in Klammern
    star(* 0.10 ** 0.05 *** 0.01) ///
    title("Event Study Ergebnisse: Effekt auf Outcome Variable") ///
    nonumbers ///                          // Keine Modellnummern
    mtitles("Koeffizient (Std.Err.)") ///
     colaborels(none) ///
    keep($deine_event_dummies) ///        // Nur die Event-Time Koeffizienten
    order($deine_event_dummies) ///
    rename(event_dummy_m2 "Periode t-2" /// // Umbenennung für die Tabelle
           event_dummy_0  "Periode t0 (Event)" ///
           event_dummy_p1 "Periode t+1" ///
           event_dummy_p2 "Periode t+2") ///
    stats(N r2_a, fmt(%9.0fc %9.3f) labels("Anzahl Beob." "Adj. R-squared")) ///
    notes("Abhängige Variable: outcome_var. Referenzperiode ist t-1. " ///
          "Alle Modelle kontrollieren für Fixed Effects (`$deine_fixed_effects'). " ///
          "Standardfehler (in Klammern) sind auf Ebene von `cluster_var' geclustert. " ///
          "Signifikanz: * p<0.10, ** p<0.05, *** p<0.01. " ///
          "Für die 2018er Kohorte ist der Effekt für t+2 nicht geschätzt (Sampleende 2019).")

display "Skript beendet. Plot und Tabelle sollten erstellt worden sein (ggf. Pfad anpassen)."
```

**Wichtige Erklärungen und Anpassungen für dich:**

1.  **Platzhalter ersetzen:** Du musst alle Platzhalter wie `firm_id`, `year`, `treatment_year_cohort`, `taxhike_indicator_firm`, `outcome_var`, `firm_fe_id`, `year_fe_id`, `year_x_industry_fe` (falls verwendet), und `cluster_var` durch deine tatsächlichen Variablennamen ersetzen.
2.  **Erstellung von `taxhike_indicator_firm`:**
    * Der Code geht davon aus, dass du eine Variable `taxhike_indicator_firm` hast, die für jede Firma *genau in dem Jahr 1 ist, in dem ihre spezifische Steuererhöhung (gemäß ihrer Kohorte) stattfindet*, und sonst 0.
    * Falls du nur eine allgemeine `taxhike_raw` (wie bei Link et al.) und eine `treatment_year_cohort`-Variable hast, ist die Zeile `gen taxhike_indicator_firm = (year == treatment_year_cohort & taxhike_raw == 1)` (oder eine ähnliche Logik) entscheidend, um den *firmenspezifischen* Event-Zeitpunkt zu definieren. Für Kontrollfirmen, bei denen `treatment_year_cohort` fehlt oder z.B. 0 ist, wird `taxhike_indicator_firm` immer 0 sein.
3.  **Fixed Effects (`deine_fixed_effects`):**
    * Ich habe im Code ein Beispiel mit `firm_fe_id` und `year_x_industry_fe` (oder `year_fe_id`, wenn du Ersteres nicht hast) als globales Makro `deine_fixed_effects` definiert. Du musst dies an die Fixed Effects anpassen, die für dein Modell angemessen sind. Orientiere dich an der Hauptspezifikation von Link et al., wenn du kannst und es für dein Setting Sinn ergibt (also Firmen-FE und z.B. Jahr x Sektor FE oder Jahr x Region FE).
4.  **Clustering (`cluster_var`):** Wähle die Variable, auf deren Ebene die Fehler korreliert sein könnten und auf der das Treatment (oder die Variation darin) primär stattfindet.
5.  **Referenzperiode:** `event_dummy_m1` (t-1) wird als Referenzperiode weggelassen. Alle Koeffizienten werden relativ zu diesem Zeitpunkt interpretiert.
6.  **Interpretation des Plots und der Tabelle:**
    * Die Koeffizienten für `event_dummy_m2` testen auf Pre-Trends.
    * `event_dummy_0` zeigt den Effekt im Eventjahr.
    * `event_dummy_p1` und `event_dummy_p2` zeigen die dynamischen Effekte danach.
    * **Beachte die 2018er Kohorte:** Der Koeffizient für `event_dummy_p2` wird *nicht* von der 2018er Kohorte informiert, da dein Sample 2019 endet (2018 + 2 = 2020). Das ist wichtig für die Interpretation und sollte in deiner Arbeit erwähnt werden (siehe `note` im Plot-Code und `notes` im Tabellen-Code). Die Schätzung für `event_dummy_p2` basiert dann nur auf den Kohorten 2016 und 2017.
7.  **`eststo clear`:** Vor `reghdfe` habe ich `eststo clear` hinzugefügt, falls du `eststo` zum Speichern von Ergebnissen in einer Schleife oder für mehrere Modelle verwendest (was Link et al. tun). Für eine einzelne Event Study ist es nicht zwingend, aber gute Praxis.
8.  **Pfade für Output:** Die Tabelle wird als `.rtf`-Datei gespeichert ("deine\_event\_study\_tabelle.rtf"). Den Pfad kannst du anpassen. Der Plot wird standardmäßig im Results-Fenster von Stata angezeigt; der Exportbefehl ist auskommentiert.

Dieser Code sollte dir eine sehr gute Grundlage geben, um deine Event Study analog zu Link et al. für dein fokussiertes Fenster zu implementieren. Teste ihn sorgfältig mit deinen Daten!
