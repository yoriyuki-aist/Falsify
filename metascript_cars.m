% (C) 2019 National Institute of Advanced Industrial Science and Technology
% (AIST)

% Configurations
%%%%%%%%%%%%%%%%
global workers_num logDir;
workers_num = 10;
staliro_dir = '../s-taliro_public/trunk/';
breach_dir = '../breach';
logDir = '../falsify-data/';
maxIter = 20;
maxEpisodes = 200;
do_cars = true;

config_tmpl = struct('maxIter', maxIter,...
                'maxEpisodes', maxEpisodes,...
                'agentName', '/RL agent');
            
% Initialization
%%%%%%%%%%%%%%%%
initialization
            
% cars Benchmark
%%%%%%%%%%%%%%%%%%%%

cars_tmpl = struct(config_tmpl);
cars_tmpl.outputs = [1 2 3 4];
cars_tmpl.input_range = [0.0 1.0; 0.0 1.0];
cars_tmpl.output_range = [0 100; 0 100; 0 100; 0 100];
cars_tmpl.init_opts = {};
cars_tmpl.interpolation = {'linear'};

%algoFullmdls = {{'RL', 'DDQN', 'carsRLFull'}};
algoBlackboxmdls = {};

algoFullmdls = {};
%algoFullmdls = {{'RL', 'A3C', 'carsRLFull'}, {'RL', 'DDQN', 'carsRLFull'}};
%algoBlackboxmdls = {{'s-taliro', 'SA', 'cars'}};
algoBlackboxmdls = {{'RL', 'A3C', 'carsRLBlackbox'}, {'RL', 'DDQN', 'carsRLBlackbox'}, {'RL', 'RAND', 'carsRLBlackbox'}, {'s-taliro', 'CE', 'cars'}, {'s-taliro', 'SA', 'cars'}};
%     {'RL', 'RAND', 'autotrans_mod04'},...
%     {'RL', 'A3C', 'autotrans_mod04'}, {'RL', 'DDQN', 'autotrans_mod04'},...
%    {'s-taliro', 'SA', 'cars_staliro'}, {'s-taliro', 'CE', 'cars_staliro'}};
sampleTimes = [5];

% Formula 1
% Invariant
fml1 = struct(cars_tmpl);
fml1.expName = 'fml1';
fml1.targetFormula = '[]p1';
fml1.monitoringFormula = 'p1';

fml1.preds(1).str = 'p1';
fml1.preds(1).A = [0 0 0 1];
fml1.preds(1).b = 40.0;
fml1.stopTime = 100;

% Formula 2
% Guarantee
fml2 = struct(cars_tmpl);
fml2.expName = 'fml2';
fml2.targetFormula = '[]<>_[0,20]p1';
fml2.monitoringFormula = '[.]_[20,20]<>_[0, 20]p1';

fml2.preds(1).str = 'p1';
fml2.preds(1).A = [0 0 0 -1];
fml2.preds(1).b = -10.0;

fml2.stopTime = 100;

%Formula 3
% Obligation
fml3 = struct(cars_tmpl);
fml3.expName = 'fml3';
fml3.targetFormula = '[](([]_[0,20]p1) \/ (<>_[0,20]p2))';
fml3.monitoringFormula = '[.]_[20.0,20.0]((([]_[0,20]p1) \/ (<>_[0,20]p2)))';

fml3.preds(1).str = 'p1';
fml3.preds(1).A = [1 0 0 0];
fml3.preds(1).b = 20;
fml3.preds(2).str = 'p2';
fml3.preds(2).A = [0 0 0 -1];
fml3.preds(2).b = -40;

fml3.stopTime = 100;

%Formula 4
%Persistence
fml4 = struct(cars_tmpl);
fml4.expName = 'fml4';
fml4.targetFormula = '[]<>_[0,20][]_[0,20]p1';
fml4.monitoringFormula = '[.]_[40,40]<>_[0,20][]_[0,20]p1';
fml4.preds(1).str = 'p1';
fml4.preds(1).A = [0 0 0 -1];
fml4.preds(1).b = -10;
fml4.stopTime = 100;

%Formula 5
%Reactivity
fml5 = struct(cars_tmpl);
fml5.expName = 'fml5';
fml5.targetFormula = '[]<>_[0,5]([]_[0,5]p1 -> []_[10,20]p2)';
fml5.monitoringFormula = '[.]_[20,20]<>_[0,5]([]_[0,5]p1 -> []_[10,20]p2)';
fml5.stopTime = 30;
fml5.preds(1).str = 'p1';
fml5.preds(1).A = [-1 0 0 0];
fml5.preds(1).b = -10;
fml5.preds(2).str = 'p2';
fml5.preds(2).A = [0 0 0 -1];
fml5.preds(2).b = -10;


formulas = {fml2, fml3, fml4, fml5};

configsFull = { };
for k = 1:size(formulas, 2)
    for i = 1:size(algoFullmdls, 2)
        for j = 1:size(sampleTimes, 2)
            config = struct(formulas{k});
            config.mdl = algoFullmdls{i}{3};
            config.algoName = [algoFullmdls{i}{1}, '-', algoFullmdls{i}{2}];
            config.sampleTime = sampleTimes(j);
            config.engine = algoFullmdls{i}{1};
            config.option = algoFullmdls{i}{2};
            for l = 1:maxIter
              configsFull = [configsFull, config];
            end
        end
    end
end

configsBlackbox = { };
for k = 1:size(formulas, 2)
    for i = 1:size(algoBlackboxmdls, 2)
        for j = 1:size(sampleTimes, 2)
            config = struct(formulas{k});
            config.mdl = algoBlackboxmdls{i}{3};
            config.algoName = [algoBlackboxmdls{i}{1}, '-', algoBlackboxmdls{i}{2}];
            config.sampleTime = sampleTimes(j);
            config.engine = algoBlackboxmdls{i}{1};
            config.option = algoBlackboxmdls{i}{2};
            for l = 1:maxIter
              configsBlackbox = [configsBlackbox, config];
            end
        end
    end
end

if do_cars
    do_experiment('cars_full', configsFull, {});
    do_experiment('cars_blackbox', configsBlackbox, {});
end