clear all
set more off 
version 12.0
set trace off
cap log close
ssc install distplot
ssc install reghdfe
ssc install ftools
* Set paths
local home "home directory"
global covidgraphs	"`home'/graphs"
global covidtables	"`home'/tables"

* Settings
local figures		= 1
local maintables	= 1
local appendix		= 1

local white 	plotregion(color(white)) graphregion(color(white)) bgcolor(white)
graph set window fontface "Palatino-Roman"

* Load data
use "C:\Users\fxrhn\Downloads\dataverse_files\BBPW_2022_GhanaCovidRelief_data.dta"

global hhchars b_adults b_children d_age male household_firm meter_prepaid meter_landlord ///
	d_generator appliance_types_total prior_electricity_USD
sum $hhchars	
******************************************************************************
********************** 1. FIGURES *******************************************
// Subsidy-Tariff Tradeoffs

ksmirnov equiv_subsidytariff=equiv_loaninterest if !missing(equiv_loaninterest)
local ksp=round(`r(p)',0.001)
distplot equiv_subsidytariff equiv_loaninterest, c(JJ) s(oo) lc(red blue) /// 
	   `white' legend(off) ///
		text(0.45 11.1 "Cash loan offer" , color(blue) size(medsmall) placement(e)) ///
		text(0.8 3 "Electricity transfer offer" , color(red) size(medsmall) placement(e)) ///
		text(0 7 "Not willing to" "repay exact amount" ,  size(medsmall) placement(n)) ///
		text(0 13 "Willing to repay" "with interest" ,  size(medsmall) placement(n)) ///
		ytitle("Cumulative share of respondents", axis(1) size(medsmall) ) ///
		xtitle("Share of transfer/loan amount", size(medsmall)) ///
		ylabel(, angle(0) nogrid labsize(medsmall)) ///
	   	xline(10) ///
		xlabel(1(1)21, angle(45) valuelabel labsize(small)) ///
		text(0.95 1 "Kolmogorov-Smirnov" "test p-value: `ksp'" , color(black) size(medsmall) placement(e))

*******************************************************************************
********************** 2. MAIN TABLES ****** *************************************
eststo clear
eststo: reg g_govt_percep subsidy30 subsidyb30 $hhchars i.week i.dow, vce(cluster hh_id)
su g_govt_percep if subsidy==0 & e(sample)
estadd scalar NoSubMean = r(mean)
estadd local Sample = "\multicolumn{1}{p{6em}}{All Households}"
estadd local ctls = "Yes"
estadd local fe = "No"
eststo: reg g_govt_percep subsidy30 subsidyb30 $hhchars i.week i.dow if !missing(g_govt_percep_old), vce(cluster hh_id)
su g_govt_percep if subsidy==0 & e(sample)
estadd scalar NoSubMean = r(mean)
estadd local Sample = "\multicolumn{1}{p{6em}}{Households with Baseline}"
estadd local ctls = "Yes"
estadd local fe = "No"
eststo: reg g_govt_percep subsidy30 subsidyb30 $hhchars i.week i.dow g_govt_percep_old, vce(cluster hh_id)
su g_govt_percep  if subsidy==0 & e(sample)
estadd scalar NoSubMean = r(mean)
estadd local Sample = "\multicolumn{1}{p{6em}}{Households with Baseline}"
estadd local ctls = "Yes"
estadd local fe = "No"
eststo: reghdfe g_govt_percep subsidy30 subsidyb30, absorb(week dow hh_id) vce(cluster hh_id)
su g_govt_percep if subsidy==0 & e(sample)
estadd scalar NoSubMean = r(mean)
estadd local Sample = "\multicolumn{1}{p{6em}}{All Households}"
estadd local ctls = "No"
estadd local fe = "Yes"

esttab using "$covidtables/tab2.tex", ///
	drop(_cons *.week *.dow b_adults b_children d_age male household_firm meter_prepaid meter_landlord ///
	d_generator appliance_types_total prior_electricity_USD) ///
	scalars("NoSubMean No Transfer Mean" "ctls Household Controls" "fe Household Fixed Effects" "Sample Sample" ) /// 
	mtitles("(1)" "(2)" "(3)" "(4)") ///
	title("Respondent political affiliation (enumerator assessment)") ///
	varwidth(45) wrap /// 
	star(* 0.10 ** 0.05 *** 0.01) ///
	addnote("SEs clustered at household level. All outcome variables are on a scale from 1 to 5 where 1 reflects very unfavorable views of NPP (or alternatively very favorable views of NDC) and 5 reflects very favorable views of NPP. Columns 1 and 4 are the FO's overall assessment of the respondent's political affiliation. Columns 2, 3, and 5 are the respondent's assessment of NPP's performance in different areas. Column 6 is the respondent's assessment of the relative performance of NDC and NPP in addressing Dumsor. Controls for the respondent's political responses during PW deployment surveys are included where available.") ///
	se(3) nonumber nonotes label replace booktabs obs b(3) f end( \\ )

}
