function [ubm,T] = ubmCalc(mfcc_ubm, mfcc_T)
%% Computes UBM and saves to file ubm.mat

%% Training the UBM
nmix        = 512;
final_niter = 1;
ds_factor   = 1;

ubm = gmm_em(mfcc_ubm, nmix, final_niter, ds_factor, 1);

stats_T = cell(size(mfcc_T,1),1);
for i=1:size(mfcc_T,1)
  [N,F] = compute_bw_stats(mfcc_T{i}, ubm);
  stats_T{i} = [N; F];
end

%% Learning the total variability subspace
tvDim = 100;
niter = 1;
T = train_tv_space(stats_T, ubm, tvDim, niter, 1);

save(['ubm' num2str(nmix) 'T' num2str(tvDim) '_zCPR.mat'], 'ubm', 'T');

end
