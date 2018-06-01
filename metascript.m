staliro_dir = '../s-taliro';
breach_dir = '../breach';
logDir = '../falsify-data/';
maxIter = 100;
workers_num = 10;

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

if exist('InitBreach.m', 'file') == 0
    addpath(breach_dir);
    cwd = pwd;
    cd(breach_dir);
    InitBreach;
    cd(pwd);
end
    
if ~ 7 == exist(logDir, 'dir')
    mkdir(logDir);
end 
logFile = fullfile(logDir, [datestr(datetime('now')), '.mat']);

mdl = 'autotrans_mod04';
outputs = [2,3,4];
maxEpisodes = 200;

config_tmpl = struct('maxIter', maxIter,...
                'maxEpisodes', maxEpisodes,...
                'mdl', mdl,...
                'outputs', outputs,...
                'input_range', [0.0 100.0; 0.0 500.0],...
                'output_range', [0.0 5000.0;0.0 160.0;1.0 4.0]);
            
algomdls = {{'RL', 'A3C', 'autotrans_mod04'}, {'RL', 'DDQN', 'autotrans_mod04'}, {'RL', 'ACER', 'autotrans_mod04'}};
algomdls = [algomdls, {{'s-taliro', 'SA', 'arch2014_staliro'}, {'s-taliro', 'CE', 'arch2014_staliro'}}];
%algomdls = [{{'s-taliro', 'SA', 'arch2014_staliro'}, {'s-taliro', 'CE', 'arch2014_staliro'}}];
%algomdls = {{'breach', 'global_nelder_mead', 'arch2014_staliro'}};
sampleTimes = [10, 5, 1];
%algomdls = {{'ACER', 'autotrans_mod04'}};
%sampleTimes = 10;

g2L = 1.5;
g3L = 2.5;
g4L = 3.5;

% Formula 1
fml1 = struct(config_tmpl);
fml1.expName = 'fml1';
fml1.targetFormula = '[]p1';
fml1.monitoringFormula = 'p1';

fml1.preds(1).str = 'p1';
fml1.preds(1).A = [1 0 0];
fml1.preds(1).b = 4770.0;

fml1.br_formula = STL_Formula('fml1', 'alw (EngineRPM <= 4770.0)')

fml1.stopTime = 30;

% Formula 2
fml2 = struct(config_tmpl);
fml2.expName = 'fml2';
fml2.targetFormula = '[](p1 /\ p2)';
fml2.monitoringFormula = 'p1 /\ p2';

fml2.preds(1).str = 'p1';
fml2.preds(1).A = [1 0 0];
fml2.preds(1).b = 4770.0;

fml2.preds(2).str = 'p2';
fml2.preds(2).A = [1 0 0];
fml2.preds(2).b = 170.0;
fml2.stopTime = 30;

%Formula 3
fml3 = struct(config_tmpl);
fml3.expName = 'fml3';
fml3.targetFormula = '[]_[0,29.0]( ((g2L/\g2U) /\ <>_[0, 0.1] g1) -> []_[0.1,1.0](!(g2L/\g2U)))';
fml3.monitoringFormula = '[.]_[1.0,1.0]( ((g2L/\g2U) /\ <>_[0, 0.1] g1) -> []_[0.1,1.0](!(g2L/\g2U)))';

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
fml4 = struct(config_tmpl);
fml4.expName = 'fml4';
fml4.targetFormula = '[]_[0,29.0]( (!g1 /\ <>_[0, 0.1] g1) -> []_[0.1,1.0](g1))';
fml4.monitoringFormula = '[.]_[1.0,1.0]((!g1 /\ <>_[0, 0.1] g1) -> []_[0.1,1.0](g1))';
fml4.preds = fml3.preds;
fml4.stopTime = 30;

%Formula 5
fml5 = struct(config_tmpl);
fml5.expName = 'fml5';
fml5.targetFormula = ['[]_[0,29]( ((!g1 /\ <>_[0,0.1] g1) -> []_[0.1,1.0]g1) /\ ((!(g2L/\g2U) /\ <>_[0,0.1] (g2L/\g2U)) ->' ...
'[]_[0.1,1.0](g2L/\g2U)) /\ ((!(g3L/\g3U) /\ <>_[0,0.1] (g3L/\g3U)) ->' ... 
'[]_[0.1,1.0](g3L/\g3U)) /\ ((!g4 /\ <>_[0,0.1] g4) -> []_[0.1,1.0]g4))'];
fml5.monitoringFormula = ['[.]_[1.0,1.0]( ((!g1 /\ <>_[0,0.1] g1) -> []_[0.1,1.0]g1) /\ ((!(g2L/\g2U) /\ <>_[0,0.1] (g2L/\g2U)) ->' ...
'[]_[0.1,1.0](g2L/\g2U)) /\ ((!(g3L/\g3U) /\ <>_[0,0.1] (g3L/\g3U)) ->' ... 
'[]_[0.1,1.0](g3L/\g3U)) /\ ((!g4 /\ <>_[0,0.1] g4) -> []_[0.1,1.0]g4))'];
fml5.preds = fml3.preds;
fml5.stopTime = 30;

% Formula 6
fml6 = struct(config_tmpl);
fml6.expName = 'fml6';
fml6.targetFormula = '[]_[0, 80](([]_[0, 10](p1)) -> ([]_[10,20](p2)))';
fml6.monitoringFormula = '[.]_[20, 20](([]_[0, 10](p1)) -> ([]_[10,20](p2)))';

fml6.preds(1).str = 'p1';
fml6.preds(1).A = [1 0 0];
fml6.preds(1).b = 4500.0;

fml6.preds(2).str = 'p2';
fml6.preds(2).A = [0 1 0];
fml6.preds(2).b = 130.0;

fml6.stopTime = 100;

%Formula 7
fml7 = struct(config_tmpl);
fml7.expName = 'fml7';
fml7.targetFormula = '!<>p1';
fml7.monitoringFormula = '!p1';

fml7.preds(1).str = 'p1';
fml7.preds(1).A = [0 -1 0];
fml7.preds(1).b = -160.0;

fml7.stopTime = 100;

%Formula 8
fml8 = struct(config_tmpl);
fml8.expName = 'fml8';
fml8.targetFormula = '[]_[0,75](<>_[0,25](!(vl/\vu)))';
fml8.monitoringFormula = '[.]_[25, 25]<>_[0,25](!(vl/\vu))';

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
fml9 = struct(config_tmpl);
fml9.expName = 'fml9';
fml9.targetFormula = '[]_[0,80](![]_[0,20](!g4 /\ highRPM))';
fml9.monitoringFormula = '[.]_[20, 20]![]_[0,20](!g4 /\ highRPM)';

pred = struct('str', 'highRPM', 'A', [-1 0 0], 'b', -3100.0);
fml9.preds = [fml3.preds, pred];

fml9.stopTime = 100;

%formulas = {fml1, fml2, fml3, fml4, fml5, fml6, fml7, fml8, fml9 };
formulas = {fml1};

configs = { };
for k = 1:size(formulas, 2)
    for i = 1:size(algomdls, 2)
        for j = 1:size(sampleTimes, 2)
            config = struct(formulas{k});
            config.mdl = algomdls{i}{3};
            config.algoName = [algomdls{i}{1}, algomdls{i}{2}];
            config.sampleTime = sampleTimes(j);
            config.engine = algomdls{i}{1};
            config.option = algomdls{i}{2};
            for l = 1:maxIter
              configs = [configs, config];
            end
        end
    end
end
 load_system(mdl);
 
 if workers_num > 1
     delete(gcp('nocreate'));
     parpool(workers_num);
     p = gcp();
     results = cell([1, size(configs ,2)]);
     for idx = 1:size(configs, 2)
        F(idx) = parfeval(p, @do_experiment,5,configs{idx});
     end
     % Build a waitbar to track progress
     h = waitbar(0,'Waiting for FevalFutures to complete...');
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
        waitbar(idx/size(configs, 2),h);
     end
     delete(h)
         
     delete(gcp('nocreate'));
 else
     h = waitbar(0,'Please wait...');
     results = cell([1, size(configs,2)]);
     for i = 1:size(configs, 2)
        config = configs{i};
        [numEpisode, elapsedTime, bestRob, bestXout, bestYout] = ...
            do_experiment(config);
        result = struct('numEpisode', numEpisode,...
                    'elapsedTime', elapsedTime,...
                    'bestRob', bestRob,...
                    'bestXout', bestXout,...
                    'bestYout', bestYout);
        results{i} = result;
        waitbar(i / size(configs, 2))
     end
     close(h)
 end
  
 [s,git_hash_string] = system('git rev-parse HEAD');
 save(logFile, 'git_hash_string', 'configs', 'results');
 

close_system(mdl, 0);

function [numEpisode, elapsedTime, bestRob, bestXout, bestYout] = do_experiment(config)
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
    br_model = BreachSimulinkSystem(config.mdl, 'all', [], {}, [], 'Verbose', 0);
    inputs = cellfun(@num2str, num2cell(1:size(config.input_range, 1)));
    signal_gen = fixed_cp_signal_gen(inputs, config.stopTime / config.sampleTime, {'spline'});
    br_model.SetInputGen(signal_gen);
    br_model.SetPramRanges(inputs, config.input_range);
    falsif_pb = FalsificationProblem(br_model, config.br_formula);
    falsif_pb.max_time = 300;
    falsif_pb.max_obj_eval = config.maxEpisodes;
    falsif_pb.setup_solver(config.option);
    falsify_pb.solve();
    numEpisode = falsif_pb.nb_obj_eval;
    elapsedTime = falsif_pb.time_spent;
    bestRob = falsif_pb.obj_best;
    bestXout = falsif_pb.BrSet_Best;
    bestYout = [];
end
