# Modular hand actions for OpenSCAD

This is a simplified ORCA-inspired visual hand, not official ORCA hardware CAD.
All dimensions are in millimeters and angles in degrees. No STL imports needed.

## Start

1. Extract the complete ZIP. Keep its folder structure.
2. Open `main.scad` in OpenSCAD. Press F5, then View > View All.
3. Select `action` in the Customizer, or edit its assignment near the top.
4. Open View > Animate (Window > Animate in some versions).
5. Set FPS=24 and Steps=240. For all-joint testing, use Steps=690.

To freeze at a known pose, uncheck `animate` and set `pose_time`.
At 0.5 most actions are fully closed. Peeling reaches maximum pull at 0.65.
The manual action ignores time and uses your manual angle vectors.
Customizer settings can override source edits; reset them if necessary.

## Files

| File | Purpose |
| --- | --- |
| main.scad | Select action and adjust scene settings |
| model/hand.scad | Geometry and 23-angle pose interface |
| actions/common.scad | Timing and pose helper functions |
| actions/joint_test.scad | Test one rotation or cycle through all |
| actions/open_close.scad | Open and close all digits |
| actions/cylinder_grasp.scad | Authored cylinder grasp with adjustable object |
| actions/pinch.scad | Thumb-index pinch and small target tab |
| actions/peel.scad | Pinch, pull, release, return; schematic peel ribbon |
| actions/wave.scad | Wrist wave with open fingers |
| actions/manual.scad | Direct control of every angle |

Each action file can also be opened directly for its default preview.
`use <...>` imports its module/functions without running that preview.
Main passes time and settings explicitly. There are no hidden angle assignments
shared between actions. Edit a motion in its own file; edit shape in the model.

## Joint numbers

| IDs | Part | Order |
| --- | --- | --- |
| 0-3 | Index | spread, base, middle, tip |
| 4-7 | Middle | spread, base, middle, tip |
| 8-11 | Ring | spread, base, middle, tip |
| 12-15 | Little | spread, base, middle, tip |
| 16-19 | Thumb | spread, opposition, base, tip |
| 20-22 | Wrist | bend, side-to-side, axial rotation |

Set action="joint_test", selected_joint=2 to test only the index middle joint.
An orange joint indicates the tested rotation; a multi-axis joint ball can
represent more than one control. These are 23 rotation controls, not a claim
about the DOF count of actual ORCA hardware.

## Tune and extend

For cylinder grasp, change `cylinder_radius`, `cylinder_length`, and
`cylinder_position` in main. The pose does not automatically adjust to these
changes. Edit `cylinder_grasp_pose()` to tune the finger and thumb angles.

To add an action, copy `actions/wave.scad`, rename the pose function and action
module, and change its 23-angle pose. Then add a use statement, dropdown option,
and dispatch branch in main. `bionic_hand(pose)` always stands upright by default.
Wrap that call in translate/rotate to move the entire hand.

## Limits

These are kinematic visual demonstrations. They do not simulate collisions,
friction, grasp stability, tendon mechanics, forces, or adhesion. Meshes may
overlap at joints and during poses. The cylinder preset and pinch target need
visual fitting if you change dimensions. The peel ribbon is a prescribed
illustration, including its reset, not deformable-material simulation.
During peeling, the entire wrist base translates as though carried by an arm.
STL exports capture a static fused pose and cannot preserve joints or animation.
For physical grasp or peel tests, build a suitable dynamics/material model.
