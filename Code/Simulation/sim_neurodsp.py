# Import sim functions
from neurodsp.sim.combined import sim_combined
from neurodsp.utils import set_random_seed

# Import function to compute power spectra
from neurodsp.spectral import compute_spectrum

# Import utilities for plotting data
from neurodsp.utils import create_times
from neurodsp.plts.spectral import plot_power_spectra
from neurodsp.plts.time_series import plot_time_series

import numpy as np

# Set the random seed, for consistency simulating data
set_random_seed(0)

# Set some general settings, to be used across all simulations
fs = 1000
n_seconds = 100
times = create_times(n_seconds, fs)

# Define the components of the combined signal to simulate
components = {'sim_synaptic_current' : {'n_neurons' : 1000, 'firing_rate' : 2, 't_ker' : 1.0,
                                        'tau_r' : 0.002, 'tau_d' : 0.02}}

# Simulate an oscillation over an aperiodic component
signal = sim_combined(n_seconds, fs, components)

# Plot the simulated data, in the time domain
plot_time_series(times, signal)

# Plot the simulated data, in the frequency domain
freqs_pre, psd_pre = compute_spectrum(signal, fs)
plot_power_spectra(freqs_pre, psd_pre)

#############
signal_post = signal*0.01

# Plot the simulated data, in the time domain
plot_time_series(times, signal_post)

# Plot the simulated data, in the frequency domain
freqs_post, psd_post = compute_spectrum(signal_post, fs)
plot_power_spectra(freqs_post, psd_post)

file_path_set1 = '/Users/admin/Desktop/simulated_data/choice1.csv'
file_path_set2 = '/Users/admin/Desktop/simulated_data/choice2.csv'
np.savetxt(file_path_set1, signal, delimiter=',')
np.savetxt(file_path_set2, signal_post, delimiter=',')

file_path_set1, file_path_set2


