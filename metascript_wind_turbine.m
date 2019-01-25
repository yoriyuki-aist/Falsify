% (C) 2019 National Institute of Advanced Industrial Science and Technology
% (AIST)
% (C) 2015 General Electic Global Research - all rights reserved

%% ========================================================================
clear all
close all
%clc

% Configurations
%%%%%%%%%%%%%%%%
global workers_num logDir;
workers_num = 1;
staliro_dir = '../s-taliro_public/trunk/';
breach_dir = '../breach';
logDir = '../falsify-data/';

maxIter = 1;
maxEpisodes = 1;

config_tmpl = struct('maxIter', maxIter,...
                'maxEpisodes', maxEpisodes,...
                'agentName', '/RL agent');
            
% Initialization
%%%%%%%%%%%%%%%%
initialization
SimplifiedTurbine_Config;

addpath('wind-turbine')
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

% Formulas
%%%%%%%%%%%%%%%

tmpl = struct(config_tmpl);
tmpl.input_range = [8.0 16.0];
tmpl.output_range = [0.0 13.0;10.0 13.0; 1000.0 1300.0; 2.80*10^4 5.0*10^4; 1.0 3.0; 0.0 13.0];
tmpl.init_opts = {};
tmpl.interpolation = {'linear'};
tmpl.agentName = '/RL agent';
tmpl.stopTime = 630;

% Formula 1, mnimum pitch angle
fml1 = struct(tmpl);
fml1.expName = 'fml1';
fml1.targetFormula = '[]_[30, 630](p2 -> p1)';
fml1.monitoringFormula = 'p2 -> p1';

fml1.preds(1).str = 'p1';
fml1.preds(1).A = [0 0 0 0 0 -1];
fml1.preds(1).b = -1.0;
fml1.preds(2).str = 'p2';
fml1.preds(2).A = [0 0 0 0 1 0];
fml1.preds(2).b = 2.5;
fml1.stopTime = Parameter.Time.TMax;

% Formula 2, maximum pitch angle
fml2 = struct(tmpl);
fml2.expName = 'fml2';
fml2.targetFormula = '[]_[30, 630]p1';
fml2.monitoringFormula = 'p1';

fml2.preds(1).str = 'p1';
fml2.preds(1).A = [0 0 0 0 0 1];
fml2.preds(1).b = 15.0;
fml2.stopTime = Parameter.Time.TMax;

% Formula 3, gnerator torque
fml3 = struct(tmpl);
fml3.expName = 'fml3';
fml3.targetFormula = '[]_[30, 630](p1 /\ p2)';
fml3.monitoringFormula = 'p1 /\ p2';

fml3.preds(1).str = 'p1';
fml3.preds(1).A = [0 0 0 1 0 0];
fml3.preds(1).b = 1500.0;
fml3.preds(2).str = 'p2';
fml3.preds(2).A = [0 0 0 -1 0 0];
fml3.preds(2).b = -800.0;
fml3.stopTime = Parameter.Time.TMax;

% Formula 4, rotor speed
fml4 = struct(tmpl);
fml4.expName = 'fml4';
fml4.targetFormula = '[]_[30, 630](p1)';
fml4.monitoringFormula = 'p1';

fml4.preds(1).str = 'p1';
fml4.preds(1).A = [0 0 0 0 1 0];
fml4.preds(1).b = 15.0;
fml4.stopTime = Parameter.Time.TMax;

% Formula 5, difference between the command pitch and the measuread pitch
fml5 = struct(tmpl);
fml5.expName = 'fml5';
fml5.targetFormula = '[]_[30, 630](<>_[0, 10](p1 /\ p2))';
fml5.monitoringFormula = 'p1 /\ p2';

fml5.preds(1).str = 'p1';
fml5.preds(1).A = [-1 0 0 0 0 1];
fml5.preds(1).b = 1.0;
fml5.preds(2).str = 'p2';
fml5.preds(2).A = [1 0 0 0 0 -1];
fml5.preds(2).b = 1.0;
fml5.stopTime = Parameter.Time.TMax;


fmls = {fml1, fml3, fml4, fml5};

% Algorithms
algorithms = {{'s-taliro', 'SA', 'SimplifiedWTModelSTaLiRo'}, {'RL', 'DDQN', 'SimplifiedWTModelRL'}};
%algorithms = {{'s-taliro', 'SA', 'SimplifiedWTModelSTaLiRo'}, {'s-taliro', 'CE', 'SimplifiedWTModelSTaLiRo'},...
%    {'RL', 'A3C', 'SimplifiedWTModelRL'}, {'RL', 'DDQN', 'SimplifiedWTModelRL'}, {'RL', 'RAND', 'SimplifiedWTModelRL'}};

% Other parameters
sampleTime = 10;

% Generate configurations
configs = {};
for i = 1:size(fmls, 2)
    for j = 1:size(algorithms, 2)
        config = struct(fmls{i});
        config.mdl = algorithms{j}{3};
        config.algoName = [algorithms{j}{1}, '-', algorithms{j}{2}];
        config.sampleTime = sampleTime;
        config.engine = algorithms{j}{1};
        config.option = algorithms{j}{2};
        for l = 1:maxIter
           configs = [configs, config]; 
        end
    end
end

do_experiment('windo_turbine', configs, {});