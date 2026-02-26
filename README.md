### FGI-GSRx
FGI-GSRx is a multi-constellation GNSS software-defined receiver developed and used extensively over the past decade for research and development in robust, resilient, and precise Positioning, Navigation, and Timing (PNT). It supports major GNSS constellations including GPS, Galileo, BeiDou, GLONASS, and NavIC. The receiver performs post-processing of raw Intermediate Frequency (IF) data through a complete GNSS signal processing chain: acquisition, code and carrier tracking, navigation message decoding, pseudorange estimation, and Position, Velocity, and Timing (PVT) computation.

The design of FGI-GSRx is modular, enabling researchers to modify or insert new algorithms at any stage without extensive changes to the underlying architecture. This flexibility has made it a key tool in numerous national and international research projects requiring experimentation with advanced GNSS receiver algorithms.
FGI-GSRx is open-source and is associated with the updated edition of the textbook 'GNSS Software Receivers' by Cambridge University Press. Supporting datasets include raw GNSS recordings, jamming and spoofing datasets, and GPS L1C example data, which are publicly available.
The software is distributed under the GNU General Public License (GPL v3), ensuring freedom to modify and redistribute the code while disclaiming warranties.


### FGI-GSRx v2.1.1
FGI GSRx v2.1.1 introduces an important enhancement: full parallel tracking support using MATLAB’s Parallel Computing Toolbox (PCT). This allows users to significantly accelerate the processing of long GNSS datasets by executing tracking channels concurrently.
Two parallel execution modes are now available:
1.	Multi instance execution via automatically generated batch script, which was released with FGI-GSRx-v2.0.0, and
2.	MATLAB PCT execution, which runs all tracking channels in parallel and automatically merges results into a single tracking dataset. This enables users to complete acquisition, tracking, and PVT in a single run. The parallel execution mode is now released with v2.1.1. 
A new configuration parameter, PCTenabled, has been added to support this functionality. 
Overall, v2.1.1 significantly improves receiver execution performance especially for large datasets and high throughput GNSS processing tasks.


### FGI-GSRx v2.1.0

To support experimentation, we have also published raw GNSS I/Q data files and MATLAB (.mat) datasets that can be processed with FGI-GSRx v2.1.0 to obtain authenticated position solutions using OSNMA.

Access the datasets here: [FGI OSNMA datasets](https://www.maanmittauslaitos.fi/en/research/research/gnss-specialists/fgi-gnss-jamming-and-spoofing-dataset-repository-fgi-jsdr)

Explore our related research presented at European Navigation Conference 2024: [An End-to-End Solution Towards Authenticated Positioning Utilizing Open-Source FGI-GSRx and FGI-OSNMA](https://www.mdpi.com/2673-4591/88/1/58).
