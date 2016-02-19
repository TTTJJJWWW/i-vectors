function [acc, eer, stats, tr] = get_results(input_mat, print_figures)
%%
% input_mat = [true_labels, predicted_labels, scores] - matrix of size (N,3)
%
if size(input_mat,2)~=3
    error('Niewlasciwy format macierzy wejsciowej');
end

true_labels = input_mat(:,1);
predicted_labels =input_mat(:,2);
scores = input_mat(:,3);
tars = scores(true_labels==predicted_labels);
imps = scores(true_labels~=predicted_labels);

%eer = 0;
[eer, FNR1, FNR01, maxACC, minCDF, FPR1_level, tr] = eerplot_bootstrap(tars,imps, print_figures);
stats = confusionmatStats(true_labels, predicted_labels);
acc = stats.accuracy;

end

function [eer, FNR1, FNR01, maxACC, minCDF, FPR1_level, tr]=eerplot_bootstrap(tars, imps, print_figures )
%% tu wczytac listy wynikow log-likelihood, gdzie:
% tars - wektor scoring�w dla target�w
% imps - wektor scoring�w dla impostor�w
% print _figures - warto�� bool (1 - wy�wietl eerploty, 0 - nie wy�wietlaj)
% wymaga przynajmniej 6 pr�bek target lub i 6 pr�bek impostor
% wyznacza i rysuje (--) 90% przedzia�y ufno�ci podstawowych wska�nik�w na
% za pomoc� metody N-bootstrap i za�o�eniu normalno�ci rozk�adu wynik�w
% cz�stkowych

leg=true; 

if size(imps,1)==1; imps=imps'; end %formatuj dane wej�ciowe
if size(tars,1)==1; tars=tars'; end %formatuj dane wej�ciowe

Nboots=min([length(imps),length(tars)]);
Nboots=max(floor(Nboots/20),2);

tars_boot=tars(randperm(length(tars)));
imps_boot=imps(randperm(length(imps)));
n_tar=1;  %indeks n-tego podzbioru target�w
n_imp=1; %indeks n-tego podzbioru impostor�w
for nboot=1:Nboots %dla wszystkich podzbior�w
    %wyznacz interesuj�ce parametry
    
    %wyznacz parametry dla nboot-oweg podzbioru
    [eer, FNR1, FNR01, maxACC, minCDF, FPR1_level,fnr,fpr,...
    Lzerofpri,Llzerofpri,tr,FPR01_level,CDet2,accuracy]=...
    evaluate(tars_boot(n_tar:n_tar-1+floor(length(tars)/Nboots)),...
    imps_boot(n_imp:n_imp-1+floor(length(imps)/Nboots)));
    n_tar=n_tar+floor(length(tars)/Nboots);
    n_imp=n_imp+floor(length(imps)/Nboots);
    
    eers(nboot)=eer;
    fnr1s(nboot)=FNR1;
    fnr01s(nboot)=FNR01;
    
    fnrs(nboot,:)=fnr;
    fprs(nboot,:)=fpr;
    
end

[H, pValue, W] = swtest(eers, 0.05, 1);  %przeprowad� test normalno�ci rozk�adu b��d�w
% pValue
% disp('Bootstrap EER non-normal?:');
% H

EER90conf=mean(eers);
EER90conf=[EER90conf-1.645*std(eers),EER90conf+1.645*std(eers)];  %90% przedzia� ufno�ci
EER90conf(EER90conf<0)=0;
EER90conf(EER90conf>100)=100;
EERSTD=std(eers);
%mean(eers)

FNR90conf=mean(fnrs);
FNR90conf=[FNR90conf-1.645*std(fnrs);FNR90conf+1.645*std(fnrs)];
FNR90conf(FNR90conf<0)=0;
FNR90conf(FNR90conf>100)=100;
FNRSTD=std(fnrs);

FPR90conf=mean(fprs);
FPR90conf=[FPR90conf-1.645*std(fprs);FPR90conf+1.645*std(fprs)];
FPR90conf(FPR90conf<0)=0;
FPR90conf(FPR90conf>100)=100;
FPRSTD=std(fprs);


%1-bootstrap
    % n_sigma=2;  %zakres rysowania histogram�w
    % ii=linspace(mean(imps)-n_sigma*std(imps),mean(tars)+n_sigma*std(tars),400);
ii=linspace(min(imps),max(tars),400);
[eer, FNR1, FNR01, maxACC, minCDF, FPR1_level,fnr,fpr,...
    Lzerofpri,Llzerofpri,tr,FPR01_level,CDet2,accuracy]=evaluate(tars,imps);
if (print_figures)
    figure(1);
    hold off;
    [h1, x1]=hist(imps,20);
    [h2, x2]=hist(tars,20);

    mh=max([sum(h1),sum(h2)])/5;
    h1=100*h1/mh;
    h2=100*h2/mh;
    bar(x1, h1, 'r');
    hold on;
    bar(x2, h2, 'b');
    h=findobj(gca, 'Type', 'patch');
    set (h, 'FaceAlpha', 0.5);
    title(['EER=',num2str(eer,2),'{\pm}_{',num2str(eer-1.645*EERSTD,2),'}^{',num2str(eer+1.645*EERSTD,2),...
        '}%     FR@1%FAR=',num2str(fnr(Lzerofpri),2),'{\pm}_{',num2str(fnr(Lzerofpri)-1.645*FNRSTD(Lzerofpri),2),...
        '}^{',num2str(fnr(Lzerofpri)+1.645*FNRSTD(Lzerofpri),2),...
        '}%     FR@0.1%FAR=',num2str(fnr(Llzerofpri),2),'{\pm}_{',num2str(fnr(Llzerofpri)-1.645*FNRSTD(Llzerofpri),2),...
        '}^{',num2str(fnr(Llzerofpri)+1.645*FNRSTD(Llzerofpri),2),'}% (90% conf.int.)']);
    xlabel(sprintf('L_{EER}=%02.1f  L_{FAR1%%}=%02.1f  L_{FRR0.1%%}=%02.1f \n\n N_{imps}=%d  N_{trgts}=%d  Bootstraps=%d  Bootstrap EER normality:%d',...
        tr,FPR1_level,FPR01_level,length(imps),length(tars),Nboots,~H));
    ylabel('%');
    plot(ii,fnr,'b');
    hold on;
    % plot(ii,CDet2,'g');
    plot(ii,fpr,'r');
    plot(ii,accuracy,'c');
    % plot([min(xlim), ii(tri)],[eer eer],'k--');
    % if ~isempty(Lzerofpr); plot([1 1]*Lzerofpr,ylim+0.01,'--'); end
    if leg, legend({'impostors','targets','FRR','FAR','ACC'},'Location','NorthEast'); end
    ylim([0 100]);
    line([tr tr],                   ylim, 'color','green','linestyle','-');
    line([FPR1_level FPR1_level],   ylim, 'color',[1,0.6471,0],'linestyle','-');
    line([FPR01_level FPR01_level], ylim, 'color','red','linestyle','-');
    xlim([min(ii),max(ii)]);
    %rysuj przedzia�y 90% ufno�ci przy za�o�eniu rozk�adu normalnego
    plot(ii,min(100,fnr+1.645*FNRSTD),'b--');
    plot(ii,max(0,fnr-1.645*FNRSTD),'b--');
    plot(ii,min(100,fpr+1.645*FPRSTD),'r--');
    plot(ii,max(0,fpr-1.645*FPRSTD),'r--');
    errorbar(tr,eer,1.645*EERSTD,'xk');
    %  set(gca,'yscale','log','ylim',[1 100]);
end



%% rysowanie DET plotu
% figure;
% hold off;
% plot(fpr,fnr);
% xlabel('fpr');
% ylabel('fnr');
% hold on;
% plot(eer,eer,'or');
% plot(min(CDet2),min(CDet2),'or');
end

%% funkcja pomocnicza - liczy statystyki
function [eer, FNR1, FNR01, maxACC, minCDF, FPR1_level,fnr,fpr,...
    Lzerofpri,Llzerofpri,tr,FPR01_level,CDet2,accuracy]=evaluate(tars,imps)
ii=linspace(min(imps),max(tars),400); %wyznacz punkty pomiaru wynik�w na osi poziomej
% wyniki ca�kowite, 1-bootstrap
for k=1:length(ii)  %iteruj po wszystkich punktach
    i=ii(k);
    tn(k)=length(imps(find(imps<=i)));  
    fn(k)=length(tars(find(tars<i)));
    tp(k)=length(tars(find(tars>=i)));
    fp(k)=length(imps(find(imps>i)));
    fpr(k)=100*fp(k)/(fp(k)+tn(k));
    fnr(k)=100*fn(k)/(fn(k)+tp(k));
    CMiss=10;
    CFalseAlarm=1;
    Ptarget=0.01;  %NIST 2008
    CDet2(k) = CMiss * fnr(k) * Ptarget + CFalseAlarm * fpr(k)*(1-Ptarget);
    CDF(k)=CDet2(k); 
    accuracy(k)=100*(tp(k)+tn(k))/length([tars;imps]);
end
maxACC = max(accuracy);
minCDF = min(CDet2);

i=find(abs([fpr-fnr])==min(abs([fpr-fnr])));
eer=mean(fpr(i)/2+fnr(i)/2);

tri=i(1);
tr=ii(tri);

imps(find(imps<min(ii)))=min(ii); %zeby nie wyswietlal  ogonow na histogramie
tars(find(tars>max(ii)))=max(ii);

Lzerofpri=min(find(fpr<1));  % indeks Score akceptowalnego rate % w�amania = 1%
if isempty(Lzerofpri)
    FNR1 = max(tars);
    FPR1_level = ii(end);
else
    FNR1 = fnr(Lzerofpri);
    FPR1_level = ii(Lzerofpri);
end

cla
Llzerofpri=min(find(fpr<0.1));  % indeks Score akceptowalnego rate % w�amania = 0.1%
if isempty(Llzerofpri)
    FNR01 = max(tars);
    FPR01_level = ii(end);
else
    FNR01 = fnr(Llzerofpri);
    FPR01_level = ii(Llzerofpri);
end
end

function [H, pValue, W] = swtest(x, alpha, tail)
%SWTEST Shapiro-Wilk parametric hypothesis test of composite normality.
%   [H, pValue, SWstatistic] = SWTEST(X, ALPHA, TAIL) performs
%   the Shapiro-Wilk test to determine if the null hypothesis of
%   composite normality is a reasonable assumption regarding the
%   population distribution of a random sample X. The desired significance 
%   level, ALPHA, is an optional scalar input (default = 0.05).
%   TAIL indicates the type of test (default = 1).
%
%   The Shapiro-Wilk hypotheses are: 
%   Null Hypothesis:        X is normal with unspecified mean and variance.
%      For TAIL =  0 (2-sided test), alternative: X is not normal.
%      For TAIL =  1 (1-sided test), alternative: X is upper the normal.
%      For TAIL = -1 (1-sided test), alternative: X is lower the normal.
%
%   This is an omnibus test, and is generally considered relatively
%   powerful against a variety of alternatives.
%   Shapiro-Wilk test is better than the Shapiro-Francia test for
%   Platykurtic sample. Conversely, Shapiro-Francia test is better than the
%   Shapiro-Wilk test for Leptokurtic samples.
%
%   When the series 'X' is Leptokurtic, SWTEST performs the Shapiro-Francia
%   test, else (series 'X' is Platykurtic) SWTEST performs the
%   Shapiro-Wilk test.
% 
%    [H, pValue, SWstatistic] = SWTEST(X, ALPHA, TAIL)
%
% Inputs:
%   X - a vector of deviates from an unknown distribution. The observation
%     number must exceed 3 and less than 5000.
%
% Optional inputs:
%   ALPHA - The significance level for the test (default = 0.05).
%
%   TAIL  - The type of the test (default = 1).
%  
% Outputs:
%  SWstatistic - The test statistic (non normalized).
%
%   pValue - is the p-value, or the probability of observing the given
%     result by chance given that the null hypothesis is true. Small values
%     of pValue cast doubt on the validity of the null hypothesis.
%
%     H = 0 => Do not reject the null hypothesis at significance level ALPHA.
%     H = 1 => Reject the null hypothesis at significance level ALPHA.
%

%
% References: Royston P. "Algorithm AS R94", Applied Statistics (1995) Vol. 44, No. 4.
%   AS R94 -- calculates Shapiro-Wilk normality test and P-value
%   for sample sizes 3 <= n <= 5000. Handles censored or uncensored data.
%   Corrects AS 181, which was found to be inaccurate for n > 50.
%

%
% Ensure the sample data is a VECTOR.
%

if numel(x) == length(x)
    x  =  x(:);               % Ensure a column vector.
else
    error(' Input sample ''X'' must be a vector.');
end

%
% Remove missing observations indicated by NaN's and check sample size.
%

x  =  x(~isnan(x));

if length(x) < 2
   error(' Sample vector ''X'' must have at least 3 valid observations.');
end

if length(x) > 5000
    warning('Shapiro-Wilk test might be inaccurate due to large sample size ( > 5000).');
end

%
% Ensure the significance level, ALPHA, is a 
% scalar, and set default if necessary.
%

if (nargin >= 2) && ~isempty(alpha)
   if numel(alpha) > 1
      error(' Significance level ''Alpha'' must be a scalar.');
   end
   if (alpha <= 0 || alpha >= 1)
      error(' Significance level ''Alpha'' must be between 0 and 1.'); 
   end
else
   alpha  =  0.05;
end

%
% Ensure the type-of-test indicator, TAIL, is a scalar integer from 
% the allowable set {-1 , 0 , 1}, and set default if necessary.
%

if (nargin >= 3) && ~isempty(tail)
   if numel(tail) > 1
      error('Type-of-test indicator ''Tail'' must be a scalar.');
   end
   if (tail ~= -1) && (tail ~= 0) && (tail ~= 1)
      error('Type-of-test indicator ''Tail'' must be -1, 0, or 1.');
   end
else
   tail  =  1;
end

% First, calculate the a's for weights as a function of the m's
% See Royston (1995) for details in the approximation.

x       =   sort(x); % Sort the vector X in ascending order.
n       =   length(x);
mtilde  =   norminv(((1:n)' - 3/8) / (n + 0.25));
weights =   zeros(n,1); % Preallocate the weights.

if kurtosis(x) > 3
    
    % The Shapiro-Francia test is better for leptokurtic samples.
    
    weights =   1/sqrt(mtilde'*mtilde) * mtilde;

    %
    % The Shapiro-Francia statistic W is calculated to avoid excessive rounding
    % errors for W close to 1 (a potential problem in very large samples).
    %

    W   =   (weights' * x) ^2 / ((x - mean(x))' * (x - mean(x)));

    nu      =   log(n);
    u1      =   log(nu) - nu;
    u2      =   log(nu) + 2/nu;
    mu      =   -1.2725 + (1.0521 * u1);
    sigma   =   1.0308 - (0.26758 * u2);

    newSFstatistic  =   log(1 - W);

    %
    % Compute the normalized Shapiro-Francia statistic and its p-value.
    %

    NormalSFstatistic =   (newSFstatistic - mu) / sigma;
    
    % the next p-value is for the tail = 1 test.
    pValue   =   1 - normcdf(NormalSFstatistic, 0, 1);
    
else
    
    % The Shapiro-Wilk test is better for platykurtic samples.

    c    =   1/sqrt(mtilde'*mtilde) * mtilde;
    u    =   1/sqrt(n);

    PolyCoef_1   =   [-2.706056 , 4.434685 , -2.071190 , -0.147981 , 0.221157 , c(n)];
    PolyCoef_2   =   [-3.582633 , 5.682633 , -1.752461 , -0.293762 , 0.042981 , c(n-1)];

    PolyCoef_3   =   [-0.0006714 , 0.0250540 , -0.39978 , 0.54400];
    PolyCoef_4   =   [-0.0020322 , 0.0627670 , -0.77857 , 1.38220];
    PolyCoef_5   =   [0.00389150 , -0.083751 , -0.31082 , -1.5861];
    PolyCoef_6   =   [0.00303020 , -0.082676 , -0.48030];

    PolyCoef_7   =   [0.459 , -2.273];

    weights(n)   =   polyval(PolyCoef_1 , u);
    weights(1)   =   -weights(n);

    % Special attention when n=3 (this is a special case).
    if n == 3
        weights(1)  =   0.707106781;
        weights(n)  =   -weights(1);
    end

    if n >= 6
        weights(n-1) =   polyval(PolyCoef_2 , u);
        weights(2)   =   -weights(n-1);
    
        count  =   3;
        phi    =   (mtilde'*mtilde - 2 * mtilde(n)^2 - 2 * mtilde(n-1)^2) / ...
                (1 - 2 * weights(n)^2 - 2 * weights(n-1)^2);
    else
        count  =   2;
        phi    =   (mtilde'*mtilde - 2 * mtilde(n)^2) / ...
                (1 - 2 * weights(n)^2);
    end

    %
    % The vector 'WEIGHTS' obtained next corresponds to the same coefficients
    % listed by Shapiro-Wilk in their original test for small samples.
    %

    weights(count : n-count+1)  =  mtilde(count : n-count+1) / sqrt(phi);

    %
    % The Shapiro-Wilk statistic W is calculated to avoid excessive rounding
    % errors for W close to 1 (a potential problem in very large samples).
    %

    W   =   (weights' * x) ^2 / ((x - mean(x))' * (x - mean(x)));

    %
    % Calculate the significance level for W (exact for n=3).
    %

    newn    =   log(n);

    if (n > 3) && (n <= 11)
    
        mu      =   polyval(PolyCoef_3 , n);
        sigma   =   exp(polyval(PolyCoef_4 , n));    
        gam     =   polyval(PolyCoef_7 , n);
    
        newSWstatistic  =   -log(gam-log(1-W));
    
    elseif n >= 12
    
        mu      =   polyval(PolyCoef_5 , newn);
        sigma   =   exp(polyval(PolyCoef_6 , newn));
    
        newSWstatistic  =   log(1 - W);
    
    elseif n == 2
        mu      =   0;
        sigma   =   1;
        newSWstatistic  =   0;
    end

    %
    % Compute the normalized Shapiro-Wilk statistic and its p-value.
    %

    NormalSWstatistic       =   (newSWstatistic - mu) / sigma;
    
    % The next p-value is for the tail = 1 test.
    pValue       =   1 - normcdf(NormalSWstatistic, 0, 1);

    % Special attention when n=3 (this is a special case).
    if n == 3
        pValue  =   1.909859 * (asin(sqrt(W)) - 1.047198);
        NormalSWstatistic =   norminv(pValue, 0, 1);
    end
    
end

% The p-value just found is for the tail = 1 test.
if tail == 0
    pValue = 2 * min(pValue, 1-pValue);
elseif tail == -1
    pValue = 1 - pValue;
end

%
% To maintain consistency with existing Statistics Toolbox hypothesis
% tests, returning 'H = 0' implies that we 'Do not reject the null 
% hypothesis at the significance level of alpha' and 'H = 1' implies 
% that we 'Reject the null hypothesis at significance level of alpha.'
%

H  = (alpha >= pValue);
end

function stats = confusionmatStats(group,grouphat)
% INPUT
% group = true class labels
% grouphat = predicted class labels
%
% OR INPUT
% stats = confusionmatStats(group);
% group = confusion matrix from matlab function (confusionmat)
%
% OUTPUT
% stats is a structure array
% stats.confusionMat
%               Predicted Classes
%                    p'    n'
%              ___|_____|_____| 
%       Actual  p |     |     |
%      Classes  n |     |     |
%
% stats.accuracy = (TP + TN)/(TP + FP + FN + TN) ; the average accuracy is returned
% stats.precision = TP / (TP + FP)                  % for each class label
% stats.sensitivity = TP / (TP + FN)                % for each class label
% stats.specificity = TN / (FP + TN)                % for each class label
% stats.recall = sensitivity                        % for each class label
% stats.Fscore = 2*TP /(2*TP + FP + FN)            % for each class label
%
% TP: true positive, TN: true negative, 
% FP: false positive, FN: false negative
% 
% from: http://www.mathworks.com/matlabcentral/fileexchange/46035-confusion-matrix--accuracy--precision--specificity--sensitivity--recall--f-score

field1 = 'confusionMat';
if nargin < 2
    value1 = group;
else
    value1 = confusionmat(group,grouphat);
end

numOfClasses = size(value1,1);
totalSamples = sum(sum(value1));
    
field2 = 'accuracy';  value2 = trace(value1)/(totalSamples);%value2 = (2*trace(value1)+sum(sum(2*value1)))/(numOfClasses*totalSamples);

[TP,TN,FP,FN,sensitivity,specificity,precision,f_score] = deal(zeros(numOfClasses,1));
for class = 1:numOfClasses
   TP(class) = value1(class,class);
   tempMat = value1;
   tempMat(:,class) = []; % remove column
   tempMat(class,:) = []; % remove row
   TN(class) = sum(sum(tempMat));
   FP(class) = sum(value1(:,class))-TP(class);
   FN(class) = sum(value1(class,:))-TP(class);
end

for class = 1:numOfClasses
    sensitivity(class) = TP(class) / (TP(class) + FN(class));
    specificity(class) = TN(class) / (FP(class) + TN(class));
    precision(class) = TP(class) / (TP(class) + FP(class));
    f_score(class) = 2*TP(class)/(2*TP(class) + FP(class) + FN(class));
end

field3 = 'sensitivity';  value3 = sensitivity;
field4 = 'specificity';  value4 = specificity;
field5 = 'precision';  value5 = precision;
field6 = 'recall';  value6 = sensitivity;
field7 = 'Fscore';  value7 = f_score;
stats = struct(field1,value1,field2,value2,field3,value3,field4,value4,field5,value5,field6,value6,field7,value7);
end