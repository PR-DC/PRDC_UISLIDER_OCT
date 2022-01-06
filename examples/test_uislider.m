% Test for uislider class
% Author: Milos Petrasinovic <mpetrasinovic@prdc.rs>
% PR-DC, Republic of Serbia
% info@pr-dc.com
% ---------------
%
% Copyright (C) 2021 PR-DC <info@pr-dc.com>
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU Lesser General Public License as 
% published by the Free Software Foundation, either version 3 of the 
% License, or (at your option) any later version.
%  
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU Lesser General Public License for more details.
%  
% You should have received a copy of the GNU Lesser General Public License
% along with this program.  If not, see <https://www.gnu.org/licenses/>.
%
% ---------------
close all, clear all, clc, tic
disp([' --- ' mfilename ' --- ']);

addpath([pwd '\..\']);

function sliderCallback(obj, ~, i)
  s_val = get(obj, 'Value');
  disp(['Slider = ' num2str(i) ', value = ' num2str(s_val)]); 
end

f = figure();

s1 = uislider('Parent', f, 'Value', 0, 'min', -100, 'max', 100, ...
  'Position', [20, 75, 40, 220], 'LineWidth', 1/5, 'KnobHeight', 1/10, ...
  'DragCallback', {@sliderCallback, 1})
  
s2 = uislider('Parent', f, 'Value', 0, 'min', -100, 'max', 100, ...
  'Position', [100, 75, 220,  40], 'LineWidth', 1/5, 'KnobHeight', 1/10, ...
  'DragCallback', {@sliderCallback, 2})

% - End of program
disp(' The program was successfully executed... ');
disp([' Execution time: ' num2str(toc, '%.2f') ' seconds']);
disp(' -------------------- ');