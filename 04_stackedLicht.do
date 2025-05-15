*-------------------------------------------------------------------------------------------------------------------
*   Project Title: THE DETERMINANTS OF TAX COMPLIANCE
*	Code: Analyze full_gwap.dta
/* 
 .do 

*/
*-------------------------------------------------------------------------------------------------------------------
*	-------------------------------------------------------------------------------------------------------------------
*	----
*	----	Block 1 :  Vorbereitung
*	----
*	-------------------------------------------------------------------------------------------------------------------
gen cohortjahr =.
replace cohortjahr = 0 if inlist(pattern_tax,"n000000")
replace cohortjahr = 2017 if inlist(pattern_tax,"n000100")
replace cohortjahr = 2018 if inlist(pattern_tax,"n000010")
replace cohortjahr = 2016 if inlist(pattern_tax,"n001000")

sort id jahr 
xtset id jahr


foreach v in taxhike  {  //taxchange ggf. hinzufügen 
 // Leads
 gen dummy_m2_`v' = F2.`v'
 gen dummy_m1_`v' = F1.`v'

 // Lags
 gen dummy_0_`v' = L0.`v'
 gen dummy_p1_`v' = L1.`v'
 gen dummy_p2_`v' = L2.`v'
 
 replace dummy_m1_`v' = 0	// reference period
}


// Optional fehelnde Werte an Rändern zu null machen (hier nur für 2018 treatmentgruppe relevant) -> sinnvoll oder besser auf missing setzen? 0 verzerrt vermutlich den Effekt?
foreach var in dummy_m2_taxhike dummy_m1_taxhike dummy_0_taxhike dummy_p1_taxhike dummy_p2_taxhike {
	replace `var' = 0 if missing(`var')
}

/*
foreach var in dummy_m2_taxchange dummy_m1_taxchange dummy_0_taxchange dummy_p1_taxchange dummy_p2_taxchange {
	replace `var' = 0 if missing(`var')
}
*/

// Dummys

*global x_lbt_hike  i.dummy_m2_taxhike i.dummy_0_taxhike i.dummy_p1_taxhike i.dummy_p2_taxhike
global x_lbt_hike c.dummy_m2_taxhike c.dummy_m1_taxhike c.dummy_0_taxhike c.dummy_p1_taxhike c.dummy_p2_taxhike   // u.a. c. statt i. damit die Variablen nicht umbenannt werden müssen 
// tbd: global x_lbt_change

// Fixed Effects
global fixed_effects1 "id jahr_X_bundesland jahr_X_industry"
global fixed_effects2 "id jahr_X_bundesland jahr_X_industry2"
global fixed_effects3 "id jahr_X_county jahr_X_industry"
// Füge noch weitere fixed Effects auf county Ebene ein. 
// Füge ggf. noch industry4 steller Fixed effects ein

// Globales Makro, das die NAMEN der FE-Globals enthält
global fe_spec_names "fixed_effects1 fixed_effects2 fixed_effects3"

*##################################################################################################################################################################################################
	global dependent_vars "ln_stpfgew ln_e_persausg "           //#
*##################################################################################################################################################################################################

*	-------------------------------------------------------------------------------------------------------------------
*	----
*	----	Block 2.A :  Schleife über Fixed Effects Spezifikation persbigger ==1
*	----
*	------------------------------------------------------------------------------------------------------------------- 

foreach fe in $fe_spec_names {
    
    di _newline(2) as result "*** Running Analysis with Fixed Effects Specification: `fe' "
	
	// Innere Schleife über abhängige Variablen
    foreach depvar of global dependent_vars {
	
		display "Schätze Event Study für Outcome: `depvar' mit `fe'"
		eststo clear 
	 
		capture reghdfe `depvar' $x_lbt_hike if persbigger380 == 1, absorb(${`fe'}) vce(cluster ags)
		
			if _rc == 0 {
			
			 // Name für die Speicherung der Schätzung
            estimates store store_`depvar' 

            display "*** Erstelle EventStudyPlot für `depvar' mit `fe' ***"

			
			// Dateiname
            local plot_filename "$outputpfad/EventStudy_stacked_`depvar'_`fe'.png"
            // Titel und Note im Plot anpassen
            local plot_title_main "Event Study: Effect on `depvar'"
            local plot_note_fe_detail "Using FE: `fe'."

            coefplot store_`depvar' ///
                , keep(dummy_m2_taxhike dummy_m1_taxhike dummy_0_taxhike dummy_p1_taxhike dummy_p2_taxhike) ///
                coeflabels(dummy_m2_taxhike="-2" dummy_m1_taxhike="-1" dummy_0_taxhike="0" dummy_p1_taxhike="1" dummy_p2_taxhike="2") ///
                omitted ///
                vert ///
                connect(L) ///
                yline(0,lcolor(black) lpattern(dash) lwidth(thin)) ///
                xline(2.8, lcolor("black") lwidth(thin)) /// 
                ytitle("Point Estimate (Relative to t = -1)") ///
                xtitle("Years Relative to the Tax Reform") ///
                legend(off) ///
                ciopts(recast(rcap) color(%70)) ///
                mcolor(%70) ///
                msymbol(O) ///
                graphregion(color(white)) ///
                title("`plot_title_main'", size(medium)) ///  
                note("95% CIs. SEs clustered at AGS level." /// 
                "For 2018 cohort, effect ends at t+1. Fixed Effects:`fe'", size(vsmall) span)

            graph export "`plot_filename'", replace width(1000)
            di as text " -> Plot gespeichert als `plot_filename'"

           

        } // Ende if _rc == 0
        else {
            di as error "ERROR: Failed to estimate model for DV: `depvar' with `fe'. Skipping."
        }
		
		
    }
	
	// Liste der erfolgreich gespeicherten Schätzungen für die aktuelle FE-Spezifikation
    local estimates_list_for_current_fe ""
    foreach depvar of global dependent_vars {
        capture estimates describe store_`depvar'
        if _rc == 0 {
            local estimates_list_for_current_fe "`estimates_list_for_current_fe' store_`depvar'"
        }
    }

    // Regressionstabelle für die aktuelle FE-Spezifikation erstellen (wenn Ergebnisse existieren)
    if "`estimates_list_for_current_fe'" != "" {
        di "--- Creating tables for FE Specification: `fe' ---"

        // Basis-Dateiname für Tabelle anpassen, Titel und Notizen für Tabelle anpassen
        local table_filename_base "$outputpfad/EventStudy_stacked_`fe'"
        local table_title_main "Stacked Event Study (TWFE DiD)"
        local tex_notes_fe_detail "Fixed Effects (`fe')"

        // TXT Tabelle erstellen
        esttab `estimates_list_for_current_fe' using "`table_filename_base'.txt", ///
            replace wide plain b(2) se(2) star(* 0.10 ** 0.05 *** 0.01) ///
            title("`table_title_main'") nonumbers stats(N, fmt(%9.0gc) labels("Observations")) ///
            addnotes("Notes: `tex_notes_fe_detail' Clustered SEs (AGS) in parentheses. Significance: * p<0.10, ** p<0.05, *** p<0.01.")

        // TEX Tabelle erstellen
        esttab `estimates_list_for_current_fe' using "`table_filename_base'.tex", ///
            replace booktabs b(2) se(2) star(* 0.10 ** 0.05 *** 0.01) ///
            title("`table_title_main' \\label{tab:event_`fe'}") nonumbers mtitle("") ///
            stats(N, fmt(%9.0gc) labels("Observations")) ///
            addnotes("\\textit{Notes:} `tex_notes_fe_detail' Clustered SEs (AGS) in parentheses. Significance: \\sym{*} \\(p<0.10\\), \\sym{**} \\(p<0.05\\), \\sym{***} \\(p<0.01\\).")

        di "-> Tables saved as `table_filename_base'.txt and .tex"
    } // Ende if `estimates_list_for_current_fe` != ""
    else {
        di as error "--- No successful estimates found to create table for FE Spec: `fe' ---"
    }

    estimates drop `estimates_list_for_current_fe'
	
   
   
    
    di _newline(2) "--------------------------------------------------" 
}







/*	
    foreach depvar of global dependent_vars {
    // reghdfe ausführen und die Fixed Effects aus dem aktuellen globalen Makro verwenden
    // Wichtig: ${`fe_spec_name'} dereferenziert zuerst fe_spec_name (z.B. zu fixed_effects1)
    // und dann ${fixed_effects1} zum Inhalt des globalen Makros.
    reghdfe ln_stpfgew $x_lbt_hike if persbigger380 == 1, absorb($fixed_effects1) vce(cluster ags)
    }
    // Optional: Ergebnisse speichern oder anzeigen
    // estimates store `fe_spec_name'_model // Speichert das Modell unter einem Namen
    // estimates table `fe_spec_name'_model // Zeigt eine formatierte Tabelle an (wenn nur ein Modell gespeichert wird)
    
    di "--------------------------------------------------" // Trennlinie für bessere Lesbarkeit

*/


*	-------------------------------------------------------------------------------------------------------------------
*	----
*	----	Block 2.B :  Schleife über unterschiedliche Wirtschaftszweige wz08 und Firmentypen (größenklassen)
*	----
*	------------------------------------------------------------------------------------------------------------------- 

// Stelle sicher, dass die benötigten Makros definiert sind
// global fixed_effects1 "i.id i.jahr_X_bundesland i.jahr_X_industry" // Beispiel
// global x_lbt_hike "deine_x_variablen_hier" // Beispiel

// global fe_spec_names anpassen auf eine FE Kombi (Mainspecifiation) und es macht keinen Unterschied
global fe_spec_names "fixed_effects1"
tab industry_base2
levelsof industry_base2, local(sektoren) missing // Speichert alle eindeutigen Werte von windustry_base2 in dem lokalen Makro `sektoren`

/* Test
foreach sektor of local sektoren {
    
    di  "Analysiere Wirtschaftszweig (wz08): `sektor'"
    

    count if persbigger380 == 1 & wz08 == `sektor'
    

    if r(N) < 98 { 
	   di as error "Zu wenige Beob. für Sektor `sektor'"
	   continue
    }

    display  "Führe reghdfe für Sektor `sektor' aus..."
    
    // 3. Führe reghdfe für den aktuellen Sektor aus

    capture reghdfe ln_stpfgew $x_lbt_hike if persbigger380 == 1 & wz08 == `sektor', absorb($fixed_effects1) vce(cluster ags)

   

    // 4. Ergebnisse anzeigen und/oder speichern 
    if !_rc { // Prüft, ob der reghdfe-Befehl erfolgreich war (Return Code _rc == 0)
        display "Ergebnisse für Sektor `sektor':"
       estimates table, title("Ergebnisse für Sektor `sektor'") // Zeigt die aktuelle Schätzung
        
        // Speichere die Schätzergebnisse für eine spätere Vergleichstabelle
        estimates store model_wz`sektor'
        display  "Schätzergebnisse gespeichert als: model_wz`sektor'"
    } 
	else {
        di as error "Fehler bei der Schätzung für Sektor `sektor'. Return code: `_rc'"
    }

}
*/


foreach fe in $fe_spec_names {
    
	di _newline(2) as result "*** Running Analysis with Fixed Effects Specification: `fe' "
		
	foreach w of local sektoren { // Beginn industry Schleife
		
		di _newline(2) as result "*** Analysiere Wirtschaftszweig (wz08): `w'"
		
		
		// Innere Schleife über abhängige Variablen
		foreach depvar of global dependent_vars {
		
			display "Schätze Event Study für Outcome: `depvar' mit `fe' für wz08 `w' "
			eststo clear 
		 
			capture reghdfe `depvar' $x_lbt_hike if persbigger380 == 1 & wz08 == `w' , absorb(${`fe'}) vce(cluster ags)
			
				if _rc == 0 {
				
				 // Name für die Speicherung der Schätzung
				estimates store store_`depvar'_`w' 

				di  "*** Erstelle EventStudyPlot für `depvar' mit `fe' für wz08 `w' ***"

				// Dateiname
				local plot_filename "$outputpfad/EventStudy_stacked_`depvar'_`fe'_WZ_`w'.png"
				// Titel und Note im Plot anpassen
				local plot_title_main "Event Study: Effect on `depvar' in WZ `w'"
				local plot_note_fe_detail "Using FE: `fe'. Industry wz08 `w' "

				coefplot store_`depvar'_`w' ///
					, keep(dummy_m2_taxhike dummy_m1_taxhike dummy_0_taxhike dummy_p1_taxhike dummy_p2_taxhike) ///
					coeflabels(dummy_m2_taxhike="-2" dummy_m1_taxhike="-1" dummy_0_taxhike="0" dummy_p1_taxhike="1" dummy_p2_taxhike="2") ///
					omitted ///
					vert ///
					connect(L) ///
					yline(0,lcolor(black) lpattern(dash) lwidth(thin)) ///
					xline(2.8, lcolor("black") lwidth(thin)) /// 
					ytitle("Point Estimate (Relative to t = -1)") ///
					xtitle("Years Relative to the Tax Reform") ///
					legend(off) ///
					ciopts(recast(rcap) color(%70)) ///
					mcolor(%70) ///
					msymbol(O) ///
					graphregion(color(white)) ///
					title("`plot_title_main'", size(medium)) ///  
					note("95% CIs. SEs clustered at AGS level." /// 
					"For 2018 cohort, effect ends at t+1. Fixed Effects:`fe'. wz08: `w'", size(vsmall) span)

				graph export "`plot_filename'", replace width(1000)
				di as text " -> Plot gespeichert als `plot_filename'"

			   

				} // Ende if _rc == 0
				else {
					di as error "ERROR: Failed to estimate model for DV: `depvar' with `fe' for WZ `w'. Skipping."
				}
			
			
		}
		
		// Liste der erfolgreich gespeicherten Schätzungen für die aktuelle FE-Spezifikation
		local estimates_list_for_current_fe ""
		foreach depvar of global dependent_vars {
			capture estimates describe store_`depvar'_`w'
			if _rc == 0 {
				local estimates_list_for_current_fe "`estimates_list_for_current_fe' store_`depvar'_`w'"
			}
			else {
					di as error "ERROR: Failed to estimate model for DV: `depvar' with `fe' for WZ `w'. Skipping."
				}
		}

		// Regressionstabelle für die aktuelle FE-Spezifikation erstellen (wenn Ergebnisse existieren)
		if "`estimates_list_for_current_fe'" != "" {
			di "--- Creating tables for FE Specification: `fe' WZ: `w'---"

			// Basis-Dateiname für Tabelle anpassen, Titel und Notizen für Tabelle anpassen
			local table_filename_base "$outputpfad/EventStudy_stacked_`fe'_WZ_`w'"
			local table_title_main "Stacked Event Study (TWFE DiD)"
			local tex_notes_fe_detail "Fixed Effects (`fe') WZ_`w'"

			// TXT Tabelle erstellen
			esttab `estimates_list_for_current_fe' using "`table_filename_base'.txt", ///
				replace wide plain b(2) se(2) star(* 0.10 ** 0.05 *** 0.01) ///
				title("`table_title_main'") nonumbers stats(N, fmt(%9.0gc) labels("Observations")) ///
				addnotes("Notes: `tex_notes_fe_detail' Clustered SEs (AGS) in parentheses. Significance: * p<0.10, ** p<0.05, *** p<0.01.")

			// TEX Tabelle erstellen
			esttab `estimates_list_for_current_fe' using "`table_filename_base'.tex", ///
				replace booktabs b(2) se(2) star(* 0.10 ** 0.05 *** 0.01) ///
				title("`table_title_main' \\label{tab:event_`fe'}") nonumbers mtitle("") ///
				stats(N, fmt(%9.0gc) labels("Observations")) ///
				addnotes("\\textit{Notes:} `tex_notes_fe_detail' Clustered SEs (AGS) in parentheses. Significance: \\sym{*} \\(p<0.10\\), \\sym{**} \\(p<0.05\\), \\sym{***} \\(p<0.01\\).")

			di "-> Tables saved as `table_filename_base'.txt and .tex"
			
			estimates drop `estimates_list_for_current_fe'
		} // Ende if `estimates_list_for_current_fe` != ""
		else {
			di as error "--- No successful estimates found to create table for FE Spec: `fe' WZ `wz'---" 
		}

		
		

	} // Ende wirtschaftszweige schleife
		

	di _newline(2) "--------------------------------------------------"
		

}




*	-------------------------------------------------------------------------------------------------------------------
*	----
*	----	Code ohne Schleifen:
*	----
*	-------------------------------------------------------------------------------------------------------------------


*	-------------------------------------------------------------------------------------------------------------------
*	----
*	----	Block 2 :  Schätzung if persbigger380 == 1 >380 fälle
*	----
*	-------------------------------------------------------------------------------------------------------------------



    di _newline as result "*** START Analyzing  ***"

    * Innere Schleife über abh Variablen, Schätzungen durchführen und speichern
  
    foreach depvar of global dependent_vars {
		
		display "Schätze Event Study für Outcome: `depvar' "
		eststo clear
		capture reghdfe `depvar' $x_lbt_hike if persbigger380 == 1 ,a($fixed_effects2) vce(cluster ags) //!***** MODELDEFINITION *****!
		
		
		
        if _rc == 0 {
            estimates store store_`depvar' // z.B. store_e_personalausg
			
			* Plot erstellen
			
			display "*** Erstelle EventStudyPlot ***"
		
			coefplot store_`depvar' ///
				, keep(dummy_m2_taxhike dummy_m1_taxhike dummy_0_taxhike dummy_p1_taxhike dummy_p2_taxhike) /// 
				coeflabels(dummy_m2_taxhike="-2" dummy_m1_taxhike="-1" dummy_0_taxhike="0" dummy_p1_taxhike="1" dummy_p2_taxhike="2") ///
				omitted ///                 
				vert  ///
				connect(L) ///
				xline(2.8, lcolor("black") lwidth(thin)) yline(0,lcolor("black") lpattern(dash) lwidth(thin)) ///   
				ytitle("Point Estimate (Relative to t = -1)") ///
				xtitle("Years Relative to the Tax Reform") ///
				legend(off) ///
				ciopts(recast(rcap) color(%70)) ///
				mcolor(%70) ///
				msymbol(O) ///
				graphregion(color(white)) ///
				title("Effect on", size(medium)) ///   // subtitle("(t-1 Referenz)", size(small)) ///
				note("95% confidence intervals shown. Standard errors clustered at the municipality level (AGS). For the 2018 cohort, the plotted effect ends at t+1 due to sample end. " ///
					 "", size(vsmall) span)

			local plot_filename "$outputpfad/EventStudy_`depvar'.png"
			graph export "`plot_filename'", replace width(1000)
			di as text " -> Plot gepeichert als EventStudy_`depvar'.png "
			
        }
        else {
            di as error "ERROR: Failed estimate model for DV: `depvar'. Skipp."
        }
    }

    * // Liste der erfolgreichen Schätzungen  erstellen
    local estimates_list_cohort ""
    foreach depvar of global dependent_vars {
        capture estimates describe store_`depvar'
        if _rc == 0 {
            local estimates_list_cohort "`estimates_list_cohort' store_`depvar'"
        }
    }
	
	

    * Regressionstabelle  erstellen (wenn Ergebnisse existieren)
    if "`estimates_list_cohort'" != "" {
        di "--- Creating tables for Cohort `cohort' ---"

        * Basis-Dateiname 
       
        local table_filename "$outputpfad\04_EVENTstacked"  // Achtung backslash forwardslash

        * Titel und Notizen 
        local table_title "StackedEVENT TWFE 2xT DiD "
        local tex_title "`table_title' \\label{tab:std_event}" // LaTeX Label anpassen
        local table_notes "Notes: FE: id jahrXregion jahrXindustry. Clustered SEs (AGS)."
        local tex_notes "\\textit{Notes:} FE: AGS, Year. Clustered SEs (AGS) in parentheses. Significance: \\sym{*} \\(p<0.10\\), \\sym{**} \\(p<0.05\\), \\sym{***} \\(p<0.01\\)."

        * TXT Tabelle erstellen
        esttab `estimates_list_cohort' using "`table_filename'.txt", ///
            replace wide plain b(2) se(2) star(* 0.10 ** 0.05 *** 0.01) ///
            title("`table_title'") nonumbers stats(N, fmt(%9.0gc) labels("Observations")) ///
            addnotes("`table_notes'")

        * TEX Tabelle erstellen
        esttab `estimates_list_cohort' using "`table_filename'.tex", ///
            replace booktabs b(2) se(2) star(* 0.10 ** 0.05 *** 0.01) ///
            title("`tex_title'") nonumbers mtitle("") ///
            stats(N, fmt(%9.0gc) labels("Observations")) addnotes("`tex_notes'")

        di "-> Tables saved as `table_filename'.txt and .tex"

    } // Ende if `estimates_list_cohort` != ""
    else {
        di as error "--- No successful estimates found to create table ---"
    }

    * Gespeicherte Schätzungen für diese Kohorte löschen, bevor die nächste beginnt
    estimates drop `estimates_list_cohort'

di _newline as result "*** StackedEVENT TWFE 2xT DiD beendet***" _newline




*	-------------------------------------------------------------------------------------------------------------------
*	----
*	----	Block 2 :  Schätzung Schätzung if persbigger380 != 1  (==0)  also alle Gemeinden mit <380 hebesatz und somit einer vollständigen Option auf die Anrechnung
*	----
*	-------------------------------------------------------------------------------------------------------------------


    di _newline as result "*** START Analyzing  ***"

    * Innere Schleife über abh Variablen, Schätzungen durchführen und speichern
  
    foreach depvar of global dependent_vars {
		
		display "Schätze Event Study für Outcome: `depvar' "
		eststo clear
		capture reghdfe `depvar' $x_lbt_hike  if persbigger380 != 1 ,a($fixed_effects1) vce(cluster ags) //!***** MODELDEFINITION *****!
		
		
		
        if _rc == 0 {
            estimates store store_`depvar' // z.B. store_e_personalausg
			
			* Plot erstellen
			
			display "*** Erstelle EventStudyPlot ***"

			coefplot (store_`depvar' , offset(-0.05) m(O)), drop(_cons) ///
				omitted ///
				coeflabels(dummy_m2_taxhike="-2" dummy_m1_taxhike="-1" dummy_0_taxhike="0" dummy_p1_taxhike="1" dummy_p2_taxhike="2") ///
				vertical ///
				yline(0) ///
				xtitle("Perioden relativ zur Steuererhöhung") ///
				ciopts(recast(rcap) color(%70)) ///
				mcolor(%70) ///
				msymbol(0) ///
				title("Event Study: Effect auf Outcome Variable: `depvar' ", size(medium)) ///
				note("95% KI, SE clustered: ags, FE:  Für 2018 Kohorte endet dargestellter Effekt bei t+1") 
				
			local plot_filename "$outputpfad/EventStudyKLEINER380Fälle_`depvar'.png"
			graph export "`plot_filename'", replace width(1000)
			di as text " -> Plot gepeichert als EventStudyKLEINER380Fälle_`depvar'.png "
			
	
			
        }
        else {
            di as error "ERROR: Failed estimate model for DV: `depvar'. Skipp."
        }
    }

    * // Liste der erfolgreichen Schätzungen  erstellen
    local estimates_list_cohort ""
    foreach depvar of global dependent_vars {
        capture estimates describe store_`depvar'
        if _rc == 0 {
            local estimates_list_cohort "`estimates_list_cohort' store_`depvar'"
        }
    }
	
	

    * Regressionstabelle  erstellen (wenn Ergebnisse existieren)
    if "`estimates_list_cohort'" != "" {
        di "--- Creating tables for Cohort `cohort' ---"

        * Basis-Dateiname 
       
        local table_filename "$outputpfad\04_EVENTstackedKLEINER380Fälle"  // Achtung backslash forwardslash

        * Titel und Notizen 
        local table_title "StackedEVENT TWFE 2xT DiD KLEINER 380 "
        local tex_title "`table_title' \\label{tab:std_event}" // LaTeX Label anpassen
        local table_notes "Notes: FE: id jahrXregion jahrXindustry. Clustered SEs (AGS)."
        local tex_notes "\\textit{Notes:} FE: AGS, Year. Clustered SEs (AGS) in parentheses. Significance: \\sym{*} \\(p<0.10\\), \\sym{**} \\(p<0.05\\), \\sym{***} \\(p<0.01\\)."

        * TXT Tabelle erstellen
        esttab `estimates_list_cohort' using "`table_filename'.txt", ///
            replace wide plain b(2) se(2) star(* 0.10 ** 0.05 *** 0.01) ///
            title("`table_title'") nonumbers stats(N, fmt(%9.0gc) labels("Observations")) ///
            addnotes("`table_notes'")

        * TEX Tabelle erstellen
        esttab `estimates_list_cohort' using "`table_filename'.tex", ///
            replace booktabs b(2) se(2) star(* 0.10 ** 0.05 *** 0.01) ///
            title("`tex_title'") nonumbers mtitle("") ///
            stats(N, fmt(%9.0gc) labels("Observations")) addnotes("`tex_notes'")

        di "-> Tables saved as `table_filename'.txt and .tex"

    } // Ende if `estimates_list_cohort` != ""
    else {
        di as error "--- No successful estimates found to create table ---"
    }

    * Gespeicherte Schätzungen für diese Kohorte löschen, bevor die nächste beginnt
    estimates drop `estimates_list_cohort'

di _newline as result "*** StackedEVENT TWFE 2xT DiD beendet***" _newline

*####################################################################################################################################################

// WInsorizing ohns winsor2


local varlist_to_process "IhreVariable1 IhreVariable2 IhreVariable3" 
local lower_perc 1
local upper_perc 99


foreach var of local varlist_to_process {
    display "Winsorisiere Variable: `var' am `lower_perc'. und `upper_perc'. Perzentil..."

    // Perzentile für die aktuelle Variable berechnen (global)
    // 'quietly' unterdrückt die Ausgabe von summarize
    quietly summarize `var', detail 
    
    // Perzentilwerte speichern
    local p_low_value = r(p`lower_perc') 
    local p_high_value = r(p`upper_perc')

    // Sicherheitscheck: Perzentilwerte gefunden wurden
    // wichtig, falls eine Variable z.B. nur aus fehlenden Werten besteht
    // oder zu wenige Beobachtungen für die Perzentilberechnung hat.
    if "`p_low_value'" == "" | "`p_high_value'" == "" {
        display as error "Konnte Perzentile für `var' nicht bestimmen. Überspringe Variable."
        continue // Geht zur nächsten Variable in der Schleife
    }

    // Neue Variable für die winsorisierten Werte erstellen 
   
    generate `var'_w = `var'
    label variable `var'_w "`var' (winsorized `lower_perc'% - `upper_perc'%)"

    // Werte unterhalb des unteren Perzentils auf den Wert des unteren Perzentils setzen
    replace `var'_w = `p_low_value' if `var' < `p_low_value' & !missing(`var')

    // Werte oberhalb des oberen Perzentils auf den Wert des oberen Perzentils setzen
    replace `var'_w = `p_high_value' if `var' > `p_high_value' & !missing(`var')
    
    display as result "-> Neue Variable `var'_w wurde erstellt."
}

display _newline "Winsorisierung für alle angegebenen Variablen abgeschlossen."











