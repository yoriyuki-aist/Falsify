% (C) 2019 National Institute of Advanced Industrial Science and Technology
% (AIST)
% (C) 2015 General Electic Global Research - all rights reserved

%% ========================================================================
clear all
close all
%clc

% Configurations
%%%%%%%%%%%%%%%%
global logDir;
staliro_dir = '../s-taliro_public/trunk';
breach_dir = '../breach';
logDir = '../falsify-data/';
maxEpisodes = 200;
initialization
addpath('wind-turbine')

config_tmpl = struct('maxIter', 1,...
                'maxEpisodes', maxEpisodes);

SimplifiedTurbine_Config;
config.ProcessCase          = 'SingleRun'; 

% add some paths
addpath('wind-turbine/tools/')
addpath('wind-turbine/wind/')
addpath(config.wafo_path)

%load wind files
load('ClassA.mat')
load('ClassA_config.mat')

load('aeromaps3.mat');
Parameter.InitialConditions = load('InitialConditions');
% remove all unnecessary fields (otherwise Simulink will throw an error)
cT_modelrm = rmfield(cT_model,{'VarNames'});%,'RMSE','ParameterVar','ParameterStd','R2','AdjustedR2'});
cP_modelrm = rmfield(cP_model,{'VarNames'});%,'RMSE','ParameterVar','ParameterStd','R2','AdjustedR2'});

% initialize WAFO
initwafo 

iBin = find(URefVector==Parameter.URef);
iRandSeed = 1;
switch config.ProcessCase
    case ('SingleRun')
        config.iBin                         = iBin;
        config.iRandSeed                    = iRandSeed;
        Parameter.v0                        = v0_cell{iBin,iRandSeed};
        Parameter.v0.signals.values         = Parameter.v0.signals.values';
        Parameter.TMax                      = v0_cell{iBin,iRandSeed}.time(end);
        config.WindFieldName                = FileNames{iBin,iRandSeed};
        % Time
        Parameter.Time.TMax                 = 630;              % [s]       duration of simulation
        Parameter.Time.dt                   = 0.01;           % [s]       time step of simulation
        Parameter.Time.cut_in               = 30;
        Parameter.Time.cut_out              = Parameter.Time.TMax;
        Parameter.v0_0 = Parameter.v0.signals.values(1);

        Parameter = SimplifiedTurbine_ParamterFile(Parameter);
        sim('SimplifiedWTModel.slx')
        SimplifiedTurbine_PostProcessing;
    case ('AllCases')
        %% Time
                Parameter.Time.TMax                 = 630;            % [s]       duration of simulation
                Parameter.Time.dt                   = 0.01;           % [s]       time step of simulation
                Parameter.Time.cut_in               = 30;
                Parameter.Time.cut_out              = Parameter.Time.TMax;
        for i_ind = 1:size(v0_cell,1)
            for j_ind = 1:size(v0_cell,2)
                clear Theta Theta_d xT xT_dot Omega lambda Mg
                iBin                                = i_ind;
                iRandSeed                           = j_ind;
                Parameter.v0                        = v0_cell{iBin,iRandSeed};
                Parameter.v0.signals.values         = Parameter.v0.signals.values';
                Parameter.TMax                      = v0_cell{iBin,iRandSeed}.time(end);
                config.WindFieldName                = FileNames{iBin,iRandSeed};
   
                Parameter.v0_0 = Parameter.v0.signals.values(1);
                
                Parameter = SimplifiedTurbine_ParamterFile(Parameter);
                sim('SimplifiedWTModel.slx')
                SimplifiedTurbine_PostProcessing;
            end
        end
        SimplifiedTurbine_PostProcessingGlobal
        
end

tmpl = struct(config_tmpl);
tmpl.input_range = [8.0 16.0];
tmpl.output_range = [0.0 12.0;11.5 13.0; 1120.0 1220.0; 3.0*10^4 5.0*10^4; 1.0 3.0; 0.0 12.0];
tmpl.init_opts = {};
tmpl.interpolation = {'linear'};
tmpl.agentName = '/RL agent';
tmpl.stopTime = 630;

% Formula 1
fml1 = struct(tmpl);
fml1.expName = 'fml1';
fml1.targetFormula = '[]_[30, 630]p1';
fml1.monitoringFormula = 'p1';

fml1.preds(1).str = 'p1';
fml1.preds(1).A = [0 0 0 0 0 1];
fml1.preds(1).b = 12.0;
fml1.stopTime = Parameter.Time.TMax;
fml1.mdl = 'SimplifiedWTModelRL';
fml1.algoName = ['RL', '-', 'DDQN'];
fml1.sampleTime = 10;
fml1.engine = 'RL';
fml1.option = 'DDQN';

[numEpisode, elapsedTime, bestRob, bestXout, bestYout] = falsify(fml1);

X = bestYout.getElement(3).Values.Data;
Y = bestYout.getElement(4).Values.Data;
T = bestYout.getElement(4).Values.Time;
v0_cell{iBin,iRandSeed}.signals.values = X(:);
v0_cell{iBin,iRandSeed}.time = T;
Theta.signals.values = Y(:, 6);
Theta.times = T(:);
Omega.signals.values = Y(:, 5);
Omega.times = T(:);
Mg.signals.values = Y(:, 3);
Mg.times = T(:);
Theta_d.signals.values = Y(:, 1);
Theta_d.times = T(:);
SimplifiedTurbine_PostProcessing;

save(config.flname, 'results', 'Parameter', 'config')
SimplifiedTurbine_PlotResults

