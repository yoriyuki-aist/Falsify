SimplifiedWTModel.slx:				Simulink model of the wind turbine and controller
SimplifiedTurbine_Config.m:			configuration file, define here 'SingleRun'  and wind speed 'URef' or 'AllCases' for all wind speeds
                                    set the path to the WAFO toolbox here
SimplifiedTurbine_Main.m:			run this file in Matlab to simulate the turbine
SimplifiedTurbine_ParamterFile.m:	specifies all turbine and controller data
SimplifiedTurbine_PostProcessing.m:	load calculation and other post processing
aeromaps.mat:						maps for $c_P$ and $c_T$ as polynomial functions
InitialConditions.mat:				initial conditions for the integrators
wind/ClassA_config.mat:				configuration for the TurbSim input files and effective wind speed calculation
                                    URefVector = wind speeds, RandSeedMatrix = random seeds used in TurbSim to generate wind fields
wind/ClassA.mat:					three random seeds per wind speed for $v_0 = 4:2:24$m/s  according to IEC Ed. 3, Class A
                                    rows correspond to the wind seeds, and colums correspond to the seeds