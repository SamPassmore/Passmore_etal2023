# PCA simulation
library(psych)

# Fake Cantometrics data
df = sapply(1:5000, function(x) sample(1:13, size = 37, replace = TRUE))
df = t(df)

scree(df)

fit = principal(df)
# eigenvalues > 1
sum(fit$values > 1)
fit$values[fit$values > 1]

# eigenvalue percentage
fit$values[fit$values > 1] / sum(fit$values)
