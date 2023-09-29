# Falsification of Cyber Physical Systems by Deep Reinforcement Learning

## What is this?

This package is to evaluate deep reinforcement learning technology for falsification of cyber-physical systems.  It contains four models (an auto-transmission model, a wind turbine model, a power train control model and an insulin model.  The insulin model currently does not work.

## Audience

This package is for researchers and developers who evaluates the technology.

## Reqiurment

- MATLAB
- Simulink
- Stateflow
- Decent distribution of Python
- ChainerRL 0.2.0
- s-taliro
- breach

## Agenda

- metascript.m : scripts for AT and PTC model. An insulin model is included but not working.
- metascript_cars.m : a script for CARS model
- metascript_wind_turbine.m : a script for the wind turbine model.

## License

(C) 2019 National Institute of Advanced Industrial Science and Technology (AIST)

The contents under the wind-turbine directory is copyrighted by the respective authors.

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.                                    

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.                           

You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

## Usage

Edit the section named "Configuration" and run the script

### - テストをしたものの各バージョンは下記の通りになります。
- Package            Version
- ------------------ -------
- MATLAB             R2023a
- python             3.8.9
- chainer            7.7.0
- chainerrl          0.8.0
- gym                0.22.0
- 
filelock           3.12.4
future             0.18.3

### s-taliroに付随して必須及びオプションのMATLABパッケージ [s-taliroダウンロードページ](https://sites.google.com/a/asu.edu/s-taliro/s-taliro/download)。

- ロケーションガードまでの距離を含むハイブリッド距離メトリックの場合、MatlabパッケージMatlabBGLが必要です。
- Powertrainのデモ例にはCheckMateが必要です。
- Robust Testing Toolboxの実行に必要なツールボックス: 
> 1. Multi Parametric Toolbox(version 3.0.)
> 1. Ellipsoidal Toolbox(version 1.1.2)
> 1. CVX: Disciplined Convex Optimization(version 1.1.2.)
- motion planning demosに必要なToolbox:
> 1. Robotics Toolbox
> 1. Multi Parametric Toolbox
- 並列シミュレーションには、Matlab Parallel Computing Toolbox が必要です。

### MATLAB環境設定

ワーキングディレクトリに

