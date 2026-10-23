import mujoco, mujoco.viewer, time, math

model = mujoco.MjModel.from_xml_path("arm.xml")
data = mujoco.MjData(model)

with mujoco.viewer.launch_passive(model, data) as v:
    t0 = time.time()
    while v.is_running():
        t = time.time() - t0
        data.ctrl[0] = 0.8 * math.sin(t)          # shoulder target (rad)
        data.ctrl[1] = 1.2 * (1 + math.sin(t)) / 2  # elbow target (rad)
        mujoco.mj_step(model, data)
        v.sync()
        time.sleep(model.opt.timestep)