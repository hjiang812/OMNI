# OMNI

This repository hosts the open-sourced resource corresponding to our article: A 1024-channel 583-nW/ch Spike-Sorting SoC with Sparsity-Aware Spike Detection Scratchpad and Ultra-Low-Leakage Dual-Voltage 5T-SRAM for 16K-Template Clustering. It includes:

(1) Software configuration used to synthesize the 1024-channel dataset, along with the example snippet of our neural recordings

(2) On-chip algorithm for selecting the hottest/coldest templates

🚧 This project is under active development.

# Example snippet of our neural recordings, along with the software configuration used to synthesize the 1024-channel dataset.

1024-channel neural dataset can be generated based on the MEArec tool with the following script:

  Neuropixel.yaml: The probe geometry is based on the Neuropixels 2.0 design. Each probe contains 256 channels, and we combine four probes to construct a 1024-channel neural recording system.
  Template_params.yaml: Drifting is not considered in our experiments.
  Recordings_params.yaml:Each probe contains seven types of spikes.

In addition, our data is also acquired using the MATLAB version of our neural recording generator. This tool follows the principles of MEArec, but allows us to use real neuron templates and measured firing rates to generate synthetic datasets. This enables the dataset to better reflect the variability in firing rates across different neurons. We have also open-sourced this generation pipeline in this repository.

Note: Due to NDA restrictions, we currently release: An example snippet of the generated data with 10 experimentally recorded neurons. The remaining related datasets will be released progressively in the future.


If you have any questions, please feel free to contact me at 21112020134@m.fudan.edu.cn at any time.
