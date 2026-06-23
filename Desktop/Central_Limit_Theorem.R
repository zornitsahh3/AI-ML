library(dplyr) #to use %>%
population<-rnorm(100000,mean=172,sd=10)
#sample of 1000 values
sample1<-sample(population,size=1000)
sample1%>%head
hist(sample1)

#a sample of 1,000 means of 5 values
#what it means:
# 1 draw 5 values
# 2 compute their mean
# 3 repeat 1000 times

means5<-numeric(1000)
for (i in 1:1000){
  means5[i] <- mean(sample(population,size=5))
}
means5%>%head
hist(means5)

means20 <- numeric(1000)
for (i in 1:1000){
  means20[i]<-mean(sample(population,size=20))
}
means20%>%head
hist(means20)

means100<-numeric(1000)
for (i in 1:1000){
  means100[i]<-mean(sample(population,size=100))
}
hist(means100)
