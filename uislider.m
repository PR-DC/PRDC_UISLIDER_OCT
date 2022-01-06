% Class uislider
% Author: Milos Petrasinovic <mpetrasinovic@prdc.rs>
% PR-DC, Republic of Serbia
% info@pr-dc.com
% --------------------
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

classdef uislider < handle
  properties
    Value;
    Min;
    Max;
    Parent;
    Position;
    BackgroundColor;
    ForegroundColor;
    SliderStep;
    LineWidth;
    KnobHeight;
    Enable;
    Callback;
    DragCallback;
    Orientation;
    Window;
  end 
  properties (Access = private)
    Enabled;
    axe;
    slider;
    CallbackVars;
    DragCallbackVars;
    buttonDiameter;
    knobPosition;
    t;
  end 
  methods
    function obj = uislider(varargin)
      p = inputParser;
      addParameter(p, 'Value', 0, ...
        @(x) isnumeric(x) && length(size(x))==2 && ...
        size(x, 1)==1 && size(x, 2)==1);
      addParameter(p, 'Min', ...
        0, @(x) isnumeric(x) && length(size(x))==2 && ...
        size(x, 1)==1 && size(x, 2)==1);
      addParameter(p, 'Max', 1, ...
        @(x) isnumeric(x) && length(size(x))==2 && ...
        size(x, 1)==1 && size(x, 2)==1);
      addParameter(p, 'Parent', [], @(x) ishandle(x));
      addParameter(p, 'Position', [20 20 60 20], ...
        @(x) isnumeric(x) && length(size(x))==2 && ...
        size(x, 1)==1 && size(x, 2)==4);
      addParameter(p, 'BackgroundColor', [1, 1, 1], ...
        @(x) ischar(x) || (isnumeric(x) && ...
        length(size(x))==2 && size(x, 1)==1 && size(x, 2)==3));
      addParameter(p, 'ForegroundColor', [.18, .52, .78], ...
        @(x) ischar(x) || (isnumeric(x) && ... 
        length(size(x))==2 && size(x, 1)==1 && size(x, 2)==3));
      addParameter(p, 'SliderStep', [0.01, 0.1], ...
        @(x) isnumeric(x) && length(size(x))==2 && ...
        size(x, 1)==1 && size(x, 2)==2);
      addParameter(p, 'LineWidth', 1/3, ...
        @(x) isnumeric(x) && length(size(x))==2 && ...
        size(x, 1)==1 && size(x, 2)==1 && x > 0 && x < 1);
      addParameter(p, 'KnobHeight', 1/6, ...
        @(x) isnumeric(x) && length(size(x))==2 && ...
        size(x, 1)==1 && size(x, 2)==1 && x > 0 && x < 1);
      addParameter(p, 'Enable', 'On', ...
        @(x) ischar(x) && (strcmpi(x, 'On') || strcmpi(x, 'Off')));
      addParameter(p, 'Callback', [], ...
        @(x) ischar(x) || isa(x, 'function_handle') || (iscell(x) && ...
        isa(x{1}, 'function_handle')));   
      addParameter(p, 'DragCallback', [], ...
        @(x) ischar(x) || isa(x, 'function_handle') || (iscell(x) && ...
        isa(x{1}, 'function_handle')));   
      p.parse(varargin{:})
      
      obj.Value = p.Results.Value;
      obj.Min = p.Results.Min;
      obj.Max = p.Results.Max;
      obj.Position = p.Results.Position;
      obj.BackgroundColor = p.Results.BackgroundColor;
      obj.ForegroundColor = p.Results.ForegroundColor;
      obj.SliderStep = p.Results.SliderStep;
      obj.LineWidth = p.Results.LineWidth;
      obj.KnobHeight = p.Results.KnobHeight;
      obj.Enable = p.Results.Enable;
      obj.t = tic;
      
      if(ischar(p.Results.Callback))
        obj.Callback = p.Results.Callback;
      elseif(iscell(p.Results.Callback))
        obj.Callback = p.Results.Callback{1};
        obj.CallbackVars = {p.Results.Callback{2:end}};
      else
        obj.Callback = p.Results.Callback;
      end
      
      if(ischar(p.Results.DragCallback))
        obj.DragCallback = p.Results.DragCallback;
      elseif(iscell(p.Results.DragCallback))
        obj.DragCallback = p.Results.DragCallback{1};
        obj.DragCallbackVars = {p.Results.DragCallback{2:end}};
      else
        obj.DragCallback = p.Results.DragCallback;
      end
      
      if(ishandle(p.Results.Parent))
        obj.Parent = p.Results.Parent;
      else
        obj.Parent = figure;
      end  
      
      obj.Window = obj.Parent;
      while(~strcmp(get(obj.Window, 'type'), 'figure'))
        obj.Window = get(obj.Window, 'Parent');
      end
      
      if(obj.Position(3) >= obj.Position(4)) 
        % Horizontal
        obj.Orientation = 1;
      else
        % Vertical
        obj.Orientation = 0;
      end
      
      if(strcmpi(obj.Enable, 'on'))
        obj.Enabled = 1;
      else
        obj.Enabled = 0;
      end
      obj.drawSlider();
    end   
    
    function obj = drawSlider(obj)
      obj.axe = axes(obj.Parent, 'Units', 'Pixels', ...
        'Position', obj.Position);
      grid off, box off, axis off, hold on;
      axis([obj.Position(1), obj.Position(1)+obj.Position(3), ...
        obj.Position(2), obj.Position(2)+obj.Position(4)]);
      
      val = (obj.Value-obj.Min)/(obj.Max-obj.Min);
      if(val > 1)
        val = 1;
      elseif(val <0) 
        val = 0;
      end
        
      if(obj.Orientation) 
        % Horizontal
        buttonDiam = obj.Position(4)*obj.LineWidth*2;
        if(buttonDiam > obj.Position(4)) 
          buttonDiam = obj.Position(4);
        end
        if(4*buttonDiam > obj.Position(3)*(1-obj.KnobHeight)) 
          buttonDiam = obj.Position(3)*(1-obj.KnobHeight)/4;
        end
      
        plusPosition = [obj.Position(1)+obj.Position(3)-buttonDiam, ...
          obj.Position(2)+1/2*obj.Position(4)-buttonDiam/2, ...
          buttonDiam, buttonDiam];
        minusPosition = [obj.Position(1), obj.Position(2)+ ...
          1/2*obj.Position(4)-buttonDiam/2, buttonDiam, buttonDiam];
        plusLinesPosition = [obj.Position(1)+...
          obj.Position(3)-buttonDiam/2, minusPosition(2)+buttonDiam/2];
        minusLinesPosition = [obj.Position(1)+buttonDiam/2, ...
          plusPosition(2)+buttonDiam/2];
        linePosition = [obj.Position(1)+buttonDiam/2, obj.Position(2)+ ...
          obj.Position(4)*(1/2-obj.LineWidth/2), obj.Position(3)- ...
          buttonDiam, obj.Position(4)*obj.LineWidth];
        knobPos = [obj.Position(1)+buttonDiam+ ...
          (obj.Position(3)-2*buttonDiam-4)*(val*(1-obj.KnobHeight)), ...
          obj.Position(2), obj.Position(3)*obj.KnobHeight, obj.Position(4)];
      else
        % Vertical
        buttonDiam = obj.Position(3)*obj.LineWidth*2;
        if(buttonDiam > obj.Position(3)) 
          buttonDiam = obj.Position(3);
        end
        if(4*buttonDiam > obj.Position(4)*(1-obj.KnobHeight)) 
          buttonDiam = obj.Position(4)*(1-obj.KnobHeight)/4;
        end
        
        plusPosition = [obj.Position(1)+1/2*obj.Position(3)-buttonDiam/2, ...
          obj.Position(2)+obj.Position(4)-buttonDiam, ...
          buttonDiam, buttonDiam];
        minusPosition = [obj.Position(1)+1/2*obj.Position(3)- ...
          buttonDiam/2, obj.Position(2), buttonDiam, buttonDiam];
        plusLinesPosition = [obj.Position(1)+1/2*obj.Position(3), ...
          obj.Position(2)+obj.Position(4)-buttonDiam/2]; 
        minusLinesPosition = [obj.Position(1)+1/2*obj.Position(3), ...
          obj.Position(2)+buttonDiam/2];
        linePosition = [obj.Position(1)+obj.Position(3)*(1/2- ...
          obj.LineWidth/2), obj.Position(2)+buttonDiam/2, ...
          obj.Position(3)*obj.LineWidth, obj.Position(4)-buttonDiam];
        knobPos = [obj.Position(1), obj.Position(2)+buttonDiam+ ...
          (obj.Position(4)-2*buttonDiam-4)*(val*(1-obj.KnobHeight)), ...
          obj.Position(3), obj.Position(4)*obj.KnobHeight];
      end
      obj.buttonDiameter = buttonDiam;
      obj.knobPosition = knobPos;
      
      function uisliderCallback(~, ~, obj, s)
        % obj - slider instance
        % s - slider callback state

        if(s == 0)
          % Knob drag started
          set(obj.Window, 'WindowButtonMotionFcn', ...
           {@uisliderCallback, obj, 1});
          set(obj.Window, 'WindowButtonUpFcn', ...
            {@uisliderCallback, obj, 2});
        elseif(s == 1)
          % Knob draging
          obj.updateKnobDrag();
        elseif(s == 2)
          % Knob drag ended
          set(obj.Window, 'WindowButtonMotionFcn', []);
          set(obj.Window, 'WindowButtonUpFcn', []);
        elseif(s == 3)
          % Knob line clicked
          obj.updateKnobClick(0);
        elseif(s == 4)
          % Plus button clicked
          obj.updateKnobClick(1);
        elseif(s == 5)
          % Minus button clicked
          obj.updateKnobClick(2);
        end
      end

      rectangle(obj.axe, 'Position', linePosition, 'EdgeColor', ...
        [.8, .8, .8], 'FaceColor', [.8, .8, .8], 'LineWidth', 2, ...
        'ButtonDownFcn', {@uisliderCallback, obj, 3});
      rectangle(obj.axe, 'Position', plusPosition, 'EdgeColor', ...
        [.8, .8, .8], 'FaceColor', [.8, .8, .8], 'LineWidth', 2, ...
        'ButtonDownFcn', {@uisliderCallback, obj, 4}, 'Curvature', 1)
      rectangle(obj.axe, 'Position', minusPosition, 'EdgeColor', ...
        [.8, .8, .8], 'FaceColor', [.8, .8, .8], 'LineWidth', 2, ...
        'ButtonDownFcn', {@uisliderCallback, obj, 5}, 'Curvature', 1)
      line(obj.axe, [plusLinesPosition(1)-buttonDiam/2+2, ...
        plusLinesPosition(1)+buttonDiam/2-2], [plusLinesPosition(2), ...
        plusLinesPosition(2)], 'LineWidth', 2, 'Color', obj.BackgroundColor, ...
        'ButtonDownFcn', {@uisliderCallback, obj, 4})
      line(obj.axe, [plusLinesPosition(1), plusLinesPosition(1)], ...
        [plusLinesPosition(2)-buttonDiam/2+2, plusLinesPosition(2)+...
        buttonDiam/2-2], 'LineWidth', 2, 'Color', obj.BackgroundColor, ...
        'ButtonDownFcn', {@uisliderCallback, obj, 4})
      line(obj.axe, [minusLinesPosition(1)-buttonDiam/2+2, ...
        minusLinesPosition(1)+buttonDiam/2-2], [minusLinesPosition(2), ...
        minusLinesPosition(2)], 'LineWidth', 2, 'Color', obj.BackgroundColor, ...
        'ButtonDownFcn', {@uisliderCallback, obj, 5})
      obj.slider.knob = rectangle(obj.axe, 'Position', knobPos, 'EdgeColor', ...
        obj.BackgroundColor, 'LineWidth', 2, 'FaceColor', obj.ForegroundColor, ...
        'ButtonDownFcn', {@uisliderCallback, obj, 0});
    end
    
    function obj = updateKnobDrag(obj)
      if(toc(obj.t) > 0.01)
        if(~obj.Enabled)
          return
        end
        MP = get(obj.axe, 'CurrentPoint');
        if(obj.Orientation) 
          % Horizontal
          if(MP(1, 1) < obj.Position(1)+obj.buttonDiameter+...
            (obj.Position(3)-2*obj.buttonDiameter-4)*obj.KnobHeight/2)
            MP = obj.Position(1)+obj.buttonDiameter+...
            (obj.Position(3)-2*obj.buttonDiameter-4)*obj.KnobHeight/2;
          elseif(MP(1, 1) > obj.Position(1)+obj.buttonDiameter+...
              (obj.Position(3)-2*obj.buttonDiameter-4)*(1-obj.KnobHeight/2))
            MP = obj.Position(1)+obj.buttonDiameter+...
              (obj.Position(3)-2*obj.buttonDiameter-4)*(1-obj.KnobHeight/2);
          else
            MP = MP(1, 1);
          end
          obj.Value = (MP-(obj.Position(1)+obj.buttonDiameter+...
            (obj.Position(3)-2*obj.buttonDiameter-4)...
            *obj.KnobHeight/2))/((obj.Position(3)-2*obj.buttonDiameter-4)*(1-...
            obj.KnobHeight))*(obj.Max-obj.Min)+obj.Min;
        else
          % Vertical
          if(MP(1, 2) < obj.Position(2)+obj.buttonDiameter+...
            (obj.Position(4)-2*obj.buttonDiameter-4)*obj.KnobHeight/2)
            MP = obj.Position(2)+obj.buttonDiameter+...
            (obj.Position(4)-2*obj.buttonDiameter-4)*obj.KnobHeight/2;
          elseif(MP(1, 2) > obj.Position(2)+obj.buttonDiameter+...
              (obj.Position(4)-2*obj.buttonDiameter-4)*(1-obj.KnobHeight/2))
            MP = obj.Position(2)+obj.buttonDiameter+...
              (obj.Position(4)-2*obj.buttonDiameter-4)*(1-obj.KnobHeight/2);
          else
            MP = MP(1, 2);
          end
          obj.Value = (MP-(obj.Position(2)+obj.buttonDiameter+...
            (obj.Position(4)-2*obj.buttonDiameter-4)...
            *obj.KnobHeight/2))/((obj.Position(4)-2*obj.buttonDiameter-4)*(1-...
            obj.KnobHeight))*(obj.Max-obj.Min)+obj.Min;
        end
        obj.moveKnob();
        
        if(ischar(obj.DragCallback))
          eval(obj.DragCallback);
        elseif(isa(obj.DragCallback, 'function_handle'))
          obj.DragCallback(obj, 'Dragged', obj.DragCallbackVars{:});
        end
        obj.t = tic;
      end
    end
    
    function obj = updateKnobSet(obj)
      obj.moveKnob();
      if(~obj.Enabled)
        return
      end
      if(ischar(obj.Callback))
        eval(obj.Callback);
      elseif(isa(obj.Callback, 'function_handle'))
        obj.Callback(obj, 'Set', obj.CallbackVars{:});
      end
    end
    
    function obj = updateKnobClick(obj, s)
      if(~obj.Enabled)
        return
      end
      if(s == 0) 
        % Knob line clicked
        MP = get(obj.axe, 'CurrentPoint');
        if(obj.Orientation) 
          % Horizontal
          if(MP(1, 1) >= obj.knobPosition) 
            sign = 1;
          else
            sign = -1;
          end 
        else
          % Vertical
          if(MP(1, 2) >= obj.knobPosition) 
            sign = 1;
          else
            sign = -1;
          end 
        end
        val = obj.Value+sign*obj.SliderStep(2)*(obj.Max-obj.Min);
      elseif(s == 1)
        % Plus button clicked
        val = obj.Value+obj.SliderStep(1)*(obj.Max-obj.Min);
      elseif(s == 2)
        % Minus button clicked
        val = obj.Value-obj.SliderStep(1)*(obj.Max-obj.Min);
      end
      if(val > obj.Max)
        val = obj.Max;
      elseif(val < obj.Min)
        val = obj.Min;
      end
      obj.Value = val;
        obj.moveKnob();

        if(ischar(obj.DragCallback))
          eval(obj.DragCallback);
        elseif(isa(obj.DragCallback, 'function_handle'))
          obj.DragCallback(obj, 'Dragged', obj.DragCallbackVars{:});
        end
    end
    
    function obj = moveKnob(obj)
      val = (obj.Value-obj.Min)/(obj.Max-obj.Min);
      if(val > 1)
        val = 1;
      elseif(val <0) 
        val = 0;
      end
      if(obj.Orientation) 
        % Horizontal
        knobPos = [obj.Position(1)+obj.buttonDiameter+...
          (obj.Position(3)-2*obj.buttonDiameter-4)*(val*(1-obj.KnobHeight)), ...
          obj.Position(2), obj.Position(3)*obj.KnobHeight, obj.Position(4)];
        obj.knobPosition = knobPos(1);
      else
        % Vertical
        knobPos = [obj.Position(1), obj.Position(2)+obj.buttonDiameter+...
          (obj.Position(4)-2*obj.buttonDiameter-4)*(val*(1-obj.KnobHeight)), ...
          obj.Position(3), obj.Position(4)*obj.KnobHeight];
        obj.knobPosition = knobPos(2);
      end
       set(obj.slider.knob, 'Position', knobPos);
    end
    
    function val = get(obj, prop)
      if (nargin < 1 || nargin > 2)
        print_usage ();
      end

      if (nargin == 1)
        val = obj.Value;
      else
        if (~ischar (prop))
          error ("@uislider/get: PROPERTY must be a string");
        end

        switch (prop)
          case "Value"
            val = obj.Value;
          case "Enable"
            val = obj.Enable;
          otherwise
            error ('@uislider/get: invalid PROPERTY "%s"', prop);
        end
      end

    end

    function obj = set(obj, varargin)
      if (numel (varargin) < 2 || rem (numel (varargin), 2) ~= 0)
        error ("@uislider/set: expecting PROPERTY/VALUE pairs");
      end

      while (numel (varargin) > 1)
        prop = varargin{1};
        val  = varargin{2};
        varargin(1:2) = [];
        if (~ischar (prop))
          error ('@uislider/set: invalid PROPERTY "%s"');
        end

        switch (prop)
          case "Value"
            if(isnumeric(val) && length(size(val))==2 &&...
             (size(val, 1)==1 || size(val, 2)==1))
              if(val > obj.Max)
                val = obj.Max;
              elseif(val < obj.Min)
                val = obj.Min;
              end
              obj.Value = val;
              obj.updateKnobSet();
            else
              error('@uislider/get: invalid VALUE for PROPERTY "%s"', ...
                prop);
            end
          case "Enable"
            if(ischar(val) && (strcmpi(val, 'On') || strcmpi(val, 'Off')))
              obj.Enable = val;
              if(strcmpi(val, 'On'))
                obj.Enabled = 1;
              else
                obj.Enabled = 0;
              end
            else
              error('@uislider/get: invalid VALUE for PROPERTY "%s"', ...
                prop);
            end
          otherwise
            error ('@uislider/get: invalid PROPERTY "%s"', prop);
        end
      end
    end 
  end
end