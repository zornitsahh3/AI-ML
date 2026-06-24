# your session times (made up but realistic)
page_a <- c(164, 130, 152, 188, 201, 173, 145, 210, 189, 167,
            178, 142, 196, 155, 183, 170, 161, 199, 148, 175, 190)

page_b <- c(196, 212, 185, 234, 193, 221, 178, 208, 245, 199,
            215, 203, 188, 227, 211)

# observed difference
observed_diff <- mean(page_b) - mean(page_a)
cat("Observed difference:", round(observed_diff, 1), "seconds\n")

# permutation test
set.seed(42)
n_permutations <- 10000
all_times      <- c(page_a, page_b)
n_a            <- length(page_a)
perm_diffs     <- numeric(n_permutations)

for (i in 1:n_permutations) {
  shuffled      <- sample(all_times)             # shuffle all 36 times #Yes, exactly. When you call sample() on a vector without a size argument, it returns all the elements in a random order
  fake_a        <- shuffled[1:n_a]               # first 21 go to fake A
  fake_b        <- shuffled[(n_a + 1):length(shuffled)]  # rest to fake B
  perm_diffs[i] <- mean(fake_b) - mean(fake_a)  # record the gap
}

# p-value: how often did chance produce a gap >= what we observed?
p_value <- mean(abs(perm_diffs) >= abs(observed_diff)) #This compares each of the 10,000 values against 21.4. Returns a logical vector of 10,000 TRUE/FALSE values
cat("P-value:", round(p_value, 4), "\n")
#1e-04 is scientific notation for 0.0001 — i.e. 1 divided by 10,000.
#It means: in 10,000 random shuffles, only 1 produced a gap as large as the one you observed. That's very strong evidence the result is not due to chance

# as a decimal
cat("P-value:", format(p_value, scientific = FALSE), "\n")
# prints: P-value: 0.0001

# as a percentage
cat("P-value:", round(p_value * 100, 4), "%\n")
# prints: P-value: 0.01 %

# plain English
cat("Only", sum(abs(perm_diffs) >= abs(observed_diff)),
    "out of", n_permutations, "random shuffles produced a gap this large.\n")
# prints: Only 1 out of 10000 random shuffles produced a gap this large.