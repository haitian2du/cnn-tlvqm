%--------------------------------------------------------------
%
%   Example of using SVR regression to predict MOS
% 
%   Runs 100 times with different random splits to training
%   and test sets, returns the results for each split in
%   terms of PCC, SCC and RMSE
%

function results = predictMOSwithSVR_100splits(features, mos)

seqlen=length(features);
avg_features = [];
for i=1:seqlen
    avg_features = [avg_features; mean(features{i})];
end
results = [];
new_result = [0 0 0];
indicator_text = '';


% Compute results for 100 random splits
for i=1:100

    % Initialize random number generation
    rng(2*i);      
    rand_seq = randperm(seqlen);
    
    fprintf(repmat(char(8), 1, length(indicator_text)));
    indicator_text = sprintf('Training and testing split %d/100\n',i);
    if i>2
        means = mean(results);
        indicator_text = [sprintf(...
            'Average results after round %d: PCC %2.3f SCC %2.3f RMSE %0.4f\n', ...
             i-1,means(1),means(2),means(3)) ...
             indicator_text];
    end
    fprintf(indicator_text);

    % Split data to training and test sets    
    XTrain = avg_features(rand_seq(1:ceil(0.8*seqlen)),:);
    YTrain = mos(rand_seq(1:ceil(0.8*seqlen)));
    XTest = avg_features(rand_seq(ceil(0.8*seqlen)+1:seqlen),:);
    YTest = mos(rand_seq(ceil(0.8*seqlen)+1:seqlen));
    
    % Train the SVR model
    model = fitrsvm(XTrain, YTrain, ...
                    'KernelFunction','gaussian','Standardize',true, ...
                    'OptimizeHyperparameters','auto','Verbose', 0, ...
                    'HyperparameterOptimizationOptions', ...
                    struct('AcquisitionFunctionName',...
                    'expected-improvement-plus', ...
                    'MaxObjectiveEvaluations', 100, ...
                    'Verbose', 0, 'ShowPlots', false));

    % Predict the values for the test set
    YPred = predict(model, XTest);    
    new_result = [corr(YTest, YPred,'type','Pearson') ...
                  corr(YTest, YPred,'type','Spearman') ...
                  sqrt(mse(YTest, YPred))];
    results = [results; new_result];
    
end

fprintf(repmat(char(8), 1, length(indicator_text)));
means = mean(results);
stds = std(results);
% fprintf('Ready! Total results: \n');
% fprintf('PCC %2.3f (%1.3f) SCC %2.3f (%1.3f) RMSE %0.4f (%0.4f)\n', ...
%          means(1),stds(1),means(2),stds(2),means(3),stds(3));
end

% EOF
