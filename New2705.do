

/// NEU:
	
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
	
	
	
	
	
	
	
	
	
	
	
	
Du hast mehrere Möglichkeiten, eine mit `tab` (ich nehme an, du meinst den Befehl `tabulate` oder den allgemeineren `table`-Befehl) erzeugte Tabelle in Stata abzuspeichern. Die beste Methode hängt davon ab, in welchem Format du die Tabelle benötigst und wie viel Automatisierung du wünschst.

Hier sind die gängigsten Methoden:

### 1. Verwendung des Community-Contributed Befehls `tabout` (Sehr empfohlen für `tabulate`)

`tabout` ist ein sehr mächtiger und flexibler Befehl, der speziell dafür entwickelt wurde, die Ausgabe von `tabulate` (Einweg-, Zweiweg- und Mehrweg-Tabellen) in verschiedene Formate zu exportieren, wie z.B. Textdateien (CSV, Tab-delimited), LaTeX, HTML und Excel (über den Umweg einer Textdatei).

* **Installation (falls noch nicht geschehen):**
    ```stata
    ssc install tabout
    ```
* **Verwendung (Beispiele):**
    Angenommen, du möchtest eine Zweiwegtabelle von `variable1` und `variable2` erstellen.

    * **Als CSV-Datei speichern (gut für Excel):**
        ```stata
        sysuse auto, clear // Beispiel-Datensatz laden
        tabulate foreign rep78
        tabout foreign rep78 using "meine_tabelle.csv", replace ///
               c(freq col) style(csv) bt f(1) clab("Häufigkeit" "Spalten-%")
        ```
        * `using "meine_tabelle.csv"`: Gibt den Dateinamen an.
        * `replace`: Überschreibt die Datei, falls sie existiert.
        * `c(freq col)`: Zeigt absolute Häufigkeiten (`freq`) und Spaltenprozente (`col`) an. Es gibt auch `row` für Zeilenprozente und `cell` für Gesamtprozente.
        * `style(csv)`: Gibt das CSV-Format an. Andere Optionen sind `tab` (tab-delimited), `tex` (LaTeX), `html`.
        * `bt`: Fügt eine Leerzeile zwischen den Tabellenblöcken ein (nützlich für Zweiwegtabellen).
        * `f(1)`: Formatiert Prozentwerte mit einer Nachkommastelle.
        * `clab(...)`: Ändert die Spaltenüberschriften für die Statistiken.

    * **Als LaTeX-Datei speichern:**
        ```stata
        tabout foreign rep78 using "meine_tabelle.tex", replace ///
               c(freq col) style(tex) bt f(1) clab("Häufigkeit" "Spalten-%") ///
               caption("Häufigkeitstabelle von Foreign und Rep78") label
        ```
        * `style(tex)`: Gibt das LaTeX-Format an.
        * `caption(...)`: Fügt eine Tabellenüberschrift hinzu.
        * `label`: Verwendet Variablenlabels anstelle von Variablennamen, falls vorhanden.

    Lies die Hilfe für mehr Optionen: `help tabout`.

### 2. Verwendung des Community-Contributed Befehls `asdoc`

`asdoc` ist ein weiterer sehr nützlicher Befehl, der die Ausgabe vieler Stata-Befehle, einschließlich `tabulate`, in gut formatierte Tabellen in Word (RTF), Excel, LaTeX oder Textdateien exportieren kann.

* **Installation (falls noch nicht geschehen):**
    ```stata
    ssc install asdoc
    ```
* **Verwendung (Beispiele):**
    ```stata
    sysuse auto, clear // Beispiel-Datensatz laden

    * Tabelle in eine Word-Datei (RTF) speichern
    asdoc tabulate foreign rep78, save("meine_tabelle.rtf") replace title("Häufigkeitstabelle")

    * Tabelle in eine Excel-Datei speichern
    asdoc tabulate foreign rep78, save("meine_tabelle.xls") replace sheet("Meine Tabelle")
    ```
    * `save("dateiname")`: Gibt den Dateinamen und das Format an.
    * `replace`: Überschreibt die Datei.
    * `title(...)`: Fügt einen Titel hinzu.
    * `asdoc` kann vor viele Stata-Befehle gestellt werden. `help asdoc` für Details.

### 3. Verwendung einer Log-Datei (Grundlegende Stata-Funktionalität)

Dies ist eine einfache Methode, um die exakte Ausgabe, wie sie im Stata-Results-Fenster erscheint, in einer Datei zu speichern.

* **Vorgehensweise:**
    1.  Starte die Log-Datei:
        ```stata
        log using "meine_ausgabe.log", text replace
        // 'text' für eine reine Textdatei, '.smcl' für Stata's eigenes Format
        ```
    2.  Führe deinen `tabulate`- oder `table`-Befehl aus:
        ```stata
        tabulate foreign rep78, cell // Beispiel
        ```
    3.  Schließe die Log-Datei:
        ```stata
        log close
        ```
    Die Datei `meine_ausgabe.log` enthält nun die Tabellenausgabe.
* **Nachteile:** Du erhältst eine reine Textrepräsentation, die du möglicherweise noch manuell in ein anderes Format (z.B. Excel) kopieren und anpassen musst. Es ist nicht ideal für direkt importierbare Tabellen.

### 4. Stata's `collect`-Framework und der neue `table`-Befehl (Stata 17+)

Wenn du Stata 17 oder neuer verwendest, bietet das `collect`-Framework zusammen mit dem überarbeiteten `table`-Befehl eine sehr mächtige und flexible Möglichkeit, benutzerdefinierte Tabellen zu erstellen und zu exportieren.

* **Beispiel:**
    ```stata
    sysuse auto, clear
    collect: table (foreign) (rep78) // Erstellt eine Tabelle
    collect layout // Zeigt die Struktur der Tabelle
    collect export "meine_moderne_tabelle.xlsx", replace // Exportiert nach Excel
    // Weitere Exportformate wie .docx, .tex, .html, .md sind verfügbar
    ```
    Dies ist die modernste und am besten integrierte Methode in neueren Stata-Versionen.

**Empfehlung:**

* Für die Ausgabe von `tabulate`-Befehlen ist **`tabout`** oft die erste Wahl aufgrund seiner Spezialisierung und Flexibilität für diese Art von Tabellen.
* **`asdoc`** ist ein großartiger Allrounder, wenn du verschiedene Arten von Stata-Ausgaben exportieren möchtest.
* Wenn du eine neuere Stata-Version (17+) hast, ist das **`collect` Framework** sehr leistungsfähig.

Wähle die Methode, die am besten zu deinem Workflow und dem gewünschten Ausgabeformat passt. Für den Export von Häufigkeitstabellen in gängige Formate wie CSV oder LaTeX ist `tabout` sehr effizient.





Hallo! Das ist eine häufige und wichtige Aufgabe bei der Datenaufbereitung und -analyse. In Stata gibt es mehrere Wege, um zu prüfen, ob zwei Spalten identische Werte haben und um das Ausmaß der Abweichungen zu quantifizieren.

Hier ist eine schrittweise Anleitung mit den entsprechenden Stata-Befehlen:

Angenommen, deine beiden Spalten heißen `spalte_original` (die ursprünglichen Werte) und `spalte_eigen` (deine eigene Berechnung).

---
### Teil 1: Überprüfen auf identische Werte
---

1.  **Der Befehl `compare` (Empfohlen als erster Schritt):**
    Der einfachste und oft informativste erste Schritt ist der Befehl `compare`. Er gibt eine Zusammenfassung der Unterschiede, einschließlich der Anzahl der Abweichungen und wie mit fehlenden Werten umgegangen wird.

    ```stata
    compare spalte_original spalte_eigen
    ```
    Die Ausgabe zeigt dir:
    * Anzahl der Beobachtungen, in denen sich die Werte unterscheiden.
    * Anzahl der Beobachtungen mit fehlenden Werten in einer oder beiden Spalten.
    * Wenn alles identisch ist (und keine unerwarteten fehlenden Werte vorliegen), wird dies klar angezeigt.

2.  **Erstellen einer Differenzvariable und Zusammenfassen:**
    Wenn die Spalten numerisch sind, kannst du eine Differenz bilden. Wenn alle nicht-fehlenden Werte identisch sind, sollte die Differenz überall null sein (wo beide Spalten Werte haben).

    ```stata
    gen differenz_check = spalte_original - spalte_eigen
    summarize differenz_check
    ```
    * Wenn `min`, `max`, `mean` und `sd` (Standardabweichung) alle `0` sind (oder sehr nahe bei `0` aufgrund von Fließkommagenauigkeit), dann sind die numerischen Werte (wo beide Spalten nicht-fehlend sind) identisch.
    * Achte auf die Anzahl der Beobachtungen (`Obs`) bei `summarize`.

3.  **Erstellen einer Indikatorvariable für Identität:**
    Du kannst eine Variable erstellen, die anzeigt, ob die Werte in jeder Zeile übereinstimmen.

    ```stata
    gen sind_identisch = (spalte_original == spalte_eigen)
    tabulate sind_identisch
    ```
    * `sind_identisch` ist `1`, wenn die Werte gleich sind (oder beide fehlend sind, da `.` == `.` in Stata wahr ist), und `0`, wenn sie unterschiedlich sind.
    * **Umgang mit fehlenden Werten:** Wenn du Fälle ausschließen möchtest, in denen mindestens ein Wert fehlt, oder eine genauere Unterscheidung möchtest:
        ```stata
        gen vergleich_status = 0 if spalte_original == spalte_eigen & !missing(spalte_original) & !missing(spalte_eigen) // Identisch, nicht fehlend
        replace vergleich_status = 1 if spalte_original != spalte_eigen & !missing(spalte_original) & !missing(spalte_eigen) // Unterschiedlich, nicht fehlend
        replace vergleich_status = 2 if missing(spalte_original) & !missing(spalte_eigen) // Original fehlend, Eigen nicht
        replace vergleich_status = 3 if !missing(spalte_original) & missing(spalte_eigen) // Original nicht fehlend, Eigen schon
        replace vergleich_status = 4 if missing(spalte_original) & missing(spalte_eigen) // Beide fehlend
        label define status_label 0 "Identisch (nicht fehlend)" 1 "Unterschiedlich (nicht fehlend)" 2 "Original fehlt" 3 "Eigen fehlt" 4 "Beide fehlen"
        label values vergleich_status status_label
        tabulate vergleich_status
        ```

4.  **Der Befehl `assert` für strikte Prüfungen:**
    Wenn du sicherstellen willst, dass alle Werte (unter bestimmten Bedingungen) identisch sind und das Skript bei einer Abweichung anhalten soll:
    ```stata
    assert spalte_original == spalte_eigen
    ```
    * Dieser Befehl gibt eine Fehlermeldung aus und stoppt die Ausführung, wenn eine Ungleichheit gefunden wird (beachte, dass `.` == `.` als wahr gilt).
    * Um nur nicht-fehlende Werte zu vergleichen:
        ```stata
        assert spalte_original == spalte_eigen if !missing(spalte_original) & !missing(spalte_eigen)
        ```

---
### Teil 2: Quantifizieren der Abweichung (wenn die Spalten nicht identisch sind)
---

Wenn die Spalten numerisch sind und sich unterscheiden, möchtest du wahrscheinlich das Ausmaß dieser Unterschiede verstehen.

1.  **Berechnung der Differenz:**
    (Diese Variable hast du vielleicht schon aus Schritt 1.2)
    ```stata
    gen abweichung = spalte_eigen - spalte_original
    ```
    Die Reihenfolge (`spalte_eigen - spalte_original` oder umgekehrt) bestimmt das Vorzeichen der Abweichung.

2.  **Detaillierte Zusammenfassung der Abweichungen:**
    ```stata
    summarize abweichung, detail
    ```
    Diese Ausgabe ist sehr informativ:
    * `Mean`: Durchschnittliche Abweichung. Ist sie nahe Null? Gibt es eine systematische Über- oder Unterschätzung?
    * `Std. Dev.`: Standardabweichung der Abweichungen – ein Maß für die Streuung der Unterschiede.
    * `Min`, `Max`: Die kleinsten und größten Abweichungen.
    * `Percentiles` (z.B. p1, p5, p25, p50 (Median), p75, p95, p99): Zeigen die Verteilung der Abweichungen und helfen, extreme Ausreißer zu identifizieren.

3.  **Absolute Abweichung:**
    Wenn dich nur die Größe der Abweichung interessiert, nicht die Richtung:
    ```stata
    gen abs_abweichung = abs(spalte_eigen - spalte_original)
    summarize abs_abweichung, detail
    ```
    Der Mittelwert der `abs_abweichung` ist die mittlere absolute Abweichung.

4.  **Prozentuale Abweichung (mit Vorsicht verwenden):**
    Wenn die Werte in `spalte_original` typischerweise positiv und nicht nahe Null sind:
    ```stata
    gen prozent_abweichung = (spalte_eigen - spalte_original) / spalte_original * 100 ///
                           if spalte_original != 0 & !missing(spalte_original) & !missing(spalte_eigen)
    summarize prozent_abweichung, detail
    ```
    Vorsicht bei Werten von `spalte_original` nahe Null, da dies zu extremen prozentualen Abweichungen führen kann.

5.  **Visualisierung der Abweichungen:**
    * **Histogramm der Abweichungen:**
        ```stata
        histogram abweichung, bin(50) normal // `bin(50)` ist nur ein Beispiel
        ```
        Zeigt die Verteilung der Unterschiede. Ist sie symmetrisch um Null? Gibt es Ausreißer?
    * **Streudiagramm (Scatter Plot):**
        ```stata
        scatter spalte_eigen spalte_original || function y=x, legend(label(2 "Identitätslinie (y=x)")) ytitle("Eigene Berechnung") xtitle("Originalwerte")
        ```
        Wenn die Werte identisch wären, würden alle Punkte auf der roten Linie `y=x` liegen. Abweichungen von dieser Linie zeigen Unterschiede.
    * **Bland-Altman-Plot (Differenzplot):**
        Sehr nützlich, um zu sehen, ob die Abweichung von der Größenordnung der Messwerte abhängt.
        ```stata
        gen durchschnitt_werte = (spalte_eigen + spalte_original) / 2
        scatter abweichung durchschnitt_werte, yline(0) ytitle("Differenz (Eigen - Original)") xtitle("Durchschnitt der beiden Werte")
        ```

6.  **Auflisten von Beobachtungen mit (großen) Abweichungen:**
    Um spezifische Fälle zu untersuchen:
    ```stata
    list id spalte_original spalte_eigen abweichung if abs_abweichung > X // Ersetze X durch einen relevanten Schwellenwert
    // Oder sortiere nach der Abweichung, um die größten zu sehen:
    sort abs_abweichung
    list id spalte_original spalte_eigen abweichung in -20/l // Zeigt die 20 Fälle mit der größten absoluten Abweichung
    ```
    (Vorausgesetzt, du hast eine ID-Variable `id`).

Wähle die Methoden, die für deine spezifische Fragestellung und die Art deiner Daten (numerisch, string, kategorial) am besten geeignet sind. Für einen ersten Überblick ist `compare` oft unschlagbar. Für die Quantifizierung numerischer Unterschiede ist `summarize abweichung, detail` zentral.
Um in Stata zu überprüfen, ob zwei Spalten (Variablen) identische Werte haben und um das Ausmaß von Abweichungen zu quantifizieren, gibt es mehrere Ansätze. Angenommen, deine neu berechnete Spalte heißt `meine_berechnung` und die Spalte mit den Ursprungswerten heißt `ursprungswerte`.

---
### Teil 1: Überprüfen auf identische Werte

1.  **Der `compare`-Befehl (empfohlen für einen ersten Überblick):**
    Stata hat einen eingebauten Befehl, der speziell dafür gedacht ist, zwei Variablen zu vergleichen.
    ```stata
    compare meine_berechnung ursprungswerte
    ```
    Dieser Befehl gibt eine Zusammenfassung aus, die zeigt:
    * Wie viele Beobachtungen übereinstimmen (`meine_berechnung == ursprungswerte`).
    * Wie viele Beobachtungen sich unterscheiden (`meine_berechnung < ursprungswerte` und `meine_berechnung > ursprungswerte`).
    * Informationen über fehlende Werte (z.B. wenn eine Variable einen Wert hat und die andere fehlt, oder wenn beide fehlen).

2.  **Erstellen einer Indikatorvariable für Unterschiede:**
    Du kannst eine neue Variable erstellen, die anzeigt, ob die Werte pro Zeile identisch sind oder nicht.
    ```stata
    gen sind_identisch = (meine_berechnung == ursprungswerte)
    tabulate sind_identisch
    ```
    * `sind_identisch` ist 1, wenn die Werte gleich sind (oder beide `.`) und 0, wenn sie unterschiedlich sind.
    * **Umgang mit fehlenden Werten (Missings):**
        * Wenn du Fälle, in denen beide Variablen fehlend sind (`.`), nicht als "identisch" betrachten möchtest oder Fälle mit mindestens einem Missing gesondert behandeln willst:
        ```stata
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
        ```

3.  **Verwendung von `assert` für strikte Prüfungen:**
    Wenn du davon ausgehst, dass die Spalten (zumindest für nicht-fehlende Werte) identisch sein *müssen*, kannst du `assert` verwenden. Stata bricht ab und gibt eine Fehlermeldung aus, wenn die Bedingung nicht erfüllt ist.
    ```stata
    assert meine_berechnung == ursprungswerte
    ```
    Oder, wenn du nur nicht-fehlende Werte vergleichen willst:
    ```stata
    assert meine_berechnung == ursprungswerte if !missing(meine_berechnung) & !missing(ursprungswerte)
    ```

---
### Teil 2: Quantifizieren der Abweichung

Wenn die Spalten nicht identisch sind, möchtest du das Ausmaß der Abweichungen verstehen.

1.  **Differenzvariable erstellen:**
    ```stata
    gen differenz = meine_berechnung - ursprungswerte
    ```

2.  **Deskriptive Statistiken der Differenz:**
    ```stata
    summarize differenz, detail
    ```
    Diese Ausgabe ist sehr informativ:
    * **Mean (Mittelwert):** Die durchschnittliche Abweichung. Ist er nahe Null?
    * **Std. Dev. (Standardabweichung):** Die Streuung der Abweichungen.
    * **Min / Max:** Die kleinsten und größten Abweichungen (zeigen extreme Ausreißer).
    * **Percentiles (z.B. p1, p5, p25, p50, p75, p95, p99):** Geben Aufschluss über die Verteilung der Abweichungen.
    * **Obs:** Anzahl der Beobachtungen, für die die Differenz berechnet werden konnte (d.h. wo keine der beiden Variablen fehlend war).

3.  **Absolute Differenz:**
    Wenn die Richtung der Abweichung (positiv oder negativ) weniger wichtig ist als ihre absolute Größe:
    ```stata
    gen abs_differenz = abs(meine_berechnung - ursprungswerte)
    summarize abs_differenz, detail
    ```
    Der Mittelwert von `abs_differenz` ist die mittlere absolute Abweichung.

4.  **Prozentuale Differenz (vorsichtig anwenden):**
    Nützlich, wenn die absolute Größe der Abweichung im Verhältnis zum Ursprungswert interpretiert werden soll. Aber Vorsicht bei Ursprungswerten nahe Null oder Null!
    ```stata
    gen prozent_differenz = (meine_berechnung - ursprungswerte) / ursprungswerte * 100 ///
                           if ursprungswerte != 0 & !missing(ursprungswerte) & !missing(meine_berechnung)
    summarize prozent_differenz, detail
    ```

5.  **Visualisierung der Abweichungen:**
    * **Histogramm der Differenzen:** Zeigt die Verteilung der Abweichungen.
        ```stata
        histogram differenz, bin(50) normal // bin(50) als Beispiel für Anzahl der Bins
        ```
    * **Streudiagramm (Scatter Plot):** Trage deine Berechnung gegen die Ursprungswerte auf. Punkte auf der 45-Grad-Linie bedeuten perfekte Übereinstimmung.
        ```stata
        scatter meine_berechnung ursprungswerte || function y=x, lcolor(red) ///
                title("Vergleich: Eigene Berechnung vs. Ursprungswerte") ///
                ytitle("Meine Berechnung") xtitle("Ursprungswerte")
        ```
    * **Bland-Altman-Plot (Differenzplot):** Trage die Differenz gegen den Durchschnitt der beiden Werte auf. Hilft zu erkennen, ob die Abweichung von der Größenordnung der Messwerte abhängt.
        ```stata
        gen durchschnitt_werte = (meine_berechnung + ursprungswerte) / 2
        scatter differenz durchschnitt_werte, ///
                yline(0, lpattern(dash) lcolor(red)) ///
                title("Differenzplot") ytitle("Differenz (Eigene - Ursprung)") ///
                xtitle("Durchschnitt (Eigene + Ursprung) / 2")
        ```

6.  **Identifizieren von Beobachtungen mit großen Abweichungen:**
    ```stata
    * Liste Beobachtungen, bei denen die absolute Differenz einen Schwellenwert überschreitet
    list id_variable meine_berechnung ursprungswerte differenz if abs_differenz > dein_schwellenwert

    * Sortiere nach der absoluten Differenz, um die größten Abweichungen zu sehen
    gsort -abs_differenz // Sortiert absteigend nach abs_differenz
    list id_variable meine_berechnung ursprungswerte differenz abs_differenz in 1/20 // Zeigt die 20 größten Abweichungen
    ```
    (Ersetze `id_variable` durch eine Variable, die deine Beobachtungen eindeutig identifiziert.)

Wähle die Methoden, die für deine spezifische Fragestellung am aussagekräftigsten sind. Der `compare`-Befehl ist oft ein guter Ausgangspunkt, gefolgt von `summarize differenz, detail` und einem Scatterplot.