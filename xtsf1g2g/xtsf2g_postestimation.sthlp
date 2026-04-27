{smcl}
{* *! version 1.0  5Aug2020}{...}
manual for {cmd:xtsf2g} postestimation
{hline}


{marker title}{...}
{title:Title}

{p2colset 1 32 34 2}{...}
{phang}{bf:xtsf2g postestimation} {hline 2} Postestimation tools for {help xtsf2g:xtsf2g}{p_end} {p2colreset}{...}


{marker description}{...}
{title:Postestimation commands}

{pstd}
The following postestimation commands are available after {opt xtsf2g}:

{synoptset 17}{...}
{p2coldent :Command}Description{p_end}
{synoptline}
{synopt :{helpb lincom}}Linear combinations of parameters{p_end}
{synopt :{helpb nlcom}}Nonlinear combinations of estimators{p_end}
{synopt :{helpb predictnl}}Obtain nonlinear predictions, standard errors, etc., after estimation{p_end}
{synopt :{helpb test}}Test linear hypotheses after estimation{p_end}
{synopt :{helpb testnl}}Test nonlinear hypotheses after estimation{p_end}
{synopt :{helpb xtsf2g postestimation##predict:predict}}predictions, residuals, efficiency measures, confidence intervals{p_end}
{synoptline}
{p2colreset}{...}

{marker syntax_predict}{...}
{marker predict}{...}
{title:Syntax for predict}

{p 8 16 2}
{cmd:predict}
{newvar}
{ifin}
[{cmd:,} {it:statistic}]

{synoptset 17 tabbed}{...}
{synopthdr :statistic}
{synoptline}
{syntab :Main}
{synopt :{opt xb}}linear prediction; the default{p_end}
{synopt :{opt resid:uals}}residuals{p_end}
{synopt :{opt te_jlms_mean}}produces estimates of time-varying efficiency measures, JLMS:= exp(-E[ui|ei]){p_end}
{synopt :{opt te_jlms_mode}}produces estimates of time-varying efficiency measures, Mode:= exp(-M[ui|ei]){p_end}
{synopt :{opt te_bc}}produces estimates of time-varying efficiency measures, BC:= E[exp(-ui)|ei]{p_end}
{synopt :{opt u_mean}}produces measures of inefficiency, E[ui|ei]{p_end}
{synopt :{opt u_mode}}produces measures of inefficiency, M[ui|ei]{p_end}
{synopt :{opt te_lb}}Produces the lower bound of  exp(-E[ui|ei]){p_end}
{synopt :{opt te_ub}}Produces the upper bound of  exp(-E[ui|ei]){p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
These statistics are available only in sample; by default {cmd:e(sample)} is used, which defines the estimation sample.

{marker des_predict}{...}
{title:Description for predict}

{pstd}
{cmd:predict} creates a new variable containing predictions such as
linear predictions, residuals, and estimates of technical efficiency.


{marker options_predict}{...}
{title:Options for predict}

{dlgtab:Main}

{phang}
{opt xb}, calculates the linear prediction.

{phang}
{opt resid:uals} calculates the residuals.

{phang}
{opt te_*} produces estimates of time-varying efficiency measures and confidence intervals.

{phang}
{opt u_*} produces estimates of time-varying inefficiency measures.

{marker examples}{...}
{title:Examples}

{pstd}Use the data only to show functionality, no theory behind the regression. Note how big the dataset is: N = 4698, sum of Ti = 28036.{p_end}
{phang2}{cmd:. webuse nlswork, clear}{p_end}

{pstd}Supose the wage frontier is determined by `job tenure, in years`, `total work experience`, and if worker is college graduate, estimate the Kumbhakar (1990) specificaiton of beta[t]. Further, assume `age` explains the inefficiency heteroskedasticity function and `hours` explains the noise heteroskedasticity function; suppress intercept in the inefficiency heteroskedasticity function{p_end}
{phang2}{cmd:. xtsf2g ln_wage tenure ttl_exp collgrad, uilnvariance(age, nocons) vitlnvariance(hours)}{p_end}

{pstd}Estimate technical efficiency{p_end}
{phang2}{cmd:. predict efficiency_mean, te_jlms_mean}{p_end}
{phang2}{cmd:. predict efficiency_mode, te_jlms_mode}{p_end}
{phang2}{cmd:. predict efficiency_bc, te_bc}{p_end}

{pstd}The correlation is very high between them{p_end}
{phang2}{cmd:. correlate efficiency_*}{p_end}

{pstd}Estimate 95% confidence intervals, which is the default{p_end}
{phang2}{cmd:. predict efficiency_lb_95, te_lb}{p_end}
{phang2}{cmd:. predict efficiency_ub_95, te_ub}{p_end}


{marker references}{...}
{title:References}

{phang}
Battese, George E. and Coelli, Tim J. (1992) "Frontier production functions, technical efficiency and panel data: With application to paddy farmers in India," {it:Journal of Productivity Analysis}, 3(1-2), 153–169

{phang}
Caudill, Steven B., Ford, Jon M. and Gropper, Daniel M. (1995) "Frontier Estimation and Firm-Specific Inefficiency Measures in the Presence of Heteroscedasticity,” {it:Journal of Business & Economic Statistics}, 1995, 13(1), 105–111

{phang}
Kumbhakar, Subal C., “Production frontiers, panel data, and time-varying technical inefficiency,” {it:Journal of Econometrics}, 1990, 46(1-2), pp. 201–211

{phang}
Kumbhakar, Subal C., Ghosh, Soumendra and McGuckin, J Thomas (1991) “A Generalized Production Frontier Approach for Estimating Determinants of Inefficiency in U.S. Dairy Farms,” {it:Journal of Business & Economic Statistics}, 9(3), 279–286

{phang}
Kumbhakar, Subal C. and Lovell, C. A. Knox (2000) {it:Stochastic Frontier Analysis}, Cambridge University Press

{phang}
Stevenson, Rodney E. (1980) "Likelihood functions for generalized stochastic frontier estimation,” {it:Journal of Econometrics}, 13(1), 57–66

{title:Author}

{psee} Oleg Badunenko{p_end}{psee} Brunel University London{p_end}{psee}E-mail: oleg.badunenko@brunel.ac.uk {p_end}

{title:Disclaimer}

{pstd} This software is provided "as is" without warranty of any kind, either expressed or implied. The entire risk as to the quality and
performance of the program is with you. Should the program prove defective, you assume the cost of all necessary servicing, repair or
correction. In no event will the copyright holders or their employers, or any other party who may modify and/or redistribute this software,
be liable to you for damages, including any general, special, incidental or consequential damages arising out of the use or inability to
use the program.{p_end}

{title:Also see}

{p 7 14 2}Help: {help xtsf1g}, {help xtsf2g}, {help xtsf2gbi}, {help xtsf3gpss1}, {help xtsf3gpss2}, {helpb xtsf3gpss3}, {help xtsf3gkss} (if installed){p_end}
