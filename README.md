# Deep Reinforcement Learning

Early robotics experiments with a MuJoCo arm simulation and OpenSCAD hand models. The current examples demonstrate scripted motion and CAD animation.

## Project files

- `test.py` and `arm.xml`: a two-joint arm simulation with sinusoidal shoulder and elbow motion.
- `arm scad files/`: bionic arm and articulated hand designs.
- `hand_actions_modular/`: modular hand animations, including grasping, pinching, waving, and joint tests.
- `scad_files/`, `stl_import.scad`, and STL files: additional CAD experiments and meshes.

## Run the arm simulation

From the repository root on Linux, with Python 3 and a graphical desktop:

```bash
python3 -m venv venv
source venv/bin/activate
python -m pip install mujoco
python test.py
```

## View the hand animations

Install OpenSCAD and open `hand_actions_modular/hand_actions/main.scad`. Press **F5**, choose an action in the Customizer, and enable **View > Animate**. Use **FPS 24** and **Steps 240**, or **Steps 690** for the full joint test.

These hand animations are kinematic visual demonstrations. See the [hand actions guide](hand_actions_modular/hand_actions/README.md) for controls and limitations.
