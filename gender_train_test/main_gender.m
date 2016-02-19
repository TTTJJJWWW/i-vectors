clear
addpath('/storage/dane/jgrzybowska/MATLAB/ivectors/MSR Identity Toolkit v1.0/code')
%% SETTINGS
cv          = 1;            % 1- perform crossvalidation, 0- use short recs for test and all data for models
load_ubm    = 1;            % 1- load ubm from file, 0- create ubm
K           = 5;            % k-fold cross-validation
%% 
database = load('/storage/dane/jgrzybowska/MATLAB/ivectors/kroswalidacja_ivectors/parameterization_and_data_prep/__database_all_min30max1e+17secs_noKids.mat');
database = database.new_database;

short_database = load('/storage/dane/jgrzybowska/MATLAB/ivectors/kroswalidacja_ivectors/parameterization_and_data_prep/__database_all_min0max30secs_noKids.mat');
short_database = short_database.new_database;

%ubm_database = load('/storage/dane/jgrzybowska/MATLAB/ivectors/kroswalidacja_ivectors/parameterization_and_data_prep/__database_all_max15secs_noKids.mat');
%ubm_database = ubm_database.new_database;

%% Data Partition
folds = databasePartition(database, K);                                        % proportional database partition
%accuracy = zeros(1,K);
%eer = zeros(1,K);
eer2 = zeros(1,K);
dcf08 = zeros(1,K);
dcf10 = zeros(1,K);
classes = unique(database.gender);
NClass =  size(unique(database.gender),1);
%% Train/load ubm
if load_ubm == 1, for_ubm = load('cv1/ubm64_300.mat'); ubm = for_ubm.ubm; T = for_ubm.T;
else [ubm,T] = ubmCalc(ubm_database.MFCC_delta_cms);
end

%% Cross-validation
for k = 1:K
  if cv == 1, train_idx = (folds ~= k); test_idx = (folds == k);
  else train_idx = logical(folds);                                              % train with all data
  end
  ivec_matrix = ivectorsCalc2(database.MFCC_delta_cms, ubm, T);                 % ivectors for whole database
  %[ivec_matrix, ubm, T] = ivectorsCalc2(database.MFCC_delta_cms);   
  if cv == 0, short_ivec_matrix = ivectorsCalc2(short_database.MFCC_delta_cms, ubm, T); end
  
  %% train models
  model_ivecs = zeros(NClass,size(ivec_matrix,2));
  gender_idx = zeros(size(database,1),1);
  for ii = 1:NClass
    for n = 1:size(database,1)
      gender_idx(n,1) = strcmp(database.gender{n}, classes{ii});
    end
    rows = gender_idx & train_idx;
    model_ivecs(ii,:) = mean(ivec_matrix(rows,:));
  end
  %% test
  if cv == 1,
    test_ivecs = ivec_matrix(test_idx,:);
    test_labels = database.gender(test_idx);
    reference_ids = zeros(size(test_labels,1),1);
  else
    test_ivecs = short_ivec_matrix;
    test_labels = short_database.gender;
    reference_ids = zeros(size(test_labels,1),1);
  end
  for i=1:size(test_labels,1)
    if strcmp(test_labels{i},'f'), reference_ids(i,1) = 1;
    else if strcmp(test_labels{i},'m'), reference_ids(i,1) = 2;
        end
    end
  end
  scores = zeros(size(test_ivecs,1),NClass);
  for ii = 1:NClass
    scores(:,ii) = dot(repmat(model_ivecs(ii,:),size(test_ivecs,1),1), test_ivecs, 2);
  end
  %scores = scores./(sqrt(dot(model_ivecs,model_ivecs))*sqrt(dot(test_ivecs,test_ivecs))');
  scores = scores./(dot(model_ivecs,model_ivecs)*dot(test_ivecs,test_ivecs)');
  %% Confusion matrix
  [sorted_test_labels,i] = sort(test_labels); sorted_scores = scores(i,:); 
  figure(1)
  imagesc(sorted_scores); 
  title('Gender Verification Likelihood (iVector Model)');
  ylabel('Test #'); xlabel('Model #');
  colorbar; axis xy; drawnow;
  %% EER, plots, dla 2 klas!
  [max_scores,predicted_ids] = max(scores,[],2);
  [~,b,~] = unique(sorted_test_labels);
  ivScoresSorted = [sorted_scores(1:b(2)-1,1); sorted_scores(1:b(2)-1,2);...
      sorted_scores(b(2):end,1); sorted_scores(b(2):end,2)];
  sorted_lbls = logical([ones(b(2)-1,1); zeros(b(2)-1,1); ...
      zeros(size(predicted_ids,1)-b(2)+1,1); ones(size(predicted_ids,1)-b(2)+1,1)]);
  %%
  %[accuracy(k), eer(k)] = get_results([reference_ids, predicted_ids, max_scores],0);
  figure(2); [eer2(k), dcf08(k), dcf10(k)] = compute_eer(ivScoresSorted, sorted_lbls, true);
  stats(k) = confusionmatStats(reference_ids,predicted_ids);
end
save(['scores' num2str(size(ubm.w,2)) 'cv.mat'], 'stats', 'dcf10', 'dcf08', 'eer2', 'sorted_scores', 'ivScoresSorted', 'sorted_lbls');
rmpath('/storage/dane/jgrzybowska/MATLAB/ivectors/MSR Identity Toolkit v1.0/code')