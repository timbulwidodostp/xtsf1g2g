{smcl}
{right:version 1.1  12Aug2020}
{cmd:help xtsf1g}
{hline}


{marker title}{...}
{title:Title}

{p2colset 5 20 22 2}{...} {phang} {bf:xtsf1g} {hline 2} the first-generation estimator of the stochastic frontier model for panel data, where effciency is time-invariant. Unbalanced panels are supported{p_end} {p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 10 17 2} {cmd:xtsf1g} {it:{help varlist:depvar}} {it:{help varlist:indepvars}} {ifin}, [{cmd:}{it:{help xtsf1g##options:options}}]

{synoptset 34 tabbed}{...}
{marker Specification}{...}
{synopthdr:Specification}
{synoptline}
{syntab :Frontier}
{synopt :{it:{help varname:depvars}}}left-hand-side variable{p_end}
{synopt :{it:{help varname:indepvars}}}right-hand-side variables. {it:indepvars} may contain factor variables; see {help fvvarlist}{p_end}
{synopt :{opt nocons:tant}}suppress constant term{p_end}

{synoptset 34 tabbed}{...}
{synopthdr :options}
{synoptline}
{syntab :Error Components}
{synopt :{cmdab:d:istribution(}{opt h:normal)}}half-normal distribution for the
inefficiency term{p_end}
{synopt :{cmdab:d:istribution(}{opt t:normal)}}truncated-normal distribution for the inefficiency term{p_end}
{synopt :{cmdab:vitlnv:ariance(}{it:{help varlist:zvit}}[{cmd:,} {opt nocons:tant}]{cmd:)}}explanatory variables for idiosyncratic error variance function; use {opt noconstant} to suppress constant term. {it:zvit} may contain factor variables; see {help fvvarlist}{p_end}
{synopt :{cmdab:uilnv:ariance(}{it:{help varlist:zui}}[{cmd:,} {opt nocons:tant}]{cmd:)}}determinants of the heteroskedasticity function of the inefficiency term; use {opt noconstant} to suppress constant term. {it:zui} may contain factor variables; see {help fvvarlist}{p_end}
{synopt :{cmdab:uim:ean(}{it:{help varlist:zmi}}[{cmd:,} {opt nocons:tant}]{cmd:)}}determinants of the expected value of the inefficiency term (Kumbhakar, Ghosh, and McGuckin, 1991); use {opt noconstant} to suppress constant term. {it:zmi} may contain factor variables; see {help fvvarlist}{p_end}

{syntab :Cost frontier}
{synopt :{opt cost}}fit cost frontier model; default is production frontier
model{p_end}
{synopt :{opt celessthanone}}efficiencies smaller than one with {cmd:cost} {p_end}

{syntab :Reporting}
{synopt :{opt lev:el(#)}}set confidence level; default as set by set level{p_end}

{syntab:Maximization}
{synopt :{opt iter:ate(#)}}perform maximum of # iterations; default is iterate(102){p_end}
{synopt :{opt trace:level}}display current parameter vector in iteration log{p_end}
{synoptline}
{p2colreset}{...}

{marker description}{...}
{title:Description}

{pstd}
{cmd:xtsf1g} fits the first-generation SF models for panel data, where the variances or both noise and inefficiency terms as well as the conditional mean of inefficiency can have expanatory variables (determinants).

{pstd}
It allows using factor variables (see {help fvvarlist}). Unbalanced panels are supported.

{pstd}The distribution of inefficiency term can be either half-normal or truncated normal. If {cmd:uimean} is specified, the distribution is truncated normal.

{pstd}See {help xtsf1g_postestimation:xtsf1g postestimation} for features available after estimation.

{marker options}{...}
{title:Options}

{dlgtab:Error Components}

{phang} {opt distribution(name)} specifies the distribution for the inefficiency term as half-normal (h) or truncated-normal (t).

{phang}
{cmd:vitlnvariance(}{help varlist:zvit} [{cmd:,} {opt noconstant}]{cmd:)} specifies that the idiosyncratic error component {it:v} is heteroskedastic, and the log of the heteroskedasticity function is modeled as a linear function {it:f} of the set of covariates specified in {it:zvit}: log(Var({it:v})) = f(zvit).  Specifying {opt noconstant} suppresses the constant term from the variance function.

{phang}
{cmd:uilnvariance(}{help varlist:zui} [{cmd:,} {opt noconstant}]{cmd:)} specifies that the inefficiency component {it:u} is heteroskedastic, and the log of the heteroskedasticity function is modeled as a linear function {it:g} of the set of covariates specified in {it:zui}: log(Var({it:u})) = g(zui).  Specifying {opt noconstant} suppresses the constant term from the variance function. If {cmd:zui} is not time constant, {cmd:xtsf1g} will use average of {cmd:zui}.

{phang}
{cmd:uimean(}{help varlist:zmi} [{cmd:,} {opt noconstant}]{cmd:)} specifies that mean of the truncated-normal distribution is modeled as a linear function {it:h} of the set of covariates specified in {it:varlist}: E[ui|z] = h(zui). Specifying {opt noconstant} suppresses the constant in the mean function.If {cmd:zmi} is not time constant, {cmd:xtsf1g} will use average of {cmd:zmi}.

{dlgtab:Cost frontier}

{phang} {opt cost} specifies that frontier fit a cost frontier model

{phang} {opt celessthanone} specifies that efficiencies smaller than one with {cmd:cost}

{dlgtab:Reporting}

{phang} {opt level(#)}; see {helpb estimation options##level():[R] estimation options}.

{dlgtab:Maximization}

{phang} {opt iterate(#)} specifies the maximum number of iterations.

{phang} {opt trace} adds to the iteration log a display of the current parameter vector.


{title:Example}

{pstd}Use the data only to show functionality, no theory behind the regression. Note how big the dataset is: N = 4698, sum of Ti = 28036.{p_end}
{phang2}{cmd:. webuse nlswork, clear}{p_end}

{pstd}Supose the wage frontier is determined by `job tenure, in years`, `total work experience`, and if worker is college graduate{p_end}
{phang2}{cmd:. xtsf1g ln_wage tenure ttl_exp collgrad}{p_end}

{pstd}The same as before, but assume the distribution of inefficiency is truncated normal{p_end}
{phang2}{cmd:. xtsf1g ln_wage tenure ttl_exp collgrad, d(t)}{p_end}
{pstd}The truncation point is not significant{p_end}

{pstd}Return to the half-normal and assume `age` explains the inefficiency heteroskedasticity function{p_end}
{phang2}{cmd:. xtsf1g ln_wage tenure ttl_exp collgrad, uilnvariance(age)}{p_end}

{pstd}Assume `hours` explains the noise heteroskedasticity function; suppress intercept in the inefficiency heteroskedasticity function{p_end}
{phang2}{cmd:. xtsf1g ln_wage tenure ttl_exp collgrad, uilnvariance(age, nocons) vitlnvariance(hours)}{p_end}

{title:Saved results}

{pstd}
{cmd:xtsf1g} saves the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(sumTi})}the sum of T_i, i = 1,...,N{p_end}
{synopt:{cmd:e(converged)}}1 if converged, 0 otherwise{p_end}
{synopt:{cmd:e(r2)}}R-squared{p_end}
{synopt:{cmd:e(r2_a)}}R-squared adjusted{p_end}
{synopt:{cmd:e(aic)}}AIC{p_end}
{synopt:{cmd:e(bic)}}BIC{p_end}
{synopt:{cmd:e((ll})}log likelihood{p_end}
{synopt:{cmd:e(shat})}standard error of the regression{p_end}
{synopt:{cmd:e(RSS})}RSS{p_end}
{synoptset 20 tabbed}{...} {p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:xtsf1g}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:e(predict)}}program used to implement {opt predict}{p_end}
{synopt:{cmd:e(properties)}}{opt b V}{p_end}
{synoptset 20 tabbed}{...} {p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}vector of estimated coefficients{p_end}
{synopt:{cmd:e(V)}}estimated variance-covariance matrix{p_end}
{synopt:{cmd:e(residuals)}}residuals{p_end}
{synopt:{cmd:e(u_mean)}}E[ui|ei]{p_end}
{synopt:{cmd:e(u_mode)}}M[ui|ei]{p_end}
{synopt:{cmd:e(eff_mean)}}Measures of efficiency, JLMS:= exp(-E[ui|ei]){p_end}
{synopt:{cmd:e(eff_mode)}}Measures of efficiency, Mode:= exp(-M[ui|ei]){p_end}
{synopt:{cmd:e(eff_bc)}}Measures of efficiency, BC:= E[exp(-ui)|ei]{p_end}
{synopt:{cmd:e(eff_lb)}}Lower bound of  exp(-E[ui|ei]){p_end}
{synopt:{cmd:e(eff_ub)}}Upper bound of  exp(-E[ui|ei]){p_end}

{synoptset 20 tabbed}{...}{p2col 5 20 24 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}
{p2colreset}{...}

{marker references}{...}
{title:References}

{phang}
Caudill, Steven B., Ford, Jon M. and Gropper, Daniel M. (1995) "Frontier Estimation and Firm-Specific Inefficiency Measures in the Presence of Heteroscedasticity,” {it:Journal of Business & Economic Statistics}, 1995, 13(1), 105–111

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

{p 7 14 2}Help: {help xtsf1g}, {help xtsf2gbi}, {help xtsf3gpss1}, {help xtsf3gpss2}, {helpb xtsf3gpss3}, {help xtsf3gkss} (if installed){p_end}
