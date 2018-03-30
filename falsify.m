function [numEpisode, elapsedTime, bestRob, bestXout, bestYout] = falsify(config)

    function Y = yout2TY(yout, outputs)
        for i=1:length(outputs)
            index = outputs(i);
            Y(:,i) = yout.getElement(index).Values.Data;
        end
    end

    function [tout, xout, yout] = runsim(agent, config)
        %mws = get_param(config.mdl, 'modelworkspace');
        assignin('base', 'Phi', config.monitoringFormula);
        assignin('base', 'Pred', config.preds);
        assignin('base', 'agent', agent);
        set_param([config.mdl, '/MATLAB Function'], 'SystemSampleTime', num2str(config.sampleTime));
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

    function [rob] = robustness(target, preds, tout, yout, outputs)
        Y = yout2TY(yout, outputs);
        rob =  dp_taliro(target, preds, Y, tout, [], [], []);
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
    agent = py.driver.start_learning();
    tic;
    for numEpisode=1:config.maxEpisodes
        [tout, xout, yout] = runsim(agent, config);
        rob = robustness(config.targetFormula, config.preds, tout, yout, config.outputs);
        py.driver.stop_episode(agent);
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

