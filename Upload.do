********************************************************************************************
********************************************************************************************



// Analyse der negativen Gewinne in e_personalausg

*----
// Gülitge Beobachtungen
	summarize e_personalausg if !missing(e_personalausg)
local valid_count = r(N)
display "Anzahl gültiger Beobachtungen: " `valid_count'

// Anteil der Werte die negativ sind berechnen mit missing und ohne missing werte berücksichtigung
generate negative = (e_personalausg < 0)
tabulate negative, missing // Erstelle eine Häufigkeitstabelle.  Die Option 'missing' berücksichtigt fehlende Werte.

// Mehrere Quantile auf einmal berechnen:
local quantiles "0.1 1 5 10"

foreach q in `quantiles' {
    _pctile e_personalausg, p(`q')
    display "`q'. Perzentil: " r(r1)
}
	
	
*----
* Kreuztabellen mit potenziell relevanten kategorialen Variablen (Beispiel)
tabulate negative gk, col // gk Betriebsgrößenklasse


list wz08 in 1/10
describe wz08

generate wz_abschnitt = substr(string(wz08), 1, 1) // Abschnitt (Buchstabe)
generate wz_abteilung = substr(string(wz08), 1, 2) // Abteilung
tabulate negative wz_abschnitt, col // Wirtschaftszweig wz08 Wirtschaftsabschnitt
tabulate negative wz_abteilung, col // Wirtschaftszweig wz08 Wirtschaftsabteilung
/*
Andere Optionen für tabulate (die relevantesten):

    row: Berechnet und zeigt Zeilenprozente an. Die Prozentsätze summieren sich innerhalb jeder Zeile zu 100%.  Das ist das Gegenstück zu col.

    cell: Berechnet und zeigt Zellenprozente an. Der Prozentsatz jeder Zelle bezieht sich auf die Gesamtzahl der Beobachtungen.  Alle Zellenprozente zusammen ergeben 100%.

    nofreq: Unterdrückt die Anzeige der absoluten Häufigkeiten.  Es werden nur die Prozentsätze (je nach Kombination von col, row, cell) angezeigt.

    nolabel: Zeigt die numerischen Werte der Variablen anstelle der Variablenlabels.  Nützlich, wenn du die Labels nicht sehen möchtest.

    missing: Behandelt fehlende Werte (.) als gültige Kategorie und nimmt sie in die Tabelle und die Prozentberechnungen auf. Standardmäßig werden fehlende Werte ignoriert.

    chi2: Berechnet den Chi-Quadrat-Test auf Unabhängigkeit. Dieser Test prüft, ob es einen statistisch signifikanten Zusammenhang zwischen den beiden Variablen gibt.

    expected: Zeigt die erwarteten Häufigkeiten unter der Annahme der Unabhängigkeit an (relevant im Zusammenhang mit dem Chi-Quadrat-Test).

*/

list ags in 1/10
describe ags
generate bundesland = substr(string(ags), 1, 2)
tabulate negative bundesland, col  // Bundeslandvariable
tabulate negative rechtsform, col // Rechtsform des Unternehmens (z.B. GmbH, AG)



* Prüfe ob es mehrere Jahre in Folge negative Personalausgaben gab (kann entsprechend erweitert werden)

bysort id (jahr): gen negative_vorjahr = e_personalausg[_n-1] < 0 if jahr > 2013 // L.e_personalausg geht auch, ist aber langsamer
bysort id (jahr): gen negative_2jahre_in_folge = (e_personalausg < 0) & (negative_vorjahr == 1)
bysort id (jahr): gen negative_vorvorjahr = e_personalausg[_n-2] < 0 if jahr > 2014
bysort id (jahr): gen negative_3jahre_in_folge = (e_personalausg < 0) & (negative_vorjahr == 1) & (negative_vorvorjahr == 1)

count if negative_2jahre_in_folge == 1 // Anzahl der Fälle mit mind. 2 Jahren in Folge
list id jahr e_personalausg if negative_3jahre_in_folge == 1 // Zeigt die Fälle mit 3 Jahren in Folge

* Ist Gewinn auch negativ bei den Beobachtungen die negative Personalausgaben haben?
generate temp_neg_pers = (e_personalausg < 0) //Hilfsvairable ist 1, wenn personalausg negativ
generate temp_neg_reing = (e_reings < 0)  //Hilfsvairable ist 1, wenn reings negativ
tabulate temp_neg_pers temp_neg_reing, col
drop temp_neg_pers temp_neg_reing // Optional: Hilfsvariablen wieder löschen


	
********************************************************************************************
********************************************************************************************


* gaps im Datensatz bei Erstellung mit xtset*

xtdescribe



xtdescribe, patterns(3000) // Zeigt die 3000 häufigsten Muster an.


/* nicht unbeding nötig

bysort id (jahr): gen present = !missing(jahr)
egen pattern = concat(present), by(id) p(" ")  // Erstellt das Muster als String
tabulate pattern, sort  // Zeigt alle Muster und ihre Häufigkeiten an, absteigend sortiert.


*/

// Beispiel für das Muster "1.1...."
list id jahr if pattern == "1 0100000"

/*

opfzeilen:

    id: 1.000e+09, 1.000e+09, ..., 1.017e+09: Deine id-Variable (wahrscheinlich die Unternehmens-ID) ist numerisch und hat sehr große Werte (wissenschaftliche Notation: 1.000e+09 ist 1 Milliarde). Das ist an sich kein Problem. n = 6859 bedeutet, dass du 6859 unterschiedliche Unternehmen in deinem Datensatz hast.
    jahr: 2013, 2014, ..., 2019: Deine jahr-Variable geht von 2013 bis 2019. T = 7 bedeutet, dass es potenziell 7 Beobachtungszeitpunkte (Jahre) gibt.
    Delta(jahr) = 1 unit: Bestätigt, dass die Zeitabstände zwischen den Jahren jeweils 1 Jahr betragen.
    Span(jahr) = 7 periods: Bestätigt, dass die gesamte Zeitspanne 7 Jahre umfasst.
    (id*jahr uniquely identifies each observation): Das ist sehr gut! Es bedeutet, dass die Kombination aus id und jahr jede Beobachtung eindeutig identifiziert. Du hast also keine Duplikate (d.h. nicht dasselbe Unternehmen im selben Jahr mehrfach).

Distribution of T_i:

    Dies zeigt, wie viele Jahre jedes Unternehmen im Datensatz vertreten ist. T_i ist die Anzahl der Jahre für Unternehmen i.
    min = 1: Das Unternehmen mit den wenigsten Beobachtungen ist nur für ein einziges Jahr im Datensatz. Das ist ein Hinweis auf erhebliche Lücken.
    5% = 1: 5% der Unternehmen haben nur 1 Beobachtung.
    25% = 1: 25% der Unternehmen haben nur 1 Beobachtung. Ein großer Anteil deiner Unternehmen hat also sehr wenige Beobachtungen!
    50% = 1: Der Median ist 1. Das heißt, mindestens die Hälfte deiner Unternehmen hat nur eine einzige Beobachtung. Das ist sehr ungewöhnlich und deutet auf ein großes Problem mit fehlenden Daten (oder eine sehr spezielle Datenstruktur) hin.
    75% = 2: 75% der Unternehmen haben höchstens 2 Beobachtungen.
    95% = 3: 95% der Unternehmen haben höchstens 3 Beobachtungen
    max = 6: Das Unternehmen mit den meisten Beobachtungen hat 6 Jahre (von 7 möglichen). Kein Unternehmen ist für alle 7 Jahre vorhanden!

Interpretation: Deine Daten haben sehr viele Lücken. Die meisten Unternehmen sind nur für sehr wenige Jahre im Datensatz.

Freq. Percent Cum. | Pattern:

    Dies zeigt die Muster der fehlenden und vorhandenen Beobachtungen.
    Freq.: Anzahl der Unternehmen mit diesem Muster.
    Percent: Prozentualer Anteil der Unternehmen mit diesem Muster.
    Cum.: Kumulierter prozentualer Anteil.
    Pattern:
        1: Beobachtung für dieses Jahr vorhanden.
        .: Beobachtung für dieses Jahr fehlend.
        Die Reihenfolge entspricht den Jahren 2013 bis 2019.

Interpretation (anhand des Outputs):

    661 9.64 9.64 | ......1: 661 Unternehmen (9.64%) haben nur im Jahr 2019 eine Beobachtung.
    623 9.08 18.72 | .....1.: 623 Unternehmen (9.08%) haben nur im Jahr 2018 eine Beobachtung.
    561 8.18 26.90 | 1......: 561 Unternehmen (8.18%) haben nur im Jahr 2013 eine Beobachtung.
    535 7.80 34.70 | ...1...: 535 Unternehmen (7.80%) haben nur im Jahr 2016 eine Beobachtung.
    533 7.77 42.47 | ....1..: 533 Unternehmen (7.77%) haben nur im Jahr 2017 eine Beobachtung.
    499 7.28 49.74 | .1.....: 499 Unternehmen (7.28%) haben nur im Jahr 2014 eine Beobachtung.
    493 7.19 56.93 | ..1....: 493 Unternehmen (7.19%) haben nur im Jahr 2015 eine Beobachtung.
    174 2.54 59.47 | ....11.: 174 Unternehmen (2.54%) haben Beobachtungen in 2017 und 2018.
    167 2.43 61.90 | .....11: 167 Unternehmen (2.43%) haben Beobachtungen in 2018 und 2019.
    2613 38.10 100.00 | (other patterns): 2613 Unternehmen (38.10%) haben andere Muster (Kombinationen aus fehlenden und vorhandenen Jahren).
    6859 100.00 | XXXXXXX: Gesamtanzahl der Unternehmen

Schlussfolgerungen und nächste Schritte:

    Sehr viele Lücken: Dein Datensatz hat extrem viele Lücken. Die meisten Unternehmen sind nur für ein oder zwei Jahre vorhanden. Das schränkt die Analysemöglichkeiten mit Paneldatenmethoden erheblich ein.
    Häufigste Muster: Die häufigsten Muster sind, dass Unternehmen nur in einem einzigen Jahr vorhanden sind (2013, 2014, 2015, 2016, 2017, 2018 oder 2019).
    Ursachenforschung: Du musst unbedingt herausfinden, warum so viele Daten fehlen. Mögliche Gründe:
        Datenquelle: Liegt es an der Art und Weise, wie die Daten erhoben wurden? Wurden Unternehmen nur einmal befragt?
        Unternehmensbestand: Sind viele Unternehmen im Laufe der Zeit aus dem Markt ausgeschieden oder neu hinzugekommen (z.B. Insolvenzen, Gründungen)?
        Zusammenführung von Datensätzen: Gab es Probleme beim Zusammenführen verschiedener Datenquellen?
        Fehlerhafte Daten: Gibt es Fehler in der id-Variable, die dazu führen, dass Unternehmen nicht korrekt über die Jahre hinweg verbunden werden?
    Auswirkungen auf die Analyse Paneldatenmodelle benötigen eine gewisse Anzahl an Beobachtungen über die Zeit. Mit derart vielen fehlenden Werten wird die Schätzung schwierig bis unmöglich, und die Ergebnisse sind mit Vorsicht zu interpretieren, da möglicherweise starke Selektionseffekte vorliegen (die Unternehmen, die du beobachtest, sind möglicherweise nicht repräsentativ für die Grundgesamtheit).
    Was tun?
        Datenqualität verbessern: Versuche, die Ursache der fehlenden Daten zu beheben (falls möglich). Kannst du zusätzliche Datenquellen heranziehen?
        Datenaufbereitung: Wenn die fehlenden Daten nicht zu beschaffen sind, überlege, ob du Unternehmen mit zu wenigen Beobachtungen ausschließt (z.B. nur Unternehmen mit mindestens 3 Jahren Beobachtungszeit). Das reduziert die Stichprobengröße, verbessert aber die Qualität der verbleibenden Daten.
        Robuste Methoden: Ziehe Analysemethoden in Betracht, die mit fehlenden Werten besser umgehen können, aber sei dir der Limitationen bewusst.
        Andere Analyse: Überlege, ob eine Paneldatenanalyse überhaupt der richtige Ansatz ist. Wenn die meisten Unternehmen nur für ein Jahr vorhanden sind, könntest du stattdessen separate Querschnittsanalysen für jedes Jahr durchführen.

Kurz gesagt: Der xtdescribe-Output zeigt ein erhebliches Problem mit fehlenden Daten in deinem Paneldatensatz. Du musst die Ursachen erforschen und geeignete Maßnahmen ergreifen, bevor du sinnvolle Analysen durchführen kannst. Die Interpretation der Ergebnisse ohne Berücksichtigung der fehlenden Daten wäre höchstwahrscheinlich irreführend.


*/


*******************************************************************************************************************************************************************************************************************DID


* Treatment-Gruppe: Steuererhöhung *nur* im Jahr 2017
gen treat = (taxhike == 1 & jahr == 2017)
bysort id: egen temp_treat = max(treat) //Stellt sicher, dass treat für alle Jahre der ID gleich ist
replace treat = temp_treat
drop temp_treat
* Kontrollgruppe: Keine Steuererhöhung in irgendeinem Jahr
bysort id (jahr): gen ever_hike = sum(taxhike) // Zählt, wie oft eine Steuererhöhung für jede ID vorkommt.
gen control = (ever_hike == 0)
drop ever_hike
* DiD-Variable (Interaktion)
gen did = treat * (jahr >= 2017) // Interaktion: Treatment-Gruppe * Post-Treatment-Periode

/*
gen treat = (taxhike == 1 & jahr == 2017): Erstellt eine Variable treat, die 1 ist, wenn die Beobachtung im Jahr 2017 eine Steuererhöhung hatte, und 0 sonst. Wichtig: Diese Variable ist zunächst nur für 2017 korrekt.
bysort id: egen temp_treat = max(treat): Erstellt eine temporäre Variable. Das egen max() innerhalb jeder id stellt sicher, dass temp_treat für alle Jahre eines Unternehmens 1 ist, wenn das Unternehmen irgendwann in der Treatment-Gruppe war (also in 2017 eine Steuererhöhung hatte).
replace treat = temp_treat: Überträgt den Wert von temp_treat auf treat. Jetzt ist treat für alle Jahre korrekt (1 für Unternehmen, die 2017 eine Steuererhöhung hatten, 0 sonst).
drop temp_treat: Löscht die Hilfsvariable.
bysort id (jahr): gen ever_hike = sum(taxhike): Zählt, wie oft eine Steuererhöhung (taxhike == 1) für jedes Unternehmen über alle Jahre vorkommt.
gen control = (ever_hike == 0): Erstellt eine Variable control, die 1 ist, wenn ein Unternehmen niemals eine Steuererhöhung hatte, und 0 sonst.
drop ever_hike: Löscht die nicht mehr benötigte Hilfsvariable.
gen did = treat * (jahr >= 2017): Erstellt die Interaktionsvariable für das DiD-Modell. Sie ist 1, wenn beide Bedingungen erfüllt sind:

    Das Unternehmen ist in der Treatment-Gruppe (treat == 1).
    Das Jahr ist 2017 oder später (jahr >= 2017).


*/


reghdfe y treat i.jahr did, absorb(id) vce(robust)

/*
reghdfe y treat i.jahr did: Führt die Regression durch.

    y: Deine abhängige Variable (Outcome). Ersetze y durch den tatsächlichen Namen deiner Outcome-Variablen.
    treat: Die Treatment-Variable.
    i.jahr: Die Jahresvariable. Das i.-Präfix sagt Stata, dass jahr als kategoriale Variable (Faktorvariable) behandelt werden soll. Dadurch werden automatisch Dummy-Variablen für jedes Jahr erstellt (bis auf eines, das als Basisjahr dient).
    did: Die Interaktionsvariable, die den DiD-Effekt schätzt.

, absorb(id): Absorbiert die id-Variable. Das ist äquivalent dazu, fixe Effekte für jedes Unternehmen in das Modell aufzunehmen. Das ist Standard in DiD-Modellen, um für unbeobachtete, zeitinvariante Unterschiede zwischen den Unternehmen zu kontrollieren.
vce(robust): Verwendet robuste Standardfehler. Dies wird immer empfohlen, um die Gültigkeit der Inferenz zu verbessern, insbesondere wenn Heteroskedastizität oder Autokorrelation vorliegen könnten.


*/


bysort jahr: egen mean_y_treat = mean(y) if treat == 1
bysort jahr: egen mean_y_contr = mean(y) if control==1
twoway (line mean_y_treat jahr if jahr <= 2017) ///
       (line mean_y_contr jahr if jahr <= 2017), ///
       legend(label(1 "Treatment Group") label(2 "Control Group")) ///
       xtitle("Jahr") ytitle("Mean Outcome") ///
	   xline(2017, lpattern(dash)) ///
       title("Parallel Trends Assumption Check")
	   
drop mean_y_treat mean_y_contr




/*
    bysort jahr: egen mean_y_treat = mean(y) if treat == 1: Berechnet den durchschnittlichen Wert von y für jedes Jahr, aber nur für die Treatment-Gruppe (treat == 1).

    bysort jahr: egen mean_y_contr = mean(y) if control == 1: Berechnet den durchschnittlichen Wert von y für jedes Jahr, aber nur für die Kontrollgruppe (control == 1).

    twoway (line mean_y_treat jahr if jahr <= 2017) (line mean_y_contr jahr if jahr <= 2017), ...: Erstellt das Diagramm.
        twoway: Der Befehl für zweidimensionale Diagramme.
        (line mean_y_treat jahr if jahr <= 2017): Zeichnet eine Linie für den durchschnittlichen Outcome der Treatment-Gruppe über die Jahre (nur bis 2017, also die Vorperiode).
        (line mean_y_contr jahr if jahr <= 2017): Zeichnet eine Linie für den durchschnittlichen Outcome der Kontrollgruppe (auch nur bis 2017).
        legend(...): Fügt eine Legende hinzu.
        xtitle(...) ytitle(...): Fügt Achsenbeschriftungen hinzu.
        xline(2017, lpattern(dash)): Zeichnet eine vertikale Linie bei x = 2017 (dem Jahr des Treatments), um die Vor- und Nachperiode zu trennen. lpattern(dash) macht die Linie gestrichelt.
        title(...): Gibt dem Diagramm einen Titel.

    drop mean_y_treat mean_y_contr: Löscht die temporären Variablen.

Interpretation des Diagramms:

Die Parallel-Trends-Annahme besagt, dass sich die Trends der abhängigen Variable in der Treatment- und Kontrollgruppe vor dem Treatment (also vor 2017) parallel entwickelt haben sollten.  Schaue dir also die Linien im Diagramm vor 2017 an.  Sie sollten ungefähr parallel verlaufen.  Perfekte Parallelität ist selten, aber es sollten keine systematischen Unterschiede in den Trends erkennbar sein (z.B. sollte die Treatment-Gruppe nicht schon vor 2017 einen stetig steigenden Trend haben, während die Kontrollgruppe einen fallenden Trend hat).

Wichtige Hinweise:

    Outcome-Variable: Ersetze y durch den tatsächlichen Namen deiner abhängigen Variable.
    Jahresbereich: Passe den Jahresbereich in der Grafik (if jahr <= 2017 und xline(2017)) an, falls dein Datensatz einen anderen Zeitraum abdeckt.
    Mehrere Treatment-Zeitpunkte: Wenn du Unternehmen hast, die zu unterschiedlichen Zeitpunkten eine Steuererhöhung hatten, ist dieses einfache DiD-Modell nicht geeignet. Du brauchst dann ein "generalisiertes" DiD-Modell (oft mit xtdidregress oder didregress in Stata).
    Annahme der gemeinsamen Trends: Die visuelle Überprüfung ist notwendig, aber nicht hinreichend. Es gibt auch formale Tests (z.B. Ereignisstudien-Regressionen), um die Annahme zu überprüfen. Diese sind aber etwas fortgeschrittener.
    Kontrollvariablen: In einem echten DiD-Modell würdest du wahrscheinlich Kontrollvariablen hinzufügen (Variablen, die den Outcome beeinflussen könnten und sich zwischen Treatment- und Kontrollgruppe unterscheiden könnten). Das würde die Regression ändern zu: reghdfe y treat i.jahr did x1 x2 x3, absorb(id) vce(robust) (wobei x1, x2, x3 deine Kontrollvariablen sind).

Dieser Code gibt dir ein grundlegendes DiD-Modell und eine Grafik zur Überprüfung der Parallel-Trends-Annahme. Für eine vollständige und robuste DiD-Analyse sind aber oft weitere Schritte und Überlegungen notwendig.
*/