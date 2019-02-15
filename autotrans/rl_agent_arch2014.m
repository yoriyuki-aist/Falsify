classdef rl_agent_arch2014 < matlab.System & matlab.system.mixin.Propagates ...
        & matlab.system.mixin.CustomIcon & matlab.system.mixin.Nondirect & ...
        matlab.system.mixin.SampleTime
    % untitled Add summary here
    %
    % NOTE: When renaming the class name untitled, the file name
    % and constructor name must be updated to use the class name.
    %
    % This template includes most, but not all, possible properties, attributes,
    % and methods that you can implement for a System object in Simulink.

    % Public, tunable properties
    properties
      sample_time = 5.0;
      input_range = [0.0 100.0; 0.0 500.0];
    end

    % Public, non-tunable properties
    properties(Nontunable)
       
    end

    properties(DiscreteState)
       action;
       last_action;
       last_t;
    end

    properties(Constant, Hidden)
       
    end
    
    % Pre-computed constants
    properties(Access = public)
  
    end

%     methods
%         % Constructor
%         function obj = untitled(varargin)
%             % Support name-value pair arguments when constructing object
%             setProperties(obj,nargin,varargin{:})
%         end
%     end

    methods(Access = protected)
        %% Common functions  
        function resetImpl(obj)
            action_normalized = [0 0];
            coder.extrinsic('py.driver.act')
            action_normalized = double(py.driver.act([-1 -1 -1]));
            action_normalized = min([1.0 1.0], max([-1.0 -1.0], action_normalized));
            lower = obj.input_range(:,1)';
            upper = obj.input_range(:,2)';
            middle = (lower + upper)/2.0;
            obj.action = (action_normalized .* (upper - middle) + middle); 
            obj.last_action = obj.action;
            obj.last_t = 0;
        end
        
        function setupImpl(obj)
            % Perform one-time calculations, such as computing constants
            obj.resetImpl();
        end

        function action = outputImpl(obj, ~, ~)
            t = getCurrentTime(obj);
            p = (t - obj.last_t) / obj.sample_time;
            action = (1 - p) * obj.last_action' + p * obj.action';
        end
        
        function updateImpl(obj, state, reward)
            coder.extrinsic('py.driver.driver')
            action_normalized = [0 0];
            t = getCurrentTime(obj);
            if floor(t ./ obj.sample_time) ~= floor(obj.last_t ./ obj.sample_time)
                action_normalized = double(py.driver.driver(state', reward(1)));
                action_normalized = min([1.0 1.0], max([-1.0 -1.0], action_normalized));
                lower = obj.input_range(:,1)';
                upper = obj.input_range(:,2)';
                middle = (lower + upper)/2.0;
                obj.last_action = obj.action;
                obj.action = (action_normalized .* (upper - middle) + middle); 
                obj.last_t = t;
            end
        end
        
%         function y = stepImpl(obj,u)
%             % Implement algorithm. Calculate y as a function of input u and
%             % discrete states.
%             y = u;
%         end
% 
%         function resetImpl(obj)
%             % Initialize / reset discrete-state properties
%         end

        %% Backup/restore functions
        function s = saveObjectImpl(obj)
            % Set properties in structure s to values in object obj

            % Set public properties and states
            s = saveObjectImpl@matlab.System(obj);

            % Set private and protected properties
            %s.myproperty = obj.myproperty;
        end

        function loadObjectImpl(obj,s,wasLocked)
            % Set properties in object obj to values in structure s

            % Set private and protected properties
            % obj.myproperty = s.myproperty; 

            % Set public properties and states
            loadObjectImpl@matlab.System(obj,s,wasLocked);
        end

        %% Simulink functions
%         function ds = getDiscreteStateImpl(~)
%             % Return structure of properties with DiscreteState attribute
%             ds = struct([]);
%         end

        function [sz,dt,cp] = getDiscreteStateSpecificationImpl(~, propertyname)
           switch propertyname 
               case 'action'
                   sz = [1 2];
                   dt = 'double';
                   cp = false;
               case 'last_action'
                   sz = [1 2];
                   dt = 'double';
                   cp = false;             
               case 'last_t'
                   sz = [1];
                   dt = 'double';
                   cp = false;
           end
        end

        function flag = isInputSizeMutableImpl(~,~)
            % Return false if input size cannot change
            % between calls to the System object
            flag = false;
        end

        function flag = isOutputFixedSizeImpl(~, ~)
           flag = true; 
        end
        
        function n = getNumInputsImpl(~)
           n = 2;
        end
        
        function out = getOutputSizeImpl(~)
            % Return size for each output port
            out = [2];

            % Example: inherit size from first input port
            % out = propagatedInputSize(obj,1);
        end

        function ds = getOutputDataTypeImpl(~)     
            ds = ['double'];
        end
        
        function flag = isOutputComplexImpl(~)     
            flag = false;
        end
        
        function icon = getIconImpl(~)
            % Define icon for System block
            icon = mfilename("class"); % Use class name
            % icon = "My System"; % Example: text icon
            % icon = ["My","System"]; % Example: multi-line text icon
            % icon = matlab.system.display.Icon("myicon.jpg"); % Example: image file icon
        end
                
        function [flag1, flag2] = isInputDirectFeedthroughImpl(~, ~, ~)
            flag1 = false;
            flag2 = false;
        end
    end

    methods(Static, Access = protected)
        %% Simulink customization functions
        function header = getHeaderImpl
            % Define header panel for System block dialog
            header = matlab.system.display.Header(mfilename("class"));
        end

        function group = getPropertyGroupsImpl
            % Define property section(s) for System block dialog
            group = matlab.system.display.Section(mfilename("class"));
        end
    end
end
