function dcc=delcep(cc,K)

%% compute delta cepstral coefficients
%%
%% cc -- cepstral coefficients
%% K  -- order of estimator
%%
[Q,T]=size(cc);

for l=1:T
 dcc(:,l)=zeros(Q,1);
 if l<K+1
   for k=-K:l-1
     dcc(:,l)=dcc(:,l)+k*cc(:,l-k);
   end
 elseif l<=T-K
   for k=-K:K
     dcc(:,l)=dcc(:,l)+k*cc(:,l-k);
   end
 else
   for k=-(T-l):K
     dcc(:,l)=dcc(:,l)+k*cc(:,l-k);
   end
 end
 %% compute normalization factor
 G=std(cc(:,l))/std(dcc(:,l));
 dcc(:,l)=G*dcc(:,l);
end

return