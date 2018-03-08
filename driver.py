from __future__ import division
from __future__ import print_function
from __future__ import unicode_literals
from __future__ import absolute_import
from builtins import *  # NOQA
from future import standard_library
standard_library.install_aliases()
from os import path
import math
import array

import chainer
from chainer import functions as F
from chainer import links as L
import numpy as np

from chainerrl.agents import a3c
from chainerrl import experiments
from chainerrl import links
from chainerrl import misc
from chainerrl.optimizers.nonbias_weight_decay import NonbiasWeightDecay
from chainerrl.optimizers import rmsprop_async
from chainerrl import policies
from chainerrl.recurrent import RecurrentChainMixin
from chainerrl import v_function


def phi(obs):
    return obs.astype(np.float32)

class A3CLSTMGaussian(chainer.ChainList, a3c.A3CModel, RecurrentChainMixin):
    """An example of A3C recurrent Gaussian policy."""

    def __init__(self, obs_size, action_size, hidden_size=200, lstm_size=128):
        self.pi_head = L.Linear(obs_size, hidden_size)
        self.v_head = L.Linear(obs_size, hidden_size)
        self.pi_lstm = L.LSTM(hidden_size, lstm_size)
        self.v_lstm = L.LSTM(hidden_size, lstm_size)
        self.pi = policies.LinearGaussianPolicyWithDiagonalCovariance(
            lstm_size, action_size)
        self.v = v_function.FCVFunction(lstm_size)
        super().__init__(self.pi_head, self.v_head,
                         self.pi_lstm, self.v_lstm, self.pi, self.v)

    def pi_and_v(self, state):

        def forward(head, lstm, tail):
            h = F.relu(head(state))
            h = lstm(h)
            return tail(h)

        pout = forward(self.pi_head, self.pi_lstm, self.pi)
        vout = forward(self.v_head, self.v_lstm, self.v)

        return pout, vout

obs_space_dim = 3 # Dimension of observations
action_space_dim = 2 # Dimension of actions

agent = None

def start_learning():
    global agent
    model = A3CLSTMGaussian(obs_space_dim, action_space_dim)
    opt = rmsprop_async.RMSpropAsync(
        lr=7e-4, eps=1e-1, alpha=0.99)
    opt.setup(model)
    opt.add_hook(chainer.optimizer.GradientClipping(40))
    agent = a3c.A3C(model, opt, t_max=10, gamma=0.80,
                beta=1e-2, phi=phi)

def driver(r,s,g,Robustness):
    reward = math.exp( - Robustness)
    state = np.array([r, s, g], np.float32)
    action = agent.act_and_train(state, reward)
    throttle = float(action[0])
    brake = float(action[1])
    throttle = min(max(throttle, -1.0), 1.0)
    brake = min(max(brake, -1.0), 1.0)
    return array.array('d', [throttle, brake])

def stop_episode():
    agent.stop_episode()

def save(savefiles):
    agent.save(savefiles)

def load(savefiles):
    agent.load(savefiles)
