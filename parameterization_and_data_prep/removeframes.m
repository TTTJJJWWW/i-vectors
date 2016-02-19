function [indeksy_ramek,sig_out]=removeframes(sig,fs,tresh,t_sil,f_len,f_rate)
%%
% function [indeksy_ramek,sig_out]=removeframes(sig,fs,tresh,t_sil,f_len,f_rate)
% indeksy_ramek
% sig_out - 
% sig - sygna� wej�ciowy mono
% fs - cz�st. pr�bkowania (Hz)
% tresh - pr�g detekcji ciszy
% t_sil - minimalny czas trwania usuwanej ciszy (sek)
% f_len - d�ugo�� ramki (sek), def.=0.02sek
% f_rate - d�ugo�� zak�adki (sek), def.=f_len/2

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
%  Nowy temat, pilne (do pi�tku).
%  funkcja w Matlabie realizujaca wskazanie kt�re ramki sygna�u mowy nale�y usun�� poniewa� nale�� do zbyt cichych segment�w nagrania.
% 
%  Algorytm wygl�da nast�puj�co:
% 
%  function [indeksy_ramek,sig_out]=removeframes(sig,fs,tresh,t_sil,f_len,f_rate)
%  gdzie:
% indeksy_ramek - wektor zawieraj�cy numery ramek , kt�re s� wskazane do usuni�cia z sygna�u (i p�niej np. z macierzy MFCC)
%  sig_out - sygna� przyci�ty
% 
%  sig - sygna� wej�ciowy audio , mono
%  fs - cz. pr�bkowania
%  tresh - pr�g detekcji cichych ramek
%  f_len - d�ugo�� ramki (deafult f_len=0.02 (20ms))
%  f_rate - pr�dko�� ramek (default f_rate=0.01 (10ms, czyli zak�adka 1/2 dla f_len=20ms)
% 
%  Kolejne kroki dzia�ania funkcji:
% 
%  normalizacja amplitudy sig=sig/max(abs(sig));
% 
%  wyznacz energie kazdej ramki jako:
%   f_en(i)=sum(frame_i.^2)
% 
%  wyznacz �redni� energi� sygna�u jako:
%  s_mean_en=log(mean(f_en)+epsilon;
%    gdzie epsilon = 0.000001
% 
%  wyznacz warto�� dB energii ramek
%    f_en=log(f_en+epsilon);
% 
%  wybierz ramki, kt�re maj� energie ni�sz� od progu:
%  I=find(f_en< (s_mean_en*alpha));
% 
%  usu� z tej listy te ramki, kt�re nie s� w ci�g�ej sekwencji o d�ugo�ci przynajmniej t_sil , domy�lnie t_sil=200ms   (pami�taj, �e jest zak�adkowanie)
% 
%  Otrzymyujesz now� (mniejsz� list� ramek do usuni�cia).
% 
% 
%  Teraz najtrudniejsze - przyci�cie sygna�u, czyli usuni�cie tych fragment�w sygna�u odpowiadaj�cych usuwanym w sekwencjach ramkom.
% 
%  usuwamy fragmenty sygna�u czasowego odpowiadaj�ce oznaczonym ramkom, i miksujemy na d�ugo�ci jednej ramki ze sob� brzegi (crossfading tr�jkatny) schodz�cych si� na skutek tego fragment�w sygna�u (aby unikn�� efekt�w nieci�g�o�ci). Je�li taka sekwencja jest na ko�cu lub pocz�tku sygna�u to jedynie wyciszamy lub nag�a�niamy sygna� liniowo od poziomu 0.
% 
%  a) Zabieg crossfadingu zostaw na koniec, wcze�niej podrzu� kolejno funkcj�, kt�ra tylko wska�e ramki do usuni�cia
%  b) potem, kt�ra usunie r�wnie� fragmenty z sygna�u (bez crossfadingu, wytnie brutalnie)
%  c) i na koniec (pt.) wytnie z crossfadingiem
% 
%  W razie pyta� pisz. W za��czeniu przesy�am plik Pythona realizuj�cy podobny zabieg, ale uwaga - tam nie ma zak�adkowania.