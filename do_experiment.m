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
     for retry_num = 1:100
         delete(gcp('nocreate'));
         Simulink.sdi.clear
         parpool(workers_num);
         p = gcp();
         disp(size(configs, 2));
         clear F;
         for idx = 1:size(configs, 2)
            F(idx) = parfeval(p, @falsify_any,3,configs{idx});
         end
         returned = [ ];
         for idx = 1:size(configs, 2)
             try
                if idx > workers_num * 2
                    exc = MException();
                    throw(exc);
                end
                [completedIdx, ...
                    numEpisode, elapsedTime, bestRob] ...
                    = fetchNext(F);
             catch ME
                 disp(ME.identifier);
                 disp(ME.message);
                 break;
             end
            % store the result
            config = configs{completedIdx};
            result = {config.expName, config.algoName, config.sampleTime,...
                numEpisode, elapsedTime, bestRob};
            results = [results; result];
            writetable(results, logFile);
            returned = [returned; completedIdx];
            % update waitbar
         end
         old_configs = configs;
         configs = {};
         for idx = 1:size(old_configs, 2)
             if ~ismember(idx, returned)
                 configs = [configs, old_configs{idx}]; 
             end
         end
         if size(configs, 2) == 0
            break;
         end
     end
     delete(gcp('nocreate'));
 else
     for i = 1:size(configs, 2)
        config = configs{i};
        [numEpisode, elapsedTime, bestRob] = ...
            falsify_any(config);
        result = {config.expName, config.algoName, config.sampleTime,...
            numEpisode, elapsedTime, bestRob};
        results = [results; result];
        writetable(results, logFile);
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
 end
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
    opt.fals_at_zero = 0;
    if strcmp(config.option, 'CE')
        opt.optimization_solver = 'CE_Taliro';
    end
    opt.optim_params.n_tests = config.maxEpisodes;
    [results, ~, ~] = staliro(config.mdl,[], config.input_range, ...
        repelem(config.stopTime / config.sampleTime, size(config.input_range, 1)),...
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
