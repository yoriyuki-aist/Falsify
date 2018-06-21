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
import sys

import gym
import gym.spaces
import functools

import chainer
from chainer import functions as F
from chainer import links as L
import numpy as np

import chainerrl
from chainerrl.agents import a3c
from chainerrl import experiments
from chainerrl import links
from chainerrl import misc
from chainerrl.optimizers.nonbias_weight_decay import NonbiasWeightDecay
from chainerrl.optimizers import rmsprop_async
from chainerrl import policies
from chainerrl.recurrent import RecurrentChainMixin
from chainerrl import v_function
from chainerrl.agents.dqn import DQN
from chainerrl import explorers
from chainerrl import q_functions
from chainerrl import replay_buffer
from chainerrl.replay_buffer import EpisodicReplayBuffer
from chainerrl import v_functions

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

def make_ddqn_agent(obs_space_dim, action_space_dim):
    gamma = 1
    obs_low = np.array([-1] * obs_space_dim)
    obs_high = np.array([1] * obs_space_dim)
    ac_low = np.array([-1] * action_space_dim)
    ac_high = np.array([1] * action_space_dim)
    obsSpace = gym.spaces.Box(obs_low, obs_high)
    actSpace = gym.spaces.Box(ac_low, ac_high)

    qFunc = q_functions.FCQuadraticStateQFunction(
            obsSpace.low.size, actSpace.low.size,
            n_hidden_channels=50,
            n_hidden_layers=2,
            action_space=actSpace)
    optimizer = chainer.optimizers.Adam(eps=1e-2)
    optimizer.setup(qFunc)
    # Use AdditiveOU for exploration
    ou_sigma = (actSpace.high - actSpace.low) * 0.25
    explorer = explorers.AdditiveOU(sigma=ou_sigma)
    # DQN uses Experience Replay.
    # Specify a replay buffer and its capacity.
    replay_buffer = chainerrl.replay_buffer.ReplayBuffer(capacity=10 ** 6)
    phi = lambda x: x.astype(np.float32, copy=False)
    agent = chainerrl.agents.DoubleDQN(
        qFunc, optimizer, replay_buffer, gamma, explorer,
        replay_start_size=500, update_interval=1,
        target_update_interval=100, phi=phi)
    return agent

def make_acer_agent(obs_space_dim, action_space_dim):
    def phi(obs):
        return obs.astype(np.float32, copy=False)
    obs_low = np.array([-1] * obs_space_dim)
    obs_high = np.array([1] * obs_space_dim)
    ac_low = np.array([-1] * action_space_dim)
    ac_high = np.array([1] * action_space_dim)
    obs_space = gym.spaces.Box(obs_low, obs_high)
    action_space = gym.spaces.Box(ac_low, ac_high)
    model = chainerrl.agents.acer.ACERSDNSeparateModel(
            pi=policies.FCGaussianPolicy(
                obs_space.low.size, action_space.low.size,
                n_hidden_channels=50,
                n_hidden_layers=2,
                bound_mean=True,
                min_action=action_space.low,
                max_action=action_space.high),
            v=v_functions.FCVFunction(
                obs_space.low.size,
                n_hidden_channels=50,
                n_hidden_layers=2),
            adv=q_functions.FCSAQFunction(
                obs_space.low.size, action_space.low.size,
                n_hidden_channels=50 // 4,
            n_hidden_layers=2),
            )

    opt = rmsprop_async.RMSpropAsync(
        lr=7e-4, eps=1e-1, alpha=0.99)
    opt.setup(model)
    opt.add_hook(chainer.optimizer.GradientClipping(40))

    replay_buffer = EpisodicReplayBuffer(10)
    agent = chainerrl.agents.acer.ACER(model, opt, t_max=5, gamma=1,
                      replay_buffer=replay_buffer,
                      n_times_replay=1,
                      replay_start_size=50,
                      disable_online_update=False,
                      use_trust_region=True,
                      trust_region_delta=0.1,
                      truncation_threshold=5,
                      beta=0.5, phi=phi)
    return agent

def make_a3c_agent(obs_space_dim, action_space_dim):
    model = A3CLSTMGaussian(obs_space_dim, action_space_dim)
    opt = rmsprop_async.RMSpropAsync(
        lr=7e-4, eps=1e-1, alpha=0.99)
    opt.setup(model)
    opt.add_hook(chainer.optimizer.GradientClipping(40))
    agent = a3c.A3C(model, opt, t_max=5, gamma=1,
                beta=1e-2, phi=phi)
    return agent

def start_learning(algo, obs_space_dim, action_space_dim):
    obs_space_dim = int(obs_space_dim)
    action_space_dim = int(action_space_dim)
    if algo == 'A3C':
        return make_a3c_agent(obs_space_dim, action_space_dim)
    elif algo == 'DDQN':
        return make_ddqn_agent(obs_space_dim, action_space_dim)
    elif algo == 'ACER':
        return make_acer_agent(obs_space_dim, action_space_dim)
    else:
        sys.exit('unknown algo')

misc.set_random_seed(0)
#log_f = open('/Users/yoriyuki/Reference/TestGenforCPS/falsify-old-model/driver-log', 'a')

def driver(agent, state, r):
    reward = math.exp( - r) - 1.0
    state = np.array(state, np.float32)
    action = agent.act_and_train(state, reward)
    action = np.minimum(1.0, np.maximum(-1.0, action))
#    print('state = {}, t = {}, b = {}'.format(state, throttle, brake), file=log_f)
#    log_f.flush()
    return array.array('d', action.tolist())

def stop_episode(agent):
    agent.stop_episode()

def stop_episode_and_train(agent, state, reward):
    s = np.array(state, np.float32)
    agent.stop_episode_and_train(s, reward)

def save(savefiles):
    agent.save(savefiles)

def load(savefiles):
    agent.load(savefiles)
