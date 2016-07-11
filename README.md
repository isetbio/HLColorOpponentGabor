# IBIOColorDetect

An isetbio computational observer for threshold detection thresholds of color Gabor stimuli.  The goal of these calculations is to understand how various factors early in the visual pathways limit performance on this simple and rigorously characterized visual task.

The place to get started is with the tutorials.  These are designed to build up to the full caclulation in stages.  Code that is illustrated in the initial tutorials is encapsulated in routines in the toolbox, with those routines called in more advanced tutorials.

## Tutorial List

t_colorGaborScene - Shows how to make an isetbio scene representing a colored Gabor pattern presented on a calibrated CRT monitor.  This is the basic stimulus whose detection threshold we are modeling in this project.  The code illustrated in this tutorial is encapsulated in function colorGaborSceneCreate.

t_colorGaborConeAbsorptionMovie - Shows how to take a temporally windowed color Gabor stimulus (Gaussian window) and compute a movie of the cone mosaic isomerizations at each time sampling point.  This relies on function colorGaborSceneCreate.

t_colorGaborConeCurrentEyeMovementsMovie - This goes further and adds modeling of eye movements as well as the tranformation from absorption to the outer segment cone current.  The functionality showin in this tutorial is encapsulated in the function colorDetectResponseInstanceConstruct.

t_colorGaborConeCurrentEyeMovementsResponseInstances - For building classifiers, we need to get multiple noisy instances 