/*
TODO am GWAP 5.6.25:
- Variablenanzeige length erweitern!!! Für einfacheres ablesen!
- Prüfe nochmal die Variable g_k2131 Entgelte für Schulden an: wie groß sind die größten werte? Über 200 000? Wie oft kommt das vor? Wie hoch sind die kleinen werte an der null? Wie oft gibt es Nas?
Vorgeschriebenen Code testen Balance Test durchüfhren!
*/



// Nach 01_1

// Wie viele müssen Gewerbesteuer zahlen?

// gen paygew = 0
// replace paygew = 1 if !missing()

//siehe tab nogew_basesum


// Wie viele haben Hinzurechnungen?

gen has_hinz = .
replace has_hinz = 1 if  g_fef315 > 0
replace has_hinz = 0 if missing(g_fef315) | g_fef315 <= 0
tab has_hinz

// Wie viele Beobachtungen haben Verlust (negativer Gewinn) oder Gewinn von 0 aber müssen trotzdem GewSt zahlen?

	// BEMessungsgrundlage g_k6524
	// Reingewinn: g_reing
	// 

	tab nogew if g_reing <= 0
	
	tab nogew_basesum if g_reing <= 0
	
// Wie viele haben Verlust (negativer Gewinn) oder Gewinn von 0 aber müssen trotzdem WEGEN HINZURECHNGUNGEN GewSt zahlen?	
	
	// Variable die 1 ist wenn wegen Hinzurechnugnen Gewerbesteuer gezahlt werden muss
		//eigene Bemessungsgrundlage berechnen, einmal mit und einmal ohne Hinzurechnungen
		// gen wegenhinz = .
		// replace wegenhinz = 1 if bmg_ohinz <= 0 & bmg_mhinz >0
		// replace wegenhinz = 0 if bmg_ohinz <= 0 & bmg_mhinz <= 0 | bmg_ohinz >= 0 & bmg_mhinz >= 0 
		// replace wegenhin = 99 if  bmg_ohinz > 0 & bmg_mhinz <= 0  // Fall sollte nicht eintreten!
		// tab wegenhinz if g_reing <=0
	
	
	
	
// 01_1	
	
// UPDATE EINTEILUNG GEWERBESTEUERZAHLEND ODER NICHT

/*  ALT	
*	-------------------------------------------------------------------------------------------------------------------
* Gewerbesteuerpflichtigkeit klären (Zahlt vs zahlt nicht GewSt)
*	-------------------------------------------------------------------------------------------------------------------	
	
	// Einteilung je Beobachtung (id jahr)
	gen nogew =0 
	
	replace nogew = 1 if g_k6524 <= 0  // Bemessungsgrundlage: Verbleibender Betrag nach Abzug des Freibetrags (Abgerundeter Gewerbeertrag - Freibetrag), vollständig vorhanden 
	replace nogew = 1 if inlist(e_ef19, 1, 2, 7) // Land und Forst
	replace nogew = 1 if inlist(e_ef19, 5, 6, 9) // Freiberuflich
	
	label var nogew "liability to LBT"
	label define placelb 0 "zahlt" 1 "zahlt nicht"
	label value nogew placelb
	
	tab nogew
	
	

	// Option 1 (Mitteleinteilung): Einteilung je id: Wenn >= 4 Jahre keine Gewerbesteuer gezahlt wurde, ist die Einteilung für die gesamte Id: keine gewerbesteuer
	sort id jahr
	bysort id : egen  sum_nogew = total(nogew)
	gen nogew_basesum = (sum_nogew >= 4) // ist diese Einteilung sinnvoll?
	label var nogew_basesum "Einordnung in Insgesamt Gewerbesteuer zahlend oder nicht"
	label value nogew_basesum placelb
	
	tab sum_nogew // Wie viele Beobachtungen je id werden wie oft als nogew eingeschätzt?
	*drop sum_nogew 
	tab nogew_basesum // Übersicht der finalen Einteilung nach id
*/


//OPTION 2
	// Option 2 (strikte Einteilung): Einteilung je id: Wenn >= 1 Jahre keine Gewerbesteuer gezahlt wurde, ist die Einteilung für die gesamte Id: keine gewerbesteuer
	*sort id jahr
	*bysort id : egen  sum_nogew = total(nogew)
	gen nogew_basesum_strict = (sum_nogew >= 1) // ist diese Einteilung sinnvoll?
	label var nogew_basesum_strict "Strikte Einordnung in Insgesamt Gewerbesteuer zahlend oder nicht"
	label value nogew_basesum_strict placelb
	
	*tab sum_nogew // Wie viele Beobachtungen je id werden wie oft als nogew eingeschätzt?
	*drop sum_nogew 
	tab nogew_basesum_strict // Übersicht der finalen Einteilung nach id

//TRENNSCHÄRFE: wie viel Prozent hatten nogew == 1 (also zahlten keine Steuer) im Jahr t-2, t-1, t0, t+1, t+2 relativ zum Treatment?

display _n as result "Erstelle Tabelle zur Steuerpflicht in Event-Perioden für behandelte Firmen..."


preserve 
	// Relative Zeit zum Treatment erstellen
	gen event_time = jahr - cohortjahr if cohortjahr > 0 & cohortjahr != .

	// Matrix für Ergebnisse initialisieren (5 Perioden + Total)
	matrix = J(6, 2, .)
	mat colnames= "Prozent_nogew_gleich_1" "N_Firmenjahre_in_Periode"
	mat rownames= "t-2" "t-1" "t0" "t+1" "t+2" "Gesamt_behandelt_beobachtet"

	local row = 1
	forval k = -2/2 {
		local event_time_label = cond(`k'<0, "t`k'", "t+`k'")
		if `k' == 0 {
			local event_time_label = "t0"
		}

		qui summarize nogew if cohortjahr > 0 & event_time == `k'
		if r(N) > 0 {
			mat[`row',1] = r(mean) * 100 // Prozent
			mat[`row',2] = r(N)
		}
		else {
			mat[`row',1] = .
			mat[`row',2] = 0
		}
		mat rownames[`row',1] = "`event_time_label'" // Zeilenname setzen
		local ++row
	}

	// Gesamtzahl der Beobachtungen von behandelten Firmen
	qui count if cohortjahr > 0 & cohortjahr != . & !missing(nogew)
	mat[`row',1] = . // Hier keinen Durchschnitt
	mat[`row',2] = r(N)
	mat rownames[`row',1] = "Behandelte Beob. (gesamt)"


	// Tabelle 
	di _n as result "Prozentsatz der behandelten Firmenjahre mit nogew == 1 (keine GwSt-Zahlung):"
	matrix list, format(%9.2f)

restore
*-------------------------------------------------------------------------------


// BMG_Problem: MISST g_k6524 das, was es messen soll? Vergleich!!!

// Teil 1: Überprüfe auf identische Werte

	gen g_k6524_ber =  // Eigene Berechnung
	gen meine_berechnung = g_k6524_ber
	gen ursprungswerte = g_k6524

    compare meine_berechnung ursprungswerte

    * Wie viele Beobachtungen übereinstimmen (`meine_berechnung == ursprungswerte`).
    * Wie viele Beobachtungen sich unterscheiden (`meine_berechnung < ursprungswerte` und `meine_berechnung > ursprungswerte`).
    * Informationen über fehlende Werte (z.B. wenn eine Variable einen Wert hat und die andere fehlt, oder wenn beide fehlen).

	// Schneller:
    gen sind_identisch = (meine_berechnung == ursprungswerte)
    tabulate sind_identisch
    ```
	// Schneller, Altenrative: Fälle, in denen beide Variablen fehlend sind (`.`), nicht als "identisch" betrachten  oder Fälle mit mindestens einem Missing gesondert behandeln :
      
        gen vergleich_status = 0 if meine_berechnung == ursprungswerte & !missing(meine_berechnung) & !missing(ursprungswerte) // Identisch und nicht fehlend
        replace vergleich_status = 1 if meine_berechnung != ursprungswerte & !missing(meine_berechnung) & !missing(ursprungswerte) // Unterschiedlich und nicht fehlend
        replace vergleich_status = 2 if missing(meine_berechnung) & !missing(ursprungswerte) // Nur meine_berechnung fehlt
        replace vergleich_status = 3 if !missing(meine_berechnung) & missing(ursprungswerte) // Nur ursprungswerte fehlt
        replace vergleich_status = 4 if missing(meine_berechnung) & missing(ursprungswerte) // Beide fehlen
        
        label define status_label 0 "Identisch (nicht fehlend)" 1 "Unterschiedlich (nicht fehlend)" ///
                                  2 "Eigene Berechnung fehlt, Ursprung vorhanden" ///
                                  3 "Eigene Berechnung vorhanden, Ursprung fehlt" ///
                                  4 "Beide fehlend"
        label values vergleich_status status_label
        tabulate vergleich_status
  

// Teil 2: Quantifizieren der Abweichung

    gen differenz = meine_berechnung - ursprungswerte

    summarize differenz, detail

    gen abs_differenz = abs(meine_berechnung - ursprungswerte)
    summarize abs_differenz, detail

    gen prozent_differenz = (meine_berechnung - ursprungswerte) / ursprungswerte * 100 ///
                           if ursprungswerte != 0 & !missing(ursprungswerte) & !missing(meine_berechnung)
    summarize prozent_differenz, detail //  Vorsicht bei Ursprungswerten nahe Null oder Null!

	// Visualisierung
	*histogram
        histogram differenz, bin(50) normal // bin(50) als Beispiel für Anzahl der Bins
 
    *Streudiagramm (Scatter Plot)
        scatter meine_berechnung ursprungswerte || function y=x, lcolor(red) ///
                title("Vergleich: Eigene Berechnung vs. Ursprungswerte") ///
                ytitle("Meine Berechnung") xtitle("Ursprungswerte")

    *Bland-Altman-Plot (Differenzplot):Trägt die Differenz gegen den Durchschnitt der beiden Werte auf. Hilft zu erkennen, ob die Abweichung von der Größenordnung der Messwerte abhängt.

        gen durchschnitt_werte = (meine_berechnung + ursprungswerte) / 2
        scatter differenz durchschnitt_werte, ///
                yline(0, lpattern(dash) lcolor(red)) ///
                title("Differenzplot") ytitle("Differenz (Eigene - Ursprung)") ///
                xtitle("Durchschnitt (Eigene + Ursprung) / 2")
  

// Teil 3: Welche Beobachtungen haben große Abweichungen?
  
    list id meine_berechnung ursprungswerte differenz if abs_differenz > 1000   // Schwellenwert von 1000 ggf anpassen!

    * Sortiere nach der absoluten Differenz (größte Abweicher)
    gsort -abs_differenz // Sortiert absteigend nach abs_differenz
    list id meine_berechnung ursprungswerte differenz abs_differenz in 1/20 // Zeigt die 20 größten Abweichungen

		

// Modelle GEWINNVARIABLEN VERGLEICH: EÜR und Gewerbesteuer	für DV Variable	
		
// Erstelle dummy der 1 ist wenn e_rohgewinns etc. vorhanden -> lasse modelle dann mit dieser if bedingung laufen und zwar nur für die Gewinnvariablen!
*e_rohgs1 // Rohgewinnsatz 1 -> hauptsächlich für Einzelgewerbetreibende gefüllt
*e_rohgs2 // Rohgewinnsatz 2  -> hauptsächlich für Einzelgewerbetreibende gefüllt
*e_halbreings // Halbreingewinnsatz -> hauptsächlich für Einzelgewerbetreibende gefüllt
*e_reings // Reingewinnsatz  -> hauptsächlich für Einzelgewerbetreibende gefüllt

gen e_rohgs1_d = .
replace e_rohgs1_d = 1 if !missing(e_rohgs1)

gen e_rohgs2_d = .
replace e_rohgs2_d = 1 if !missing(e_rohgs2)

gen e_halbreings_d = .
replace e_halbreings_d = 1 if !missing(e_halbreings)

gen e_reings_y = .
replace e_reings_y = 1 if !missing(e_reings)


// Vergleiche den Füllungsggrad der e_Dummys-> ähnlichkeit wünschenswert!

local dummies "e_rohgs1_d e_rohgs2_d e_halbreings_d e_reings_y"
foreach var of local dummies {
    replace `var' = 0 if missing(`var')
}

// Alle gleich?
gen alle_gleich = (e_rohgs1_d == e_rohgs2_d & ///
                   e_rohgs2_d == e_halbreings_d & ///
                   e_halbreings_d == e_reings_y)

tabulate alle_gleich

// Wertekonstellationen, wenn sie nicht alle gleich sind:
tabulate e_rohgs1_d e_rohgs2_d if alle_gleich == 0, missing
tabulate e_rohgs1_d e_halbreings_d if alle_gleich == 0, missing
tabulate e_rohgs1_d e_reings_y if alle_gleich == 0, missing

//  spezifische Musterzählen:
gen muster = string(e_rohgs1_d) + string(e_rohgs2_d) + string(e_halbreings_d) + string(e_reings_y)
tabulate muster


/// TODO:



Nimm mal nur die variablen für die in der EÜR beobachtungen da sind und schaue dann nochmal die Gewerbesteuervariablen an, 

Summary Tabellen Fertig erstellen, insbesondere abh. Variablen!




Pre Trends:

Über den balanced Test drüber schauen!


Robustheit:
Altenrative Schätzer impelementieren
Goodman Bacon Decomposition machen um zu sehen wie groß das Problem der TWFE Ansatzes in meinem Fall ist.


Placebo:
Placebo Tests implementieren: 2013er Jahr rein, andere Schätzer ausprobieren wie Link 2024, 
Placebotest für die Gruppen die zwar in treatmentgemeinde sind, aber vom treatment selbst nicht beeinflusst werden sollten, also die ohne Bemessungsgrundlage sind!







Falls Zeit -> Entkräftung von Argumenten:
Code für: wie viele Personengesellschaften und Sonstige Einzelgewerbetreibende müssen überhaupt Gewerbesteuer zahlen. Ganz zu beginn anschauen! Wie viele in unserem sample?
Wie viele Unternehmen haben überhaupt Hinzurechnungen insgesamt und in unserem sample?
Wie viele müssen Gewerbesteuer zahlen obwohl sie Gewinn von 0 oder Verlust haben, weil sie so viele Hinzurechnungen haben? IN unserem sample?


TODO am GWAP 5.6.25:
- Variablenanzeige length erweitern!!! Für einfacheres ablesen!
- Prüfe nochmal die Variable g_k2131 Entgelte für Schulden an: wie groß sind die größten werte? Über 200 000? Wie oft kommt das vor? Wie hoch sind die kleinen werte an der null? Wie oft gibt es Nas?
- Vorgeschriebenen Code testen Balance Test durchüfhren!


Die Schwerwiegendheit der Anwendung eines klassischen Two-Way Fixed Effects (TWFE) Ansatzes in Ihrem spezifischen Wellendesign hängt primär davon ab, ob und wie stark die Behandlungseffekte zwischen Ihren Kohorten (2016, 2017, 2018) und über die Zeit seit der Behandlung variieren (also heterogene Behandlungseffekte).
Ihr Design ist eine Form der gestaffelten Einführung (staggered adoption), bei der verschiedene Gruppen zu unterschiedlichen Zeitpunkten behandelt werden. Genau hier setzen die bekannten Probleme des TWFE-Schätzers an.

Mögliche Probleme des TWFE-Ansatzes in Ihrem Fall
Der TWFE-Schätzer zerlegt den Gesamteffekt in implizite 2x2 Difference-in-Differences-Vergleiche. Einige dieser Vergleiche können problematisch sein:
	1. Vergleich von bereits behandelten Einheiten mit später behandelten Einheiten (die noch nicht behandelt wurden):
		○ Eine Firma, die 2016 behandelt wurde, dient in den Jahren vor 2017 als "Kontrolle" für eine Firma, die erst 2017 behandelt wird. Das ist unproblematisch.
		○ Problem: Eine Firma, die 2016 behandelt wurde, dient in den Jahren nach 2016 (z.B. 2017, 2018) als Teil der "Kontrollgruppe" für Firmen, die erst 2017 oder 2018 behandelt werden. Wenn der Behandlungseffekt für die 2016er Kohorte in 2017 noch anhält (was zu erwarten ist), dann ist diese Firma keine saubere Kontrolle mehr. Der TWFE-Schätzer kann hier negative Gewichtungen auf diese Vergleiche legen oder die Effekte falsch mitteln.
	2. Vergleich von früher behandelten Einheiten mit später behandelten Einheiten (die bereits behandelt sind):
		○ Dies ist in Ihrem Design weniger relevant, da jede Firma nur einmal behandelt wird. Es geht eher darum, dass die Post-Treatment-Perioden früherer Kohorten die Schätzung für spätere Kohorten beeinflussen.
	3. Heterogenität der Behandlungseffekte:
		○ Zwischen Kohorten: Der Effekt einer Steuererhöhung im Jahr 2016 könnte anders sein als der einer Steuererhöhung im Jahr 2018 (z.B. aufgrund unterschiedlicher makroökonomischer Bedingungen in diesen Jahren). Der TWFE-Schätzer würde einen Durchschnitt über diese potenziell unterschiedlichen Effekte bilden.
		○ Über die Zeit (dynamische Effekte): Der Effekt im Behandlungsjahr (t0) könnte anders sein als in t+1 oder t+2. Der TWFE-Schätzer, wenn er nur einen einzigen Behandlungseffikt schätzt (nicht Ihr Event-Study-Design), würde dies ebenfalls mitteln. In Ihrem Event-Study-Design mit relativen Zeit Dummies versuchen Sie ja gerade, diese dynamischen Effekte zu erfassen. Das Problem hier ist, dass der Koeffizient für z.B. dummy_0_taxhike (Effekt bei t=0) kontaminiert sein kann durch die bereits behandelten Einheiten früherer Kohorten, die nicht mehr "sauber" sind.
Wie schwerwiegend ist das für Ihr Design?
	• "Nur" drei Wellen und eine "Niemals-Behandelt"-Kontrollgruppe: Ihr Design ist übersichtlicher als Setups mit vielen Behandlungswellen über einen langen Zeitraum. Die Präsenz einer klaren Kontrollgruppe (pattern_tax == "n000000") ist hilfreich.
	• Fokus auf kleine Unternehmen/Personengesellschaften: Es ist denkbar, dass diese Gruppe homogener reagiert als z.B. große Kapitalgesellschaften, was die Heterogenität der Effekte reduzieren könnte. Dies ist aber eine empirische Frage.
	• Kurzer Zeitraum (2013-2019): Der Zeitraum ist relativ kurz. Das begrenzt die Anzahl der Post-Treatment-Perioden, in denen sich Effekte stark unterscheiden könnten. Für Ihre 2018er Kohorte gibt es nur eine Post-Treatment-Periode (2019). Für die 2016er Kohorte gibt es drei (2017, 2018, 2019).
Die Hauptsorge ist, dass die geschätzten Event-Study-Koeffizienten (βk​) keine saubere Interpretation als Durchschnittseffekt im relativen Jahr k haben, wenn starke heterogene Behandlungseffekte vorliegen. Sie könnten durch die "falschen" Vergleiche verzerrt sein.

Empfehlung
	1. Goodman-Bacon Decomposition: Führen Sie eine Goodman-Bacon-Zerlegung (bacondecomp in Stata, von ssc install bacondecomp) durch. Diese zeigt Ihnen, welche 2x2 Vergleiche in Ihre Schätzung eingehen und welche Gewichte sie haben. Sie sehen dann explizit, wie viel von Ihrer Schätzung von "bereits behandelt vs. später behandelt" Vergleichen getrieben wird. Wenn diese problematischen Vergleiche nur ein geringes Gewicht haben oder ähnliche Effekte zeigen wie die "sauberen" Vergleiche (behandelt vs. nie behandelt oder behandelt vs. noch nicht behandelt), ist Ihr TWFE-Ergebnis möglicherweise weniger verzerrt.
	2. Vergleich mit robusten Schätzern: Wie bereits erwähnt, schätzen Sie Ihr Modell zusätzlich mit csdid oder eventstudyinteract. 
		○ csdid würde Ihnen erlauben, Effekte für jede Kohorte und jeden relativen Zeitpunkt getrennt zu schätzen, basierend auf Vergleichen mit den "niemals behandelten" oder "noch nicht behandelten" Einheiten.
		○ eventstudyinteract liefert eine saubere Schätzung des gewichteten Durchschnitts der Kohorten-spezifischen Event-Study-Koeffizienten. Wenn die Ergebnisse dieser Methoden stark von Ihren reghdfe-Ergebnissen abweichen, ist dies ein Hinweis auf relevante Heterogenität und eine Verzerrung im TWFE-Modell. Wenn sie ähnlich sind, können Sie mit größerer Sicherheit Ihre TWFE-Ergebnisse interpretieren.
Fazit:
Es ist schwierig, a priori genau zu sagen, wie schwerwiegend das Problem in Ihrem Fall ist, ohne die Daten genauer zu analysieren. Dass Sie ein Wellendesign mit nur einmaliger Behandlung haben, ist an sich nicht das Problem – die gestaffelte Einführung ist der Knackpunkt. Die potenziellen Verzerrungen sind real, aber ihre Magnitude hängt von der Datenstruktur und der wahren Heterogenität der Effekte ab. Die oben genannten diagnostischen Schritte können Ihnen helfen, das Ausmaß des Problems einzuschätzen.


	
	
	
