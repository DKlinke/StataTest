// Schaue nochmal 04 stacke von Licht an passt meins wirklich so? ja wohl schon

// warum wird für p2 ein Effekt von null angezeigt überall?!?! done multikollinearität



// inkludiere Schleifen wie besprochen 

//-> über wz08, unterschiedlcihe fixed Effects  usw!

//

// Teste andere variablen! schau wie man truncaten asbschneiden und ersetzen und binnen kann!


// schaue v.a. ob es einen unterschied macht, dass die anderen Gruppe nicht rausgenommen werden! also n00-100 usw! wichtig! dies abzuändern! es sollen nur die richtigen treatmentgruppen enthalten bleiben. passiert das in stacked modell?




// Gespräch Inga:

// -> Inga sieht Problem bei der exogenität von Gewerbesteuererhöhung. Prüfe ob die Erhöhung von der Gewrebesteuer getrieben ist durch schlechte Haushaltslage -> Schaue dafür mal in die Realsteuerstatisti un überprüfe ob UNternhemen wirklich die Steuer erhöhen wenn die Haushaltslage schlecht ist? ISt Erhöhung wirklilch nicht exogen wie von manchen Leuten bemängelt.





// nehme die 12er mit auf also Einzelunternehmer! -> erhöht die Stichprobe evtl. merklich


// 


// später: 
//erstelle eine summary statas tabelle für eine übersicht des samples!-> Packe in Masterarbeit!

// inkludiere die anderen robusten Schätzer von Link! -> nächstes Mal!











// Comments Ideas!:


--> Ja! In vielen Fällen unterscheiden sich die Schätzer nur minimal. Ich würde erst einmal alles mit einem einfachen Schätzer machen und dann am Ende - falls noch Zeit ist - ggf. einen Robustness Check machen. Meiner Erfahrung nach macht es häufiger einen größeren Unterschied, welche Spezifikation mit welchen Kontrollvariablen man schätzt, als welchen TWFE-Schätzer man hat.
M.E. sind die Probleme mit der Spezifikation in unserem Fall ohnehin nicht so gravierend, da wir per Konstruktion keine multiplen Treatments mit heterogenen Effekten haben. 
Pragmatisch gesehen für ein künftiges Paper: Die Reviewer eines zukünftigen Papers sind Steuer-/Public-Finance-Menschen und keine Ökonometriker, d.h. man braucht ein sinnvolles Argument, warum die Chaisemartin et. al. Kritik in unserem Fall nicht relevant ist bzw. irgendeine Art von Robustness Check/zeigen, dass man das irgendwie adressiert hat. Ob das der allerkorrekteste Weg ist, fällt im Regelfall nicht auf (und Link et al haben das wahrscheinlich auch pragmatisch gelöst) - in vielen Fällen ist es quantitativ ohnehin irrelevant, welchen TWFE-Schätzer man genau genommen hat...

Ich habe die Endpunkte nicht gebinnt, aber sonst so implementiert wie bei Link24, mit zwei Pre Perioden t-2 t-1, der Treatmentperiode t0 und zwei Postperioden t1 t2 ( wobei t2 nur die Effekte der Treatmentgruppen 2017 und 2016 enthält). Ich habe noch überlegt, zusätzlich eine weitere pre periode (t-3) aufzunehmen, auch wenn das für die Treatmentgruppe 2016 dann 2013 einschließt, welches kein sauberes Beobachtungsjahr ist (siehe unten). Aber wenn der Effekt für t-3 insignifikant wäre, könnte das die Parallel Trends Assumption zusätzlich stützen,  oder?
--> Das klingt gut. Die Variante mit 2013 würde ich mal als Robustnesscheck anschauen - natürlich wäre es schön, wenn der Effekt insignifikant ist, aber das Sample ändert sich doch sehr. Das wäre nicht meine oberste Prio.




2)
Ich habe die Ergebnisse mit dieser neuen angepassten DiD Version zwischen >380 (keine vollständige Anrechnung)  und  <380 ( vollständige Anrechnung) Hebesatz Gemeinden verglichen (ich schaue mir nur Personengesellschaften an und habe noch mehr Variablen aus der Gewerbesteuerstatistik eingefügt):
 
>380 (keine vollständige Anrechnung):
ln_afa_ubwg:    t1: positiv*  (AfA auf unbewegliche Wirtschaftsgüter (Grundstücke und gebäude) aus der EÜR, n = ca. 2500)
 
sonst finde ich keine sign. post effekte
 
<380 (vollständige Anrechnung):
ln_abggewer:    t0: negativ**   (abgerundeter Gewerbeertrag  aus Gewerbesteuerstatistik, n=ca 150 000)
 
ln_gew:               t0: negativ**   (Gewinn aus Gewerbebetrieb aus Gewerbesteuerstatistik n=ca 150 000)
                           t1: negativ**
 
ln_steub:            t1: positiv**  (Rechts- und Steuerberatung, Buchführung aus der EÜR n=ca 17000)
                             t2:positiv***

ln_afa_ubwg:     t0: positiv*** (n = ca. 3500)
                            t1: positiv**
 
g_reings:            t1: negativ** ( (Gewerbeertrag - Hinzurechnungen + Kürzungen) / Umsatz*100 aus Gewerbesteuerstatistik und Umsatzsteuerveranlagung ,n=ca. 150 000)
 
sonst finde ich keine sign. post effekte
 
 
Die Ergebnisse ergeben an und für sich Sinn, deuten aber m.E. auch darauf hin, dass ich bei der Einteilung in keine Anrechnung bzw. Anrechnung etwas vertauscht haben könnte (da die Effekte genau andersrum zu erwarten gewesen wären: wo keine vollständige Anrechnung möglich ist sollte ich den Effekt einer Erhöhung eher spüren). Ich bin den Code am GWAP mehrmals durchgangen habe aber keine Verwechslung gefunden. Sobald ich den Code heute zugeschickt bekomme, schaue ich mir das nochmal an und schicke ein Update.
--> Das sieht schon einmal viel plausibler aus! Allerdings wundert es mich ebenfalls, wie herum die Effekte auftreten. Es macht sicher Sinn, den Code noch einmal anzuschauen.
Treten irgendwo quantitativ relevante, aber insignifikante Effekte auf? Das könnte etwas sein, wo man eine Subgruppenanalyse machen könnte.
Ist n bei >380 bei allen Variablen deutlich geringer? Dann liegt die fehlende Signifikanz vielleicht an der Sample Size?
Ich könnte mir außerdem vorstellen, dass sich in Gemeinden mit >380 systematisch andere Branchen befinden als mit <380. Vielleicht erklärt das einen Teil der Differenz? --> Da wäre wieder ein Loop über die Branchen spannend. Zukünftiger Ansatz (keine Prio für Masterarbeit, aber zukünftig relevant, wenn wir ein Paper daraus machen): Triple Diff mit >380 vs <380 --> da könnten wir gemeinsame Branchen-FEs etc. für beide Gruppen schätzen.
@Simon: An was orientieren sich die Kosten für Steuerberatung? Ist das nach Stundensätzen/Aufwand oder hängt das in irgendeiner Form an der Steuerlast o.ä.?

Bzgl. eines Zoomtreffens bei den Uhrzeiten bin ich flexibel und spontan. Ich denke allerdings, dass ich erstmal nochmal an den GWAP schauen sollte um die Effekte besser zu verstehen/wirklich sicher zu gehen. Falls mein Termin am Do genehmigt wird, können wir uns gerne ab Freitag zusammenschalten. 
--> Super, wie wäre es Montag, z.B. vormittags um 10.30 oder 11? Simon, magst du auch dazu kommen? Wie gesagt: Keine 100%ige Garantie, dass ich die exakte Uhrzeit hinbekomme, aber vormittags sitzt Lennart gerne mal schlafend in der Trage und die Chancen auf ein halbwegs ungestörtes Meeting stehen gut :-)



*########################################################################

**To-Do-Liste GWAP-Bearbeitung**

**Priorität 1: Grundlegende Überprüfungen & Datenintegrität**

1.  **Code-Überprüfung (>380 vs. <380 Hebesatz):**
    * Dringend den Code überprüfen, der die Gemeinden in "keine vollständige Anrechnung" (>380) und "vollständige Anrechnung" (<380) einteilt. Die aktuellen Ergebnisse deuten auf eine mögliche Vertauschung hin, da die Effekte gegenteilig zu den Erwartungen ausfallen.
2.  **Datenquelle EÜR vs. Gewerbesteuerstatistik:**
    * **Dringend testen:** Ergebnisse mit Variablen aus der **Gewerbesteuerstatistik** überprüfen und vergleichen, anstatt oder ergänzend zur EÜR. Es besteht der Verdacht, dass die EÜR-Datenqualität problematisch sein könnte oder ein Merge-Fehler vorliegt. Dies betrifft insbesondere Gewinnvariablen.
3.  **ID-Fixed Effects (ID-FEs):**
    * Sicherstellen, dass ID-FEs in den Schätzungen enthalten sind.

**Priorität 2: Modell & Spezifikation (TWFE/DiD)**

4.  **Hauptanalyse (TWFE analog Link 2024):**
    * Vorerst bei der aktuellen TWFE-Spezifikation bleiben, die sich an Link 2024 orientiert.
5.  **Event Study Implementierung:**
    * **Überprüfen:** Sicherstellen, dass die aktuelle Implementierung methodisch einer korrekten Event Study entspricht.
    * **Endpunkte anpassen:** Das Paper von Siegloch/Schmidheiny (2021) zur Adjustierung der Endpunkte in Event Studies prüfen und ggf. implementieren.
    * **Pre-Perioden:** Aktuell t-2, t-1. Die Aufnahme einer weiteren Pre-Periode (t-3) als Robustness Check in Betracht ziehen (niedrigere Priorität, da das Sample sich ändert und 2013 kein "sauberes" Jahr ist).
6.  **Robustness Checks für TWFE (später, falls Zeit):**
    * Robustere Schätzer wie `did_imputation` oder `eventstudyinteract` für einen späteren Robustness Check im Hinterkopf behalten.
    * Argumentation vorbereiten, warum die Kritik von de Chaisemartin et al. im spezifischen Kontext deiner Arbeit (z.B. keine multiplen Treatments mit heterogenen Effekten) möglicherweise weniger gravierend ist.

**Priorität 3: Fixed Effects & Outcome-Variablen-Anpassung**

7.  **Fixed Effects Variation:**
    * **WZ-Ebenen:** Eine Schleife implementieren, um die FE auf verschiedenen WZ-Ebenen zu schätzen (insbesondere **WZ-2-Steller** ausprobieren, da dies näher an Link 2024 ist und um zu sehen, ob sich Ergebnisse ändern).
    * **Regionale Ebene:** Zusätzlich `jahr X regionale Ebene` Fixed Effects testen (analog zu Lichter et al. 2025).
8.  **Outcome-Variablen Variation (Outlier-Prüfung):**
    * Eine Schleife implementieren, um verschiedene Varianten der Outcome-Variablen zu testen:
        * Winsorizing.
        * Entfernen der obersten und untersten Perzentile.
        * Ziel: Prüfen, ob komische Ergebnisse von Outliern getrieben werden.

**Priorität 4: Subgruppenanalysen & Detailuntersuchungen**

9.  **Branchenspezifische Effekte:**
    * Eine Schleife über die WZ-2-Steller (oder andere relevante Ebenen) laufen lassen, um zu prüfen, ob die (unerwarteten) Ergebnisse von einzelnen Branchen getrieben werden. Dies ist auch relevant für den Vergleich >380 vs. <380.
10. **Analyse der Gruppe mit Hebesatz <= 380:**
    * Genauer untersuchen, ob bei dieser Gruppe (die als Kontrollgruppe dienen könnte) ein anderer oder der gleiche Effekt auftritt wie im bisherigen Sample.
11. **Sample Size in der Gruppe >380:**
    * Prüfen, ob die möglicherweise geringere Fallzahl (n) bei den Variablen für die Gruppe >380 die fehlende Signifikanz erklärt.
12. **Quantitativ relevante, aber insignifikante Effekte:**
    * Ausschau halten nach Effekten, die quantitativ relevant, aber (knapp) insignifikant sind. Diese könnten Ansatzpunkte für weitere Subgruppenanalysen sein.
13. **Kapitalgesellschaften:**
    * **Gewinnvariable:** Eine Gewinnvariable aus der Gewerbesteuerstatistik für Kapitalgesellschaften anschauen.
    * **Sample-Prüfung:** Überprüfen, ob Kapitalgesellschaften möglicherweise versehentlich größtenteils aus dem Datensatz gefallen sind, da die Beobachtungszahl sehr gering ist.

**Priorität 5: Interpretation & Dokumentation für die Masterarbeit**

14. **Fokus der Arbeit:**
    * Den Fokus auf Personengesellschaften beibehalten.
15. **Ergebnisdarstellung:**
    * Einen Überblick über die Gesamtergebnisse geben.
    * Diskutieren, wo Effekte gefunden werden und wo nicht.
    * Herausarbeiten, wo Ergebnisse der bestehenden Literatur widersprechen.
    * **Transparenz:** Jegliche "verwirrende" oder unerwartete Ergebnisse sowie die treibenden Subgruppen (z.B. spezifische Treatmentjahre) klar und transparent dokumentieren. Dies ist für eine Masterarbeit unproblematisch.
16. **Begründung des Vorgehens:**
    * Modellaufbau und Auswahl von Gruppen weiterhin an Papern wie Link et al. (2024) und Fuest et al. (2018 – mit Vorsicht wg. Alter) orientieren und dies begründen.

**Sonstiges / Administratives**

17. **Vorbereitung auf das Meeting mit Prof. Krolage (und Simon):**
    * Termin: Montag, 10:30 oder 11:00 Uhr (Flexibilität bei der genauen Uhrzeit beachten).
    * Bis dahin idealerweise erste Ergebnisse der Code-Überprüfung (>380 vs. <380) und ggf. erste Tests mit Gewerbesteuerdaten haben.
18. **Zukünftige Überlegung (für Paper, nicht Prio MA):**
    * Triple Difference (Triple Diff) Ansatz für den Vergleich >380 vs. <380 mit gemeinsamen Branchen-FEs.

Diese Liste sollte dir helfen, die nächsten Schritte strukturiert anzugehen. Viel Erfolg bei der weiteren Bearbeitung!



*########################################################################


Ja, schauen wir uns die Liste deiner Ado-Files an.

Für das direkte Winsorizing oder das Abschneiden von Variablen (Trimming) ist keines der genannten Ado-Files *primär* oder *alleinstehend* als Standardwerkzeug bekannt, wie es beispielsweise `reghdfe` für Fixed-Effects-Regressionen ist. Einige der Tools könnten zwar Funktionen enthalten, die man dafür als Bausteine verwenden könnte (z.B. `fastxtile` oder Funktionen aus `egenmore` zur Berechnung von Perzentilen), aber es gibt kein Ado wie `winsorize_variable varname, ends(1 99)` in deiner Liste.

Daher ist es am besten, dies mit Standard-Stata-Befehlen umzusetzen, was sehr flexibel und transparent ist.

Hier ist einfach zu implementierender Stata-Code, den du verwenden kannst:

**Annahmen:**

  * Du möchtest eine Variable namens `meine_variable` bearbeiten.
  * Du möchtest beispielsweise am 1. und 99. Perzentil winsorisieren oder trimmen.

**1. Winsorizing (Werte an den Perzentilen "kappen")**

Beim Winsorizing werden extreme Werte nicht entfernt, sondern auf einen bestimmten Perzentilwert gesetzt. Zuerst definieren wir die Perzentile (z.B. 1% und 99%).

```stata
* Variable, die winsorized werden soll: meine_variable
* Perzentile: 1% und 99%

* Schritt 1: Die Perzentilwerte bestimmen
summarize meine_variable, detail

* Die relevanten Perzentilwerte aus dem r()-Return speichern
local p1 = r(p1)
local p99 = r(p99)

* Schritt 2: Eine neue Variable erstellen, die die winsorized Werte enthält
* Es ist gute Praxis, die Originalvariable nicht direkt zu überschreiben
generate meine_variable_winsorized = meine_variable

* Schritt 3: Werte unterhalb des unteren Perzentils auf das untere Perzentil setzen
replace meine_variable_winsorized = `p1' if meine_variable < `p1' & !missing(meine_variable)

* Schritt 4: Werte oberhalb des oberen Perzentils auf das obere Perzentil setzen
replace meine_variable_winsorized = `p99' if meine_variable > `p99' & !missing(meine_variable)

* Zur Kontrolle die neue Variable anschauen
summarize meine_variable meine_variable_winsorized
```

**Erläuterung:**

  * `summarize meine_variable, detail`: Dieser Befehl berechnet detaillierte Statistiken, einschließlich verschiedener Perzentile. Die Ergebnisse werden temporär in `r()` gespeichert.
  * `local p1 = r(p1)`: Speichert das 1. Perzentil (p1) in einem lokalen Makro `p1`.
  * `local p99 = r(p99)`: Speichert das 99. Perzentil (p99) in einem lokalen Makro `p99`.
  * `generate meine_variable_winsorized = meine_variable`: Erstellt eine Kopie deiner Variable.
  * `replace ... if ... & !missing(meine_variable)`: Ersetzt die Werte. Der Zusatz `& !missing(meine_variable)` stellt sicher, dass fehlende Werte nicht fälschlicherweise durch die Perzentilwerte ersetzt werden.

**Alternative mit `centile` (falls man spezifische Perzentile braucht, die `summarize, detail` nicht direkt ausgibt):**

```stata
* Alternative, falls man andere Perzentile als die Standard p1, p5, p10 etc. braucht
centile meine_variable, centile(1 99)
local p1_alt = r(c_1)
local p99_alt = r(c_2)

* Dann weiter wie oben mit den `replace` Befehlen und diesen lokalen Makros
```

**2. Trimming (Werte an den Perzentilen abschneiden/entfernen)**

Beim Trimming werden extreme Werte entfernt, d.h. auf "missing" gesetzt.

```stata
* Variable, die getrimmt werden soll: meine_variable
* Perzentile: 1% und 99%

* Schritt 1: Die Perzentilwerte bestimmen (falls noch nicht geschehen)
summarize meine_variable, detail
local p1 = r(p1)
local p99 = r(p99)

* Schritt 2: Eine neue Variable erstellen, die die getrimmten Werte enthält
generate meine_variable_trimmed = meine_variable

* Schritt 3: Werte unterhalb des unteren Perzentils auf missing setzen
replace meine_variable_trimmed = . if meine_variable < `p1' & !missing(meine_variable)

* Schritt 4: Werte oberhalb des oberen Perzentils auf missing setzen
replace meine_variable_trimmed = . if meine_variable > `p99' & !missing(meine_variable)

* Zur Kontrolle die neue Variable anschauen
summarize meine_variable meine_variable_trimmed
codebook meine_variable_trimmed // Zeigt auch die Anzahl der missing values
```

**Wichtige Hinweise:**

  * **Immer Kopien erstellen:** Modifiziere nicht direkt deine Originalvariablen, sondern erstelle immer eine neue Variable (z.B. mit dem Suffix `_winsorized` oder `_trimmed`). So kannst du immer auf die Originaldaten zurückgreifen.
  * **Perzentile anpassen:** Du kannst die Perzentile leicht anpassen, indem du z.B. `r(p5)` und `r(p95)` für das 5. und 95. Perzentil verwendest oder `centile` mit den gewünschten Werten.
  * **Dokumentation:** Dokumentiere in deinem Do-File genau, welche Variablen du wie und an welchen Perzentilen winsorized oder getrimmt hast. Dies ist entscheidend für die Replizierbarkeit und Nachvollziehbarkeit deiner Ergebnisse.
  * **Subgruppen:** Wenn du das Winsorizing/Trimming für bestimmte Subgruppen separat durchführen möchtest (z.B. pro Jahr oder pro Branche), musst du die Perzentile innerhalb dieser Subgruppen berechnen. Dies geht z.B. mit `bysort gruppenvariable: summarize ...` und dann entsprechend die `replace` Befehle anpassen oder eine Schleife verwenden.

Dieser direkte Ansatz mit `summarize, detail` (oder `centile`) und `replace` ist sehr verbreitet, einfach zu verstehen und gibt dir volle Kontrolle über den Prozess.