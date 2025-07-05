from sumolib import checkBinary
import traci

sumo_exe = checkBinary("sumo-gui")
traci.start([
    sumo_exe, "-c", "cfg/Jakhospital.sumocfg"
])

import csv
import os
import traci.constants as tc

# ✅ Hapus ketergantungan pada variabel environment
em_vid = "eme"
em_vehicle_start_time = 3000
end_time = 2000000
detect_range = 80
lctime = 3
lcmode = 0b011001000101

road_id = "29977851#1"

def get_vid_info(vid, step):
    acc = traci.vehicle.getAccel(vid)
    speed = traci.vehicle.getSpeed(vid)
    pos = traci.vehicle.getLanePosition(vid)
    lane = traci.vehicle.getLaneIndex(vid)
    return (step, vid, acc, speed, pos, lane)

def main(road_id):
    f = open('data/data.csv', 'a+')
    writer = csv.writer(f)
    step = 0

    # ✅ Selalu gunakan sumo-gui
    sumo_exe = "sumo-gui"

    # ✅ Jalankan traci dengan GUI config
    traci.start([
        sumo_exe, "-c", "cfg/emergency.city.sumo.cfg",
        "--lanechange.duration", "2",
        "--random",
        "--tls.actuated.jam-threshold", "3",
        "--device.bluelight.explicit", "true"
    ])

    # ✅ Atur GUI jika GUI digunakan
    traci.gui.setSchema("View #0", "real world")

    while step < end_time:
        traci.simulationStep()

        if step == em_vehicle_start_time:
            traci.vehicle.add(em_vid, "em_route", typeID="emergency_v", departSpeed="19", departLane="0")
            traci.vehicle.setParameter(em_vid, "emergency", "yes")
            traci.vehicle.setParameter(em_vid, "device.bluelight.reactiondist", str(90))
            traci.vehicle.setMaxSpeed(em_vid, 33)
            traci.vehicle.setSpeedMode(em_vid, 32)

            traci.gui.trackVehicle("View #0", em_vid)
            traci.gui.setZoom("View #0", 3000)

        if step % 20 == 0 and step > em_vehicle_start_time + 800:
            road_id = traci.vehicle.getRoadID(em_vid)
            em_info = get_vid_info(em_vid, step)
            car_list = traci.edge.getLastStepVehicleIDs(road_id)
            if car_list:
                for vid in car_list:
                    res = get_vid_info(vid, step)
                    traci.vehicle.setLaneChangeMode(vid, lcmode)

                    if (res[4] - em_info[4] < detect_range) and (res[4] - em_info[4] > 0) and res[5] == em_info[5] and res[3] > 3:
                        lcsl = traci.vehicle.couldChangeLane(vid, 1)
                        lcsr = traci.vehicle.couldChangeLane(vid, -1)
                        if lcsl:
                            traci.vehicle.changeLaneRelative(vid, 1, lctime)
                            print(f"vid:{vid}, change left")
                        else:
                            traci.vehicle.changeLaneRelative(vid, -1, lctime)
                            print(f"vid:{vid}, change right")
                    elif (res[4] - em_info[4] < detect_range) and (res[4] - em_info[4] > 0) and res[3] > 3:
                        if (res[5] - em_info[5] > 0):
                            traci.vehicle.changeLaneRelative(vid, 1, lctime)
                        if (res[5] - em_info[5] < 0):
                            traci.vehicle.changeLaneRelative(vid, -1, lctime)

        if step % 10 == 0 and step > em_vehicle_start_time - 1000:
            car_list = traci.edge.getLastStepVehicleIDs(road_id)
            if car_list:
                for vid in car_list:
                    res = get_vid_info(vid, step)
                    writer.writerow(res)

        if step % 500 == 0 and step > em_vehicle_start_time - 1000:
            f.flush()

        step += 1

if __name__ == "__main__":
    main(road_id)
