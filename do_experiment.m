function do_experiment(modelname, configs)
 results = table('Size', [0 8],...
     'VariableTypes', {'int32', 'string', 'string', 'string', 'double', 'int32', 'double', 'double'},...
     'VariableNames', {'id', 'modelName', 'expName', 'algoName', 'sampleTime',...
     'numEpisode', 'elapsedTime', 'bestRob'});
 global workers_num logDir;
 logFile = fullfile(logDir, [modelname, '.csv']);
 id = 1;
 if workers_num > 1
   while size(configs, 2) > 0
     delete(gcp('nocreate'));
     Simulink.sdi.clear
     parpool(workers_num);
     p = gcp();
     disp(size(configs, 2));
     clear F;
     for idx = 1:min(size(configs, 2), workers_num * 2)
         F(idx) = parfeval(p, @falsify,6,configs{idx});
     end
     returned = [ ];
     for idx = 1:min(size(configs, 2), workers_num * 2)
         try
             [completedIdx, ...
                 numEpisode, elapsedTime, bestRob, bestXout, bestYout, bestOpts] ...
                 = fetchNext(F);
         catch ME
             disp(ME.identifier);
             disp(ME.message);
             break;
         end
         % store the result
         config = configs{completedIdx};
         result = {id, modelname, config.expName, config.algoName, config.sampleTime,...
             numEpisode, elapsedTime, bestRob};
         results = [results; result];
         writetable(results, logFile);
         fname = [modelname, '-', config.expName, '-', config.algoName, '-', num2str(id)];
         file = fullfile(logDir, [fname,  '.mat']);
         save(file, 'bestXout', 'bestYout', 'bestOpts', 'config');
         returned = [returned; completedIdx];
         id = id + 1;
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
     delete(gcp('nocreate'));
   end
 else
     for i = 1:size(configs, 2)
         config = configs{i};
         [numEpisode, elapsedTime, bestRob, bestXout, bestYout, bestOpts] = falsify(config);
         result = {id, modelname, config.expName, config.algoName, config.sampleTime,...
             numEpisode, elapsedTime, bestRob};
         results = [results; result];
         writetable(results, logFile);
         fname = [modelname, '-', config.expName, '-', config.algoName, '-', num2str(id)];
         file = fullfile(logDir, [fname,  '.mat']);
         save(file, 'bestXout', 'bestYout', 'bestOpts');
         id = id+1;
     end
 end
end
