mdl = 'autotrans_mod04';
numRuns = 100;
targetFormula = '[]_[0, 80](([]_[0, 10](p1)) -> ([]_[10,20](p2)))';
monitoringFormula = '[.]_[20, 20](([]_[0, 10](p1)) -> ([]_[10,20](p2)))';
outputs = [1,2];

ii = 1;
preds(ii).str = 'p1';
preds(ii).A = [0 1];
preds(ii).b = 4500/5000;
preds(ii).loc = [1:7];

ii = ii+1;
preds(ii).str = 'p2';
preds(ii).A = [1 0];
preds(ii).b = 130/160;
preds(ii).loc = [1:7];

Phi = monitoringFormula;
Pred = preds;

bestRob = inf;
py.driver.start_learning();
for i=1:1000
    [~, yout] = runsim(mdl);
    rob = robustness(targetFormula, preds,yout, outputs);
    py.driver.stop_episode();
    disp(['Current iteration: ', num2str(i), ', rob = ', num2str(rob)])
    if rob < bestRob
        bestRob = rob;
        bestYout = yout;
        if rob < 0 
            break;
        end
    end
end
disp(['Iteration= ', num2str(i) ,', best robustness= ', num2str(bestRob)]);

function [T,Y] = yout2TY(yout, outputs)
    for i=1:length(outputs)
        index = outputs(i);
        T = yout.getElement(index).Values.Time; % danger
        Y(:,i) = yout.getElement(index).Values.Data;
    end
end

function [xout, yout] = runsim(mdl)
    simOut = sim(mdl,'SimulationMode','normal','AbsTol','1e-5',...
                 'SaveState','on','StateSaveName','xout',...
                 'SaveOutput','on','OutputSaveName','yout',...
                 'SaveFormat', 'Dataset');
    xout = simOut.get('xout');
    yout = simOut.get('yout');
end

function [rob] = robustness(target, preds, yout, outputs)
    [T,Y] = yout2TY(yout, outputs);
    rob =  dp_taliro(target, preds, Y, T, [], [], []);
end
        