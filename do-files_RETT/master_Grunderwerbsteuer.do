***********************************
* Project: Grunderwerbsteuer
************************************


version 15.1
clear all
macro drop _all

set matsize 2000
set varabbrev off, permanent
set more off, permanently


cd "F:\Neumeier_RETT\Replication_files"
global do_files "do-files\"
global graphs "Figures\"
global tables "Tables\"
global logs "Logs\"
global data "Data\"

global today: di %tdDNCY daily("$S_DATE", "DMY")
di $today

*** Choose what to run
global Grunderwerbsteuer 1

if ${Grunderwerbsteuer} == 1 {
	global data_prep 0
	
	global descriptives 1

	global event_study 0
	
	global staggered 0

		** Figure 1: Joint estimation for apartments, houses and apartment buildings
		global Figure1 0 
		
		*** Figure 2: Effects of changes in RETT rate delta tau across property types
		global Figure2 0
		
		*** Figure 3: Effects of changes in RETT rate delta tau on the number of listed properties
		global Figure3 0
		
		*** Figure 4: Effects of changes in RETT rate delta tau across counties
		global Figure4 0
		
		*** Figure 5: Effects of changes in RETT rate delta tau across housing market regions
		global Figure5 0
		
		*** Figure A.3: Stacked event study design
		global stackprep 1 // data prep for stacked design
		global FigureA3 1
		
		*** Figure A.5: Robustness check: Effects of changes in the log net-of-tax-rate
		global FigureA5 0
		
		*** Figure A.6: Robustness check: Property-specific control variables
		global FigureA6 0
		
		*** Figure A.7: Robustness check: Regional control variables
		global FigureA7 0
		
		*** Figure A.8: Robustness check: Without postal codes within 10km of the border
		global FigureA8 0
				
	
}



*** Run do-files
if ${Grunderwerbsteuer} == 1 {
	if ${data_prep} == 1 do "${do_files}/01_Dataprep.do"
	if ${descriptives} == 1 do "${do_files}/02_Descriptives.do"
	if ${event_study} == 1 do "${do_files}/03_Eventstudy_prices.do"
	if ${staggered} == 1 do "${do_files}/04_Eventstudy_staggered.do"
	if ${Figure3} == 1 do "${do_files}/05_Eventstudy_quantities.do"
}
