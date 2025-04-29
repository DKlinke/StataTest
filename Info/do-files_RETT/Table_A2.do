use "F:\Neumeier_RETT\Replication_files\Data\external_data\Table_A2.dta", clear

	
eststo clear
eststo: xtreg increase l.le l.ce l.AQ_endg_tax_base rw_total l.Debt_tsd_pc l.Shared_taxes_pc l.pop_growth 				i.year, fe rob cluster(id)
estadd local fixed "Yes", replace
eststo: xtreg increase l.le l.ce l.AQ_endg_tax_base rw_total l.Debt_tsd_pc l.Shared_taxes_pc l.migration_per_tsd   		i.year, fe rob cluster(id)
estadd local fixed "Yes", replace
eststo: xtreg increase l.le l.ce l.AQ_endg_tax_base rw_total l.Debt_tsd_pc l.Shared_taxes_pc l.workage_pop_growth 		i.year, fe rob cluster(id)
estadd local fixed "Yes", replace
eststo: xtreg increase l.le l.ce l.AQ_endg_tax_base rw_total l.Debt_tsd_pc l.Shared_taxes_pc l.empl_soc_contr_growth 		i.year, fe rob cluster(id)
estadd local fixed "Yes", replace
eststo: xtreg increase l.le l.ce l.AQ_endg_tax_base rw_total l.Debt_tsd_pc l.Shared_taxes_pc l.unempl_rate_change 		i.year, fe rob cluster(id)
estadd local fixed "Yes", replace
eststo: xtreg increase l.le l.ce l.AQ_endg_tax_base rw_total l.Debt_tsd_pc l.Shared_taxes_pc l.loc_bus_tax_pc 			i.year, fe rob cluster(id)
estadd local fixed "Yes", replace

			