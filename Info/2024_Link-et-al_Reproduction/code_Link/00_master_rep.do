*******************************************************************************

****  Downward Revision of Investment Decisions after Corporate Tax Hikes  ****
**** 	Sebastian Link, Manuel Menkhoff, Andreas Peichl, Paul Schüle	   ****
**** 							01.08.2023								   ****	

*******************************************************************************
* Master
*******************************************************************************

*******************************************************************************
* Settings
*******************************************************************************

clear all
macro drop all
version 17.0

* set paths
global PATH "F:\lmps_archive" // adjust path
cd $PATH
global datapath "${PATH}\data"
global code "${PATH}\code"
global outputpath "${PATH}\results"

* set adopaths
sysdir set PLUS "${PATH}\ado"
sysdir set PERSONAL "${PATH}\ado"
sysdir set OLDPLACE "${PATH}\ado"

adopath

/*
* packages to install
ssc install ftools
ssc install reghdfe
ssc install coefplot
ssc install grstyle
ssc install palettes
ssc install colrspace
ssc install distinct
ssc install estout
ssc install binscatter
ssc install did_imputation
ssc install eventstudyinteract
ssc install avar
* dm79
*/

*******************************************************************************
* Graphics
*******************************************************************************
	
grstyle clear
*start programm
grstyle init
*set general graph option
grstyle set plain, horizontal grid dotted
*set different style for vertical and horizontal line in graph
grstyle color xyline black
grstyle linewidth xyline thin
*change grid
grstyle color major_grid gs5
grstyle linewidth major_grid medium
grstyle yesno grid_draw_max yes
*change lines in lineplot
grstyle linewidth plineplot 0.55

* baseline sample: sample = 1 ; to get tax drops: sample = 2

global sample = 1

*******************************************************************************
* Sample Preparation
*******************************************************************************

* prepare local business tax data
do "${code}\01_prep"

* prepare and match firm level data
do "${code}\02_prep"

* sample adjustments and further preparation
do "${code}\03_prep"

*******************************************************************************
* Analysis
*******************************************************************************

* figures based on external data
do "${code}\04_figures_with_prep_data"

* figures based on municipality data
do "${code}\04b_figures_balanced_panel"

* maps
do "${code}\04c_figures_maps"

* figures with baseline sample
do "${code}\05_figures"

* event study figures
do "${code}\06_event_studies"

* all tables
do "${code}\07_tables"

* in-text numbers
do "${code}\08_intext_numbers"

*******************************************************************************
* [Pre-preparation of external data (optional)]
*******************************************************************************

do "${code}\09_prep_prep"




