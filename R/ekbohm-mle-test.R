#' Ekbohm’s MLE-based test under homoscedasticity
#' 
#' \code{ekbohm.mle.test} uses Ekbohm’s MLE-based test under homoscedasticity
#' to obtain a p-value for a partially matched pairs test.
#' 
#' Ekbohm’s test makes use of a modified maximum likelihood estimator and
#' assumption of homoscedasticity. Under the null hypothesis, the resulting test
#' statistic Z_E, follows an approximate t distribution with n1 degrees of
#' freedom. Mathematical details are provided in [Kuan & Huang, 2013].
#' 
#' If proper sample size conditions are not met, then \code{ekbohm.mle.test} may
#' exit or perform a paired or unpaired two-sample t.test, depending on the
#' nature of the sample size issue.
#' 
#' If the variance of input data is close to zero, \code{ekbohm.mle.test} will
#' return an error message.
#'
#' @param x a non-empty numeric vector containing some NA values
#' @param y a non-empty numeric vector containing some NA values
#' @param alternative specification of the alternative hypothesis.
#' Takes values: \code{"two.sided"}, \code{"greater"}, or \code{"less"}.
#'
#' @return p-value associated with the hypothesis test
#'
#' @examples
#' In the following, the true means are not equal:
#' 
#' x = rnorm(400, 0, 1)
#' x[sample(1:400, size=75, replace=FALSE)] = NA
#' y = rnorm(400, 0.4, 3)
#' y[sample(1:400, size=75, replace=FALSE)] = NA
#' ekbohm.mle.test(x, y, alternative = 'two.sided')
#' 
#' @references
#' Kuan, Pei Fen, and Bo Huang. "A simple and robust method for partially
#' matched samples using the p‐values pooling approach." Statistics in 
#' medicine 32.19 (2013): 3247-3259.
#'
#' @export
ekbohm.mle.test = function(x, y,
                           alternative = c('two.sided', 'greater', 'less')) {
     # check whether length(x)==length(y)
     if (length(x)!=length(y)) {
          if (sum(!is.na(x))<3 | sum(!is.na(y))<3) {
               stop('Sample sizes are too small and length of x ',
                    'should equal length of y.')
          } else {
               warning('Length of x should equal length of y. ',
                       'Two sample t-test attempted')
               return (t.test(x[!is.na(x)], y[!is.na(y)])$p.value)
          }
     }
     pair.inds = !is.na(x) & !is.na(y)
     only.x = !is.na(x) & is.na(y)
     only.y = !is.na(y) & is.na(x)
     pair.x = x[pair.inds]
     pair.y = y[pair.inds]
     # test whether appropriate sample size conditons are met
     n1 = sum(pair.inds)
     n2 = sum(only.x)
     n3 = sum(only.y)
     if (n1<4 & n2+n3<5) {
             stop('Sample sizes are too small')
     } else if (n1>=4 & n2+n3<5) {
             warning('Not enough missing data for modified t-test. ',
                     'Matched pairs t-test attempted')
             return (t.test(pair.x, pair.y,
                            alternative = alternative, paired = TRUE)$p.value)
     } else if (n1<4 & n2+n3>=5) {
             warning('Not enough matched pairs for modified t-test. ',
                     'Two sample t-test attempted')
             return (t.test(x[only.x], y[only.y],
                            alternative = alternative)$p.value)
     }
     # else, n1>=4 and n2+n3>=5 is met, Ekbohm MLE test is executed
     T.bar = mean(x[!is.na(x)])
     N.bar = mean(y[!is.na(y)])
     ST = sd(x[!is.na(x)])
     SN = sd(y[!is.na(y)])
     T1.bar = mean(pair.x)
     N1.bar = mean(pair.y)
     ST1 = sd(pair.x)
     SN1 = sd(pair.y)
     STN1 = cov(pair.x, pair.y)
     # check whether variance of data is approx. zero
     if (ST   < 10*.Machine$double.eps * abs(T.bar)  &
         SN   < 10*.Machine$double.eps * abs(N.bar)  &
         ST1  < 10*.Machine$double.eps * abs(T1.bar) &
         SN1  < 10*.Machine$double.eps * abs(N1.bar) &
         STN1 < 10*.Machine$double.eps * 
         max(abs(mean(pair.x)), abs(mean(pair.y)))){
             stop('Variance of data is too close to zero')
     }
     r = STN1 / (ST1 * SN1)
     f.star = n1*(n1+n3+n2*r) / ((n1+n2)*(n1+n3)-n2*n3*r^2)
     g.star = n1*(n1+n2+n3*r) / ((n1+n2)*(n1+n3)-n2*n3*r^2)
     sigma.hat.sq = ((n1-1)*ST1^2 + (n1-1)*SN1^2 +
                     (1+r^2)*((n2-1)*ST^2 + (n3-1)*SN^2) ) / 
                     (2*(n1-1) + (1+r^2)*(n2+n3-2))
     V1.star = sigma.hat.sq * (2*n1*(1-r) + (n2+n3)*(1-r^2)) /
                              ((n1+n2)*(n1+n3)-n2*n3*r^2)
     Ze = (f.star*(T1.bar-T.bar) - g.star*(N1.bar-N.bar) + T.bar - N.bar) /
          sqrt(V1.star)
     if (all(alternative == 'greater')) {
          p.value = pt(Ze, n1, lower.tail = FALSE)
     } else if (all(alternative == 'less')) {
          p.value = pt(Ze, n1, lower.tail = TRUE)
     } else if (all(alternative == 'two.sided')) {
          p.value = 2*pt(abs(Ze), n1, lower.tail = FALSE)
     }
     return (p.value)
}
