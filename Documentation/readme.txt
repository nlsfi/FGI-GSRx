%%This folder 'Documentation' is created to upload lecture materails, 'How-Tos', presentations, videos and other related materials related to FGI-GSRx. 

The FGI-GSRx software receiver has been extensively used as a research platform for the last one decade in different national and international Research and Development (R&D) projects to develop, test and validate novel receiver processing algorithms for robust, resilient and precise Position, Navigation and Timing (PNT). At present, the FGI-GSRx can process GNSS signals from multiple constellations, including GPS, Galileo, BeiDou, GLONASS, and NavIC. The software receiver is intended to process raw Intermediate Frequency (IF) signals in post-processing. The processing chain of the software receiver consists of GNSS signal acquisition, code and carrier tracking, decoding the navigation message, pseudorange estimation, and Position, Velocity, and Timing (PVT) estimation. The software architecture is built in such a way that any new algorithm can be developed and tested at any stage in the receiver processing chain without requiring significant changes to the original codes.

Multi-Constellation FGI-GSRx receiver offers diversity and improved accuracy as it evolves from a GPS-only receiver to a more extensive receiver with capabilities from multiple global/regional constellations like Galileo, GLONASS, BeiDou, and NavIC. The FGI-GSRx offers flexible interface and configuration files, where any researcher with basic understanding on the GNSS receiver can further implement their own codes/algorithms at different receiver processing stages. This allows user to go much deeper on the code without thinking greater detail of the actual implementation. 
The FGI-GSRx software receiver is now being released as open source for the whole GNSS community to utilize it and it will also be tied with the book ‘GNSS Software Receivers’ by Cambridge University Press, a next edition of one of the fundamental GNSS textbooks, which is now in press to be published in the second half of 2022 [1].

Source code for FGI-GSRx can be downloaded here: https://github.com/nlsfi/FGI-GSRx
Example raw GNSS data files and FGI-GSRx processed data files can be downloaded here: https://tiedostopalvelu.maanmittauslaitos.fi/tp/julkinen/lataus/tuotteet/FGI-GSRx-OS-DATAFILES

FGI's GNSS Jamming and Spoofing Datasets can be found [here](https://www.maanmittauslaitos.fi/en/research/research/gnss-specialists/fgi-gnss-jamming-and-spoofing-dataset-repository-fgi-jsdr)

Example data for GPS L1C processing can be accessed [here](https://etsin.fairdata.fi/dataset/63f8b776-680b-4c98-ace7-d5e443f2b1c5).

Copyright 2015-2022 Finnish Geospatial Research Institute FGI, National Land Survey of Finland. FGI-GSRx is a free software: you can redistribute it and/or  modify it under the terms of the GNU General Public License as published  by the Free Software Foundation, either version 3 of the License, or any later version. FGI-GSRx software receiver is distributed in the hope  that it will be useful, but WITHOUT ANY WARRANTY, without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details. You should have received a copy of the GNU General Public License along with FGI-GSRx software-defined receiver. If not, please visit the following website for further information: https://www.gnu.org/licenses/.

[1] Borre, K., Fernández-Hernández, I., Lopez-Salcedo, José A., Bhuiyan, M. Z. H. (2022) "GNSS Software Receivers", in press, Cambridge University Press, Publication date: August 2022

Some relevant publications where FGI-GSRx was used as a research tool are listed below.

Liaquat, M., Bhuiyan, M. Z. H., Islam, S., Pääkkönen, I., & Kaasalainen, S. (2024). An Enhanced FGI-GSRx Software-Defined Receiver for the Execution of Long Datasets. Sensors, 24(12), 4015.

Ala-Poikela, M. (2024). BeiDou B1C implementation on a software‑defined GNSS receiver (Master’s thesis, Tampere University). Trepo.
https://trepo.tuni.fi/bitstream/handle/10024/162652/Ala-PoikelaMatti.pdf?sequence=2

Pääkkönen, I., Bhuiyan, M. Z. H., Kaasalainen, S. (2024). Implementation of GPS L1C in an Open-Source Software-Defined Receiver. Proceedings of the 37th International Technical Meeting of the Satellite Division of The Institute of Navigation (ION GNSS+ 2024), Baltimore, Maryland, September 2024, pp. 2926-2939. https://doi.org/10.33012/2024.19747.

Pääkkönen, I. J. A. (2024). Implementation of the new GPS L1C signal in a software-defined Global Navigation Satellite System Receiver (Master’s thesis, Aalto University). Aaltodoc. https://aaltodoc.aalto.fi/items/fd6ad2c3-41fc-4747-aebe-b8f04eba7257

Islam, S., Bhuiyan, M. Z. H., Liaquat, M., Pääkkonen, I., Kaasalainen, S. (2024). An open GNSS spoofing data repository: characterization and impact analysis with FGI-GSRx open-source software-defined receiver. GPS Solution, 28, 176 (2024).

Liaquat, M., Bhuiyan, M. Z. H., Islam, S., Hammarberg, T., and Sanna Kaasalainen, S. (2024). An end-to-end solution towards navigation message authentication utilizing open source FGI-GSRx and FGI-OSNMA. Proceedings of the European Navigation Conference 2024, Noordwijk, Netherlands, 22–24 May 2024.

Pany, T., Akos, D., Arribas, J., Bhuiyan, M. Z. H., Closas, P., Dovis, F., Fernandez-Hernandez, I., Fernández–Prades, C., Gunawardena, S., Humphreys, T., Kassas, Z., López-Salcedo, J. A., Nicola, M., Psiaki, M. L., Rügamer, A., Song, Y-J., & Won, J-H. (2024). "GNSS software-defined radio: History, current developments, and standardization efforts," NAVIGATION, 71(1). https://doi.org/10.33012/navi.628.

Islam, S., Bhuiyan, M. Z. H., Pääkkönen, I., Saajasto, M., Mäkelä, M. and Kaasalainen, S. (2023). "Impact analysis of spoofing on different-grade GNSS receivers,” 2023 IEEE/ION Position, Location and Navigation Symposium (PLANS), Monterey, CA, USA, 2023, pp. 492-499. https://dx.doi.org/ 10.1109/PLANS53410.2023.10139934.

Akos, D., Arribas, J., Bhuiyan, M. Z. H., Closas, P., Dovis, F., Fernandez-Hernandez, I., Fernández–Prades, C., Gunawardena, S., Humphreys, T., Kassas, Z. M., Salcedo, J. A. López., Nicola, M., Pany, T., Psiaki, M. L., Rügamer, A., Song, Y.-J., and Won, J.-H. (2022). GNSS Software Defined Radio: History, Current Developments, and Standardization Efforts. Proceedings of the 35th International Technical Meeting of the Satellite Division of The Institute of Navigation (ION GNSS+ 2022), Denver, Colorado, September 2022. pp. 3180-3209. https://doi.org/10.33012/2022.18434.

Islam, S., Bhuiyan, M. Z. H., Thombre, S., Kaasalainen, S. (2022) “Combating Single Frequency Jamming through a Multi-Frequency Multi-Constellation Software Receiver: A Case Study for Maritime Navigation in the Gulf of Finland, Sensors 2022, 22(6), 2294; https://doi.org/10.3390/s22062294, March’2022.

Linty, N., Bhuiyan, M. Z. H., Kirkko-Jaakkola, M. (2020) “Opportunities and challenges of Galileo E5 wideband real signals processing,” International Conference on Localization and GNSS (ICL-GNSS), Tampere (Finland), pp. 1-6, 2020. DOI: 10.1109/ICL-GNSS49876.2020.9115573.

Islam, S., Bhuiyan, M. Z. H., Nicola L., Thombre, S. (2019) "GPS L5 Software Receiver Implementation in FGI-GSRx," XXXV Finnish URSI Convention on Radio Science. Tampere, Finland, October 2019.

Bhuiyan, M. Z. H., Nikolskiy, S., Linty, N., Hashemi, A., Thombre, S. (2019) "Implementation and Performance Analysis of Galileo E5a and E5b signals in a Software-defined Multi-GNSS Receiver," 7th International Colloquium on Scientific and Fundamental Aspect of GNSS, Zurich, Switzerland, 2019.

Ferrara, N. G., Bhuiyan, M. Z. H., Söderholm, S., Ruotsalainen, L., Kuusniemi, H. (2018) "A New Implementation of Narrowband Interference Detection, Characterization and Mitigation Technique for a Software-defined multi-GNSS Receiver," GPS Solutions, Vol. 22, No. 4, DOI: 10.1007/s10291-018-0769-z, 2018.

Söderholm, S., Bhuiyan, M. Z. H., Ferrara, G., Kuusniemi, H., Thombre, S. (2017) "A Multi-GNSS Software-defined Receiver for Promoting Science within PNT," 6th International Colloquium on Scientific and Fundamental Aspects of GNSS / Galileo, Valencia, Spain, October 2017.

Innac, A., Bhuiyan, M. Z. H, Söderholm, S., Kuusniemi, H. and Gaglione, S. (2016) "Reliability testing for multiple GNSS measurement outlier detection," ENC’2016, Helsinki, Finland, DOI: 10.1109/EURONAV.2016.7530540, 2016.

Söderholm, S., Bhuiyan, M. Z. H., Thombre, S., Ruotsalainen, L., and Kuusniemi, H. (2015) "A Multi-GNSS Software-defined Receiver: Design, Implementation and Performance Benefits," Annals of Telecommunications (2016), pp. 1-12, DOI: 10.1007/s12243-016-0518-7, 2015.

Thombre, S., Bhuiyan, M. Z. H., Söderholm, S., Kirkko-Jaakkola, M., Ruotsalainen, L., and Kuusniemi, H. (2015) "A Software Multi-GNSS Receiver Implementation for the Indian Regional Navigation Satellite System," IETE Journal of Research, DOI: 10.1080/03772063.2015.1093968, 2015.

Bhuiyan, M. Z. H., Honkala, S., Söderholm, S., and Kuusniemi, H. (2015) "Performance Analysis of a Multi-GNSS receiver in the Presence of a Commercial Jammer," International Association of Institutes of Navigation World Congress, Prague, Czech Republic, DOI: 10.1109/IAIN.2015.7352260, October 2015.

Bhuiyan, M. Z. H., Söderholm, S., Thombre, S., Ruotsalainen, L., and Kuusniemi, H. (2015) "Performance Analysis of a Dual-frequency Software-defined BeiDou Receiver with B1 and B2 signals," accepted for publication in Chinese Satellite Navigation Conference 2015 Proceedings: Lecture Notes in Electrical Engineering, Chapter 72, Springer Berlin Heidelberg, Editors: Jiadong Sun, Jingnan Liu, Shiwei Fan, Xiaochun Lu, pp.827-839 April 2015, DOI: 10.1007/978-3-662-46638-4_72, 2015.

Bhuiyan, M. Z. H., Söderholm, S., Kuusniemi, H., Thombre, S., and Ruotsalainen, L. (2015) "Utilization of a Novel Channel Quality Index for Improved Multi-GNSS Positioning in GNSS-denied Environments," 5th Int. Galileo Science Colloquium, Braunschweig, Germany, October 2015.

Bhuiyan, M. Z. H., Söderholm, S., Thombre, S., Ruotsalainen, L., Kuusniemi, H. (2014) "Overcoming the Challenges of BeiDou Receiver Implementation," Sensors 2014, 14, pp. 22082-22098, 2014.

Bhuiyan, M. Z. H., Kuusniemi, H., Söderholm, S., and Airos, E. (2014) "The Impact of Interference on GNSS Receiver Observables – A Running Digital Sum Based Simple Jammer Detector," Raidoengineering journal, Vol. 23, No. 3, pp. 898-906, 2014.

Bhuiyan, M. Z. H., Söderholm, S., Thombre, S., Ruotsalainen, L., and Kuusniemi, H. (2014) "Implementation of a Software-defined BeiDou Receiver," Chinese Satellite Navigation Conference Proceedings: Volume I, Lecture Notes in Electrical Engineering, pp. 751-762, Vol. 303, ISSN 1876-1100, Springer, DOI: https://doi.org/10.1007/978-3-642-54737-9_65, 2014.

Kirkko-Jaakkola, M., Ruotsalainen, L., Bhuiyan, M. Z. H., Söderholm, S., Thombre, S., and Kuusniemi, H. (2014) "Performance of a MEMS IMU Deeply Coupled with a GNSS Receiver under Jamming," UPINLBS’2014, Texas, USA, 20-21 Nov’2014, DOI: 10.1109/UPINLBS.2014.7033711, 2014.

Thombre, S., Bhuiyan, M. Z. H., Söderholm, S., Ruotsalainen, L., Kirkko-Jaakkola, M., and Kuusniemi, H., (2014) "Tracking IRNSS Satellites for Multi-GNSS Positioning in Finland," InsideGNSS, Nov-Dec, 2014.

Kuusniemi H., Bhuiyan M. Z. H., and Kröger T. (2013) "Signal Quality Indicators and Reliability Testing for Spoof-Resistant GNSS Receivers," European Journal of Navigation, 11(2): 12-19, ISSN 1571-473-X, 2013.
