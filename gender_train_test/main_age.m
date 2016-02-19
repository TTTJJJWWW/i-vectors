clear
addpath('/storage/dane/jgrzybowska/MATLAB/ivectors/MSR Identity Toolkit v1.0/code')
%% SETTINGS
cv          = 1;            % 1- perform crossvalidation, 0- use short recs for test and all data for models
load_ubm    = 0;            % 1- load ubm from file, 0- create ubm
K           = 5;            % k-fold cross-validation
%% 
if cv == 0, K = 1; end
%%
database = load('/storage/dane/jgrzybowska/MATLAB/ivectors/kroswalidacja_ivectors/parameterization_and_data_prep/__database_all_min5max1e+32secs.mat');
database = database.new_database;
ubm_database = database;

%% fragment tylko dla kroswalidacji tylko jednej bazy, np. aGender
%database = load('/storage/dane/jgrzybowska/MATLAB/ivectors/kroswalidacja_ivectors/parameterization_and_data_prep/_database_aGender.mat');
%database = database.database;
%for i=1:size(database,1); corpus_id{i,1} = 'aGender'; end
%database = [database corpus_id]; database.Properties.VariableNames{8} = 'corpus_id';
%ubm_database = database;

%%

test_database = load('/storage/dane/jgrzybowska/MATLAB/ivectors/kroswalidacja_ivectors/parameterization_and_data_prep/__database_all_min5max15secs.mat');
test_database = test_database.new_database;

%% osobna baza do utworzenia ubm'a
%ubm_database = load('/storage/dane/jgrzybowska/MATLAB/ivectors/kroswalidacja_ivectors/parameterization_and_data_prep/__database_all_max15secs_noKids.mat');
%ubm_database = ubm_database.new_database;

%% Data Partition
folds = databasePartition(database, K);                                        % proportional database partition
%accuracy = zeros(1,K);
%eer = zeros(1,K);
eer2 = zeros(1,K);
dcf08 = zeros(1,K);
dcf10 = zeros(1,K);
classes = unique(database.age_class);
NClass =  size(unique(database.age_class),1);
%% Cross-validation
for k = 1:K
  if cv == 1, train_idx = (folds ~= k); test_idx = (folds == k);
  else train_idx = logical(folds);                                              % train with all data
  end
  %% Train/load ubm
  if load_ubm == 1, for_ubm = load('cv1/ubm512_300.mat'); ubm = for_ubm.ubm; T = for_ubm.T;
  else [ubm,T] = ubmCalc(ubm_database.MFCC_delta_cms(train_idx));
  end
  %%
  ivec_matrix = ivectorsCalc2(database.MFCC_delta_cms, ubm, T);                 % ivectors for whole database
  %[ivec_matrix, ubm, T] = ivectorsCalc2(database.MFCC_delta_cms);   
  if cv == 0, short_ivec_matrix = ivectorsCalc2(test_database.MFCC_delta_cms, ubm, T); end
  
  %% train models
  model_ivecs = zeros(NClass,size(ivec_matrix,2));
  age_idx = zeros(size(database,1),1);
  for ii = 1:NClass
    for n = 1:size(database,1)
      age_idx(n,1) = isequal(database.age_class(n), classes(ii));
    end
    rows = age_idx & train_idx;
    model_ivecs(ii,:) = mean(ivec_matrix(rows,:));
  end
  %% test
  if cv == 1,
    test_ivecs = ivec_matrix(test_idx,:);
    test_labels = database.age_class(test_idx);
    %reference_ids = zeros(size(test_labels,1),1);
  else
    test_ivecs = short_ivec_matrix;
    test_labels = test_database.age_class;
    %reference_ids = zeros(size(test_labels,1),1);
  end
  reference_ids = test_labels;
  %for i=1:size(test_labels,1)
  %  if strcmp(test_labels{i},'f'), reference_ids(i,1) = 1;
  %  else if strcmp(test_labels{i},'m'), reference_ids(i,1) = 2;
  %      end
  %  end
  %end
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
  title('Age Class Verification Likelihood (iVector Model)');
  ylabel('Test #'); xlabel('Model #');
  colorbar; axis xy; drawnow;
  %% EER, plots, dla 2 klas!
  [max_scores,predicted_ids] = max(scores,[],2);
  %[~,b,~] = unique(sorted_test_labels);
  %ivScoresSorted = [sorted_scores(1:b(2)-1,1); sorted_scores(1:b(2)-1,2);...
  %    sorted_scores(b(2):end,1); sorted_scores(b(2):end,2)];
  %sorted_lbls = logical([ones(b(2)-1,1); zeros(b(2)-1,1); ...
  %    zeros(size(predicted_ids,1)-b(2)+1,1); ones(size(predicted_ids,1)-b(2)+1,1)]);
  %%
  %[accuracy(k), eer(k)] = get_results([reference_ids, predicted_ids, max_scores],0);
  %figure(2); [eer2(k), dcf08(k), dcf10(k)] = compute_eer(ivScoresSorted, sorted_lbls, true);
  stats(k) = confusionmatStats(reference_ids,predicted_ids);
end
%%
tab_scores = table(reference_ids, predicted_ids, max_scores, 'VariableNames', {'ref' 'pred' 'max_score'});
tab_scores = sortrows(tab_scores,'ref','ascend');
%%
save(['age_scores' num2str(size(ubm.w,2)) 'cv_5s_UBMzTrain_TvDim' num2str(size(T,1)) '.mat'], 'stats', 'tab_scores', 'ubm', 'T', 'model_ivecs');
rmpath('/storage/dane/jgrzybowska/MATLAB/ivectors/MSR Identity Toolkit v1.0/code')