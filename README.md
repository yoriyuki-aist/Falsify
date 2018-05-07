# Falsify

Falsify Simulink models using deep reinforcement learning

## Reqiurment

- s-taliro
- MATLAB
- Simulink
- Stateflow
- Decent distribution of Python
- ChainerRL

## Setup

Clone the repository
```
$ git clone git@bitbucket.org:yoriyuki-aist/s-taliro.git
$ git clone git@bitbucket.org:yoriyuki-aist/falsify.git
```
Install Anaconda or miniconda from https://www.continuum.io/downloads and follow the instruction.
Create your own environment
````
conda create -n <env-name> python=3
source activate <env-name>
````
Install ChainerRL
````
pip install chainerrl
````
Run matlab using the current Python environment
```
<path-to-MATLAB>/matlab
```
Inside the matlab, go to `s-taliro` directory and
```
>> setup_staliro
>> cd monitor
>> setup_monitor
```
Go to `falsify` directory
```
>> cd ../../falsify
>> falsify
```
If you open autotorans_mod04 model by Simulink, then you can use the scope to inspect the change of values.