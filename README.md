# Data-Processing-Public
This repository contains MATLAB code to process C3D files, containing 3D marker locations, 3D ground reaction forces and EMG muscle activations, and export them to commonly used file formats in the musculoskeletal software [OpenSim](https://simtk.org/frs/index.php?group_id=91).

The code has been developed to process the dataset, linked below. However, it can also be used to process other C3D files. Some minor tweaks might be required to run the OpenSim pipeline. Scaling OpenSim models has to be performed manually, i.e. is not included in the pipeline.

# Structure
The code is divided into 2 subfolders:

- **data-processing** contains code to read and process the raw C3D files.
- **opensim-tools** contains code to run the OpenSim pipelines (IK, ID, analyze) automatically, for a given set of settings.

We recommend using the main files as an example to using the code:

- **processData.m** allows you to process the raw C3D files, and extract the (processed) marker, ground reaction forces and EMG data.
- **runOpenSim.m** runs the OpenSim pipeline, including IK, ID, and the analysis tool to compute joint powers.
- **processResults.m** combines the processed data, and OpenSim results, into a MAT structure, with gait-averaged, synchronized data.

You can also visualize the processed data, inside the MAT structure, using the **plotData.m** code.

# External Libraries
To run the code, you need to install the libraries and toolboxes below. You can verify whether the installation is complete by running the **verifySetup.m** file. It will prompt you to select the directory where you installed the ezc3d toolbox.

- [OpenSim](https://github.com/opensim-org/opensim-core)
- [ezc3d toolbox](https://github.com/pyomeca/ezc3d/releases/tag/Release_1.5.19)
- [Matlab Robotics System Toolbox](https://nl.mathworks.com/products/robotics.html)

# Citation
The dataset linked to this repository can be found [here](soon).

If you use this repository, please cite the following paper: (currently submitted in Nature Data):

Denayer, M., Turcksin, T., De Pauw, K. & Verstraten, T. (2025). A Full-body Motion Capture Dataset for Bilateral Weighted Shank Walking. _journal name_. _DOI Link_
