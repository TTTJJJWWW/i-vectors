%
% From string-end (right-side) find position of kth character matching given pattern 
%
% Returns: - matching position if found
%          - 0 otherwise
%
% Syntax:  INSTRREV (string, pattern, [right_match_count])
%
% Example: 
% if:
%   text='/home/reg2/argo/usmirror/coriolis/7900077/profiles/R7900077_018.nc'
%   pattern='/' and match_count=3
% then
%   instrrev(text,'/',3)=34
%   text(1:instrrev(text,'/',3)-1) = /home/reg2/argo/usmirror/coriolis
%
% Caveat: for multi-character pattern block, position returned is the first (leftest) of each matching block
%
% NB: INSTRREV (named according to industry convention) was replicated as STRREVFIND for Matlab users
%
% Auhtor TVT, last update: 1 Jun 2006
%

function ipos=instrrev(text, pattern, varargin)

if nargin <1
  msg={['SYNTAX:  ', mfilename, '(string, pattern, [right_match_count])'],...
       'Example: for string=''abc\efgabc\\hij''',...
       '         INSTRREV(string, ''\'') returns 12',...
       '         INSTRREV(string, ''\'', 3) returns 4'};
  disp(char(msg))
  return
end  

if ~isempty(varargin)
  count=varargin{1};
  if ~isnumeric(count); return; end
else
  count=1;    
end    

found=strfind(text, pattern);
ifound=length(found);

if ifound <count
  ipos=0;
  return
end

text1=text;
for i = 1 : count
  found=strfind(text1, pattern);
  ifound=length(found);
  text1=text(1:found(ifound)-1);   
  ipos=found(ifound);      
end  