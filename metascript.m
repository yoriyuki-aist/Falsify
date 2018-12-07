% Configurations
%%%%%%%%%%%%%%%%
global workers_num logDir;
workers_num = 4;
staliro_dir = '../s-taliro';
breach_dir = '../breach';
logDir = '../falsify-data/';
maxIter = 100;
maxEpisodes = 200;
do_arch2014 = true;
do_ptc = false;
do_insulin = false;


% Initialization
%%%%%%%%%%%%%%%%
if exist('dp_taliro.m', 'file') == 0
    addpath(staliro_dir);
    cwd = pwd;
    cd(staliro_dir);
    setup_staliro;
    cd(cwd);
end

if exist('setup_monitor.m', 'file') == 0
    addpath(fullfile(staliro_dir, 'monitor'));
    cwd = pwd;
    cd(fullfile(staliro_dir, 'monitor'));
    setup_monitor;
    cd(cwd);
end

if exist('InitBreach.m', 'file') == 0
    addpath(breach_dir);
    cwd = pwd;
    cd(breach_dir);
    InitBreach;
    cd(cwd);
end    
if ~ 7 == exist(logDir, 'dir')
    mkdir(logDir);
end
start_time = datetime('now');

config_tmpl = struct('maxIter', maxIter,...
                'maxEpisodes', maxEpisodes);
% ARCH2014 Benchmark
%%%%%%%%%%%%%%%%%%%%
outputs = [2,3,4];

arch2014_tmpl = struct(config_tmpl);
arch2014_tmpl.outputs = [2, 3, 4];
arch2014_tmpl.input_range = [0.0 100.0; 0.0 500.0];
arch2014_tmpl.output_range = [0.0 5000.0;0.0 160.0;1.0 4.0];
arch2014_tmpl.init_opts = {};
arch2014_tmpl.interpolation = {'linear'};
            
%algomdls = {{'RL', 'A3C', 'autotrans_mod04'}, {'RL', 'DDQN', 'autotrans_mod04'}};
%algomdls = [algomdls, {{'s-taliro', 'SA', 'arch2014_staliro'}}, {{'s-taliro', 'CE', 'arch2014_staliro'}}];
%algomdls = {{'RL', 'DDQN', 'autotrans_mod04'}, {'s-taliro', 'CE', 'arch2014_staliro'}};
%br_algomdls = {};
algomdls = {};
cmaes_algomdls = {{'breach', 'cmaes', 'arch2014_staliro'}};
basic_algomdls = {{'breach', 'basic', 'arch2014_staliro'}};
nm_algomdls = {{'breach', 'global_nelder_mead', 'arch2014_staliro'}};
sampleTimes = [10, 5, 1];
%algomdls = {{'ACER', 'autotrans_mod04'}};
%sampleTimes = 10;

g2L = 1.5;
g3L = 2.5;
g4L = 3.5;

% Formula 1
fml1 = struct(arch2014_tmpl);
fml1.expName = 'fml1';
fml1.targetFormula = '[]p1';
fml1.monitoringFormula = 'p1';

fml1.preds(1).str = 'p1';
fml1.preds(1).A = [1 0 0];
fml1.preds(1).b = 4770.0;
fml1.br_formula = STL_Formula('fml1', 'alw (Out1[t] <= 4770.0)');
fml1.stopTime = 30;

% Formula 2
fml2 = struct(arch2014_tmpl);
fml2.expName = 'fml2';
fml2.targetFormula = '[](p1 /\ p2)';
fml2.monitoringFormula = 'p1 /\ p2';
fml2.br_formula = STL_Formula('fml2', 'alw ((Out1[t] <= 4770.0) and (Out2[t] <= 170))');

fml2.preds(1).str = 'p1';
fml2.preds(1).A = [1 0 0];
fml2.preds(1).b = 4770.0;

fml2.preds(2).str = 'p2';
fml2.preds(2).A = [0 1 0];
fml2.preds(2).b = 170.0;
fml2.stopTime = 30;

%Formula 3
fml3 = struct(arch2014_tmpl);
fml3.expName = 'fml3';
fml3.targetFormula = '[]_[0,29.0]( ((g2L/\g2U) /\ <>_[0, 0.1] g1) -> []_[0.1,1.0](!(g2L/\g2U)))';
fml3.monitoringFormula = '[.]_[1.0,1.0]( ((g2L/\g2U) /\ <>_[0, 0.1] g1) -> []_[0.1,1.0](!(g2L/\g2U)))';
fml3.br_formula = STL_Formula('fml3',...
    'alw_[0, 29.0](((Out3[t] >= 1.5 and Out3[t] <= 2.5) and ev_[0, 0.1] (Out3[t] <= 1.5)) => alw_[0.1,1.0]((Out3[t]< 1.5) or (Out3[t] > 2.5)))');

fml3.preds(1).str = 'g1';
fml3.preds(1).A = [0 0 1];
fml3.preds(1).b = g2L;
fml3.preds(2).str = 'g2L';
fml3.preds(2).A = [0 0 -1];
fml3.preds(2).b = -g2L;
fml3.preds(3).str = 'g2U';
fml3.preds(3).A = [0 0 1];
fml3.preds(3).b = g3L;
fml3.preds(4).str = 'g3L';
fml3.preds(4).A = [0 0 -1];
fml3.preds(4).b = -g3L;
fml3.preds(5).str = 'g3U';
fml3.preds(5).A = [0 0 1];
fml3.preds(5).b = g4L;
fml3.preds(6).str = 'g4';
fml3.preds(6).A = [0 0 -1];
fml3.preds(6).b = -g4L;

fml3.stopTime = 30;

%Formula 4
fml4 = struct(arch2014_tmpl);
fml4.expName = 'fml4';
fml4.targetFormula = '[]_[0,29.0]( (!g1 /\ <>_[0, 0.1] g1) -> []_[0.1,1.0](g1))';
fml4.monitoringFormula = '[.]_[1.0,1.0]((!g1 /\ <>_[0, 0.1] g1) -> []_[0.1,1.0](g1))';
fml4.br_formula = STL_Formula('fml4',...
    'alw_[0, 29.0](((Out3[t] > 1.5) and ev_[0, 0.1] (Out3[t] <= 1.5)) => alw_[0.1,1.0](Out3[t]<= 1.5))');
fml4.preds = fml3.preds;
fml4.stopTime = 30;

%Formula 5
fml5 = struct(arch2014_tmpl);
fml5.expName = 'fml5';
fml5.targetFormula = ['[]_[0,29]( ((!g1 /\ <>_[0,0.1] g1) -> []_[0.1,1.0]g1) /\ ((!(g2L/\g2U) /\ <>_[0,0.1] (g2L/\g2U)) ->' ...
'[]_[0.1,1.0](g2L/\g2U)) /\ ((!(g3L/\g3U) /\ <>_[0,0.1] (g3L/\g3U)) ->' ... 
'[]_[0.1,1.0](g3L/\g3U)) /\ ((!g4 /\ <>_[0,0.1] g4) -> []_[0.1,1.0]g4))'];
fml5.monitoringFormula = ['[.]_[1.0,1.0]( ((!g1 /\ <>_[0,0.1] g1) -> []_[0.1,1.0]g1) /\ ((!(g2L/\g2U) /\ <>_[0,0.1] (g2L/\g2U)) ->' ...
'[]_[0.1,1.0](g2L/\g2U)) /\ ((!(g3L/\g3U) /\ <>_[0,0.1] (g3L/\g3U)) ->' ... 
'[]_[0.1,1.0](g3L/\g3U)) /\ ((!g4 /\ <>_[0,0.1] g4) -> []_[0.1,1.0]g4))'];
fml5.br_formula = STL_Formula('fml5',...
    ['alw_[0, 29.0](', ...
        '(((Out3[t] > 1.5) and ev_[0, 0.1] (Out3[t] <= 1.5)) => alw_[0.1,1.0](Out3[t]<= 1.5)) and',...
        '((((Out3[t] < 1.5) or (Out3[t] > 2.5)) and ev_[0, 0.1] ((Out3[t] >= 1.5) and (Out3[t] <= 2.5))) => alw_[0.1,1.0]((Out3[t] >= 1.5) and (Out3[t] <= 2.5))) and',...
        '((((Out3[t] < 2.5) or (Out3[t] > 3.5)) and ev_[0, 0.1] ((Out3[t] >= 2.5) and (Out3[t] <= 3.5))) => alw_[0.1,1.0]((Out3[t] >= 2.5) and (Out3[t] <= 3.5))) and',...
        '(((Out3[t] < 3.5) and ev_[0, 0.1] (Out3[t] >= 3.5)) => alw_[0.1,1.0](Out3[t] >= 3.5)))']);
fml5.preds = fml3.preds;
fml5.stopTime = 30;

% Formula 6
fml6 = struct(arch2014_tmpl);
fml6.expName = 'fml6';
fml6.targetFormula = '[]_[0, 80](([]_[0, 10](p1)) -> ([]_[10,20](p2)))';
fml6.monitoringFormula = '[.]_[20, 20](([]_[0, 10](p1)) -> ([]_[10,20](p2)))';
fml6.br_formula = STL_Formula('fml6', 'alw_[0,80.0]((alw_[0,10](Out1[t]<=4500)) => alw_[10,20](Out2[t]<=130))');

fml6.preds(1).str = 'p1';
fml6.preds(1).A = [1 0 0];
fml6.preds(1).b = 4500.0;

fml6.preds(2).str = 'p2';
fml6.preds(2).A = [0 1 0];
fml6.preds(2).b = 130.0;

fml6.stopTime = 100;

%Formula 7
fml7 = struct(arch2014_tmpl);
fml7.expName = 'fml7';
fml7.targetFormula = '!<>p1';
fml7.monitoringFormula = '!p1';
fml7.br_formula = STL_Formula('fml6', 'not ev (Out2[t]>=160)');

fml7.preds(1).str = 'p1';
fml7.preds(1).A = [0 -1 0];
fml7.preds(1).b = -160.0;

fml7.stopTime = 100;

%Formula 8
fml8 = struct(arch2014_tmpl);
fml8.expName = 'fml8';
fml8.targetFormula = '[]_[0,75](<>_[0,25](!(vl/\vu)))';
fml8.monitoringFormula = '[.]_[25, 25]<>_[0,25](!(vl/\vu))';
fml8.br_formula = STL_Formula('fml8', 'alw_[0,75](ev_[0,25](not ((Out2[t]>=70) and (Out2[t]<=80))))');

vl = 70.0;
vu = 80.0;
fml8.preds(1).str = 'vl';
fml8.preds(1).A = [0 -1 0];
fml8.preds(1).b = -vl;
fml8.preds(2).str = 'vu';
fml8.preds(2).A = [0 1 0];
fml8.preds(2).b = vu;

fml8.stopTime = 100;

%Formula 9
fml9 = struct(arch2014_tmpl);
fml9.expName = 'fml9';
fml9.targetFormula = '[]_[0,80](![]_[0,20](!g4 /\ highRPM))';
fml9.monitoringFormula = '[.]_[20, 20]![]_[0,20](!g4 /\ highRPM)';
fml9.br_formula = STL_Formula('fml9', 'alw_[0,80](not alw_[0,20]((Out3[t]<3.5) and (Out1[t]>=3100)))');

pred = struct('str', 'highRPM', 'A', [-1 0 0], 'b', -3100.0);
fml9.preds = [fml3.preds, pred];

fml9.stopTime = 100;

formulas = {fml1, fml2, fml3, fml4, fml5, fml6, fml7, fml8, fml9 };
%formulas = {fml1};

configs = { };
for k = 1:size(formulas, 2)
    for i = 1:size(algomdls, 2)
        for j = 1:size(sampleTimes, 2)
            config = struct(formulas{k});
            config.mdl = algomdls{i}{3};
            config.algoName = [algomdls{i}{1}, '-', algomdls{i}{2}];
            config.sampleTime = sampleTimes(j);
            config.engine = algomdls{i}{1};
            config.option = algomdls{i}{2};
            for l = 1:maxIter
              configs = [configs, config];
            end
        end
    end
end

br_configs = { };

cmaes_sample_times = [10,5,1];
nm_sample_times = [10];
basic_sample_times = [10, 5, 1];
for k = 1:size(formulas, 2)
    for i = 1:size(cmaes_algomdls, 2)
        for j = 1:size(cmaes_sample_times, 2)
            config = struct(formulas{k});
            config.mdl = cmaes_algomdls{i}{3};
            config.algoName = [cmaes_algomdls{i}{1}, '-', cmaes_algomdls{i}{2}];
            config.sampleTime = cmaes_sample_times(j);
            config.engine = cmaes_algomdls{i}{1};
            config.option = cmaes_algomdls{i}{2};
            for l = 1:100
              br_configs = [br_configs, config];
            end
        end
        for j = 1:size(basic_sample_times, 2)
            config = struct(formulas{k});
            config.mdl = basic_algomdls{i}{3};
            config.algoName = [basic_algomdls{i}{1}, '-', basic_algomdls{i}{2}];
            config.sampleTime = basic_sample_times(j);
            config.engine = basic_algomdls{i}{1};
            config.option = basic_algomdls{i}{2};
            for l = 1:100
              br_configs = [br_configs, config];
            end
        end
        for j = 1:size(nm_sample_times, 2)
            config = struct(formulas{k});
            config.mdl = nm_algomdls{i}{3};
            config.algoName = [nm_algomdls{i}{1}, '-', nm_algomdls{i}{2}];
            config.sampleTime = nm_sample_times(j);
            config.engine = nm_algomdls{i}{1};
            config.option = nm_algomdls{i}{2};
            for l = 1:100
              br_configs = [br_configs, config];
            end
        end
    end
end

if do_arch2014
    do_experiment('ARCH2014', configs, br_configs);
end



% Power Control Benchmark Model
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ptc_tmpl = struct(config_tmpl);
%ptc_tmpl.outputs = [2];
ptc_tmpl.output_range = [-0.1 0.1; 0.0 1.0; 8.8 90.0; 900.0 1100.0];
ptc_tmpl.init_opts = {{'simTime', 50}, {'en_speed', 1000},...
    {'measureTime', 1}, {'fault_time', 60}, {'spec_num', 1},...
    {'fuel_inj_tol', 1.0}, {'MAF_sensor_tol', 1.0}, {'AF_sensor_tol', 1.0}};
ptc_tmpl.interpolation = {'pconst'};

ptc_fml26 = struct(ptc_tmpl);
ptc_fml26.expName = 'ptc_fml26';
ptc_fml26.input_range = [ 8.8 69.9; 900.0 1100.0];
ptc_fml26.targetFormula = '[]_[11,50](pl /\ pu)';
ptc_fml26.monitoringFormula = 'pl /\ pu';
ptc_fml26.preds(1).str = 'pl';
ptc_fml26.preds(1).A = [1 0 0 0];
ptc_fml26.preds(1).b = 0.1;
ptc_fml26.preds(2).str = 'pu';
ptc_fml26.preds(2).A = [-1 0 0 0];
ptc_fml26.preds(2).b = 0.1;
ptc_fml26.stopTime = 50;

ptc_fml27_rise = struct(ptc_tmpl);
ptc_fml27_rise.expName = 'ptc_fml27-rise';
ptc_fml27_rise.input_range = [8.8 69.9; 900.0 1100.0];
ptc_fml27_rise.targetFormula = '[]_[11,50]((r1  /\ <>_[0,0.1] r2) -> []_[1,5](pl /\ pu))';
ptc_fml27_rise.monitoringFormula = '(r1  /\ <>_[0,0.1] r2) -> []_[1,5](pl /\ pu)';
ptc_fml27_rise.preds(1).str = 'pl';
ptc_fml27_rise.preds(1).A = [1 0 0 0];
ptc_fml27_rise.preds(1).b = 0.02;
ptc_fml27_rise.preds(2).str = 'pu';
ptc_fml27_rise.preds(2).A = [-1 0 0 0];
ptc_fml27_rise.preds(2).b = 0.02;
ptc_fml27_rise.preds(3).str = 'r1';
ptc_fml27_rise.preds(3).A = [0 0 1 0];
ptc_fml27_rise.preds(3).b = 25.0;
ptc_fml27_rise.preds(4).str = 'r2';
ptc_fml27_rise.preds(4).A = [0 0 -1 0];
ptc_fml27_rise.preds(4).b = -45.0;
ptc_fml27_rise.stopTime = 50;


ptc_fml27_fall = struct(ptc_tmpl);
ptc_fml27_fall.expName = 'ptc_fml27-fall';
ptc_fml27_fall.input_range = [8.8 69.9; 900.0 1100.0];
ptc_fml27_fall.targetFormula = '[]_[11,50]((r2  /\ <>_[0,0.1] r1) -> []_[1,5](pl /\ pu))';
ptc_fml27_fall.monitoringFormula = '(r2  /\ <>_[0,0.1] r1) -> []_[1,5](pl /\ pu)';
ptc_fml27_fall.preds(1).str = 'pl';
ptc_fml27_fall.preds(1).A = [1 0 0 0];
ptc_fml27_fall.preds(1).b = 0.025;
ptc_fml27_fall.preds(2).str = 'pu';
ptc_fml27_fall.preds(2).A = [-1 0 0 0];
ptc_fml27_fall.preds(2).b = 0.025;
ptc_fml27_fall.preds(3).str = 'r1';
ptc_fml27_fall.preds(3).A = [0 0 1 0];
ptc_fml27_fall.preds(3).b = 25.0;
ptc_fml27_fall.preds(4).str = 'r2';
ptc_fml27_fall.preds(4).A = [0 0 -1 0];
ptc_fml27_fall.preds(4).b = -45.0;
ptc_fml27_fall.stopTime = 50;

ptc_fml30 = struct(ptc_tmpl);
ptc_fml30.expName = 'ptc_fml30';
ptc_fml30.input_range = [ 8.8 69.9; 900.0 1100.0];
ptc_fml30.targetFormula = '[]_[11,50](pu)';
ptc_fml30.monitoringFormula = 'pu';
ptc_fml30.preds(1).str = 'pu';
ptc_fml30.preds(1).A = [-1 0 0 0];
ptc_fml30.preds(1).b = 0.2;
ptc_fml30.stopTime = 50;
ptc_fml30.init_opts = {{'simTime', 50}, {'en_speed', 1000},...
    {'measureTime', 1}, {'fault_time', 60}, {'spec_num', 1},...
    {'fuel_inj_tol', 1.05}, {'MAF_sensor_tol', 1.05}, {'AF_sensor_tol', 1.01}};

ptc_fml31 = struct(ptc_tmpl);
ptc_fml31.expName = 'ptc_fml31';
ptc_fml31.input_range = [ 8.8 69.9; 900.0 1100.0];
ptc_fml31.targetFormula = '[]_[11,50](pl)';
ptc_fml31.monitoringFormula = 'pl';
ptc_fml31.preds(1).str = 'pl';
ptc_fml31.preds(1).A = [1 0 0 0];
ptc_fml31.preds(1).b = 0.2;
ptc_fml31.stopTime = 50;
ptc_fml31.init_opts = {{'simTime', 50}, {'en_speed', 1000},...
    {'measureTime', 1}, {'fault_time', 60}, {'spec_num', 1},...
    {'fuel_inj_tol', 0.95}, {'MAF_sensor_tol', 0.95}, {'AF_sensor_tol', 0.99}};

ptc_fml32 = struct(ptc_tmpl);
ptc_fml32.expName = 'ptc_fml32';
ptc_fml32.input_range = [8.8 90.0; 900.0 1100.0];
ptc_fml32.targetFormula = '[]_[11,50]((power /\ <>_[0,0.1]normal) -> []_[1,5](pl /\ pu))';
ptc_fml32.monitoringFormula = '(power /\ <>_[0,0.1]normal) -> []_[1,5](pl /\ pu)';
ptc_fml32.preds(1).str = 'pl';
ptc_fml32.preds(1).A = [1 0 0 0];
ptc_fml32.preds(1).b = 0.03;
ptc_fml32.preds(2).str = 'pu';
ptc_fml32.preds(2).A = [-1 0 0 0];
ptc_fml32.preds(2).b = 0.03;
ptc_fml32.preds(3).str = 'power';
ptc_fml32.preds(3).A = [0 -1 0 0];
ptc_fml32.preds(3).b = -0.51;
ptc_fml32.preds(4).str = 'normal';
ptc_fml32.preds(4).A = [0 1 0 0];
ptc_fml32.preds(4).b = 0.50;
ptc_fml32.stopTime = 50;

ptc_fml33 = struct(ptc_tmpl);
ptc_fml33.expName = 'ptc_fml33';
ptc_fml33.input_range = [8.8 90.0; 900.0 1100.0];
ptc_fml33.targetFormula = '[]_[11,50](power -> (pl /\ pu))';
ptc_fml33.monitoringFormula = 'power -> (pl /\ pu)';
ptc_fml33.preds(1).str = 'pl';
ptc_fml33.preds(1).A = [1 0 0 0];
ptc_fml33.preds(1).b = 0.2;
ptc_fml33.preds(2).str = 'pu';
ptc_fml33.preds(2).A = [-1 0 0 0];
ptc_fml33.preds(2).b = 0.2;
ptc_fml33.preds(3).str = 'power';
ptc_fml33.preds(3).A = [0 -1 0 0];
ptc_fml33.preds(3).b = -0.50;
ptc_fml33.stopTime = 50;

ptc_fml34 = struct(ptc_tmpl);
ptc_fml34.expName = 'ptc_fml34_sensorfail';
ptc_fml34.input_range = [8.8 69.9; 900.0 1100.0];
ptc_fml34.targetFormula = '[]_[15,50](((r1  /\ <>_[0,0.1] r2) \/ (r2  /\ <>_[0,0.1] r1)) -> []_[1,5](pl /\ pu))';
ptc_fml34.monitoringFormula = '((r1  /\ <>_[0,0.1] r2) \/ (r2  /\ <>_[0,0.1] r1)) -> []_[1,5](pl /\ pu)';
ptc_fml34.preds(1).str = 'pl';
ptc_fml34.preds(1).A = [1 0 0 0];
ptc_fml34.preds(1).b = 0.1;
ptc_fml34.preds(2).str = 'pu';
ptc_fml34.preds(2).A = [-1 0 0 0];
ptc_fml34.preds(2).b = 0.1;
ptc_fml34.preds(3).str = 'r1';
ptc_fml34.preds(3).A = [0 0 1 0];
ptc_fml34.preds(3).b = 25.0;
ptc_fml34.preds(4).str = 'r2';
ptc_fml34.preds(4).A = [0 0 -1 0];
ptc_fml34.preds(4).b = -45.0;
ptc_fml34.stopTime = 50;
ptc_fml34.init_opts = {{'simTime', 50}, {'en_speed', 1000},...
    {'measureTime', 1}, {'fault_time', 15}, {'spec_num', 1},...
    {'fuel_inj_tol', 1.0}, {'MAF_sensor_tol', 1.0}, {'AF_sensor_tol', 1.0}};

%ptc_formulas = {ptc_fml26, ptc_fml27_rise, ptc_fml27_fall, ptc_fml30, ptc_fml31, ptc_fml32, ptc_fml33, ptc_fml34};
ptc_formulas = {ptc_fml26, ptc_fml27_fall, ptc_fml30, ptc_fml31, ptc_fml32};

ptc_algomdls = {{'RL', 'A3C', 'PTC_M1_RL'}, {'RL', 'DDQN', 'PTC_M1_RL'},...
    {'s-taliro', 'SA', 'PTC_M1'}, {'s-taliro', 'CE', 'PTC_M1'}};
%ptc_algomdls = {{'RL', 'A3C', 'PTC_M1_RL'}};

ptc_sampleTimes = [10];

ptc_configs = { };
for k = 1:size(ptc_formulas, 2)
    for i = 1:size(ptc_algomdls, 2)
        for j = 1:size(ptc_sampleTimes, 2)
            config = struct(ptc_formulas{k});
            config.mdl = ptc_algomdls{i}{3};
            config.algoName = [ptc_algomdls{i}{1}, '-', ptc_algomdls{i}{2}];
            config.sampleTime = ptc_sampleTimes(j);
            config.engine = ptc_algomdls{i}{1};
            config.option = ptc_algomdls{i}{2};
            for l = 1:maxIter
              ptc_configs = [ptc_configs, config];
            end
        end
    end
end

if do_ptc
    do_experiment('PTC', ptc_configs, {});
end

% Insulin Benchmark Model
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

insulin_tmpl = struct(config_tmpl);
insulin_tmpl.output_range = [0 160;0 40;0 40];
insulin_tmpl.input_range = [40 40; 30 30;200 200;40 40;150 250;0 80;20 50;100 300;20 70;-.3 .3];
insulin_tmpl.init_opts = {{'simTime', 30}};

% insulin Formula 1
insulin_fml1 = struct(insulin_tmpl);
insulin_fml1.expName = 'insulin_fml1';
insulin_fml1.targetFormula = '[]p1';
insulin_fml1.monitoringFormula = 'p1';

insulin_fml1.preds(1).str = 'p1';
insulin_fml1.preds(1).A = [-1 0 0];
insulin_fml1.preds(1).b = [-2 0 0];

insulin_fml1.stopTime = 30;

insulin_formulas = {insulin_fml1};
insulin_algomdls = {{'RL', 'A3C', 'insulin_RL'}};
insulin_sampleTimes = [5];

insulin_configs = {};
for k = 1:size(insulin_formulas, 2)
    for i = 1:size(insulin_algomdls, 2)
        for j = 1:size(insulin_sampleTimes, 2)
            config = struct(insulin_formulas{k});
            config.mdl = insulin_algomdls{i}{3};
            config.algoName = [insulin_algomdls{i}{1}, '-', insulin_algomdls{i}{2}];
            config.sampleTime = insulin_sampleTimes(j);
            config.engine = insulin_algomdls{i}{1};
            config.option = insulin_algomdls{i}{2};
            for l = 1:maxIter
              insulin_configs = [insulin_configs, config];
            end
        end
    end
end

if do_insulin
    do_experiment('insulin', insulin_configs, {});
end


function do_experiment(name, configs, br_configs)
 total = size(configs, 2) + size(br_configs, 2);
 no_br = size(configs, 2);
 results = table('Size', [0 6],...
     'VariableTypes', {'string', 'string', 'int32', 'int32', 'double', 'double'},...
     'VariableNames', {'expName', 'algoName', 'sampleTime',...
     'numEpisode', 'elapsedTime', 'bestRob'});
 global workers_num logDir;
 [~,git_hash_string] = system('git rev-parse HEAD');
 git_hash_string = strrep(git_hash_string,newline,'');
 logFile = fullfile(logDir, [name, '-', datestr(datetime('now'), 'yyyy-mm-dd-HH-MM'), '-', git_hash_string, '.csv']);
 if workers_num > 1
     delete(gcp('nocreate'));
     parpool(workers_num);
     p = gcp();
     h = waitbar(0,'Waiting for experiments to complete...');
     for idx = 1:size(configs, 2)
        F(idx) = parfeval(p, @falsify_any,3,configs{idx});
     end
     % Build a waitbar to track progress
     for idx = 1:size(configs, 2)
        [completedIdx, ...
            numEpisode, elapsedTime, bestRob] ...
            = fetchNext(F);
        % store the result
        config = configs{completedIdx};
        result = {config.expName, config.algoName, config.sampleTime,...
            numEpisode, elapsedTime, bestRob};
        results = [results; result];
        writetable(results, logFile);
        % update waitbar
        waitbar(idx/total,h);
     end
         
     delete(gcp('nocreate'));
 else
     h = waitbar(0,'Please wait...');
     for i = 1:size(configs, 2)
        config = configs{i};
        [numEpisode, elapsedTime, bestRob] = ...
            falsify_any(config);
        result = {config.expName, config.algoName, config.sampleTime,...
            numEpisode, elapsedTime, bestRob};
        results = [results; result];
        waitbar(i / total)
     end
 end
 for i = 1:size(br_configs, 2)
    config = br_configs{i};
    [numEpisode, elapsedTime, bestRob] = ...
        falsify_any(config);
    result = {config.expName, config.algoName, config.sampleTime,...
                numEpisode, elapsedTime, bestRob};
    results = [results; result];
    writetable(results, logFile);
    waitbar((no_br + i) / total)
 end
 close(h);
end

function [numEpisode, elapsedTime, bestRob] = falsify_any(config)
    for i = 1:size(config.init_opts, 2)
       assignin('base', config.init_opts{i}{1}, config.init_opts{i}{2});
    end
    if strcmp(config.engine, 's-taliro')
        [numEpisode, elapsedTime, bestRob, ~, ~] = falsify_staliro(config);
    elseif strcmp(config.engine, 'RL')
        [numEpisode, elapsedTime, bestRob, ~, ~] = falsify(config);
    elseif strcmp(config.engine, 'breach')
        [numEpisode, elapsedTime, bestRob, ~, ~] = falsify_breach(config);
    end
end

function [numEpisode, elapsedTime, bestRob, bestXout, bestYout] = falsify_staliro(config)
    opt = staliro_options();
    opt.interpolationtype = config.interpolation;
    if strcmp(config.option, 'CE')
        opt.optimization_solver = 'CE_Taliro';
    end
    opt.optim_params.n_tests = config.maxEpisodes;
    [results, ~, ~] = staliro(config.mdl,[], config.input_range, ...
        repelem(config.stopTime / config.sampleTime, length(config.input_range)),...
        config.targetFormula, config.preds, config.stopTime, opt);
    numEpisode = results.run.nTests;
    elapsedTime = results.run.time;
    bestRob = results.run.bestRob;
    bestXout = results.run.bestSample;
    bestYout = [];
end

function [numEpisode, elapsedTime, bestRob, bestXout, bestYout] = falsify_breach(config)
    mdl = BreachSimulinkSystem(config.mdl, 'all', [], {}, [], 'Verbose', 0);
    br_model = mdl.copy();
    in_dim = size(config.input_range, 1);
    siggens = {};
    inputs = {};
    params = {};
    params_range = [];
    for i = 1:in_dim
       name = ['Input', num2str(i)];
       times = config.stopTime / config.sampleTime;
       inputs = [inputs, name];
       siggen = fixed_cp_signal_gen({name}, times, {'linear'});
       siggens = [siggens, siggen];
       param_names = cellfun(@(num) [name, '_u', num2str(num)], num2cell(0:(times-1)), 'UniformOutput', false);
       params = [params, param_names];
       params_range = [params_range, repmat(transpose(config.input_range(i,:)), [1, times])];
    end
    InputGen = BreachSignalGen(num2cell(siggens));
    br_model.SetInputGen(InputGen);
    br_model.SetParamRanges(params, params_range');
    pb = FalsificationProblem(br_model, config.br_formula);
    falsify_pb = pb.copy();
    falsify_pb.max_time = 600;
    falsify_pb.max_obj_eval = config.maxEpisodes;
    falsify_pb.setup_solver(config.option);
    falsify_pb.solve();
    numEpisode = falsify_pb.nb_obj_eval;
    elapsedTime = falsify_pb.time_spent;
    bestRob = falsify_pb.obj_best;
    bestXout = falsify_pb.BrSet_Best;
    bestYout = [];
end
