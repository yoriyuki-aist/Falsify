addpath('autotrans', 'cars', 'insulin', 'PTC');

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
