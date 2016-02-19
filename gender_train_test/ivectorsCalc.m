function [ivecMatrix, T, ubm] = ivectorsCalc(MFCCs, train_idx)
% Calculates ivectors for all database (table). Each row of ivecMatrix
% corresponds to one observation.

%% Training the UBM
nmix        = 64;
final_niter = 1;
ds_factor   = 1;
mfcc_ubm    = MFCCs(train_idx);

ubm = gmm_em(mfcc_ubm, nmix, final_niter, ds_factor, 1);

stats_ubm = cell(size(mfcc_ubm,1),1);
for i=1:size(mfcc_ubm,1)
  [N,F] = compute_bw_stats(mfcc_ubm{i}, ubm);
  stats_ubm{i} = [N; F];
end

%% Learning the total variability subspace
tvDim = 300;
niter = 1;

T = train_tv_space(stats_ubm, ubm, tvDim, niter, 1);

%% ivectors for all files
stats = cell(size(MFCCs,1),1);
for i=1:size(MFCCs,1)
  [N,F] = compute_bw_stats(MFCCs{i}, ubm);
  stats{i} = [N; F];
end

ivecMatrix = zeros(size(MFCCs,1),tvDim);
for i = 1:size(MFCCs,1)
    ivecMatrix(i, :) = extract_ivector(stats{i}, ubm, T);
end
