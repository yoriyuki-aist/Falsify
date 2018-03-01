# Falsify

Simulink models using deep reinforcement learning

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

## Current status

- Can falsify fml6 in the FM2018 paper
- No statistics, therefore I cannot check whether the performance is improved

## Todo

### Toward a journal paper

- [ ] Performance measurement
- [ ] Logging and generating summary automatically (but don't spend too much time on it)
- [ ] Configuration
	- [ ] Switcing a model, a formula and predicates
	- [ ] Automatically setup s-taliro etc.
- [ ] PTC model and more
- [ ] Compare other methods
	- [ ] S-Taliro, Breach
	- [ ] automate logging and summary generation for these methods, too (but don't...)
- [ ] Experiments
- [ ] More through review of related works
- [ ] More detailed explanation on backgroud (Robustness, RL...)
- [ ] Analysis of results

### Toward distrubing tools 

- [ ] Create a patch for s-taliro, or make a bug report
- [ ] Run the entire experiments by one script? (but don't ...)
- [ ] Documentation
- [ ] Check copyrights

### Things to discuss

- [ ] Meeting frequency
- [ ] Attendees
- [ ] Milestones and roadmap
- [ ] Move to WeChat?  Connection to Tianjin was not stable using Skype
- [ ] Data sharing (Git is not suitable for large data.  What service can you guys in China use?
	
	