% Configurations
%%%%%%%%%%%%%%%%
global workers_num logDir;
workers_num = 1;
staliro_dir = '../s-taliro';
breach_dir = '../breach';
logDir = '../falsify-data/';
maxIter = 20;
maxEpisodes = 200;

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
    cd(pwd);
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
            
%algomdls = {{'RL', 'A3C', 'autotrans_mod04'}, {'RL', 'DDQN', 'autotrans_mod04'}};
%algomdls = [algomdls, {{'s-taliro', 'SA', 'arch2014_staliro'}}, {{'s-taliro', 'CE', 'arch2014_staliro'}}];
%algomdls = [{{'s-taliro', 'SA', 'arch2014_staliro'}, {'s-taliro', 'CE', 'arch2014_staliro'}}];
algomdls = {};
br_algomdls = {{'breach', 'basic', 'arch2014_staliro'}};
sampleTimes = [10, 5, 1];
%algomdls = {{'ACER', 'autotrans_mod04'}};
%sampleTimes = 10;

g2L = 1.5;
g3L = 2.5;
g4L = 3.5;



% Power Control Benchmark Model
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ptc_tmpl = struct(config_tmpl);
%ptc_tmpl.outputs = [2];
ptc_tmpl.output_range = [-0.1 0.1; 0.0 1.0];
ptc_tmpl.init_opts = {{'simTime', 50}, {'en_speed', 1000},...
    {'measureTime', 1}, {'fault_time', 60}, {'spec_num', 1},...
    {'fuel_inj_tol', 1.0}, {'MAF_sensor_tol', 1.0}, {'AF_sensor_tol', 1.0}};

ptc_fml26 = struct(ptc_tmpl);
ptc_fml26.expName = 'ptc_fml26';
ptc_fml26.input_range = [900.0 1000.0; 8.8 69.9];
ptc_fml26.targetFormula = '[]_[11,50](pl /\ pu)';
ptc_fml26.monitoringFormula = 'pl /\ pu';
ptc_fml26.preds(1).str = 'pl';
ptc_fml26.preds(1).A = [1 0];
ptc_fml26.preds(1).b = 0.05;
ptc_fml26.preds(2).str = 'pu';
ptc_fml26.preds(2).A = [-1 0];
ptc_fml26.preds(2).b = 0.05;
ptc_fml26.stopTime = 50;

ptc_fml33 = struct(ptc_tmpl);
ptc_fml33.expName = 'ptc_fml33';
ptc_fml33.input_range = [900.0 1000.0; 8.8 90.0];
ptc_fml33.targetFormula = '[]_[11,50](power -> (pl /\ pu))';
ptc_fml33.monitoringFormula = 'power -> (pl /\ pu)';
ptc_fml33.preds(1).str = 'pl';
ptc_fml33.preds(1).A = [1 0];
ptc_fml33.preds(1).b = 0.2;
ptc_fml33.preds(2).str = 'pu';
ptc_fml33.preds(2).A = [-1 0];
ptc_fml33.preds(2).b = 0.2;
ptc_fml33.preds(3).str = 'power';
ptc_fml33.preds(3).A = [0 -1];
ptc_fml33.preds(3).b = -0.5;
ptc_fml33.stopTime = 50;

ptc_formulas = {ptc_fml26, ptc_fml33};

%ptc_algomdls = {{'s-taliro', 'SA', 'PTC_M1'}, {'s-taliro', 'CE', 'PTC_M1'}};
%ptc_algomdls = {{'s-taliro', 'CE', 'PTC_M1'}};
ptc_algomdls = { {'s-taliro', 'SA', 'PTC_M1'}, {'s-taliro', 'CE', 'PTC_M1'},...
    {'RL', 'A3C', 'PTC_M1_RL'}, {'RL', 'DDQN', 'PTC_M1_RL'}};

ptc_sampleTimes = [10, 5];

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

%do_experiment('PTC', ptc_configs, {});

insulin_tmpl = struct(config_tmpl);
insulin_tmpl.output_range = [0 160;0 40;0 40];
insulin_tmpl.input_range = [40 40; 30 30;200 200;40 40;150 250;0 80;20 50;100 300;20 70;-.3 .3];
insulin_tmpl.init_opts = {{'simTime', 50}, {'en_speed', 1000},...
    {'measureTime', 1}, {'fault_time', 60}, {'spec_num', 1}};

% Formula 1
insulin_fml1 = struct(config_tmpl);
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
do_experiment('insulin', insulin_configs, {});

function do_experiment(name, configs, br_configs)
 total = size(configs, 2) + size(br_configs, 2);
 no_br = size(configs, 2);
 h = waitbar(0,'Waiting for experiments to complete...');
 global workers_num logDir;
 if workers_num > 1
     delete(gcp('nocreate'));
     parpool(workers_num);
     p = gcp();
     results = cell([1, size(configs ,2)]);
     for idx = 1:size(configs, 2)
        F(idx) = parfeval(p, @falsify_any,5,configs{idx});
     end
     % Build a waitbar to track progress
     for idx = 1:size(configs, 2)
        [completedIdx, ...
            numEpisode, elapsedTime, bestRob, bestXout, bestYout] ...
            = fetchNext(F);
        % store the result
        result = struct('numEpisode', numEpisode,...
                    'elapsedTime', elapsedTime,...
                    'bestRob', bestRob,...
                    'bestXout', bestXout,...
                    'bestYout', bestYout);
        results{completedIdx} = result;
        % update waitbar
        waitbar(idx/total,h);
     end
         
     delete(gcp('nocreate'));
 else
     h = waitbar(0,'Please wait...');
     results = cell([1, size(configs,2)]);
     for i = 1:size(configs, 2)
        config = configs{i};
        [numEpisode, elapsedTime, bestRob, bestXout, bestYout] = ...
            falsify_any(config);
        result = struct('numEpisode', numEpisode,...
                    'elapsedTime', elapsedTime,...
                    'bestRob', bestRob,...
                    'bestXout', bestXout,...
                    'bestYout', bestYout);
        results{i} = result;
        waitbar(i / total)
     end
 end
 for i = 1:size(br_configs, 2)
    config = br_configs{i};
    [numEpisode, elapsedTime, bestRob, bestXout, bestYout] = ...
        falsify_any(config);
    result = struct('numEpisode', numEpisode,...
                'elapsedTime', elapsedTime,...
                'bestRob', bestRob,...
                'bestXout', bestXout,...
                'bestYout', bestYout);
    results{no_br + i} = result;
    waitbar((no_br + i) / total)
 end
 close(h);
 configs = [configs, br_configs];

 logFile = fullfile(logDir, [name, '-', datestr(datetime('now'), 'yyyy-mm-dd-HH-MM'), '.mat']);
 [~,git_hash_string] = system('git rev-parse HEAD');
 save(logFile, 'git_hash_string', 'configs', 'results');
end

function [numEpisode, elapsedTime, bestRob, bestXout, bestYout] = falsify_any(config)
    for i = 1:size(config.init_opts, 2)
       assignin('base', config.init_opts{i}{1}, config.init_opts{i}{2});
    end
    if strcmp(config.engine, 's-taliro')
        [numEpisode, elapsedTime, bestRob, bestXout, bestYout] = falsify_staliro(config);
    elseif strcmp(config.engine, 'RL')
        [numEpisode, elapsedTime, bestRob, bestXout, bestYout] = falsify(config);
    elseif strcmp(config.engine, 'breach')
        [numEpisode, elapsedTime, bestRob, bestXout, bestYout] = falsify_breach(config);
    end
end

function [numEpisode, elapsedTime, bestRob, bestXout, bestYout] = falsify_staliro(config)
    opt = staliro_options();
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
    disp(config);
    global workers_num
    delete(gcp('nocreate'));
    parpool(workers_num);
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
       siggen = fixed_cp_signal_gen({name}, times, {'spline'});
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
    if workers_num > 1
        falsify_pb.SetupParallel(workers_num);
    end
    falsify_pb.max_time = 600;
    falsify_pb.max_obj_eval = config.maxEpisodes;
    falsify_pb.setup_solver(config.option);
    falsify_pb.solve();
    numEpisode = falsify_pb.nb_obj_eval;
    elapsedTime = falsify_pb.time_spent;
    bestRob = falsify_pb.obj_best;
    bestXout = falsify_pb.BrSet_Best;
    bestYout = [];
    delete(gcp('nocreate'));
end
