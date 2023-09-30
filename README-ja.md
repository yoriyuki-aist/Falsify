# 深層強化学習によるサイバーフィジカルシステムの改竄

## 導入

このコンテンツは、サイバーフィジカルシステムの改竄に対する深層強化学習技術を評価するためのものである。4 つのモデル (自動変速機モデル、風力タービンモデル、パワートレイン制御モデル、インスリンモデル) が含まれている。インスリンモデルは現在機能しません。

## 対象

このコンテンツは、技術を評価する研究者や開発者向けである。

## 環境要件

- MATLAB
- Simulink
- Stateflow
- Decent distribution of Python
- ChainerRL 0.2.0
- s-taliro
- breach

## Agenda

- metascript.m : ATおよびPTCモデル用のスクリプト。インスリンモデルは現在機能しません。
- metascript_cars.m : CARSモデル用のスクリプト
- metascript_wind_turbine.m : 風力タービンモデルのスクリプト。

## ライセンス

(C) 2019 National Institute of Advanced Industrial Science and Technology (AIST)

The contents under the wind-turbine directory is copyrighted by the respective authors.

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.                                    

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.                           

You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

(C) 2019 産業技術総合研究所（AIST）

Wind-Turbine ディレクトリ内のコンテンツは、それぞれの作成者に著作権があります。

このプログラムはフリーソフトウェアです。Free Software Foundation によって公開されている GNU General Public License の条件に基づいて、再配布したり変更したりすることができます。ライセンスのバージョン 2、または (オプションで) それ以降のバージョンのいずれか。

このプログラムは役立つことを期待して配布されていますが、いかなる保証もありません。商品性や特定目的への適合性についての暗黙の保証もありません。詳細については、GNU 一般公衆利用許諾書を参照してください。

このプログラムと一緒に GNU 一般公衆利用許諾書のコピーも受け取っているはずです。そうでない場合は、Free Software Foundation, Inc. (59 Temple Place, Suite 330, Boston, MA 02111-1307 USA) までご連絡ください。

## Usage

Edit the section named "Configuration" and run the script

"Configuration" という名前のセクションを編集し、スクリプトを実行します。

### - テストをしたものの各バージョンは下記の通りになります。
- Package            Version
- ------------------ -------
- MATLAB             R2023a
- python             3.8.9
- chainer            7.7.0
- chainerrl          0.8.0
- gym                0.22.0
- 

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

