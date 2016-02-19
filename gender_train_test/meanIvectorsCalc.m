function [ ivecMatrix, new_database ]= meanIvectorsCalc(database, ubm, T)
% Calculates mean ivectors for 5 second frames. Each row of ivecMatrix
% corresponds to one observation.

MFCCs = database.MFCC_delta_cms;

%% stats for all files
stats = cell(size(MFCCs,1),1);
for i=1:size(MFCCs,1)
  [N,F] = compute_bw_stats(MFCCs{i}, ubm);
  stats{i} = [N; F];
end

%% mean stats
speakers = cell(size(MFCCs,1),1);
for i=1:size(MFCCs,1)
  idx = instrrev(database.file_id{i},'-');
  speakers{i,1} = database.file_id{i}(1:idx-1);
end

[~,ind] = unique(speakers);
mean_stats = cell(size(ind,1),1);
for i = 1:size(ind,1)
  new_database(i,:) = database(ind(i),{'file_id', 'gender', 'age', 'age_class', 'corpus_id'});
  if i ~= size(ind,1), temp_stats = stats(ind(i):ind(i+1)-1,1);
    else temp_stats = stats(ind(i):end,1); 
  end
  suma = 0; 
  Nframes = size(temp_stats,1);
    for m = 1:Nframes
      suma = suma + temp_stats{m};
    end
  if Nframes > 3                       % at least 4 frames x 5 seconds = 20 seconds per speaker
  mean_stats{i,1} = suma/m;
  else 
      mean_stats{i,1} = [];
      new_database(i,:) = [];
  end
end

% clean data
toDelete = new_database.age_class == 0;
new_database(toDelete,:) = [];
mean_stats = mean_stats(~cellfun('isempty', mean_stats));

%% T matrix
tvDim = size(T,1);
ivecMatrix = zeros(size(new_database,1),tvDim);
for i = 1:size(new_database,1)
    ivecMatrix(i, :) = extract_ivector(mean_stats{i}, ubm, T);
end
