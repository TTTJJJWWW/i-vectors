function [eer, FNR1, FNR01, maxACC, minCDF, FPR1_level]=wyliczanie_eer_i_hist(datamk, data, leg)
%% tu wczytac listy wynikow log-likelihood, gdzie:
% datamk - scoringi dla targetów
% data - scoringi dla impostorów

if nargin<3, leg=true; end

if size(data,1)==1; data=data'; end
if size(datamk,1)==1; datamk=datamk'; end

%Histogramy Mateusz Kulpa   mean+/- 3sigma
ii=linspace(mean([data;datamk])-5*std([data;datamk]),mean([data;datamk])+5*std([data;datamk]),500);
for k=1:length(ii)
    i=ii(k);
    tn(k)=length(data(find(data<i)));
    fn(k)=length(datamk(find(datamk<i)));
    tp(k)=length(datamk(find(datamk>=i)));
    fp(k)=length(data(find(data>i)));
    
    fpr(k)=100*fp(k)/(fp(k)+tn(k));
    fnr(k)=100*fn(k)/(fn(k)+tp(k));
    
    CMiss=10;
    CFalseAlarm=1;
    Ptarget=0.01;
    CDet2(k) = CMiss * fnr(k) * Ptarget + CFalseAlarm * fpr(k)*(1-Ptarget);
    CDF(k)=CDet2(k);
    
    accuracy(k)=100*(tp(k)+tn(k))/length([datamk;data]);

end

maxACC = max(accuracy);
minCDF = min(CDet2);

i=find(abs([fpr-fnr])==min(abs([fpr-fnr])));
eer=mean(fpr(i)/2+fnr(i)/2);

tri=i(1);
tr=ii(tri);

data(find(data<min(ii)))=[]; %zeby nie wyswietlal  ogonow na histogramie
datamk(find(datamk<min(ii)))=[];

Lzerofpri=min(find(fpr<1));  % akceptowalny rate % w³amania = 1%
FNR1 = fnr(Lzerofpri);
FPR1_level = ii(Lzerofpri);

Llzerofpri=min(find(fpr<0.1));  % akceptowalny rate % w³amania = 0.1%
FNR01 = fnr(Llzerofpri);
FPR01_level = ii(Llzerofpri);

if leg
    % figure;
    hold off;
    [h1, x1]=hist(data,20);
    [h2, x2]=hist(datamk,20);

        mh=max([sum(h1),sum(h2)])/5;
    h1=100*h1/mh;
    h2=100*h2/mh;
    bar(x1, h1, 'r');
    hold on;
    bar(x2, h2, 'b');
    h=findobj(gca, 'Type', 'patch');
    set (h, 'FaceAlpha', 0.5);
    title(['EER=',num2str(eer),'%   fnr=' num2str(fnr(Lzerofpri),2),'% @ fpr<1%   fnr=' num2str(fnr(Llzerofpri),2),'% @ fpr<0.1%']);%, 'FontSize',12.5);
    xlabel(sprintf('L_{EER}=%02.2f  L_{FPR1%%}=%02.2f  L_{FPR0.1%%}=%02.2f',tr,FPR1_level,FPR01_level));
    ylabel('%');
    plot(ii,fpr,'k');
    hold on;
    plot(ii,fnr,'b');
    plot(ii,CDet2,'g');
    plot(ii,accuracy,'c');
    % plot([min(xlim), ii(tri)],[eer eer],'k--');
    % if ~isempty(Lzerofpr); plot([1 1]*Lzerofpr,ylim+0.01,'--'); end
    legend({'impostors','target','FPR','FNR','CDF','ACC'},'Location','NorthEast');
    ylim([0 100]);
    line([tr tr],                   ylim, 'color','green','linestyle','--');
    line([FPR1_level FPR1_level],   ylim, 'color',[1,0.6471,0],'linestyle','--');
    line([FPR01_level FPR01_level], ylim, 'color','red','linestyle','--');

    %  set(gca,'yscale','log','ylim',[1 100]);
    % 
    % figure;
    % hold off;
    % plot(fpr,fnr);
    % xlabel('fpr');
    % ylabel('fnr');
    % hold on;
    % plot(eer,eer,'or');
    % plot(min(CDet2),min(CDet2),'or');
end