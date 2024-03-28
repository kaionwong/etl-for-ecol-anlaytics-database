import pandas as pd
import os
import helper

helper.pandas_output_setting()
input_dir1 = "mainframe_flat_files"
input_dir2 = "Collisions 2000-2016"
input_filename = 'Collisions'
file_year = 2000
save_switch = True

# Mapping of character positions and column names
column_mapping = [
    (1, 4, "case_year"),
    (5, 12, "case_number"),
    (13, 15, "object_number"),
    (16, 18, "sequence_number"),
    (19, 26, "fatal_file_number"),
    (27, 27, "R3_COLL_COMPLETE_IND"),
    (28, 36, "batch_number"),
    (37, 40, "police_service_code"),
    (41, 55, "police_file_number"),
    (56, 65, "occurrence_date"),
    (56, 59, "occurrence_year"),
    (61, 62, "occurrence_month"),
    (66, 66, "occurrence_day_of_week"),
    (67, 74, "occurrence_time"),
    (75, 75, "in_near"),
    (76, 77, "municipality_type"),
    (78, 107, "municipality"),
    (108, 111, "on_highway"),
    (112, 112, "highway_legal_class"),
    (113, 116, "at_intersection_with_highway"),
    (117, 176, "on_street"),
    (177, 236, "at_intersection_with_street"),
    (237, 242, "not_at_intersection_distance"),
    (243, 244, "not_at_intersection_direction"),
    (245, 245, "not_at_intersection_km_metre"),
    (246, 255, "reported_to_police_date"),
    (256, 263, "reported_time"),
    (264, 264, "police_file_status"),
    (265, 268, "total_vehicles"),
    (269, 272, "total_injured"),
    (273, 276, "total_fatalities"),
    (277, 277, "hit_and_run"),
    (278, 278, "scene_visited_by_police"),
    (279, 280, "special_study"),
    (281, 281, "property_damage_over_1000"),
    (282, 290, "radius_of_curve"),
    (291, 330, "district"),
    (331, 331, "additional_witnesses_on_file"),
    (332, 341, "investigator"),
    (342, 347, "investigator_reg_no"),
    (348, 353, "approving_regimental_no"),
    (354, 363, "fatal_reported_date"),
    (364, 373, "engineer_notified_date"),
    (374, 383, "engineer_report_received_date"),
    (394, 387, "fatal_police_service_code"),
    (388, 391, "collision_type"),
    (392, 393, "vehicle_1_direction_of_travel"),
    (394, 395, "vehicle_2_direction_of_travel"),
    (396, 397, "vehicle_1_maneuver"),
    (398, 399, "vehicle_2_maneuver"),
    (400, 424, "not_at_intersection_reference_point_description"),
    (425, 484, "special_reference_location_description"),
    (485, 488, "highway_number"),
    (489, 491, "control_section"),
    (492, 494, "subsection"),
    (495, 502, "km_post"),
    (503, 513, "latitude"),
    (514, 524, "longitude"),
    (525, 538, "structure_ID"),
    (539, 544, "outside_shoulder_width"),
    (545, 551, "inside_shoulder_width"),
    (552, 559, "surface_width"),
    (560, 565, "median_width"),
    (566, 574, "aadt"),
    (575, 578, "aadt_year"),
    (579, 581, "speed_limit_day"),
    (582, 584, "speed_limit_night"),
    (585, 586, "highway_type"),
    (587, 588, "surface_type"),
    (589, 590, "shoulder_type"),
    (591, 591, "urban_rural"),
    (592, 651, "from_location_reference"),
    (652, 711, "to_location_reference"),
    (712, 713, "road_alignment_a"),
    (714, 715, "road_alignment_b"),
    (716, 717, "intersection_type"),
    (718, 719, "collision_severity"),
    (720, 721, "collision_location"),
    (722, 723, "primary_event"),
    (724, 725, "road_class"),
    (726, 727, "special_facility"),
    (728, 729, "collision_environmental_condition"),
    (730, 731, "collision_surface_condition")
]

# Create a list of dictionaries
data_list = []
input_file_path = os.path.join(input_dir1, input_dir2, f"{input_filename} {file_year}")

# Read the flat file and populate the list
with open(input_file_path, 'r') as file:
    for line in file:
        data = {}
        for start, end, col_name in column_mapping:
            data[col_name] = line[start-1:end].strip()
        data_list.append(data)

# Create DataFrame from the list of dictionaries
df = pd.DataFrame(data_list)

# Display the resulting DataFrame
print(df.head())

if save_switch:
    df.to_csv(f'mainframe_extract_{input_filename.lower()}_{file_year}.csv', index=False)