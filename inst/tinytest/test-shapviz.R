exit_if_not(
  requireNamespace("ranger", quietly = TRUE),
  requireNamespace("shapviz", quietly=TRUE),
  packageVersion("shapviz") >= "0.8.0"
)

# Read in the data and clean it up a bit
set.seed(2220)  # for reproducibility
trn <- gen_friedman(500)
tst <- gen_friedman(10)

# Features only
X <- subset(trn, select = -y)
newX <- subset(tst, select = -y)

# Fit a default random forest
set.seed(2222)  # for reproducibility
rfo <- ranger::ranger(y ~ ., data = trn)

# Prediction wrapper
pfun <- function(object, newdata) {
  predict(object, data = newdata)$predictions
}

# Generate explanations for test set
set.seed(2024)  # for reproducibility
ex1 <- explain(rfo, X = X, newdata = newX, pred_wrapper = pfun, adjust = TRUE,
               nsim = 50)

# Same, but set `shap_only = FALSE` for convenience with shapviz
set.seed(2024)  # for reproducibility
ex2 <- explain(rfo, X = X, newdata = newX, pred_wrapper = pfun, adjust = TRUE,
               nsim = 50, shap_only = FALSE)

# Create "shapviz" objects
shv1 <- shapviz::shapviz(ex1, X = newX)
shv2 <- shapviz::shapviz(ex2)
shv3 <- shapviz::shapviz(ex2$shapley_values, X = newX, baseline = ex2$baseline)

# Expectations
expect_error(shapviz::shapviz(ex1))
expect_identical(ex2$baseline, mean(pfun(rfo, X)))
expect_identical(shv1$X, shv2$X)
expect_identical(shv1$X, shv3$X)
expect_identical(shv1$baseline, shv2$baseline)
expect_identical(shv1$baseline, shv3$baseline)

# # SHAP waterfall plots
# shapviz::sv_waterfall(shv1, row_id = 1)
# shapviz::sv_waterfall(shv2, row_id = 1)
# shapviz::sv_waterfall(shv3, row_id = 1)
