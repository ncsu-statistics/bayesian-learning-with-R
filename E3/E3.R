rm(list = ls())
library(rle)
setwd("c:/e/brucebcampbell-git/bayesian-learning-with-R/E3")

load("heatwaves.RData")

plot(y[1,1:365,1])
abline(h = quantile(y[1,1:365,1],.95))

###################################################################
#  HW  = 3 consecutive days above 95th quantile for that year
###################################################################
X.num <- matrix(nrow =41, ncol = 9 )
X.sev <- matrix(nrow =41, ncol = 9 )

for(i in 1:41)
{
  for(k in 1:9)
  {
    data <- y[i,1:365,k]
    data <- na.exclude(data)
    q_ik <-  quantile(data,.95)
    hot_ik <- data > q_ik
    run_lengths <- rle(hot_ik)
    df_rl <- data.frame(l = run_lengths$lengths,v = run_lengths$values)
    hot_groups <- df_rl[df_rl$v==TRUE,]
    heat_waves <- hot_groups[hot_groups$l>3,]
    num_hw <- nrow(heat_waves)
    sev_hw <- sum(heat_waves$l)
    
    X.num[i,k] <- num_hw
    X.sev[i,k] <- sev_hw
  }
    
}

image(X.num)
image(X.sev)
f<- rowSums(X.num)
plot(f)
f<- rowSums(X.sev)
plot(f)
plot(X.sev[,1])
plot(X.sev[,2])
plot(X.sev[,3])
plot(X.sev[,4])
plot(X.sev[,5])
plot(X.sev[,6])
plot(X.sev[,7])
plot(X.sev[,8])
plot(X.sev[,9])


###################################################################
#  HW  = World Meteorological Organization definition
#  daily temperature for more than five consecutive days exceeds the average temperature by 9 degrees
###################################################################
X.num <- matrix(nrow =41, ncol = 9 )
X.sev <- matrix(nrow =41, ncol = 9 )

#Daily Averages
DA <- matrix(nrow = 365,ncol = 9)
for(j in 1:365)
{
  for(k in 1:9)
  {
    data <- y[1:41,j,k]
    data <- na.exclude(data)
    DA[j,k] <- mean(data)
  }
}
plot(y[1,1:365,1]); lines(DA[,1],col='red')


AboveDA.Idx <- y
for(i in 1:41)
{
  for(k in 1:9)
  {
    for(j in 1:365)
    {
      t <- y[i,j,k]
      A <- DA[j,k]
      isHot <- t >=A+9
      AboveDA.Idx[i,j,k] <- isHot
    }
  }
}

X.num <- matrix(nrow =41, ncol = 9 )
X.sev <- matrix(nrow =41, ncol = 9 )

for(i in 1:41)
{
  for(k in 1:9)
  {
    data <- AboveDA.Idx[i,1:365,k]
    data <- na.exclude(data)
    run_lengths <- rle(as.vector(data))
    df_rl <- data.frame(l = run_lengths$lengths,v = run_lengths$values)
    hot_groups <- df_rl[df_rl$v==TRUE,]
    heat_waves <- hot_groups[hot_groups$l>5,]
    num_hw <- nrow(heat_waves)
    sev_hw <- sum(heat_waves$l)
    
    X.num[i,k] <- num_hw
    X.sev[i,k] <- sev_hw
  }
  
}

image(X.num)
image(X.sev)
f<- rowSums(X.num)
plot(f)
f<- rowSums(X.sev)
plot(f)
plot(X.sev[,1])
plot(X.sev[,2])
plot(X.sev[,3])
plot(X.sev[,4])
plot(X.sev[,5])
plot(X.sev[,6])
plot(X.sev[,7])
plot(X.sev[,8])
plot(X.sev[,9])



###############################
#Plot the prior, likelihood, and posterior on a grid
k=1
for(i in 1:41)
{
  N      <- 1
  Y      <- X.num[i,k]
  a      <- 1
  b      <- 0.5
  grid   <- seq(0.01,10,.01)
  like   <- dpois(Y,N*grid)
  like   <- like/sum(like) #standardize
  prior  <- dgamma(grid,a,b)
  prior  <- prior/sum(prior) #standardize
  post   <- like*prior
  post   <- post/sum(post)
  ps.mean <-sum(post*grid)
  plot(grid,like,type="l",lty=2,
       xlab="lambda",ylab="Density",main=paste(Y," post mean = ",ps.mean,sep = ' '), ylim=c(0,.1))
   lines(grid,prior)
  lines(grid,post,lwd=2)
  legend("topright",c("Likelihood","Prior","Posterior"),lwd=c(1,1,2),lty=c(2,1,1),inset=0.05)
}

################################## Find MLE of fit to pois and negbinom, and fit glm's with time as predictor
mle.nb.params <- matrix(nrow = 9,ncol = 2)
mle.pois.params <- matrix(nrow = 9,ncol = 1)

mle.nb.glm.params <- matrix(nrow = 9,ncol = 8)
mle.pois.glm.params <- matrix(nrow = 9,ncol = 8)
for(k in 1:9)
{
  hist(X.num[,k])
  library(fitdistrplus)   
  library(gamlss)          
  fit_nb <- fitdist(X.num[,k], 'nbinom', start = list(mu = 3, size = 0.1)) 
  mle.nb.params[k,1] <- fit_nb$estimate[1]
  mle.nb.params[k,2] <- fit_nb$estimate[2]
  
  fit_pois <- fitdist(X.num[,k], 'pois',method = 'mle')
  mle.pois.params[k,1] <- fit_pois$estimate[1]
  #plot(fit_nb)
  #gofstat(fi_nb)
  
  df <- data.frame(t=seq(1:41),Y=X.num[,k])
  model.pois <- glm( Y~ t, family=poisson, df)
  sp <- summary.glm(model.pois)
  
  model.nb <- glm.nb(Y~t,data=df)
  snb <- summary.glm(model.nb)
  
  mle.nb.glm.params[k,1:4] <- snb$coefficients[1,]
  mle.nb.glm.params[k,5:8] <- snb$coefficients[2,]
  
  mle.pois.glm.params[k,1:4] <- sp$coefficients[1,]
  mle.pois.glm.params[k,5:8] <- sp$coefficients[2,]
}

colnames(mle.nb.glm.params) <- c(colnames(snb$coefficients),colnames(snb$coefficients))

colnames(mle.pois.glm.params) <- c(colnames(sp$coefficients),colnames(sp$coefficients))



###################################### Fit JAGS GLM Models for Negative Binomial
library(rjags)
library(coda)
model_code = '
model
{
  ## Likelihood
    for(i in 1:N){
  Y[i] ~ dnegbin(p[i],r)
  p[i] <- r/(r+lambda[i]) 
  log(lambda[i]) <- mu[i]
  mu[i] <- intercept + beta*t[i]
  } 
  ## Priors
  beta ~ dnorm(mu.beta,tau.beta)
  intercept ~ dnorm(mu.intercept,tau.intercept)
  r ~ dunif(0,50)
}
'
for(k in 1:5)
{
  # Set up the data
  model_data = list(N = 41, t=seq(1:41),Y=X.num[,k],mu.beta=0,tau.beta=.0001,mu.intercept=0,tau.intercept=.0001  )
  # Choose the parameters to watch
  model_parameters =  c("r","beta", "intercept")
  n.chains =2;nSamples = 10000
  model <- jags.model(textConnection(model_code),data = model_data,n.chains = n.chains)#Compile Model Graph
  update(model, nSamples, progress.bar="none"); # Burnin
  out.coda  <- coda.samples(model, variable.names=model_parameters,n.iter=2*nSamples) 
  plot(out.coda)
  #assess the posteriors??? stationarity, by looking at the Heidelberg-Welch convergence diagnostic:
  heidel.diag(out.coda) 
  # check that our chain???s length is satisfactory.
  raftery.diag(out.coda)  
  
  geweke.diag(out.coda)
  
  if(n.chains > 1)
  {
    gelman.srf <-gelman.diag(out.coda)
    plot(gelman.srf$psrf,main = "Gelman Diagnostic")
  }
  
  chains.ess <- lapply(out.coda,effectiveSize)
  first.chain.ess <- chains.ess[1]
  plot(unlist(first.chain.ess), main="Effective Sample Size")
} 























