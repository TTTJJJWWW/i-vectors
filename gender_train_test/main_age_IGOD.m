%% wersja main_age.m dostosowana do dzialania systemu IGOD (5s okna)

clear
addpath('/storage/dane/jgrzybowska/MATLAB/ivectors/MSR Identity Toolkit v1.0/code')
%% SETTINGS
cv          = 0;            % 1- perform crossvalidation, 0- use test recs for test and all data for models
load_ubm    = 1;            % 1- load ubm from file, 0- create ubm
K           = 1;            % k-fold cross-validation
plot        = 1;
%% 
if cv == 0, K = 1; end
%%
train_database = load('/storage/dane/jgrzybowska/MATLAB/ivectors/kroswalidacja_ivectors/parameterization_and_data_prep/__database_all_5s.mat'); % 
train_database = train_database.database;
train_database = sortrows(train_database,'file_id','ascend');
%% fragment tylko dla kroswalidacji tylko jednej bazy, np. aGender
%corpus_id = cell(size(train_database,1),1);
%for i=1:size(train_database,1); corpus_id{i,1} = 'aGender'; end
%train_database = [train_database corpus_id]; train_database.Properties.VariableNames{8} = 'corpus_id';

%%
if cv == 0
test_database = load('/storage/dane/jgrzybowska/MATLAB/ivectors/kroswalidacja_ivectors/parameterization_and_data_prep/__database_all_5s.mat'); % 
test_database = test_database.database;
test_database = sortrows(test_database,'file_id','ascend');

%% fragment tylko dla kroswalidacji tylko jednej bazy, np. aGender
%corpus_id = cell(size(test_database,1),1);
%for i=1:size(test_database,1); corpus_id{i,1} = 'TIMIT'; end
%test_database = [test_database corpus_id]; test_database.Properties.VariableNames{8} = 'corpus_id';
end

%% osobna baza do utworzenia ubm'a
if load_ubm == 0, 
  ubm_database = load('/storage/dane/jgrzybowska/MATLAB/ivectors/kroswalidacja_ivectors/parameterization_and_data_prep/_database_CPR.mat');
  ubm_database = ubm_database.database;
end
%% osobna baza do macierzy T
if load_ubm == 0,
  T_database = load('/storage/dane/jgrzybowska/MATLAB/ivectors/kroswalidacja_ivectors/parameterization_and_data_prep/_database_CPR.mat');
  T_database = T_database.database;
end
%% Data Partition
%if cv == 1, folds = databasePartition(train_database, K); end % proportional database partition
eer = zeros(1,K);
accuracy = zeros(1,K);
eer_conf = zeros(1,K);
accuracy_conf = zeros(1,K);
tr = zeros(1,K);
classes = unique(train_database.age_class);
NClass =  size(unique(train_database.age_class),1);

%% Train/load ubm
if load_ubm == 1, for_ubm = load('ubm512T100_zCPR.mat'); ubm = for_ubm.ubm; T = for_ubm.T;
else [ubm,T] = ubmCalc(ubm_database.MFCC_delta_cms, T_database.MFCC_delta_cms);
end
%% Calculate i-vectors (mean BW statistics)
[train_ivec_matrix, train_database] = meanIvectorsCalc(train_database, ubm, T);
if cv == 0, [test_ivec_matrix, test_database] = meanIvectorsCalc(test_database, ubm, T); end  
%% Cross-validation
for k = 1:K
  %% 
  if k == 1, folds = crossvalind('Kfold', size(train_database,1), K); end
  if cv == 1, train_idx = (folds ~= k); test_idx = (folds == k);
  else train_idx = logical((1:size(train_database))');                    % train with all training data
  end
  %% Train models
  model_ivecs = zeros(NClass,size(train_ivec_matrix,2));
  age_idx = zeros(size(train_database,1),1);
  for ii = 1:NClass
    for n = 1:size(train_database,1)
      age_idx(n,1) = isequal(train_database.age_class(n), classes(ii));
    end
    rows = age_idx & train_idx;
    model_ivecs(ii,:) = mean(train_ivec_matrix(rows,:));
  end
  %% Test
  if cv == 1,
    test_ivecs = train_ivec_matrix(test_idx,:);
    test_labels = train_database.age_class(test_idx);
  else
    test_ivecs = test_ivec_matrix;
    test_labels = test_database.age_class;
  end
  reference_ids = test_labels;
%%
  scores = zeros(size(test_ivecs,1),NClass);
  for ii = 1:NClass
    scores(:,ii) = dot(repmat(model_ivecs(ii,:),size(test_ivecs,1),1), test_ivecs, 2);
  end

  %% normalizacja
  %new_scores = zeros(size(scores));
  %for ii = 1:NClass
  %  for i = 1:size(test_ivecs,1)
  %      new_scores(i,ii) = scores(i,ii)/(norm(model_ivecs(:,ii))*norm(test_ivecs(i,:)));
  %  end
  %end
  %scores = new_scores;
  new_scores = scores./(norm(model_ivecs)*norm(test_ivecs));
  %scores = scores./(sqrt(dot(model_ivecs,model_ivecs))*sqrt(dot(test_ivecs,test_ivecs))');
  %scores = scores./(dot(model_ivecs,model_ivecs)*dot(test_ivecs,test_ivecs)');
  
  %% Post-processing
  scores_llr = zeros(size(scores));
  for col=1:NClass
      scores_llr(:,col) = log(exp(scores(:,col))./mean(exp(scores(:,classes~=col)),2));
  end
  %% EER, plots
  [max_scores, predicted_ids] = max(new_scores,[],2);

  try
      [accuracy(k), eer(k), stats(k), tr(k)] = get_results([reference_ids, predicted_ids, max_scores],plot);
  catch
      stats(k) = confusionmatStats(reference_ids,predicted_ids);
  end
  %% Confidence
  conf = tr(k);
  conf_th = max_scores >= conf;
  try
      [accuracy_conf(k), eer_conf(k), stats_conf(k)] = get_results([reference_ids(conf_th), predicted_ids(conf_th), max_scores(conf_th)],plot);
  catch
      stats_conf(k) = confusionmatStats(reference_ids(conf_th),predicted_ids(conf_th));
  end
  disp(['Pozostalo ' num2str(floor(sum(conf_th)/size(test_labels,1)*100)) '% danych testowych'])
  %% Confusion matrix
  [sorted_test_labels,i] = sort(test_labels); sorted_scores = scores_llr(i,:); 
  figure()
  imagesc(sorted_scores); 
  title('Age Class Verification Likelihood (iVector Model)');
  ylabel('Test #'); xlabel('Model #');
  colorbar; axis xy;
  %% Confusion matrix with confidence threshold
  scores_conf = scores_llr(conf_th,:);
  [sorted_test_labels_conf,i_conf] = sort(test_labels(conf_th)); sorted_scores_conf = scores_conf(i_conf,:); 
  figure()
  imagesc(sorted_scores_conf); 
  title('Age Class Verification Likelihood (iVector Model)');
  ylabel('Test #'); xlabel('Model #');
  colorbar; axis xy;
end
save('modele_NOT_balanced2.mat', 'ubm', 'T', 'model_ivecs', 'tr');
%save(['age_scores' num2str(size(ubm.w,2)) '_mean5sFrames_TvDim' num2str(size(T,1)) '.mat'], 'stats', 'ubm', 'T', 'model_ivecs');
rmpath('/storage/dane/jgrzybowska/MATLAB/ivectors/MSR Identity Toolkit v1.0/code')