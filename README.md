# Data-Processing-Public
This repository contains MATLAB code to process C3D files, containing 3D marker locations, 3D ground reaction forces and EMG muscle activations, and export them to commonly used file formats in the musculoskeletal software [OpenSim](https://simtk.org/frs/index.php?group_id=91).

The code has been developed to process the dataset, linked below. However, it can also be used to process other C3D files. Some minor tweaks might be required to run the OpenSim pipeline. Scaling OpenSim models has to be performed manually, i.e. is not included in the pipeline.

# Structure
The code is divided into 3 subfolders:

- **data-processing** contains code to read and process the raw C3D files.
- **opensim-tools** contains code to run the OpenSim pipelines (IK, ID, analyze) automatically, for a given set of settings.
- **model-creation** contains codes to generate the weighted OpenSim models, representing subjects with added mass around the shank (see dataset/paper for more information).

We recommend using the main files as an example to using the code:

- **processData.m** allows you to process the raw C3D files, and extract the (processed) marker, ground reaction forces and EMG data. We recommend creating a folder, containing all of the C3D files, for one subject, and selecting this folder when processing the data. In this way, all the trials are used when computing the MVC scaling.
- **runOpenSim.m** runs the OpenSim pipeline, including IK, ID, and the analysis tool to compute joint powers. The code assumes the input files are sorted in the same order (e.g. trial 1 for markers, GRF etc., then trial 2 ...).
- **processResults.m** combines the processed data, and OpenSim results, into a MAT structure, with gait-averaged, synchronized data. As the code assumes the files are sorted in the same order for the different variables (GRF, markers, EMG etc.), make sure that files, created from the static & MVC trials are removed from the directory.

You can also visualize the processed data, inside the MAT structure, using the **plotData.m** code.

# External Libraries
To run the code, you need to install the libraries and toolboxes below. You can verify whether the installation is complete by running the **verifySetup.m** file. It will prompt you to select the directory where you installed the ezc3d toolbox.

- [OpenSim](https://github.com/opensim-org/opensim-core)
- [ezc3d toolbox](https://github.com/pyomeca/ezc3d/releases/tag/Release_1.5.19)
- [Matlab Robotics System Toolbox](https://nl.mathworks.com/products/robotics.html)

# Citation
The dataset linked to this repository can be found [here](coming soon).

If you use this repository, please cite the following paper: (currently submitted in Nature Data):

Denayer, M., Turcksin, T., De Pauw, K. & Verstraten, T. (2025). A Full-body Motion Capture Dataset for Bilateral Weighted Shank Walking. _journal name_. _DOI Link_
