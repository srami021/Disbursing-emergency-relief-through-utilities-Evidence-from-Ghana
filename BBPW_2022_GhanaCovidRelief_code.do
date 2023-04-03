clear all
set more off 
version 12.0
set trace off
cap log close

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

if `figures'==1 {

// Electricity WTP

preserve
collapse (mean) wtp_elec (max) meter_landlord (max) lifeline_march, by(hh_id)

/*
lab def dcurve 	1 "Lower than 15 Cash" ///
				2 "15 Cash" ///
				3 "15-25 Cash" ///
				4 "25 Cash" /// 
				5 "25-35 Cash" /// 
				6 "35 Cash" /// 
				7 "35-50 Cash" /// 
				8 "50 Cash" /// 
				9 "50-60 Cash" /// 
				10 "60 Cash" ///
				11 "60-75 Cash" /// 
				12 "75 Cash" /// 
				13 "75-100 Cash" /// 
				14 "100 Cash" /// 
				15 "More than 100 Cash"
*/
lab val wtp_elec dcurve
local white 	plotregion(color(white)) graphregion(color(white)) bgcolor(white)

ksmirnov wtp_elec, by(meter_landlord)
local ksp=round(`r(p)',0.001)
distplot wtp_elec, over(meter_landlord) lc(red blue) /// 
	   `white' legend(off) ///
		text(0.4 1 "Pays a landlord" "for electricity" , color(blue) size(medsmall) placement(e)) ///
		text(0.6 9 "Pays electricity" "directly" , color(red) size(medsmall) placement(e)) ///
		text(0 4.5 "Prefers cash" ,  size(medsmall) placement(n)) ///
		text(0 11 "Prefers electricity" ,  size(medsmall) placement(n)) ///
		ytitle(" ", axis(1) size(small) ) xtitle("") ///
		ylabel(, angle(0) nogrid labsize(small)) ///
	   	xline(8) title("(b)", size(medsmall)) ///
		xlabel(1(1)15, angle(45) valuelabel labsize(vsmall)) ///
		text(0.95 0.9 "Kolmogorov-Smirnov" "test p-value: `ksp'" , color(black) size(medsmall) placement(e)) ///
		name(hist2a)

ksmirnov wtp_elec, by(lifeline_march)
local ksp=round(`r(p)',0.001)
distplot wtp_elec, over(lifeline_march) lc(red blue) /// 
	   `white' legend(off) ///
		text(0.32 1 "March lifeline" "customer" , color(blue) size(medsmall) placement(e)) ///
		text(0.5 8.5 "March non-lifeline" "customer" , color(red) size(medsmall) placement(e)) ///
		text(0 4.5 "Prefers cash" ,  size(medsmall) placement(n)) ///
		text(0 11 "Prefers electricity" ,  size(medsmall) placement(n)) ///
		ytitle("Cumulative share of respondents", axis(1) size(medsmall) ) xtitle("") ///
		ylabel(, angle(0) nogrid labsize(small)) ///
	   	xline(8) title("(a)", size(medsmall))  ///
		xlabel(1(1)15, angle(45) valuelabel labsize(vsmall))  ///
		text(0.95 0.9 "Kolmogorov-Smirnov" "test p-value: `ksp'" , color(black) size(medsmall) placement(e)) ///
		name(hist1a)
restore
gr combine hist1a hist2a, plotregion(color(white)) graphregion(color(white)) rows(1)
graph export "$covidgraphs/fig1.pdf", replace

// Subsidy Receipt Timelines

* Ever received relief
local white 	plotregion(color(white)) graphregion(color(white)) bgcolor(white)
preserve
	bys round meter_landlord: egen subsidy_sub = mean(subsidy_rev)
	su subsidy_sub,d
	bys round lifeline_march: egen subsidy_sub2=mean(subsidy_rev)
	su subsidy_sub2,d
	bys round meter_landlord: egen count_sub = count(subsidy_rev)
	su count_sub,d
	bys round lifeline_march: egen count_sub2 = count(subsidy_rev)
	su count_sub2,d
	drop if count_sub<10 | count_sub2<10
	la def rounds 1 "May-June" 2 "June-July" 3 "Aug.-Oct."
	la val round rounds
	twoway 	(line subsidy_sub round if meter_landlord==0, color(black)) ///
		(line subsidy_sub round if meter_landlord==1, color(blue)) /// 
		(line subsidy_sub2 round if lifeline_march==0, color(red) lpattern(dash)) ///
		(line subsidy_sub2 round if lifeline_march==1, color(green) lpattern(dash)) /// 
		, `white' ///
		ytitle(" ", axis(1) size(medsmall) ) ///
		ylabel(0(0.1)1, labsize(medsmall) angle(0) nogrid) ///
		yscale(axis(1) lcolor(black)) /// 
		xtitle("Survey Round", size(medsmall)) ///
		xlabel(1(1)3, angle(45) valuelabel labsize(small)) xline(2.5) ///
		text(0.95 1.5 "All HHs" "eligible" , color(black) size(small) placement(e)) ///
		text(0.95 2.6 "Only lifeline" "HHs eligible " , color(black) size(small) placement(e)) ///
		text(0.05 2.49 "Start of" "Phase 2" , color(black) size(small) placement(w)) ///
		text(0.6 1 "Direct pay" , color(black) size(small) placement(e)) ///
		text(0.45 1 "Landlord pay" , color(blue) size(small) placement(e)) ///
		text(0.6 2 "Non-lifeline" , color(red) size(small) placement(n)) ///
		text(0.34 2 "Lifeline" , color(green) size(small) placement(n)) ///
		legend(off)  title("(a) Ever received relief", color(black) size(medsmall)) name(timeround1)
restore

* Received relief in last 30 days
preserve
	replace subsidy30=subsidy_rev if month==5
	bys round meter_landlord: egen subsidy_sub = mean(subsidy30)
	su subsidy_sub,d
	bys round lifeline_march: egen subsidy_sub2=mean(subsidy30)
	su subsidy_sub2,d
	bys round meter_landlord: egen count_sub = count(subsidy30)
	su count_sub,d
	bys round lifeline_march: egen count_sub2 = count(subsidy30)
	su count_sub2,d
	drop if count_sub<10 | count_sub2<10
	la def rounds 1 "May-June" 2 "June-July" 3 "Aug.-Oct."
	la val round rounds
	twoway 	(line subsidy_sub round if meter_landlord==0, color(black)) ///
		(line subsidy_sub round if meter_landlord==1, color(blue)) /// 
		(line subsidy_sub2 round if lifeline_march==0, color(red) lpattern(dash)) ///
		(line subsidy_sub2 round if lifeline_march==1, color(green) lpattern(dash)) /// 
		, `white' ///
		ytitle(" ", axis(1) size(medsmall) ) ///
		ylabel(0(0.1)1, labsize(medsmall) angle(0) nogrid) ///
		yscale(axis(1) lcolor(black)) /// 
		xtitle("Survey Round", size(medsmall)) ///
		xlabel(1(1)3, angle(45) valuelabel labsize(small)) xline(2.5) ///
		text(0.95 1.5 "All HHs" "eligible" , color(black) size(small) placement(e)) ///
		text(0.95 2.6 "Only lifeline" "HHs eligible " , color(black) size(small) placement(e)) ///
		text(0.05 2.49 "Start of" "Phase 2" , color(black) size(small) placement(w)) ///
		text(0.5 1 "Direct pay" , color(black) size(small) placement(e)) ///
		text(0.35 1 "Landlord pay" , color(blue) size(small) placement(e)) ///
		text(0.4 1 "Non-lifeline" , color(red) size(small) placement(e)) ///
		text(0.19 1 "Lifeline" , color(green) size(small) placement(e)) ///
		legend(off)  title("(b) Received relief in last 30 days", color(black) size(medsmall)) name(timeround2)
restore

gr combine timeround1 timeround2, plotregion(color(white)) graphregion(color(white)) rows(1)
graph export "$covidgraphs/fig2.pdf", replace

// Distribution of relief amount received

preserve
su f_subsidy_actual_USD,d
replace f_subsidy_actual_USD = `r(p99)' if f_subsidy_actual_USD>`r(p99)' & !missing(f_subsidy_actual_USD)
replace f_subsidy_actual_USD=. if f_subsidy_actual_USD==0 & subsidy30==1

twoway histogram f_subsidy_actual_USD if f_subsidy_actual_USD>0, ///
	percent  start(0) width(1) color(black) fcolor(gs8) xline(3.5, lcolor(black)) `white' ///
	text(15 3.5 "Cost of 50 kWh" ,  size(small) placement(e)) ///
	ylabel(, labsize(small) angle(0))
graph export "$covidgraphs/figa3.pdf",replace	
restore

preserve
su f_subsidy_actual_total_USD,d
replace f_subsidy_actual_total_USD = `r(p99)' if f_subsidy_actual_total_USD>`r(p99)' & !missing(f_subsidy_actual_total_USD)
replace f_subsidy_actual_total_USD=. if f_subsidy_actual_total_USD==0 & subsidy==1
twoway 	(scatter f_subsidy_actual_total_USD d_march_ANY_USD, mcolor(gs8) msize(small)) ///
		(lfit f_subsidy_actual_total_USD d_march_ANY_USD, lcolor(black)) ///
		(lfitci f_subsidy_actual_total_USD d_march_ANY_USD)  ///
		(function y=1.5*x, range(0 54) lcolor(red) lpattern(dash)) , ///
		legend(off) `white' ///
		xtitle("March electricity spending (USD)") ///
		ytitle("Total electricity transfers" "received over 5 months (USD)") ///
		xline(3.5, lcolor(black)) text(82 3.6 "50 kWh" "lifeline cutoff",  size(small) placement(e)) ///
		yline(17.5, lcolor(blue) lpattern(dash)) ///
		text(35 60 "Linear prediction" , color(green) size(small) placement(e)) ///
		text(20 37 "Expected lifeline transfer amount after 5 months" , color(blue) size(small) placement(e)) ///
		text(55 38 "Expected non-lifeline transfer" "amount after 5 months" , color(red) size(small) placement(e))
graph export "$covidgraphs/figa4.pdf",replace		
restore

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
graph export "$covidgraphs/fig3.pdf", replace

// Subsidy Satisfaction 

graph bar f_subsidy_appropriate1 f_subsidy_appropriate2, over(subsidy_timing, label(labsize(small)))	///
	legend(label(1 "Satisfaction (1-5)") label(2 "Satisfaction if tariffs increase (1-5)") col(1) size(medsmall)) ///
	ylabel(, angle(0) nogrid labsize(medsmall)) ///
	`white' 
graph export "$covidgraphs/figa5.pdf", replace

}

******************************************************************************
********************** 2. MAIN TABLES ****** *************************************

if `maintables'==1 {

// Subsidy receipt by connection type

local hhchars2 b_adults b_children d_age male household_firm meter_prepaid ///
	d_generator appliance_types_total prior_electricity_USD
eststo clear
eststo: reg subsidy_rev meter_landlord i.week i.dow, vce(cluster hh_id)
su subsidy_rev
estadd scalar Mean = r(mean)
estadd local ctl = "No"
eststo: reg subsidy_rev meter_landlord meter_prepaid prior_electricity_USD i.week i.dow, vce(cluster hh_id)
su subsidy_rev if !missing(prior_electricity_USD)
estadd scalar Mean = r(mean)
estadd local ctl = "No"
eststo: reg subsidy_rev meter_landlord meter_prepaid prior_electricity_USD appliance_types_total i.week i.dow, vce(cluster hh_id)
su subsidy_rev if !missing(prior_electricity_USD) & !missing(appliance_types_total)
estadd scalar Mean = r(mean)
estadd local ctl = "No"
eststo: reg subsidy_rev meter_landlord `hhchars2' i.week i.dow, vce(cluster hh_id)
su subsidy_rev if !missing(prior_electricity_USD) & !missing(appliance_types_total)
estadd scalar Mean = r(mean)
estadd local ctl = "Yes"
eststo: reg subsidy_rev meter_landlord `hhchars2' lifeline_march i.week i.dow, vce(cluster hh_id)
su subsidy_rev if !missing(prior_electricity_USD) & !missing(appliance_types_total) & !missing(lifeline_march)
estadd scalar Mean = r(mean)
estadd local ctl = "Yes"
eststo: reg subsidy_rev d_shared_meter `hhchars2' lifeline_march i.week i.dow, vce(cluster hh_id)
su subsidy_rev if !missing(prior_electricity_USD) & !missing(appliance_types_total) & !missing(lifeline_march)
estadd scalar Mean = r(mean)
estadd local ctl = "Yes"

esttab using "$covidtables/tab1.tex", ///
	drop(_cons *.week *.dow b_adults b_children d_age male household_firm d_generator) /// 
	scalars("Mean Dep. Var. Mean" "ctl Additional Controls") /// 
	title("Respondent received electricity transfer") ///
	mtitles("(1)" "(2)" "(3)" "(4)" "(5)" "(6)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	addnote("SEs clustered at household level.") ///
	se(3) nonumber nonotes label replace booktabs obs b(3) f end( \\ )
	
* Checking subsidy receipt by baseline (pre-Covid) variables
reghdfe subsidy_rev $hhchars, absorb(week dow) vce(cluster hh_id)
foreach v of varlist f_tv_n f_fridge_n f_fan_n f_ac_n f_surge_n d_incomedaily_PERADULT n_phones concrete_wall metal_roof {
	reghdfe subsidy_rev `v' $hhchars, absorb(week dow) vce(cluster hh_id)
	reg subsidy_rev `v' if round==3
}

// Current political perspectives and subsidy receipt

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

******************************************************************************
********************** 3. APPENDICES *******************************************

if `appendix'==1 {

// Summary statistics
 
preserve
drop if round==4
* Only keep first round answers for variables that are at the household level (rather than per round)
isid hh_id week
sort hh_id week

* Some should be average: 
by hh_id: egen temp = mean(f_wtp_elec)
replace f_wtp_elec = temp 
drop temp

* For all of these, only keep 1st observation:
local hhvars = "b_adults b_children d_age male household_firm d_generator appliance_types_total d_shared_meter d_meter_users meter_landlord meter_prepaid d_remote_topup lifeline_march subsidy_1r f_wtp_elec prior_electricity_USD"
foreach var of varlist `hhvars' {
		by hh_id: replace `var' = . if _n != 1		
}

* Add variable: number of rounds for household
by hh_id: gen rounds = _N if _n==1 
lab var rounds "Number of survey rounds"
replace subsidy30=subsidy_rev if month==5
local statvars b_adults b_children d_age male household_firm d_generator appliance_types_total b_move ///
	c_consumption_total_USD_pc c_food_USD_pc c_loans_any c_loans_formal ///
	d_shared_meter d_meter_users meter_landlord d_landlord_lastpay d_landlord_amount_USD ///
	meter_prepaid d_prepaid_balance_USD d_topup_num d_topup_amt_USD d_topup_feb_interval ///
	d_month_ANY_USD prior_electricity_USD lifeline_march ///
	g_govt_percep g_trust_govt g_political_dumsor g_better_dumsor g_political_covid ///
	f_prog_elecsubs f_subsidy_appropriate subsidy1rev subsidy3 subsidy_rev subsidy30 /// 
	f_subsidy_actual_USD f_subsidy_you_USD f_subsidy_actual_total_USD 
	
eststo sumstats: estpost tabstat `statvars', statistics(mean sd min p25 p50 p75 max count) columns(statistics)
esttab sumstats using "$covidtables/taba2.tex", ///
	noobs nonum nomtitle label end( \\ ) replace booktabs f ///
	refcat(	b_adults "\textit{Household characteristics}" ///
			d_shared_meter "\textit{Electricity connection and use}" ///
			g_govt_percep "\textit{Government perceptions}" ///
			f_prog_elecsubs "\textit{Electricity relief experience}", nolabel) ///
	cells("mean(fmt(2) label(\multicolumn{1}{c}{Mean})) sd(fmt(2) label(\multicolumn{1}{c}{SD})) min(fmt(1) label(Min)) p25(fmt(1) label(25$^{th}$)) p50(fmt(1) label(50$^{th}$)) p75(fmt(1) label(75$^{th}$)) max(fmt(1) label(Max)) count(fmt(0) label(\multicolumn{1}{c}{N})) ")
eststo clear

* Check on some characteristics
su lifeline_march
bys lifeline_march: su meter_prepaid d_remote_topup d_shared_meter meter_landlord
foreach v of varlist meter_prepaid d_remote_topup d_shared_meter meter_landlord {
ttest `v', by(lifeline_march)
}
su d_shared_meter if meter_landlord==1

restore

// Correlates of electricity connection types
global hhchars2 b_adults b_children d_age male household_firm ///
	d_generator appliance_types_total prior_electricity_USD

eststo clear
eststo: reg meter_prepaid $hhchars2 lifeline_march if round==1
su meter_prepaid if round==1
estadd scalar Mean = r(mean)
eststo: reg meter_landlord $hhchars2 lifeline_march if round==1
su meter_landlord if round==1
estadd scalar Mean = r(mean)
eststo: reg d_shared_meter $hhchars2 lifeline_march meter_landlord meter_prepaid if round==1
su d_shared_meter if round==1
estadd scalar Mean = r(mean)	
eststo: reg lifeline_march $hhchars2 meter_landlord meter_prepaid if round==1
su lifeline_march if round==1
estadd scalar Mean = r(mean)

esttab using "$covidtables/taba3.tex", ///
	drop(_cons) scalars("Mean Dependent Variable Mean") /// 
	mlabels("\shortstack{Prepaid \\ meter}" "\shortstack{Pays third \\ party}" ///
	"\shortstack{Shared \\ meter}" "\shortstack{March lifeline \\ household}") /// 
	title("Electricity connection correlates") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	se(3) nonumber nonotes label replace booktabs obs b(3) f end( \\ )

// Water subsidy receipt

local hhchars2 b_adults b_children d_age male household_firm meter_prepaid ///
	d_generator appliance_types_total prior_electricity_USD

eststo clear
eststo: reg subsidy meter_landlord `hhchars2' lifeline_march i.week i.dow, vce(cluster hh_id)
su subsidy if !missing(prior_electricity_USD) & !missing(appliance_types_total) & !missing(lifeline_march)
estadd scalar Mean = r(mean)
estadd local ctl = "Yes"
estadd local sample = "All"
eststo: reg subsidy meter_landlord `hhchars2' lifeline_march i.week i.dow if !missing(water_sub)
su subsidy if !missing(prior_electricity_USD) & !missing(appliance_types_total) & !missing(lifeline_march) & !missing(water_sub)
estadd scalar Mean = r(mean)
estadd local ctl = "Yes"
estadd local sample = "Wave 3"
eststo: reg water_sub meter_landlord `hhchars2' lifeline_march i.week i.dow
su water_sub if !missing(prior_electricity_USD) & !missing(appliance_types_total) & !missing(lifeline_march)
estadd scalar Mean = r(mean)
estadd local ctl = "Yes"
estadd local sample = "Wave 3"

esttab using "$covidtables/taba4.tex", ///
	drop(_cons *.week *.dow b_adults b_children d_age male household_firm d_generator) /// 
	scalars("Mean Dep. Var. Mean" "ctl Additional Controls" "sample Sample") /// 
	title("Respondent received subsidy") ///
	mtitles("Electricity" "Electricity" "Water") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	addnote("SEs clustered at household level.") ///
	se(3) nonumber nonotes label replace booktabs obs b(3) f end( \\ )

// Impacts of transfer receipt

eststo clear
foreach v of varlist c_consumption_total_USD_pc c_food_USD_pc e_enough_food e_skip_meals {
	eststo: reghdfe `v' subsidy30 subsidyb30, absorb(week dow hh_id) vce(cluster hh_id)
	su `v' if subsidy30==0 & e(sample)
	estadd scalar NoSubMean = r(mean)
	estadd local Sample = "\multicolumn{1}{p{6em}}{All Households}"
}
esttab using "$covidtables/taba5.tex", ///
	drop(_cons) ///
	scalars("NoSubMean Control Mean" "Sample Sample" ) /// 
	mlabels("\shortstack{Expenditure \\ per capita}" "\shortstack{Food exp. \\ per capita}" "\shortstack{Worry about \\ having \\ enough food}" "\shortstack{Days adults \\ skipped meals}") ///		
	star(* 0.10 ** 0.05 *** 0.01) ///
	addnote("SEs clustered at household level.") ///
	se(3) varwidth(45) nonum nonotes label replace booktabs nobaselevels obs b(3) f end( \\ )

eststo clear
foreach v of varlist d_month_ANY_USD d_prepaid_balance_USD d_topup_num d_topup_amt d_outage_topup {
	eststo: reghdfe `v' subsidy30 subsidyb30, absorb(week dow hh_id) vce(cluster hh_id)
	su `v' if subsidy30==0 & e(sample)
	estadd scalar NoSubMean = r(mean)
	estadd local Sample = "\multicolumn{1}{p{6em}}{All Households}"
}
esttab using "$covidtables/taba6.tex", ///
	drop(_cons) ///
	scalars("NoSubMean Control Mean" "Sample Sample" ) /// 
	mlabels("\shortstack{Electricity \\ spending}" "\shortstack{Pre-paid meter \\ balance}" "\shortstack{Number of \\ top-ups}" "\shortstack{Average \\ top-up amount}" "\shortstack{Outages due \\ to non-payment}") ///		
	star(* 0.10 ** 0.05 *** 0.01) ///
	addnote("SEs clustered at household level.") ///
	se(3) varwidth(45) nonum nonotes label replace booktabs nobaselevels obs b(3) f end( \\ )
	
// Current perspective changes and subsidy receipt

eststo clear
foreach v of varlist g_govt_percep1 g_govt_percep2 g_govt_percep3 g_govt_percep4 g_govt_percep5 govt {
	eststo: reg `v' subsidy30 subsidyb30 $hhchars i.week i.dow g_govt_percep_old, vce(cluster hh_id)
	su `v' if subsidy==0 & !missing(`v') & !missing(g_govt_percep_old)
	estadd scalar NoSubMean = r(mean)
}
esttab using "$covidtables/taba7.tex", ///
	drop(_cons *.week *.dow b_adults b_children d_age male household_firm meter_prepaid meter_landlord ///
	d_generator appliance_types_total prior_electricity_USD) scalars("NoSubMean No Subsidy Mean") /// 
	mlabels("\multicolumn{1}{p{5em}}{Govt Support =1}" "\multicolumn{1}{p{5em}}{Govt Support =2}" ///
	"\multicolumn{1}{p{5em}}{Govt Support =3}" "\multicolumn{1}{p{5em}}{Govt Support =4}" ///
	"\multicolumn{1}{p{5em}}{Govt Support =5}" "\multicolumn{1}{p{5em}}{Govt Support >3}") /// 
	title("Respondent political affiliation (enumerator assessment)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	addnote("SEs clustered at household level. All outcome dummies based on the FO's overall assessment of the respondent's political affiliation. Controls for the respondent's estimated political affiliation during PW deployment surveys are included.") ///
	se(3) nonumber nonotes label replace booktabs obs b(3) f end( \\ )

// Different political perspectives and subsidy receipt, old perspective controls

eststo clear
eststo: reg g_trust_govt subsidy30 subsidyb30 $hhchars i.week i.dow g_govt_percep_old, vce(cluster hh_id)
su g_trust_govt  if subsidy==0 & !missing(g_govt_percep_old)
estadd scalar NoSubMean = r(mean)
eststo: reg g_political_covid subsidy30 subsidyb30 $hhchars i.week i.dow g_govt_percep_old, vce(cluster hh_id)
su g_political_covid  if subsidy==0 & !missing(g_govt_percep_old)
estadd scalar NoSubMean = r(mean)
eststo: reg g_political_dumsor subsidy30 subsidyb30 $hhchars i.week i.dow g_political_dumsor_old, vce(cluster hh_id)
su g_political_dumsor  if subsidy==0 & !missing(g_political_dumsor_old)
estadd scalar NoSubMean = r(mean)
eststo: reg g_better_dumsor subsidy30 subsidyb30 $hhchars i.week i.dow g_better_dumsor_old, vce(cluster hh_id)
su g_better_dumsor  if subsidy==0 & !missing(g_better_dumsor_old)
estadd scalar NoSubMean = r(mean)

esttab using "$covidtables/taba8.tex", ///
	drop(_cons *.week *.dow b_adults b_children d_age male household_firm meter_prepaid meter_landlord ///
	d_generator appliance_types_total prior_electricity_USD) scalars("NoSubMean No Subsidy Mean") /// 
	mlabels("\multicolumn{1}{p{6em}}{Trust NPP to Care for Citizens}" "\multicolumn{1}{p{6em}}{NPP Addressing Covid}" ///
	"\multicolumn{1}{p{6em}}{NPP Adressing Dumsor}" "\multicolumn{1}{p{6em}}{NPP vs NDC Dumsor}") /// 
	title("Respondent political affiliation (enumerator assessment)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	addnote("SEs clustered at household level. All outcome variables are on a scale from 1 to 5 where 1 reflects very unfavorable views of NPP (or alternatively very favorable views of NDC) and 5 reflects very favorable views of NPP. Columns 1 and 4 are the FO's overall assessment of the respondent's political affiliation. Columns 2, 3, and 5 are the respondent's assessment of NPP's performance in different areas. Column 6 is the respondent's assessment of the relative performance of NDC and NPP in addressing Dumsor. Controls for the respondent's political responses during PW deployment surveys are included where available.") ///
	se(3) nonumber nonotes label replace booktabs obs b(3) f end( \\ )

// Impact of transfer amount

preserve
su f_subsidy_actual_USD,d
replace f_subsidy_actual_USD = `r(p99)' if f_subsidy_actual_USD>`r(p99)' & !missing(f_subsidy_actual_USD)
replace f_subsidy_actual_USD=. if f_subsidy_actual_USD==0 & subsidy30==1
eststo clear
eststo: reg g_govt_percep f_subsidy_actual_USD $hhchars i.week i.dow, vce(cluster hh_id)
su f_subsidy_actual_USD if subsidy30==1 & e(sample)
estadd scalar NoSubMean = r(mean)
estadd local Sample = "\multicolumn{1}{p{6em}}{All Households}"
estadd local ctls = "Yes"
estadd local fe = "No"
eststo: reg g_govt_percep f_subsidy_actual_USD $hhchars i.week i.dow if !missing(g_govt_percep_old), vce(cluster hh_id)
su f_subsidy_actual_USD if subsidy30==1 & e(sample)
estadd scalar NoSubMean = r(mean)
estadd local Sample = "\multicolumn{1}{p{6em}}{Households with Baseline}"
estadd local ctls = "Yes"
estadd local fe = "No"
eststo: reg g_govt_percep f_subsidy_actual_USD $hhchars i.week i.dow g_govt_percep_old, vce(cluster hh_id)
su f_subsidy_actual_USD if subsidy30==1 & e(sample)
estadd scalar NoSubMean = r(mean)
estadd local Sample = "\multicolumn{1}{p{6em}}{Households with Baseline}"
estadd local ctls = "Yes"
estadd local fe = "No"
eststo: reghdfe g_govt_percep f_subsidy_actual_USD, absorb(week dow hh_id) vce(cluster hh_id)
su f_subsidy_actual_USD if subsidy30==1 & e(sample)
estadd scalar NoSubMean = r(mean)
estadd local Sample = "\multicolumn{1}{p{6em}}{All Households}"
estadd local ctls = "No"
estadd local fe = "Yes"
eststo: reg g_govt_percep f_subsidy_actual_total_USD $hhchars i.week i.dow, vce(robust)
su f_subsidy_actual_total_USD if f_subsidy_actual_total_USD>0 & e(sample)
estadd scalar NoSubMean = r(mean)
estadd local Sample = "\multicolumn{1}{p{6em}}{Round 3 Households}"
estadd local ctls = "Yes"
estadd local fe = "No"

esttab using "$covidtables/taba9.tex", ///
	drop(_cons *.week *.dow b_adults b_children d_age male household_firm meter_prepaid meter_landlord ///
	d_generator appliance_types_total prior_electricity_USD) ///
	scalars("NoSubMean Mean Transfer Amount Among Recipients" "ctls Household Controls" "fe Household Fixed Effects" "Sample Sample" ) /// 
	mtitles("(1)" "(2)" "(3)" "(4)" "(5)") ///
	title("Respondent political affiliation (enumerator assessment)") ///
	varwidth(45) wrap /// 
	star(* 0.10 ** 0.05 *** 0.01) ///
	addnote("SEs clustered at household level. All outcome variables are on a scale from 1 to 5 where 1 reflects very unfavorable views of NPP (or alternatively very favorable views of NDC) and 5 reflects very favorable views of NPP. Columns 1 and 4 are the FO's overall assessment of the respondent's political affiliation. Columns 2, 3, and 5 are the respondent's assessment of NPP's performance in different areas. Column 6 is the respondent's assessment of the relative performance of NDC and NPP in addressing Dumsor. Controls for the respondent's political responses during PW deployment surveys are included where available.") ///
	se(3) nonumber nonotes label replace booktabs obs b(3) f end( \\ )
restore
	
// Voting

eststo clear
eststo: reg voted_election g_govt_percep_old $hhchars if round==3 
	su voted_election if e(sample)
	estadd scalar mean = r(mean)
eststo: reg voted_election govt $hhchars if round==3 
	su voted_election if e(sample) & govt==0
	estadd scalar mean = r(mean)
eststo: reg voted_election subsidy $hhchars if round==3 
	su voted_election if e(sample) & subsidy==0
	estadd scalar mean = r(mean)
eststo: reg voted_election i.govt##i.subsidy $hhchars if round==3 
	su voted_election if e(sample) & subsidy==0 & govt==0
	estadd scalar mean = r(mean)
	
esttab using "$covidtables/taba10.tex", ///
	drop(_cons b_adults b_children d_age male household_firm meter_prepaid meter_landlord ///
	d_generator appliance_types_total prior_electricity_USD 0.govt#0.subsidy 0.govt#1.subsidy 0.govt 0.subsidy 1.govt#0.subsidy) scalars("mean Control Mean") /// 
	mtitles("(1)" "(2)" "(3)" "(4)") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	addnote("SEs clustered at household level. All outcome dummies based on the FO's overall assessment of the respondent's political affiliation. Controls for the respondent's estimated political affiliation during PW deployment surveys are included.") ///
	se(3) nonumb nonotes label replace booktabs obs b(3) f end( \\ )

// Subsidy receipt and baseline (pre-Covid) political perspectives

eststo clear
eststo: reg subsidy $hhchars i.week i.dow g_govt_percep_old, vce(cluster hh_id)
su subsidy if !missing(g_govt_percep_old)
estadd scalar Mean = r(mean)
eststo: reg subsidy $hhchars i.week i.dow govt_old opp_old, vce(cluster hh_id)
su subsidy if !missing(govt_old)
estadd scalar Mean = r(mean)
eststo: reg subsidy $hhchars i.week i.dow g_political_dumsor_old, vce(cluster hh_id)
su subsidy if !missing(g_political_dumsor_old)
estadd scalar Mean = r(mean)
eststo: reg subsidy $hhchars i.week i.dow g_better_dumsor_old, vce(cluster hh_id)
su subsidy if !missing(g_better_dumsor_old)
estadd scalar Mean = r(mean)

esttab using "$covidtables/taba11.tex", ///
	drop(_cons *.week *.dow b_adults b_children d_age male household_firm meter_prepaid meter_landlord ///
	d_generator appliance_types_total prior_electricity_USD) scalars("Mean Dep. Var. Mean") /// 
	mtitles("(1)" "(2)" "(3)" "(4)") ///
	title("Respondent received electricity subsidy") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	addnote("SEs clustered at household level.") ///
	se(3) nonumber nonotes label replace booktabs obs b(3) f end( \\ )

// Responses to Transfer Tradeoff Scenarios

preserve
keep if round==3
eststo clear
local statvars subsidy_level tariff_even_reject f_tariff_why_1-f_tariff_why_16 ///
	amount c_equiv_loaninterest loan_even_reject c_loan_offer_why_1-c_loan_offer_why_10 
eststo sumstats: estpost tabstat `statvars', statistics(mean sd min p25 p50 p75 max count) columns(statistics)
esttab sumstats using "$covidtables/taba12.tex", ///
	noobs nonum nomtitle label end( \\ ) replace booktabs f ///
	refcat(subsidy_level "\textit{Willingness to accept transfer given next year increase in electricity costs}" ///
	amount "\textit{Willingness to accept loan given next year repayment amount}" ///
	, nolabel) ///
	cells("mean(fmt(2) label(\multicolumn{1}{c}{Mean})) sd(fmt(2) label(\multicolumn{1}{c}{SD})) min(fmt(1) label(Min)) p25(fmt(1) label(25$^{th}$)) p50(fmt(1) label(50$^{th}$)) p75(fmt(1) label(75$^{th}$)) max(fmt(1) label(Max)) count(fmt(0) label(\multicolumn{1}{c}{N})) ")
eststo clear
restore
	
// Subsidy-Tariff Tradeoffs

eststo clear
eststo: reg tariff_even_reject subsidy30 subsidyb30 f_subsidy_appropriate1 $hhchars c_loans_any c_loans_formal loan_even_reject i.week i.dow, vce(cluster hh_id)
su tariff_even_reject if subsidy==0
estadd scalar CtlMean = r(mean)
eststo: reg loan_even_reject subsidy30 subsidyb30 f_subsidy_appropriate1 $hhchars c_loans_any c_loans_formal i.week i.dow, vce(cluster hh_id)
su loan_even_reject if subsidy==0
estadd scalar CtlMean = r(mean)
esttab using "$covidtables/taba13.tex", ///
	drop(_cons *.week *.dow b_adults b_children d_age male household_firm meter_prepaid meter_landlord ///
	d_generator appliance_types_total prior_electricity_USD) ///
	scalars("CtlMean Mean - No Transfers Received") /// 
	mtitles("Electr. Transfer" "Cash Loan" ) /// 
	title("Tradeoff Scenario Decisions") ///
	star(* 0.10 ** 0.05 *** 0.01) ///
	varwidth(45) wrap /// 
	addnote("SEs clustered at household level.") ///
	se(3) numb nonotes label replace booktabs obs b(3) f end( \\ )
}
