library(tidyverse)
set.seed(42) #makes random results reproducible

#simulate 5 million adult heights
#true mean: 172cm, true sd: 10cm
population <- rnorm(n = 5000000, mean = 172, sd = 10)
population %>% head()
#the "true" values we're trying to estimate
true_mean <- mean(population)
true_Sd <- sd(population)

cat("True mean:", round(true_mean, 3), "\n")
cat("True SD:  ", round(true_Sd, 3), "\n")

#Step 2 — Take one sample and compute statistics
n <- 30  # sample size

sample1 <- sample(population, size = n)  # like Python's random.sample()

# descriptive statistics
cat("Sample mean:  ", round(mean(sample1), 3), "\n")
cat("Sample SD:    ", round(sd(sample1), 3), "\n")
cat("True mean was:", round(true_mean, 3), "\n")

#Step 3 — Build a confidence interval using the t-distribution
#This is where the t-distribution enters. We don't know the true σ, so we use our sample SD and the t-distribution to express our uncertainty:

sample_mean <- mean(sample1)
sample_sd <- sd(sample1)
se <- sample_sd/sqrt(n) #standard error - how much sample means vary

#t critical value for 95% confidence, df=n-1
t_critical <-qt(0.975,df=n-1) #qt() is the t-distribution quantile function

margin <-t_critical*se
lower <- sample_mean-margin
upper <- sample_mean+margin
cat("Sample mean:      ", round(sample_mean, 2), "\n")
cat("95% CI:           ", round(lower, 2), "to", round(upper, 2), "\n")
cat("True mean inside?:", true_mean >= lower & true_mean <= upper, "\n")
#The confidence interval tells you: if we repeated this many times, 95% of our intervals would contain the true mean.

#Step 4 — Repeat the experiment 1000 times
#This is the core of Gossett's insight. Let's actually do what he imagined:
n_experiments <- 1000

results <-tibble(
  experiment = 1:n_experiments,
  sample_mean=numeric(n_experiments),
  lower_ci=numeric(n_experiments),
  upper_ci=numeric(n_experiments)
)

for (i in 1:n_experiments){
  s<-sample(population,size=n)
  m<-mean(s)
  se<-sd(s)/sqrt(n)
  t_crit<-qt(0.975,df=n-1)
  
  results$sample_mean[i] <- m
  results$lower_ci[i]<-m-t_crit*se
  results$upper_ci[i]<-m+t_crit*se
}

results <- results |>
  mutate(captured = lower_ci <= true_mean & true_mean <= upper_ci)

colnames(results)
cat("CIs that captured true mean:", sum(results$captured), "out of", n_experiments, "\n")
cat("That's", round(mean(results$captured) * 100, 1), "% — should be close to 95%\n")

ggplot(results, aes(x = sample_mean)) +
  geom_histogram(aes(y = after_stat(density)),
                 bins = 40, fill = "steelblue", color = "white", alpha = 0.7) +
  geom_density(color = "darkblue", linewidth = 1) +
  geom_vline(xintercept = true_mean, color = "red",
             linetype = "dashed", linewidth = 1) +
  labs(
    title    = "Sampling Distribution of the Mean (n=30, 1000 experiments)",
    subtitle = "Red line = true population mean",
    x        = "Sample Mean Height (cm)",
    y        = "Density"
  ) +
  theme_minimal()

results |> slice(1:50) |>
  ggplot(aes(x = factor(experiment), y = sample_mean, color = captured)) +
  geom_point() +
  geom_errorbar(aes(ymin = lower_ci, ymax = upper_ci), width = 0.3) +
  geom_hline(yintercept = true_mean, color = "red",
             linetype = "dashed", linewidth = 1) +
  scale_color_manual(values = c("FALSE" = "tomato", "TRUE" = "steelblue")) +
  coord_flip() +
  labs(title = "95% Confidence Intervals — First 50 Experiments",
       color = "Captured") +
  theme_minimal()
