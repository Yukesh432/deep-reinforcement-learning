# Modular hand actions for OpenSCAD

This is a simplified ORCA-inspired visual hand, not official ORCA hardware CAD.
All dimensions are in millimeters and angles in degrees. No STL imports needed.

## Start

1. Clone or extract the complete repository. The mounted model imports geometry from `arm scad files/openai_human_bionic_arm.scad`.
2. Open `main.scad` in OpenSCAD. Press F5, then View > View All.
3. Select `action` in the Customizer, or edit its assignment near the top.
4. Open View > Animate (Window > Animate in some versions).
5. Set FPS=24 and Steps=960 for whole-potato peeling (60 frames per band at 16 bands). For the other actions use Steps=240, or Steps=690 for all-joint testing.

The `peel_whole` action moves the hand and peeler around a **stationary potato** in successive latitude bands. The arm carries the hand to the far side and both ends; the potato and holder never translate, spin or tilt. The sequence removes the complete skin, including both polar caps. Select `peel` for the original single-strip pinch/pull/release demonstration, or `arm_reach` for a forward and sideways reach with a grasp.

The blue outline shows the active **wrist socket envelope** in world coordinates. Whole-potato peeling uses X −155 to 155, Y 25 to 335, Z 385 to 645 mm, controlled by `whole_workspace_lower` and `whole_workspace_upper`. This larger envelope allows the hand to travel around the fixed workpiece, whose centre is [0,180,548] mm with the arm shown. Its corners are not all reachable: every wrist target is checked against both the box and the arm's reachable shell. The box is a trajectory envelope, not a claim that its entire volume is reachable.

Other actions retain the smaller X −55 to 55, Y 145 to 285, Z 385 to 477 mm box (110 × 140 × 92 mm, 1.4168 litres), controlled by `workspace_lower` and `workspace_upper`. For these actions the entire box is required to fit within the 180/155 mm arm's reachable shell. The default `reach_margin` is 2 mm from full extension and folding; the smaller box's farthest corner has about 2.1 mm clearance. Toggle `show_workspace` to hide either envelope or `fill_workspace` for a translucent preview fill. These are wrist position checks; fingers, elbow, potato and peel may extend outside the box. They do not certify joint limits or collision clearance.

Open/close, wave and arm reach attach the hand to the forearm transform, including swivel and roll. Open/close also animates finger spread and all three wrist angles. Pinch, cylinder grasp and single-strip peel explicitly maintain the authored world orientation while the elbow swivels. In whole-potato mode the hand frame follows the surface normal, and the three wrist controls make small adjustments. The wrist position compensates both rotations to keep the grip at the peeler handle. Shoulder/elbow motion, elbow swivel and forearm roll accompany the moving hand. Manual and joint-test modes keep the arm steady for inspection. Uncheck `show_arm` for the hand-only scene; its workspace overlay and arm reach checks are then hidden/disabled.

To freeze at a known pose, uncheck `animate` and set `pose_time`.
At 0.5 most single-cycle actions are fully closed. Single-strip peeling reaches maximum pull at 0.65; whole-potato peeling has completed half its bands at 0.5 and all its skin is removed at 1.
The manual action ignores time and uses your manual angle vectors.
Customizer settings can override source edits; reset them if necessary.

## Files

| File | Purpose |
| --- | --- |
| main.scad | Select action and adjust scene settings |
| model/mounted_arm.scad | Reference stand and two-link arm that follows the wrist |
| model/workspace.scad | Wrist envelopes, overlays and optional whole-box reach validation |
| model/hand.scad | Geometry and 23-angle pose interface |
| model/kinematics.scad | Point rotations used to track moving contact frames |
| actions/common.scad | Timing and pose helper functions |
| actions/joint_test.scad | Test one rotation or cycle through all |
| actions/arm_reach.scad | Coordinated 3D reach and grasp |
| actions/open_close.scad | Open and close all digits |
| actions/cylinder_grasp.scad | Authored cylinder grasp with adjustable object |
| actions/pinch.scad | Thumb-index pinch and small target tab |
| actions/peel.scad | Pinch, peel, release, return; surface-length-constrained skin strip |
| actions/peel_whole.scad | Stationary potato, complete surface coverage, moving peeler and coordinated arm |
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

For `peel_whole`, use these controls:

| Control | Meaning |
| --- | --- |
| `whole_peel_bands` | 8–24 latitude bands; one hand circuit per band, default 16 |
| `whole_workspace_lower` / `whole_workspace_upper` | World-space limits for the larger wrist trajectory |
| `show_potato_holder` | Show the stationary support and reference marker |
| `show_whole_peel_strip` | Show skin feeding off the blade and dropping between passes |

For smooth playback, use about `60 * whole_peel_bands` animation steps. Each pass
approaches the skin, moves the hand through 360 degrees around the potato while
cutting, retracts the tool, drops the strip, and moves to the next band. The hand keeps the peeler gripped
between passes and opens at the end. Its thumb/index pose and three wrist controls
move along with the arm. The blade spans the current band's meridian arc. Strip
centreline length follows the removed elliptical latitude arc (96-chord estimate);
its straight hanging shape and discard motion are prescribed.

Skin removal is tracked in the potato's fixed coordinates, so moving the hand
does not restore previous bands. The old `whole_orbit_radius` setting has been
removed. Band limits extend from −90 to +90 degrees to
include both poles. At `pose_time=1` only the flesh remains; starting the animation
over at 0 restores the skin. The holder is an illustrative fixed support, not a
second grasping hand. Support contact and blade/hand/fixture collisions are not
solved; physical pole access would require a support/regrasp strategy.

For single-strip `peel`, `peel_length` is the **surface arc length removed**, in millimetres
(0–53 in the Customizer; the full authored arc is approximately 53.28 mm).
`peel_lift_angle` is the strip's angle above the surface tangent (0–80 degrees).
These replace the old independent `pull_distance` and `lift_distance` controls,
which could demand a strip longer than the available skin. Reset saved Customizer
presets that still use those controls.

The wrist follows the free end of a straight strip whose length equals the peeled
arc. The strip centreline lies in the potato's tangent plane. Surface arc length
uses 96 chords, with less than 0.001 mm total error for this potato. This is a
kinematic constraint, not a material or force solver. The pinch pose remains
authored for the current potato size and contact target.

| Time | Peel behaviour |
| --- | --- |
| 0–0.20 | Close thumb and index at the initial skin target |
| 0.20–0.65 | Advance the peel front, exposing flesh; wrist follows the strip tip |
| 0.65–0.80 | Open the fingers; the released strip starts rotating downward at 0.72 |
| 0.80–1 | Return the wrist; strip finishes hanging at 0.90 and skin stays peeled |
| Next loop at 0 | Reset the demonstration to intact skin |

The released strip remains attached at the peel front. Its downward rotation is
prescribed, not a gravity simulation. At `pose_time=1` the wrist is home and the
skin remains peeled; resetting time to 0 explicitly starts a new demonstration.

For cylinder grasp, change `cylinder_radius`, `cylinder_length`, and
`cylinder_position` in main. The pose does not automatically adjust to these
changes. Edit `cylinder_grasp_pose()` to tune the finger and thumb angles.

To add an action, copy `actions/wave.scad`, rename the pose function and action
module, and change its 23-angle pose. Then add a use statement, dropdown option,
and dispatch branch in main. `bionic_hand(pose)` always stands upright by default.
Wrap that call in translate/rotate to move the entire hand.

## Validation

With Python 3 and OpenSCAD installed, run from the repository root:

```bash
python3 -m unittest discover -s tests -v
```

The checks evaluate every action with and without the mounted arm, exercise
invalid workspace/peel settings, and verify strip length, contact-tip tracking,
release/return separation, and sampled wrist trajectories. CSG evaluation is
not a collision or physical-stability test. Whole-potato checks also cover the
poles, persistent removal, pass-boundary continuity, moving wrist grip alignment,
stationary potato/holder geometry, and the allowed band counts. Hide the workspace before exporting
the scene to STL; the outline is geometry, while the optional fill is preview-only.

## Limits

These are kinematic visual demonstrations. They do not simulate collisions,
friction, grasp stability, tendon mechanics, forces, or adhesion. Meshes may
overlap at joints and during poses. The cylinder preset and pinch target need
visual fitting if you change dimensions. The peel ribbon is a prescribed
illustration, including its reset, not deformable-material simulation.
Single-strip and grasp actions maintain their authored working orientation;
whole-potato mode adjusts the wrist orientation and its position together.
STL exports capture a static fused pose and cannot preserve joints or animation.
For physical grasp or peel tests, build a suitable dynamics/material model.
`test.py` and `arm.xml` remain a separate two-joint MuJoCo example using 300/250 mm
links, not this 180/155 mm CAD arm. A future physics model needs matching link and
hand joints, millimetre-to-metre conversion, a potato support, collision geometry,
contact/friction, and a peel-resistance model before it can support RL experiments.
