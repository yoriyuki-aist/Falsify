function [numEpisode, elapsedTime, bestRob, bestXout, bestYout] = falsify(config)

    function [Y, T, R] = yout2TY(yout)
            Y = yout.getElement(2).Values.Data;
            T = yout.getElement(2).Values.Time;
            R = yout.getElement(1).Values.Data;
    end

    function [normal_preds] = normalize_pred(preds, range)
       normal_preds = [];
       lower = range(:,1);
       upper = range(:,2);
       middle = (lower + upper)/2;
       d = (upper - lower)/2;
       for i = 1:size(preds,2)
          normal_preds(i).str = preds(i).str;
          normal_preds(i).A = preds(i).A .* d';
          normal_preds(i).b = preds(i).b - preds(i).A * middle;
       end
    end

    function [tout, xout, yout] = runsim(agent, config, normal_preds)
        %mws = get_param(config.mdl, 'modelworkspace');
        assignin('base', 'Phi', config.monitoringFormula);
        assignin('base', 'Pred', normal_preds);
        assignin('base', 'agent', agent);
        assignin('base', 'input_range', config.input_range);
        assignin('base', 'output_range', config.output_range);
        assignin('base', 'sample_time', config.sampleTime);
        simOut = sim(config.mdl,'SimulationMode','normal','AbsTol','1e-5',...
                     'SaveTime', 'on', 'TimeSaveName', 'tout',...
                     'SaveState','on','StateSaveName','xout',...
                     'SaveOutput','on','OutputSaveName','yout',...
                     'SaveFormat', 'Dataset',...
                     'StopTime', num2str(config.stopTime));
        tout = simOut.get('tout');
        xout = simOut.get('xout');
        yout = simOut.get('yout');
    end

    currDir = pwd;
    addpath(currDir);
    P = py.sys.path;
    insert(P,int32(0),pwd);
    tmpDir = tempname;
    mkdir(tmpDir);
    cd(tmpDir);
    % Load the model on the worker
    load_system(config.mdl);
    bestRob = inf;
    normal_preds = normalize_pred(config.preds, config.output_range);
    disp(size(config.input_range, 1));
    disp(size(config.output_range, 1));
    agent = py.driver.start_learning(config.option,...
        size(config.output_range, 1), size(config.input_range, 1));
    tic;
  

    for numEpisode=1:config.maxEpisodes
        [~, xout, yout] = runsim(agent, config, normal_preds);
        [Y, T, R] = yout2TY(yout);
        rob =  dp_taliro(config.targetFormula, normal_preds, Y, T, [], [], []);
        py.driver.stop_episode_and_train(agent, Y(end, :), exp(- R(end, 1)) - 1);
        disp(['Current iteration: ', num2str(numEpisode), ', rob = ', num2str(rob)])
        if rob < bestRob
            bestRob = rob;
            bestYout = yout;
            bestXout = xout;
            if rob < 0 
                break;
            end
        end
    end
    elapsedTime = toc;
    cd(currDir);
    rmdir(tmpDir,'s');
    rmpath(currDir);
    close_system(config.mdl, 0);
end

