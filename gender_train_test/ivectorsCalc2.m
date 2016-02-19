function ivecMatrix = ivectorsCalc2(MFCCs, ubm, T)
% Calculates ivectors for all database (table). Each row of ivecMatrix
% corresponds to one observation.

%% ivectors for all files
stats = cell(size(MFCCs,1),1);
for i=1:size(MFCCs,1)
  [N,F] = compute_bw_stats(MFCCs{i}, ubm);
  stats{i} = [N; F];
end

tvDim = size(T,1);
ivecMatrix = zeros(size(MFCCs,1),tvDim);
for i = 1:size(MFCCs,1)
    ivecMatrix(i, :) = extract_ivector(stats{i}, ubm, T);
end
