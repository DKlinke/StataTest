



*-------------------------------------------------------------------------------
* Deskriptive Statistik-Tabelle (Matrix-Ansatz, angelehnt an Link et al. 2024)
* Stata 16+ kompatibel
*-------------------------------------------------------------------------------

*--------------------------------------------------------------------------------
* Table 1: Sample Tax Hikes across Municipalities and Firms: Summary Statistics
*--------------------------------------------------------------------------------

use "$neudatenpfad/Temp/DiD_prep.dta", clear

mat M = J(6,5,.)

* Teil 1: Statistiken auf Gemeindeebene (Spalten 1-3 der Tabelle)

// Die höchste Gruppennummer entspricht der Anzahl der einzigartigen AGS /// ÄNDERE NOCHMAL TOTAL NUMBERS BERECHNUNG!!! diese vermutlich falsch!
egen ags_group = group(ags)
summarize ags_group
local anzahl_einzigartige_ags = r(max)

preserve 
    duplicates drop ags jahr, force

    // Kontrollgruppe never treated
    sum taxchange if inlist(pattern_tax,"n000000") & taxhike == 0
    mat M[1,1] = r(N)/6                     // Anzahl Gemeinde-Jahre mit Steuererhöhung -> hier / 6 da wir 6jahre haben je id die nie eine steuererhöhung erfährt
    mat M[1,2] = round(r(mean),0.01)      // Mittlere Höhe der Steuererhöhung (taxchange), hier = 0
    mat M[1,3] = round(r(sd),0.01)        // Standardabweichung von taxchange, hier  = 0

    // Treatmentgruppe: 2016
    sum taxchange if inlist(pattern_tax,"n001000") & taxhike == 1
    mat M[2,1] = r(N)
    mat M[2,2] = round(r(mean),0.01)
    mat M[2,3] = round(r(sd),0.01)

    // Treatmentgruppe: 2017
    sum taxchange if inlist(pattern_tax,"n000100") & taxhike == 1
    mat M[3,1] = r(N)
    mat M[3,2] = round(r(mean),0.01)
    mat M[3,3] = round(r(sd),0.01)

    // Treatmentgruppe: 2018
    sum taxchange if inlist(pattern_tax,"n000010") & taxhike == 1
    mat M[4,1] = r(N)
    mat M[4,2] = round(r(mean),0.01)
    mat M[4,3] = round(r(sd),0.01)

    // Full Treatment 2016 2017 2018
    sum taxchange if  taxhike == 1
    mat M[5,1] = r(N)
    mat M[5,2] = round(r(mean),0.01)
    mat M[5,3] = round(r(sd),0.01)
	
	// Total Sample
    mat M[6,1] =  `anzahl_einzigartige_ags'
    mat M[6,2] = .
    mat M[6,3] = .
restore 

* Teil 2: Statistiken auf Firmenebene - Firmenbeobachtungen (Spalten 4-5 der Tabelle) Datensatz auf Firmen-Jahr-Ebene

	//Gesamtzahl ids
	egen anzahl_einzigartige_id = nvals(id)
	scalar n_unique_id = anzahl_einzigartige_id[1]
	drop anzahl_einzigartige_id

	// Kontrollgruppe never treated
	sum taxchange if inlist(pattern_tax,"n000000") & taxhike == 0
	mat M[1,4] = r(N)/6                     // Anzahl Firmen-Jahre mit Steuererhöhung
	mat M[1,5] = round((r(N)/6)/n_unique_id,0.0001)    // Share gemessen an Gesamt Beobachteten Firmen 

	// Treatmentgruppe: 2016
	sum taxchange if inlist(pattern_tax,"n001000") & taxhike == 1
	mat M[2,4] = r(N)
	mat M[2,5] = round(r(N)/n_unique_id,0.0001)

	// Treatmentgruppe: 2017
	sum taxchange if inlist(pattern_tax,"n000100") & taxhike == 1
	mat M[3,4] = r(N)
	mat M[3,5] = round(r(N)/n_unique_id,0.0001)

	// Treatmentgruppe: 2018
	sum taxchange if inlist(pattern_tax,"n000010") & taxhike == 1
	mat M[4,4] = r(N)
	mat M[4,5] = round(r(N)/n_unique_id,0.0001)

	// Full Treatment 2016 2017 2018
    sum taxchange if  taxhike == 1
	mat M[5,4] = r(N)
	mat M[5,5] = round(r(N)/n_unique_id,0.0001)

	// Total Sample
	mat M[6,4] = n_unique_id
	mat M[6,5] = n_unique_id/n_unique_id


// Spalten- und Zeilennamen für die Matrix M definieren
mat colnames M =  "N" "Mean Taxchange" "SD Taxchange"  "N" "Share"  
mat rownames M = "Control" "Treat 2016" "Treat 2017" "Treat 2018" "Sum Treat" "Total" // "Full Sample"

// Matrix anzeigen (optional, zur Kontrolle)
mat list M

// Matrix M exportieren
esttab matrix(M) using "${outputpfad}\tab_1_ags_firms_hike.tex" , replace booktabs mlabel(none) label
esttab matrix(M) using "${outputpfad}\tab_1_ags_firms_hike.txt" , replace booktabs mlabel(none) label


// Todo Tabelle zu Sample und wave zusammensetzung !!!

// Whole Sample Treat 1 Treat 2 Treat 3

// Rechtsform (12 und die Personengesellschaften auflisten)
// Abhängige Variablen die man sich anschaut aufnehmen!




// TODO:

// Balance Statistics of Firms in Treatment And Contorl Group TABLE B3 Link -> für einzelne treatmentgruppen 16 17 18 machen ?! ode rbesser treatment und dann gesamt controllgruppe? vemrutlich besser da ähnlicher und ausreichend -> siehe LInk24! bleibe so nah wie möglich an Link24!!!




*-------------------------------------------------------------------------------
* Skript: 07_tables.txt (Auszug für Tabelle B.3)
* Paper: Link, Menkhoff, Peichl, Schüle (2024)
* Tabelle B.3: Balance Statistics of Firms in the Treatment and Control Group
*-------------------------------------------------------------------------------

// Annahme: Der Datensatz "final_data.dta" ist bereits geladen und enthält
// die Variablen:
// - plantnum (Firmen-ID), year
// - F1_taxhike (Dummy: 1, wenn im NÄCHSTEN Jahr eine Steuererhöhung stattfindet, also t-1 relativ zum Event in t0)
// - taxhike (Dummy: 1, wenn im AKTUELLEN Jahr eine Steuererhöhung stattfindet)
// - besch_lj (Beschäftigte im Vorjahr, hier als Proxy für t-1 Charakteristik verwendet)
// - rev_k (Umsatz in Tsd. im Vorjahr, hier als Proxy für t-1 Charakteristik verwendet)
// - reali_inv_k (Realisierte Investition in Tsd. im Vorjahr, hier als Proxy für t-1 Charakteristik verwendet)
// - down_dummy (Abwärtsrevision der Investition im aktuellen Jahr)
// - logdiff (Log-Revisionsquote im aktuellen Jahr)
// - ao_gem_2017 (Gemeinde-ID für Clustering, obwohl hier für t-test nicht direkt verwendet)

// Datensatz laden (falls noch nicht geschehen)
// use "${datapath}\final_data.dta", replace // Pfad muss angepasst sein

// Panelstruktur deklarieren (wichtig für Lead/Lag-Operatoren, aber hier werden die Variablen schon existieren)
xtset id jahr

// Initialisiere eine Matrix M mit 5 Zeilen und 3 Spalten, um die Ergebnisse zu speichern.
// 5 Zeilen: Employees, Revenues, Investment, Downward Revision, Log Revision Ratio
// 3 Spalten: Mean(Treated), Mean(Control), p-value(T-Test)
mat M = J(5,3,.)

// Definition der "Treated"-Gruppe für die Balance-Tabelle:
// Firmen, die im nächsten Jahr (t0) eine Steuererhöhung haben (F1_taxhike == 1),
// aber im aktuellen Jahr (t-1) selbst noch keine Steuererhöhung haben (taxhike == 0).
// Die Charakteristika werden für dieses t-1 gemessen.

// Definition der "Control"-Gruppe für die Balance-Tabelle:
// Firmen, die im nächsten Jahr (t0) KEINE Steuererhöhung haben (F1_taxhike == 0),
// und im aktuellen Jahr (t-1) auch keine Steuererhöhung haben (taxhike == 0).
// Die Charakteristika werden für dieses t-1 gemessen.

local r = 1 // Zeilenzähler für die Matrix M

// Schleife über die zu vergleichenden Variablen
// WICHTIG: Die Variablen besch_lj, rev_k, reali_inv_k sind im Datensatz "last year's" values.
// Wenn die Analyse für das Event in t0 ist, und wir t-1 Charakteristika wollen,
// dann sind das die Werte von besch_lj etc. aus der Beobachtung des Jahres t-1.
// Die Outcome-Variablen down_dummy und logdiff in der Beobachtung t-1 beziehen sich
// auf die Revision des Plans, der in t-2 für t-1 gemacht wurde.
foreach var in besch_lj rev_k reali_inv_k down_dummy logdiff {

    // Mittelwert für die "Treated"-Gruppe (die in t0 behandelt werden, Werte aus t-1)
    // Die Bedingung ist: F1_taxhike == 1 (Event in t+1, also aktuelle Periode ist t-1)
    // UND taxhike == 0 (kein Event in der aktuellen Periode t-1 selbst)
    sum `var' if F1_taxhike == 1 & taxhike == 0 , d
    mat M[`r',1] = round(r(mean),0.01)

    // Mittelwert für die "Control"-Gruppe (die in t0 NICHT behandelt werden, Werte aus t-1)
    // Die Bedingung ist: F1_taxhike == 0 (kein Event in t+1)
    // UND taxhike == 0 (kein Event in der aktuellen Periode t-1 selbst)
    sum `var' if F1_taxhike == 0 & taxhike == 0 , d
    mat M[`r',2] = round(r(mean),0.01)

    // T-Test für den Mittelwertunterschied zwischen Treated und Control in t-1
    // Die Gruppierungsvariable für den ttest ist F1_taxhike.
    // Wir betrachten nur Beobachtungen, die im aktuellen Jahr t-1 selbst kein Treatment haben (taxhike != 1 oder taxhike == 0).
    ttest `var' if taxhike == 0 , by(F1_taxhike) // F1_taxhike definiert die Gruppen (zukünftig treated vs. zukünftig control)
                                                // für das Jahr t-1 (da taxhike==0)
    mat M[`r',3] = round(r(p),0.0001) // p-Wert des T-Tests

    local r = `r' + 1 // Nächste Zeile in der Matrix
}


// Zeilen- und Spaltennamen für die Matrix M definieren
mat rownames M = "Employees" "Revenues" "Investment" "Downward Revision" "Log Revision Ratio"
mat colnames M = "Treated" "Control" "p-value"

// Matrix anzeigen (optional, zur Kontrolle)
mat list M

// Matrix M als LaTeX-Tabelle exportieren
esttab matrix(M) using "${outputpath}\tab_b3_balance_test.tex" , replace booktabs mlabel(none) label
esttab matrix(M) using "${outputpath}\tab_b3_balance_test.txt" , replace booktabs mlabel(none) label




/*
H0: Nullhypothese des t-Tests ist, dass es keinen Unterschied im Mittelwert der jeweiligen Variable (var) zwischen der Gruppe der zukünftig behandelten Firmen und der Gruppe der zukünftigen Kontrollfirmen im Pre-Treatment-Jahr PreTreat=PreCont
H1: dass es einen Unterschied im Mittelwert der jeweiligen Variable (var) zwischen der Gruppe der zukünftig behandelten Firmen und der Gruppe der zukünftigen Kontrollfirmen im Pre-Treatment-Jahr PreTreat!=PreCont
Die Tabelle B.3 liefert unterstützende Evidenz dafür, dass die Firmen, die von einer Steuererhöhung betroffen sein werden, sich im Jahr vor der Erhöhung nicht systematisch von den Kontrollfirmen unterscheiden, weder in wichtigen Firmenmerkmalen noch in den Ergebnisvariablen selbst. Das stärkt das Vertrauen in die Kausalaussagen der Studie.

 für eine valide DiD-Analyse, dass sie die Nullhypothese nicht verwerfen können. Ein hoher p-Wert (typischerweise > 0.05 oder > 0.10) würde bedeuten, dass es keine statistisch signifikanten Unterschiede zwischen den Gruppen vor dem Treatment gibt. Das ist ein gutes Zeichen dafür, dass die Gruppen vergleichbar ("balanced") sind, was die Parallel-Trends-Annahme stützt.


*/

Hallo\! Du hast eine sehr gute Frage zu dem `ttest`-Befehl und der `by()`-Option im Kontext der Tabelle B.3 von Link et al. (2024) gestellt. Diese Tabelle ist entscheidend, um die Vergleichbarkeit von Treatment- und Kontrollgruppe *vor* dem eigentlichen "Treatment" (der Steuererhöhung) zu prüfen.

Lass uns das im Detail anschauen:

**Zweck der Tabelle B.3 (Balance Statistics)**

Wie wir schon besprochen haben, dient diese Tabelle dazu zu zeigen, dass sich die Firmen, die im nächsten Jahr eine Steuererhöhung erfahren werden (zukünftige Treatmentgruppe), und die Firmen, die im nächsten Jahr keine Steuererhöhung erfahren werden (zukünftige Kontrollgruppe), in ihren beobachtbaren Eigenschaften im Jahr *vor* der Steuererhöhung ($t\_{-1}$) nicht systematisch unterscheiden. Wenn sie sich nicht unterscheiden, ist das ein gutes Zeichen für die Validität des Difference-in-Differences-Ansatzes.

**Der `ttest`-Befehl in Stata und die `by()`-Option**

Der allgemeine Stata-Befehl `ttest varname, by(groupvar)` führt einen Zwei-Stichproben-T-Test für Mittelwertunterschiede durch.

  * `varname`: Ist die Variable, deren Mittelwerte zwischen den beiden Gruppen verglichen werden sollen (z.B. Beschäftigtenzahl, Umsatz).
  * `by(groupvar)`: Dies ist die entscheidende Option. `groupvar` ist eine Variable, die genau **zwei Gruppen** definiert. Stata teilt dann die Beobachtungen basierend auf den Werten dieser `groupvar` in zwei Stichproben ein und testet, ob der Mittelwert von `varname` zwischen diesen beiden Gruppen statistisch signifikant unterschiedlich ist.

**Der spezifische Befehl bei Link et al. (2024) für Tabelle B.3:**

```stata
ttest `var' if taxhike == 0 , by(F1_taxhike)
```

Lass uns diesen Befehl auseinandernehmen:

1.  **`var`**: Dies ist ein Platzhalter (in der Schleife `foreach var in besch_lj rev_k ...`) für die jeweilige Variable, die gerade auf Balance geprüft wird (z.B. `besch_lj` für Beschäftigte).

2.  **`if taxhike == 0`**:

      * `taxhike` ist ein Dummy, der 1 ist, wenn im *aktuellen* Jahr (der aktuellen Beobachtung im Datensatz) eine Steuererhöhung stattfindet, und 0 sonst.
      * Die Bedingung `if taxhike == 0` filtert den Datensatz für den T-Test. Es werden also nur Firmen-Jahr-Beobachtungen berücksichtigt, in denen **im aktuellen Jahr keine Steuererhöhung** stattfindet.
      * **Warum ist das wichtig?** Die Autoren wollen die Gruppen im Jahr *vor* dem potenziellen Treatment ($t\_0$) vergleichen. Wenn wir also eine Beobachtung im Jahr $t\_{-1}$ betrachten, dann ist `taxhike` für diese Beobachtung (die sich auf das Jahr $t\_{-1}$ bezieht) gleich 0.

3.  **`, by(F1_taxhike)`**:

      * `F1_taxhike` ist eine **Lead-Variable**. Sie wurde so erstellt, dass `F1_taxhike` im Jahr $t\_{-1}$ den Wert 1 annimmt, wenn im *darauffolgenden* Jahr $t\_0$ eine Steuererhöhung (`taxhike == 1` in $t\_0$) stattfindet. Wenn im Jahr $t\_0$ keine Steuererhöhung stattfindet, ist `F1_taxhike` im Jahr $t\_{-1}$ gleich 0.
      * Die Option `by(F1_taxhike)` teilt also die Stichprobe (die bereits durch `if taxhike == 0` auf das "Vor-Treatment-Jahr" $t\_{-1}$ eingeschränkt wurde) in genau zwei Gruppen:
          * **Gruppe 1 (`F1_taxhike == 1`):** Das sind die Firmen, die sich im Jahr $t\_{-1}$ befinden und bei denen wir wissen, dass sie im **nächsten Jahr ($t\_0$) eine Steuererhöhung erfahren werden**. Das ist die "Treated"-Gruppe in Tabelle B.3.
          * **Gruppe 0 (`F1_taxhike == 0`):** Das sind die Firmen, die sich im Jahr $t\_{-1}$ befinden und bei denen wir wissen, dass sie im **nächsten Jahr ($t\_0$) keine Steuererhöhung erfahren werden**. Das ist die "Control"-Gruppe in Tabelle B.3.

**Was der T-Test also genau macht:**

Er nimmt alle Firmen-Jahr-Beobachtungen, die sich ein Jahr *vor* einer potenziellen Steuererhöhung befinden (`if taxhike == 0`). Dann teilt er diese Beobachtungen danach ein, ob im *darauffolgenden* Jahr tatsächlich eine Steuererhöhung stattfindet (`by(F1_taxhike)`). Schließlich vergleicht er die Mittelwerte der Variable `var` (z.B. Beschäftigte in $t\_{-1}$) zwischen diesen beiden Gruppen (den zukünftig Behandelten und den zukünftigen Kontrollen). Der p-Wert (`r(p)`) gibt dann an, wie wahrscheinlich ein so großer oder größerer Unterschied in den Mittelwerten wäre, wenn es in Wahrheit keinen Unterschied gäbe.

**Zu deinem "TODO" und deinen Treatmentgruppen (2016, 2017, 2018):**

Dein Kommentar ist sehr gut: *"Balance Statistics of Firms in Treatment And Contorl Group TABLE B3 Link -\> für einzelne treatmentgruppen 16 17 18 machen ?\! ode rbesser treatment und dann gesamt controllgruppe? vemrutlich besser da ähnlicher und ausreichend -\> siehe LInk24\! bleibe so nah wie möglich an Link24\!\!\!"*

  * **Vorgehen von Link et al.:** Link et al. machen für Tabelle B.3 **eine einzige, gepoolte Balance-Tabelle**. Ihre "Treated"-Gruppe besteht aus *allen* Firmen, die im nächsten Jahr eine Steuererhöhung erfahren, unabhängig davon, in welchem Kalenderjahr dieses "nächste Jahr" liegt. Die Charakteristika werden immer im $t\_{-1}$ relativ zu diesem spezifischen, firmeneigenen Event-Jahr gemessen.
  * **Deine Implementierung:** Um so nah wie möglich an Link et al. zu bleiben, solltest du ebenfalls eine **gepoolte Balance-Tabelle** erstellen.
      * Deine Variable `F1_taxhike` (oder `dummy_m1_taxhike` in deinem Code, wenn sie korrekt als `F1.dein_firmenspezifischer_event_indikator` erstellt wurde) macht das bereits richtig, wenn dein zugrundeliegender `taxhike`-Indikator firmenspezifisch ist (also nur 1 im Jahr 2016 für die 2016er Kohorte, nur 1 im Jahr 2017 für die 2017er Kohorte usw.).
          * Für eine Firma der 2016er Kohorte ist `F1_taxhike` im Jahr 2015 gleich 1.
          * Für eine Firma der 2017er Kohorte ist `F1_taxhike` im Jahr 2016 gleich 1.
          * Für eine Firma der 2018er Kohorte ist `F1_taxhike` im Jahr 2017 gleich 1.
          * Für eine Kontrollfirma ist `F1_taxhike` immer 0.
      * Die Bedingung `if taxhike == 0` im `ttest` stellt dann sicher, dass du für die 2016er Kohorte die Werte aus 2015 nimmst, für die 2017er Kohorte die Werte aus 2016 und für die 2018er Kohorte die Werte aus 2017 (da `taxhike` in diesen Jahren für die jeweilige Kohorte 0 ist, aber `F1_taxhike` 1 ist).
      * Die Kontrollgruppe im T-Test besteht dann aus allen Firmen-Jahr-Beobachtungen, für die `taxhike == 0` (kein aktuelles Event) UND `F1_taxhike == 0` (auch kein Event im nächsten Jahr) gilt. Das schließt deine "nie behandelten" Firmen in den relevanten Jahren ein, sowie Firmen, die erst später behandelt werden, in ihren jeweiligen Pre-Pre-Treatment-Jahren.

**Fazit für dich:**
Dein Code zur Erstellung der Tabelle B.3, so wie du ihn gepostet hast, ist **methodisch korrekt und entspricht dem Vorgehen von Link et al. (2024)**, um eine gepoolte Balance-Tabelle zu erstellen. Die `by(F1_taxhike)`-Option in Verbindung mit `if taxhike == 0` definiert die Vergleichsgruppen genau so, dass die Charakteristika im Jahr vor dem jeweiligen (kohortenspezifischen) Treatment verglichen werden. Du musst also keine separaten Balance-Tabellen für jede deiner Treatment-Kohorten erstellen, um dem Ansatz von Link et al. zu folgen.















/*
clear all
version 16

// Annahme: Globale Makros für Pfade sind definiert
// global neudatenpfad "PFAD_ZU_DEINEN_NEUEN_DATEN"
// global outputpfad "PFAD_ZU_DEINEM_OUTPUT"

use "$neudatenpfad/Temp/DiD_prep.dta", clear

// Optional: Sicherstellen, dass nur die relevanten Gruppen im Datensatz sind
// Wenn DiD_prep.dta bereits gefiltert ist, ist dieser Schritt nicht nötig.
// keep if inlist(pattern_tax, "n001000", "n000100", "n000010", "n000000")


* 1. Gesamtzahlen für das "Total Sample" (Basis für Prozentanteile)
* Diese werden auf dem aktuellen Datensatz berechnet, der die 4 Hauptgruppen enthält.
*-------------------------------------------------------------------------------
preserve
    bysort id: gen temp_first_id_total = (_n==1)
    count if temp_first_id_total
    scalar total_N_firms_sample = r(N)
    drop temp_first_id_total
    count
    scalar total_N_obs_sample = r(N)
restore
di "Total N Firms in Sample (for %): " total_N_firms_sample
di "Total N Obs in Sample (for %): " total_N_obs_sample

* 2. Matrix initialisieren
* 5 Zeilen: Treat 2016, Treat 2017, Treat 2018, Kontrolle, Total Sample
* 7 Spalten: N_ags, Mean(n_hikes), SD(n_hikes), N_firms, %_Firms, N_obs, %_Obs
*-------------------------------------------------------------------------------
matrix M = J(5,7,.)


* --- Zeile 1: Treatment 2016 (pattern_tax == "n001000") ---
di _n as yellow "Berechne Statistiken für: Treatment 2016"
preserve
    keep if pattern_tax == "n001000"
    // Spalte 1: N_ags
    bysort ags: gen temp_tag_ags = (_n==1)
    count if temp_tag_ags
    matrix M[1,1] = r(N)
    drop temp_tag_ags
    // Spalten 2 & 3: Mean/SD n_hikes
    if M[1,1] > 0 {
        duplicates drop ags, force
        qui summarize n_hikes
        matrix M[1,2] = round(r(mean), .01)
        matrix M[1,3] = round(r(sd), .01)
        if missing(M[1,3]) { matrix M[1,3] = 0 }
    }
restore
preserve
    keep if pattern_tax == "n001000"
    // Spalte 4: N_firms
    bysort id: gen temp_tag_id = (_n==1)
    count if temp_tag_id
    matrix M[1,4] = r(N)
    drop temp_tag_id
    // Spalte 5: % Firmen
    if total_N_firms_sample > 0 { matrix M[1,5] = round((M[1,4] / total_N_firms_sample) * 100, .1) }
    // Spalte 6: N_obs
    count
    matrix M[1,6] = r(N)
    // Spalte 7: % Beob.
    if total_N_obs_sample > 0 { matrix M[1,7] = round((M[1,6] / total_N_obs_sample) * 100, .1) }
restore

* --- Zeile 2: Treatment 2017 (pattern_tax == "n000100") ---
di _n as yellow "Berechne Statistiken für: Treatment 2017"
preserve
    keep if pattern_tax == "n000100"
    bysort ags: gen temp_tag_ags = (_n==1)
    count if temp_tag_ags
    matrix M[2,1] = r(N)
    drop temp_tag_ags
    if M[2,1] > 0 {
        duplicates drop ags, force
        qui summarize n_hikes
        matrix M[2,2] = round(r(mean), .01)
        matrix M[2,3] = round(r(sd), .01)
        if missing(M[2,3]) { matrix M[2,3] = 0 }
    }
restore
preserve
    keep if pattern_tax == "n000100"
    bysort id: gen temp_tag_id = (_n==1)
    count if temp_tag_id
    matrix M[2,4] = r(N)
    drop temp_tag_id
    if total_N_firms_sample > 0 { matrix M[2,5] = round((M[2,4] / total_N_firms_sample) * 100, .1) }
    count
    matrix M[2,6] = r(N)
    if total_N_obs_sample > 0 { matrix M[2,7] = round((M[2,6] / total_N_obs_sample) * 100, .1) }
restore

* --- Zeile 3: Treatment 2018 (pattern_tax == "n000010") ---
di _n as yellow "Berechne Statistiken für: Treatment 2018"
preserve
    keep if pattern_tax == "n000010"
    bysort ags: gen temp_tag_ags = (_n==1)
    count if temp_tag_ags
    matrix M[3,1] = r(N)
    drop temp_tag_ags
    if M[3,1] > 0 {
        duplicates drop ags, force
        qui summarize n_hikes
        matrix M[3,2] = round(r(mean), .01)
        matrix M[3,3] = round(r(sd), .01)
        if missing(M[3,3]) { matrix M[3,3] = 0 }
    }
restore
preserve
    keep if pattern_tax == "n000010"
    bysort id: gen temp_tag_id = (_n==1)
    count if temp_tag_id
    matrix M[3,4] = r(N)
    drop temp_tag_id
    if total_N_firms_sample > 0 { matrix M[3,5] = round((M[3,4] / total_N_firms_sample) * 100, .1) }
    count
    matrix M[3,6] = r(N)
    if total_N_obs_sample > 0 { matrix M[3,7] = round((M[3,6] / total_N_obs_sample) * 100, .1) }
restore

* --- Zeile 4: Kontrollgruppe (pattern_tax == "n000000") ---
di _n as yellow "Berechne Statistiken für: Kontrollgruppe"
preserve
    keep if pattern_tax == "n000000"
    bysort ags: gen temp_tag_ags = (_n==1)
    count if temp_tag_ags
    matrix M[4,1] = r(N)
    drop temp_tag_ags
    if M[4,1] > 0 {
        duplicates drop ags, force
        qui summarize n_hikes
        matrix M[4,2] = round(r(mean), .01)
        matrix M[4,3] = round(r(sd), .01)
        if missing(M[4,3]) { 
		matrix M[4,3] = 0 
		}
    }
restore
preserve
    keep if pattern_tax == "n000000"
    bysort id: gen temp_tag_id = (_n==1)
    count if temp_tag_id
    matrix M[4,4] = r(N)
    drop temp_tag_id
    if total_N_firms_sample > 0 { matrix M[4,5] = round((M[4,4] / total_N_firms_sample) * 100, .1) }
    count
    matrix M[4,6] = r(N)
    if total_N_obs_sample > 0 { matrix M[4,7] = round((M[4,6] / total_N_obs_sample) * 100, .1) }
restore

* --- Zeile 5: Total Sample ---
di _n as yellow "Berechne Statistiken für: Total Sample"
preserve
    // Spalte 1: N_ags (Total)
    bysort ags: gen temp_tag_ags = (_n==1)
    count if temp_tag_ags
    matrix M[5,1] = r(N)
    drop temp_tag_ags
    // Spalten 2 & 3: Mean/SD n_hikes (Total)
    if M[5,1] > 0 {
        duplicates drop ags, force
        qui summarize n_hikes
        matrix M[5,2] = round(r(mean), .01)
        matrix M[5,3] = round(r(sd), .01)
        if missing(M[5,3]) { 
		matrix M[5,3] = 0 
		}
    }
restore
// Spalte 4: N_firms (Total) - bereits in Skalar
matrix M[5,4] = total_N_firms_sample
// Spalte 5: % Firmen (Total)
if total_N_firms_sample > 0 { matrix M[5,5] = round((total_N_firms_sample / total_N_firms_sample) * 100, .1) } else { matrix M[5,5] = . }
// Spalte 6: N_obs (Total) - bereits in Skalar
matrix M[5,6] = total_N_obs_sample
// Spalte 7: % Beob. (Total)
if total_N_obs_sample > 0 { matrix M[5,7] = round((total_N_obs_sample / total_N_obs_sample) * 100, .1) } else { matrix M[5,7] = . }


* 3. Spalten- und Zeilennamen für die Matrix definieren
*-------------------------------------------------------------------------------
mat colnames M = N_AGS Mean_n_hikes SD_n_hikes N_Firms Pct_Firms N_Obs Pct_Obs
mat rownames M = "Treat 2016" "Treat 2017" "Treat 2018" "Kontrolle" "Total Sample"

* 4. Matrix zur Kontrolle anzeigen
*-------------------------------------------------------------------------------
di _n as cyan "Matrix M zur Kontrolle:"
mat list M, format(%9.2f) // Passe das Format bei Bedarf an, z.B. für ganze Zahlen bei N

* 5. Matrix als Tabelle exportieren
*-------------------------------------------------------------------------------
// Definiere Spaltentitel für esttab
local coltitles ///
    "Anzahl Gemeinden (AGS)" ///
    "Mittl. Summe Tax Hikes pro Gemeinde*" ///
    "SD Summe Tax Hikes pro Gemeinde*" ///
    "Anzahl Firmen (ID)" ///
    "% Firmen (von Total)" ///
    "Anzahl Beob. (Firma-Jahr)" ///
    "% Beob. (von Total)"

// Export für .tex mit esttab
// ssc install estout, replace // Einmalig ausführen, falls estout Paket nicht installiert ist
esttab matrix(M) using "$outputpfad/summary_stats_gruppen_matrix.tex", ///
    replace booktabs nonumbers nodepvars ///
    title("Deskriptive Statistik der Analyse-Gruppen") ///
    collabels(`coltitles') ///
    mtitles("Treatment 2016" "Treatment 2017" "Treatment 2018" "Kontrollgruppe" "Total Sample") /// // Zeilentitel
    alignment(S S S S S S S) style(tex) /// // S für siunitx-Paket (bessere Dezimalausrichtung)
    nostarnote ///
    addnotes("Anmerkungen:" ///
             "* 'Summe Tax Hikes pro Gemeinde' basiert auf der Variable n_hikes (egen n_hikes = sum(taxhike), by(ags))," ///
             "  die die Summe der Tax-Hike-Indikatoren (0/1) über alle Firma-Jahr-Beobachtungen innerhalb einer Gemeinde darstellt." ///
             "  Der Mittelwert und die SD beziehen sich auf diese gemeindespezifische Summe.")

// Export für .txt mit esttab
esttab matrix(M) using "$outputpfad/summary_stats_gruppen_matrix.txt", ///
    replace plain nonumbers nodepvars ///
    collabels(`coltitles') ///
    mtitles("Treatment 2016" "Treatment 2017" "Treatment 2018" "Kontrollgruppe" "Total Sample") ///
    nostarnote ///
    addnotes("Anmerkungen:" ///
             "* 'Summe Tax Hikes pro Gemeinde' basiert auf der Variable n_hikes (egen n_hikes = sum(taxhike), by(ags))," ///
             "  die die Summe der Tax-Hike-Indikatoren (0/1) über alle Firma-Jahr-Beobachtungen innerhalb einer Gemeinde darstellt." ///
             "  Der Mittelwert und die SD beziehen sich auf diese gemeindespezifische Summe.")

di _n as green "Deskriptive Statistik-Tabelle (Matrix-Methode) wurde erstellt und gespeichert als:"
di as yellow "$outputpfad/summary_stats_gruppen_matrix.tex"
di as yellow "$outputpfad/summary_stats_gruppen_matrix.txt"

* Aufräumen
clear scalar
exit

*/