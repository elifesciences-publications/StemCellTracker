function [mij, mimagej] = ijinitialize(varargin)
%
% mij = ijinitialize(ijpath)
%
% description:
%    initializes ImageJ interface by installing the java jars
%
% input:
%    ijpath  (optional) hint to path to ImageJ or Fiji ([] = autodetection)
%
% output:
%    mij     ij.ImageJ instance of imagej
%
% See also: ijstart

if ~exist('ij.ImageJ', 'class')
   % add imagej to java path
   ipath = ijpath(varargin{:});
   javaaddjar(ipath, 'all');
end

if ~exist('ij.ImageJ', 'class')
   error('ijinitialize: failed try to specify correct ijpath!');
end

% add MImageJ to jave path
mpath = fileparts(which(mfilename));
if ~javacheckclasspath(mpath)
   javaaddpath(mpath, '-end');
end

mij = ijinstance();
if isempty(mij)
   try
      mij = ij.ImageJ([], 2);
   catch
      error('ijinitialize: error while initializing ImageJ classes')
   end
   %ijinfo();
end

if nargout > 1
   mimagej = MImageJ();
end

end

%%% old Fiji version
% dirn = pwd;
% 
% if nargin < 1
%    ijpath = '/home/ckirst/programs/Fiji/scripts/';
% end
% 
% addpath(ijpath);
% 
% Miji(false); %run startup script from Fiji
% 
% cd(dirn)
