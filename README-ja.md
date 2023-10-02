# 深層強化学習によるサイバーフィジカルシステムの改竄

## 導入

このコンテンツは、サイバーフィジカルシステムの改竄に対する深層強化学習技術を評価するためのものである。4 つのモデル (自動変速機モデル、風力タービンモデル、パワートレイン制御モデル、インスリンモデル) が含まれている。インスリンモデルは現在機能しません。

## 対象

このコンテンツは、技術を評価する研究者や開発者向けである。

## 環境 (テスト済みバージョン)

- MATLAB (R2023a)
- Simulink (10.7)
- Stateflow (10.8)
- Deep Learning Toolbox (14.6)
- Optimization Toolbox (9.5)
- Parallel Computing Toolbox (7.8)
- Python (3.8.9)
- Chainer (7.8.1)
- ChainerRL (0.8.0)
- Gym (0.22.0)
- s-taliro
- breach


## コンテンツ

- metascript.m : ATおよびPTCモデル用のスクリプト(インスリンモデルは現在機能しません)
- metascript_cars.m : CARSモデル用のスクリプト
- metascript_wind_turbine.m : 風力タービンモデルのスクリプト


## 実行例
### 準備
- 作業ディレクトリにPython仮想環境を構築
>詳しくは[Python virtual environments with MATLAB](https://jp.mathworks.com/matlabcentral/answers/1750425-python-virtual-environments-with-matlab)を参照

- `falsify-data`フォルダーに`sldemo_autotrans_data`を追加
>`sldemo_autotrans_data`については[こちら](https://jp.mathworks.com/help/simulink/slref/modeling-an-automatic-transmission-controller.html)を参照

### 実行
"Configuration" という名前のセクションを編集、スクリプトを実行


## ライセンス

(C) 2019 National Institute of Advanced Industrial Science and Technology (AIST)

The contents under the wind-turbine directory is copyrighted by the respective authors.

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.                                    

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.                           

You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
