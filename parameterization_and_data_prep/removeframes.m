function [indeksy_ramek,sig_out]=removeframes(sig,fs,tresh,t_sil,f_len,f_rate)
%%
% function [indeksy_ramek,sig_out]=removeframes(sig,fs,tresh,t_sil,f_len,f_rate)
% indeksy_ramek
% sig_out - 
% sig - sygna³ wejœciowy mono
% fs - czêst. próbkowania (Hz)
% tresh - próg detekcji ciszy
% t_sil - minimalny czas trwania usuwanej ciszy (sek)
% f_len - d³ugoœæ ramki (sek), def.=0.02sek
% f_rate - d³ugoœæ zak³adki (sek), def.=f_len/2

sig = sig/max(abs(sig));
sig_t=sig(:);
sig=filter([1 ,-0.98],1,sig_t);

epsilon = 5*eps; %0.000001;

%defaults:
if nargin<6
    if nargin < 5
        f_len = 0.02;
    end
    f_rate = f_len/2;    
end
length_signal = length(sig);
frame_len_in_samples = round(f_len*fs);
frame_rate_in_samples = round(f_rate*fs);
number_of_frames = floor((length_signal-frame_len_in_samples)/frame_rate_in_samples + 1);

%normalization
% sig = sig/max(abs(sig));

%energy of frames
frames_energy = zeros(1,number_of_frames);
for i=0:1:number_of_frames
    fr=sig(1+i*frame_rate_in_samples:(i+1)*frame_rate_in_samples,1);
    frames_energy(i+1) = (fr'*fr);
end

% s_mean_en = log(mean(frames_energy)+epsilon);
% tresh_log = log(mean(frames_energy)*tresh+epsilon);
% tresh_log = log(mean(frames_energy)+epsilon);
tresh_log = mean(log((frames_energy+epsilon)));
frames_energy_dB = log(frames_energy + epsilon);
en_var=std(frames_energy_dB);
frames_energy_dB = (frames_energy_dB - tresh_log)/en_var-tresh*4+2;


max_number_of_sil_frames = floor((t_sil - f_len)/f_rate) + 1;
current_number_of_sil_frames = 0;

indeksy_ramek = zeros(1,length(frames_energy_dB));

for i=1:1:length(frames_energy_dB)
   if frames_energy_dB(i) < 0 %(tresh_log)
       current_number_of_sil_frames = current_number_of_sil_frames +1;
       indeksy_ramek(i) = current_number_of_sil_frames;
   else
       current_number_of_sil_frames = 0;
   end
end
i=length(frames_energy_dB);
while i>0
    asd = indeksy_ramek(i);
    if indeksy_ramek(i)>max_number_of_sil_frames
        for j=1:1:asd
            indeksy_ramek(i) = 1;
            i = i - 1;
        end
    else
        indeksy_ramek(i) = 0;
        i=i-1;       
    end
    
end
     

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%a) to co wyzej - wskazanie ramek do usuniecia  
%indeksy_ramek 1 - do usuniecia, 0 - zostawiamy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%b) usuniecie bez crossfadingu
% sig_out = [];
% if indeksy_ramek(1)==1
%     poprzednia_ramka = 1;
% else
%     pocz = 1;
%     poprzednia_ramka = 0;
% end
% 
% for i=2:1:length(indeksy_ramek)
%     if indeksy_ramek(i)==poprzednia_ramka
%         %nic nie rob
%     else
%         poprzednia_ramka = indeksy_ramek(i);
%         if indeksy_ramek(i) == 0
%             pocz = i;            
%         else
%             sig_out = vertcat(sig_out, sig(1+(pocz-1)*frame_rate_in_samples:i*frame_rate_in_samples));
%         end
%     end
% end
% if poprzednia_ramka == 0
%     sig_out = vertcat(sig_out, sig(1+(pocz-1)*frame_rate_in_samples:length_signal));
% end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%c to samo z crossfadingiem

%triangle /|
triangle_left = (0:1/(frame_len_in_samples-1):1)';
%triangle |\
triangle_right = (1:-1/(frame_len_in_samples-1):0)';
sig=sig_t;

sig_out = [];

i=1;

if indeksy_ramek(1)==1
    %wycinanmy poczatek pomijajac go
    while(indeksy_ramek(i)==1 && i<length(indeksy_ramek))
        i = i + 1;
    end
    last_right_triangle = triangle_right*0;
else
    
    while(indeksy_ramek(i)==0 && i<length(indeksy_ramek))
        i = i + 1;
    end
    if i == length(indeksy_ramek)
        %zwracamy nie przyciety sygnal
        sig_out = sig;
%         zwracamy_caly_nie_przyciety_sygnal = 'prawda';
    else
        if i==2
            %jesli pierwsza ramka nie jest cicha, a nastepna/e sa ciche i do wyciecia, 
            %trzeba ten przypadek rozpatrzec osobno:
            last_right_triangle = sig(1:frame_len_in_samples).*triangle_right;
            
        else
            %poczatek + przygotowujemy ramke do laczenia z inna ramka
            sig_out = sig(1:(i-2)*frame_rate_in_samples);
            last_right_triangle = sig((i-2)*frame_rate_in_samples + 1: (i-2)*frame_rate_in_samples + frame_len_in_samples).*triangle_right;            
        end
    end
    while(indeksy_ramek(i)==1 && i<length(indeksy_ramek))
        i = i + 1;
    end
        
end

poprzednia_ramka = 1;

while(i<length(indeksy_ramek))
    if indeksy_ramek(i)==poprzednia_ramka
        %nic nie rob
    else
        poprzednia_ramka = indeksy_ramek(i);
        if indeksy_ramek(i)==0
            pocz = i;
        else
            %dodanie dwoch granicznych ramek
            sig_out = vertcat(sig_out,last_right_triangle + triangle_left.*sig((pocz-1)*frame_rate_in_samples+1:(pocz-1)*frame_rate_in_samples + frame_len_in_samples));
            %dodanie srodka
            sig_out = vertcat(sig_out,sig((pocz-1)*frame_rate_in_samples + frame_len_in_samples+1 :(i-2)*frame_rate_in_samples-1));
            %zapisanie ostatniego trojkata
            last_right_triangle = sig((i-2)*frame_rate_in_samples:(i-2)*frame_rate_in_samples+frame_len_in_samples-1).*triangle_right;            
        end        
    end
    i = i + 1;
end

if poprzednia_ramka == 0
    %jesli koniec jest nie ucinany
    sig_out = vertcat(sig_out, last_right_triangle + triangle_left.*sig((pocz-1)*frame_rate_in_samples+1:(pocz-1)*frame_rate_in_samples + frame_len_in_samples));
    sig_out = vertcat(sig_out,sig((pocz-1)*frame_rate_in_samples + frame_len_in_samples :length_signal));
else
    %jesli koniec jest ucinany
    if sum(indeksy_ramek)<length(indeksy_ramek)
        sig_out = vertcat(sig_out, sig((i-2)*frame_rate_in_samples:(i-2)*frame_rate_in_samples+frame_len_in_samples-1).*triangle_right);
    else
        sig_out = [0]; %jesli caly plik jest cichy, zwracamy jedno 0;
%         ucinamy_caly_plik = 'prawda'
    end
end

indeksy_ramek = logical(indeksy_ramek);
    
% figure(1);
% hold off
% plot(frames_energy_dB);
% hold on
% % plot(xlim,[1 1]*tresh);
% stem(-indeksy_ramek,'y');
% 
% figure(2)
% hold off;
% plot(sig_out);
% sound(sig_out,fs);
% % 











% 3)
%  Nowy temat, pilne (do pi¹tku).
%  funkcja w Matlabie realizujaca wskazanie które ramki sygna³u mowy nale¿y usun¹æ poniewa¿ nale¿¹ do zbyt cichych segmentów nagrania.
% 
%  Algorytm wygl¹da nastêpuj¹co:
% 
%  function [indeksy_ramek,sig_out]=removeframes(sig,fs,tresh,t_sil,f_len,f_rate)
%  gdzie:
% indeksy_ramek - wektor zawieraj¹cy numery ramek , które s¹ wskazane do usuniêcia z sygna³u (i póŸniej np. z macierzy MFCC)
%  sig_out - sygna³ przyciêty
% 
%  sig - sygna³ wejœciowy audio , mono
%  fs - cz. próbkowania
%  tresh - próg detekcji cichych ramek
%  f_len - d³ugoœæ ramki (deafult f_len=0.02 (20ms))
%  f_rate - prêdkoœæ ramek (default f_rate=0.01 (10ms, czyli zak³adka 1/2 dla f_len=20ms)
% 
%  Kolejne kroki dzia³ania funkcji:
% 
%  normalizacja amplitudy sig=sig/max(abs(sig));
% 
%  wyznacz energie kazdej ramki jako:
%   f_en(i)=sum(frame_i.^2)
% 
%  wyznacz œredni¹ energiê sygna³u jako:
%  s_mean_en=log(mean(f_en)+epsilon;
%    gdzie epsilon = 0.000001
% 
%  wyznacz wartoœæ dB energii ramek
%    f_en=log(f_en+epsilon);
% 
%  wybierz ramki, które maj¹ energie ni¿sz¹ od progu:
%  I=find(f_en< (s_mean_en*alpha));
% 
%  usuñ z tej listy te ramki, które nie s¹ w ci¹g³ej sekwencji o d³ugoœci przynajmniej t_sil , domyœlnie t_sil=200ms   (pamiêtaj, ¿e jest zak³adkowanie)
% 
%  Otrzymyujesz now¹ (mniejsz¹ listê ramek do usuniêcia).
% 
% 
%  Teraz najtrudniejsze - przyciêcie sygna³u, czyli usuniêcie tych fragmentów sygna³u odpowiadaj¹cych usuwanym w sekwencjach ramkom.
% 
%  usuwamy fragmenty sygna³u czasowego odpowiadaj¹ce oznaczonym ramkom, i miksujemy na d³ugoœci jednej ramki ze sob¹ brzegi (crossfading trójkatny) schodz¹cych siê na skutek tego fragmentów sygna³u (aby unikn¹æ efektów nieci¹g³oœci). Jeœli taka sekwencja jest na koñcu lub pocz¹tku sygna³u to jedynie wyciszamy lub nag³aœniamy sygna³ liniowo od poziomu 0.
% 
%  a) Zabieg crossfadingu zostaw na koniec, wczeœniej podrzuæ kolejno funkcjê, która tylko wska¿e ramki do usuniêcia
%  b) potem, która usunie równie¿ fragmenty z sygna³u (bez crossfadingu, wytnie brutalnie)
%  c) i na koniec (pt.) wytnie z crossfadingiem
% 
%  W razie pytañ pisz. W za³¹czeniu przesy³am plik Pythona realizuj¹cy podobny zabieg, ale uwaga - tam nie ma zak³adkowania.