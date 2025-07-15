## Confusion Matrix

This evaluates model performance by applying the trained classifier to the test data and comparing model-predicted attrition to actual attrition.  This yields a number of statistics, which we will not go into here.  We will focus on only three numbers:

1. Accuracy - the proportion of test cases whose model-predicted values match their actual values;
1. No Information Rate - the accuracy of a naive classifier, which simply predicts all cases fall into the most-frequently-occurring outcome; and
1. P-Value [Acc > NIR] - the probability that the observed difference in accuracy between the model and the naive classifier would occur by chance.

A p-value less than .05 would indicate that the trained model is a statistically significantly better classifier (i.e., more predictive) than the naive classifier.