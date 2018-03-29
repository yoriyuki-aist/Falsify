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

## Current status

- Can falsify all formulas in the FM2018 paper
- Got statistics, need to analyze them

## Todo

### Toward a journal paper

- [ ] Performance measurement
	- [x] implementation
	- [ ] analysis
- [ ] Logging and generating summary automatically (but don't spend too much time on it)
	- [x] implementation
	- [x] analysis script
- [ ] Configuration
	- [x] Switcing a model, a formula and predicates
		- [x] implementation
		- [x] test
	- [ ] Automatically setup s-taliro etc.
- [ ] PTC model and more
- [ ] Compare to other methods
	- [ ] S-Taliro, Breach
	- [ ] automate logging and summary generation for these methods, too (but don't...)
- [ ] Experiments
- [ ] More through review of related works
- [ ] More detailed explanation on backgroud (Robustness, RL...)
- [ ] Analysis of results

### Toward distrubing tools 

- [ ] Create a patch for s-taliro, or make a bug report
- [x] Run the entire experiments by one script? (but don't ...)
	 - use metascript
- [ ] Documentation
- [ ] Check copyrights

### Things to discuss

- [x] Meeting frequency
- [x] Attendees
- [ ] Milestones and roadmap
- [ ] Data sharing (Git is not suitable for large data.  What service can you guys in China use?
- [ ] Computing resources 
	- [x] ordered a multicore machine.  
	- [ ] Check the equipments of Tianjin side.
	